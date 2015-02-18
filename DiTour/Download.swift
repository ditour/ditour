//
//  Download.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 11/6/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import CoreData


// MARK: Presentation Group Download Session
/* manages a session for downloading presentation media from the remote server */
class PresentationGroupDownloadSession : NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate {
	/* main model */
	let mainModel : DitourModel

	/* unique background session identifier */
	let backgroundSessionID : String

	/* indicates whether the session is actively downloading */
	var active = true

	/* indicates whether the session has been canceled */
	var canceled = false

	/* file download status keyed by download task */
	let downloadTaskRemoteItems = ConcurrentDictionary<NSURLSessionTask,DownloadFileStatus>()

	/* URL Session for managing the download */
	private(set) var downloadSession : NSURLSession!

	/* completion handler for background session */
	private var backgroundSessionCompletionHandler : ( ()->Void )?

	/* download status of the group */
	private(set) var groupStatus : DownloadContainerStatus?


	//MARK: - Configuration and initialization

	init(mainModel: DitourModel) {
		self.mainModel = mainModel

		self.backgroundSessionID = PresentationGroupDownloadSession.makeBackgroundSessionID()

		let configuration = PresentationGroupDownloadSession.makeBackgroundConfiguration(self.backgroundSessionID)
		configuration.HTTPMaximumConnectionsPerHost = 4

		super.init()

		self.downloadSession = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
	}


	/* create a unique background session identifier */
	private class func makeBackgroundSessionID() -> String {
		let formatter = NSDateFormatter()
		formatter.dateFormat = "yyyyMMdd'-'HHmmss.SSSS"

		let timestamp = formatter.stringFromDate(NSDate())
		return "DiTour.DownloadSession_\(timestamp)"
	}


	/* make a new background configuration */
	private class func makeBackgroundConfiguration(backgroundSessionID: String) -> NSURLSessionConfiguration {
		// need to call best method available for making a new background configuraton
		if NSURLSessionConfiguration.respondsToSelector("backgroundSessionConfigurationWithIdentifier:") {
			// proper method to call in iOS 8 (available starting in iOS 8)
			return NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundSessionID)
		}
		else {
			// needed for iOS 7 but deprecated in iOS 8
			return NSURLSessionConfiguration.backgroundSessionConfiguration(backgroundSessionID)
		}
	}


	/* if background session ID matches the specified identifier, then handle events for background session and return true otherwise return false */
	func handleEventsForBackgroundURLSession( identifier: String, completionHandler: ()->Void ) -> Bool {
		if identifier == self.backgroundSessionID {
			self.backgroundSessionCompletionHandler = completionHandler
			return true
		} else {
			return false
		}
	}


	//MARK: - State control

	/* cancel the session due to an explicit request or error */
	func cancel() {
		if self.active {
			self.active = false
			self.canceled = true

			self.groupStatus?.canceled = true
			self.downloadSession.invalidateAndCancel()
			self.publishChanges()
		}
	}


	/* stop the session due to normal termination */
	func stop() {
		if self.active {
			self.active = false

			self.downloadSession.invalidateAndCancel()
			self.publishChanges()
		}
	}


	/* update the group status */
	func updateStatus() {
		self.groupStatus?.updateProgress()

		// if all tasks have been submitted and no tasks remain then we can cancel the session
		if (self.groupStatus?.completed ?? false) && self.downloadTaskRemoteItems.count == 0 {
			self.stop()
			self.publishChanges()
			self.mainModel.reloadPresentationNextCycle()
		}
	}


	/* publish changes to the persistent storage */
	func publishChanges() {
		if let groupStatus = self.groupStatus {
			let group = groupStatus.remoteItem
			group.managedObjectContext!.performBlockAndWait{ () -> Void in
				group.managedObjectContext!.refreshObject(group, mergeChanges: true)
			}
			self.persistentSaveContext(groupStatus.remoteItem.managedObjectContext!, error: nil)
		}
	}


	//MARK: - Download

	/* initiate downloading of the specified group and provide updates to the specified delegate */
	func downloadGroup(group: PresentationGroupStore, delegate: DownloadStatusDelegate) -> DownloadContainerStatus {
		let status = DownloadContainerStatus(remoteItem: group, container: nil)

		status.delegate = delegate
		self.groupStatus = status

		// perform the updates on the global queue
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) { () -> Void in
			group.managedObjectContext!.performBlockAndWait { () -> Void in
				var possibleError : NSError?

				group.markDownloading()

				// cache the initial config if any so we can reuse the file if possible
				let initialConfig = group.configuration

				// remove any existing pending presentations as we will create new ones so stale ones are no longer useful
				group.managedObjectContext!.refreshObject(group, mergeChanges: true)
				for presentation in group.pendingPresentations as [PresentationStore] {
					group.removePresentation(presentation)
					group.managedObjectContext!.deleteObject(presentation)
				}
				self.persistentSaveContext(group.managedObjectContext!, error: &possibleError)

				// ------------- fetch the directory references from the remote URL

				if let groupRemoteDirectory = RemoteDirectory.parseDirectoryAtURL(group.remoteURL!, error: &possibleError) {
					// process any files (e.g. config files)
					var hasRemoteConfig = false		// indicates whether there is a remote config file to load
					for remoteFile in groupRemoteDirectory.files {
						hasRemoteConfig = group.processRemoteFile(remoteFile)
					}

					// store the active presentations by name so they can be used as parents if necessary
					var activePresentationsByName = [String:PresentationStore]()
					for presentation in group.activePresentations {
						activePresentationsByName[presentation.name] = presentation
					}

					// fetch presentations
					for remotePresentationDirectory in groupRemoteDirectory.subdirectories {
						let presentation = PresentationStore.newPresentationInGroup(group, from: remotePresentationDirectory)

						// if an active presentation has the same name then assign it as a parent
						if let presentationParent = activePresentationsByName[presentation.name] {
							presentation.parent = presentationParent
						}
					}

					// any active presentation which does not have a revision should be removed except for the currently playing one if any
					for presentation in group.activePresentations {
						if presentation.revision == nil {
							presentation.markDisposable()

							if !presentation.isCurrent {
								group.removePresentation(presentation)
								group.managedObjectContext!.deleteObject(presentation)
							}
						}
					}

					self.persistentSaveContext(group.managedObjectContext!, error: &possibleError)

					// updates fetched properties
					group.managedObjectContext?.refreshObject(group, mergeChanges: true)

					// ----------- now begin downloading the files

					// if the group has a configuration then determine whether the configuration file can be copied from the initial one
					if hasRemoteConfig {
						if let groupConfiguration = group.configuration {
							// if the intial config exists and is up to date, we can just use it, otherwise download a new copy
							let fileManager = NSFileManager.defaultManager()
							switch (initialConfig?.remoteInfo, initialConfig?.absolutePath) {
							case (.Some(let initialConfigInfo), .Some(let initialConfigPath)) where initialConfigInfo == groupConfiguration.remoteInfo && initialConfigPath == groupConfiguration.absolutePath && fileManager.fileExistsAtPath(initialConfigPath):
								groupConfiguration.markReady()
							default:
								// since there was no match dispose of the old config file if any
								if let initialConfigPath = initialConfig?.absolutePath {
									if fileManager.fileExistsAtPath(initialConfigPath) {
										self.removeFileAt(initialConfigPath)
									}
								}
								// download a new config file
								self.downloadRemoteFile(groupConfiguration, containerStatus: status, cache: [String:RemoteFileStore]())
							}
						}
					} else if initialConfig != nil {	// since the configuration is no longer used, remove it
						group.configuration = nil
						group.managedObjectContext!.deleteObject(initialConfig!)
					}

					// download the presentations and immediately perform all the copies from existing files
					for pendingPresentation in group.pendingPresentations {
						self.downloadPresentation(pendingPresentation, groupStatus: status)
					}

					// at this point all status items have been submitted
					status.submitted = true
					self.updateStatus()

					// loop over all download tasks and begin running them
					for (downloadTask,_) in self.downloadTaskRemoteItems {
						downloadTask.resume()
					}
				} else {	// something happened that caused the remote directory parsing to fail
					if let error = possibleError {
						println("Error downloading group: \(error.localizedDescription)")
						status.possibleError = error
						self.cancel()
					} else {
						self.stop()
					}
					
					group.markPending()
				}
			}
		}

		return status
	}


	/* Download a presentation */
	private func downloadPresentation(presentation: PresentationStore, groupStatus: DownloadContainerStatus) {
		let status = DownloadContainerStatus(remoteItem: presentation, container: groupStatus)

		presentation.managedObjectContext!.performBlockAndWait { () -> Void in
			var possibleError : NSError? = nil
			NSFileManager.defaultManager().createDirectoryAtPath(presentation.absolutePath, withIntermediateDirectories: true, attributes: nil, error: &possibleError)

			if let error = possibleError {
				status.possibleError = error
				println("Error creating presentation directory: \(presentation.absolutePath) with error: \(error.localizedDescription)")
			} else {
				presentation.markDownloading()

				// generate the cache of local items in the parent if any keyed by URL spec
				let localCache = presentation.parent?.generateFileDictionaryKeyedByURL() ?? [String:RemoteFileStore]()

				if let configuration = presentation.configuration {
					self.downloadRemoteFile(configuration, containerStatus: status, cache: localCache)
				}

				for track in presentation.tracks.array as! [TrackStore] {
					self.downloadTrack(track, presentationStatus: status, cache: localCache)
				}

				status.submitted = true
			}
		}
	}


	/* Download a track */
	private func downloadTrack(track: TrackStore, presentationStatus: DownloadContainerStatus, cache: [String:RemoteFileStore]) {
		let status = DownloadContainerStatus(remoteItem: track, container: presentationStatus)

		track.managedObjectContext!.performBlockAndWait { () -> Void in
			var possibleError : NSError?
			NSFileManager.defaultManager().createDirectoryAtPath(track.absolutePath, withIntermediateDirectories: true, attributes: nil, error: &possibleError)

			if let error = possibleError {
				status.possibleError = error
				println("Error creating track directory: \(error.localizedDescription)")
			} else {
				track.markDownloading()

				if let configuration = track.configuration {
					self.downloadRemoteFile(configuration, containerStatus: status, cache: cache)
				}

				for remoteMedia in (track.remoteMedia.array as! [RemoteMediaStore]) {
					self.downloadRemoteFile(remoteMedia, containerStatus: status, cache: cache)
				}

				status.submitted = true
			}
		}
	}


	/* Download a remote file */
	private func downloadRemoteFile(remoteFile: RemoteFileStore, containerStatus: DownloadContainerStatus, cache: [String:RemoteFileStore]) {
		let status = DownloadFileStatus(remoteItem: remoteFile, container: containerStatus)
		remoteFile.managedObjectContext!.performBlockAndWait { () -> Void in
			if remoteFile.isPending {
				// first see if the local cache has a current version of the file we want
				if let cachedFile = cache[remoteFile.remoteLocation] {
					let cacheInfo = cachedFile.remoteInfo
					let remoteInfo = remoteFile.remoteInfo
					if remoteInfo == cacheInfo {
						let fileManager = NSFileManager.defaultManager()

						if fileManager.fileExistsAtPath(cachedFile.absolutePath) {
							// create a hard link from the original path to the new path so we save space
							var error : NSError?
							let success = fileManager.linkItemAtPath(cachedFile.absolutePath, toPath: remoteFile.absolutePath, error: &error)
							if success {
								remoteFile.markReady()
								status.completed = true
								status.setAndPropagateProgress(1.0, forcePropagation: true)
								self.updateStatus()
								return
							} else {
								status.possibleError = error
								println("Error creating hard link to remote file: \(remoteFile.absolutePath) from existing file at \(cachedFile.absolutePath)")
							}
						}
					}
				}

				// anything that fails in using the cache file will fall through to here which forces a fresh fetch to the server
				//Create a new download task using the URL session. Tasks start in the “suspended” state; to start a task you need to explicitly call -resume on a task after creating it.

				let downloadURL = remoteFile.remoteURL
				let request = NSURLRequest(URL: downloadURL!)
				let downloadTask = self.downloadSession.downloadTaskWithRequest(request)
				self.downloadTaskRemoteItems[downloadTask] = status
				remoteFile.markDownloading()
//				downloadTask.resume()
			}
		}
	}


	//MARK: - NSURLSession Task and Download Delegate Implementation

	/* download task incrementally wrote some data */
	func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		// report progress on the task
		let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
		if let downloadStatus = self.downloadTaskRemoteItems[downloadTask] {
			downloadStatus.setAndPropagateProgress(progress, forcePropagation: false)
		}
	}


	/* download task finished normally */
	func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
		if let downloadStatus = self.downloadTaskRemoteItems[downloadTask] {
			let remoteFile = downloadStatus.remoteItem as! RemoteFileStore
			var destination : String!
			var remoteURL : NSURL!
			remoteFile.managedObjectContext?.performBlockAndWait{ () -> Void in
				destination = remoteFile.absolutePath
				remoteURL = remoteFile.remoteURL
			}

			let fileManager = NSFileManager.defaultManager()
			var error : NSError?

			if fileManager.fileExistsAtPath(destination) {
				println("Error: Existing file at destination: \(destination) for remote: \(remoteURL)")
			} else {
				fileManager.copyItemAtPath(location.path!, toPath: destination, error: &error)
			}

			if error != nil {
				// cached the current cancel state since we will be canceling
				let alreadyCanceled = self.canceled

				self.cancel()
				downloadStatus.possibleError = error

				// if not already canceled then this is the causal error for the group since we will get a flood of errors due to the cancel which we can ignore
				if !alreadyCanceled {
					self.groupStatus?.possibleError = error
					println("Error copying file from \(location) to \(destination), \(error!.localizedDescription)")
				}
			}

			downloadStatus.completed = true
			downloadStatus.setAndPropagateProgress(1.0, forcePropagation: true)

			self.persistentSaveContext(remoteFile.managedObjectContext!, error: nil)
			self.updateStatus()
		}
	}


	/* task completed with the possibility of an error */
	func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		if let downloadStatus = self.downloadTaskRemoteItems[task] {
			let remoteFile = downloadStatus.remoteItem as! RemoteFileStore

			if error == nil {	// normal completion
				remoteFile.managedObjectContext?.performBlock{ () -> Void in
					remoteFile.markReady()
				}
			} else {		// completed with error
				// cached the current cancel state since we will be canceling
				let alreadyCanceled = self.canceled

				self.cancel()
				downloadStatus.possibleError = error

				// if not already canceled then this is the causal error for the group since we will get a flood of errors due to the cancel which we can ignore
				if !alreadyCanceled {
					self.groupStatus?.possibleError = error
					println("Task: \(task) completed with error: \(error?.localizedDescription)")
				}

				remoteFile.managedObjectContext?.performBlock{ () -> Void in
					remoteFile.markPending()
				}
			}

			// download completed whether successful or not
			downloadStatus.completed = true

			self.downloadTaskRemoteItems.removeValueForKey(task)

			// if all tasks have been submitted and no tasks remain then we can cancel the session
			if self.groupStatus!.completed && self.downloadTaskRemoteItems.count == 0 {
				self.stop()
			}

			self.persistentSaveContext(remoteFile.managedObjectContext!, error: nil)
			self.updateStatus()
		}
	}


	/*
	If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message, the session delegate will receive this message to indicate that all messages previously enqueued for this session have been delivered. At this time it is safe to invoke the previously stored completion handler, or to begin any internal updates that will result in invoking the completion handler.
	*/
	func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
		if let completionHandler = self.backgroundSessionCompletionHandler {
			self.backgroundSessionCompletionHandler = nil
			completionHandler()
		}
	}


	/* download resumed */
	func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
		// Not yet supported
	}


	//MARK: - Private Utility

	/* remove the file at the specified path */
	private func removeFileAt( path: String ) {
		var possibleError: NSError?
		let fileManager = NSFileManager.defaultManager()

		if fileManager.fileExistsAtPath(path) {
			fileManager.removeItemAtPath(path, error: &possibleError)
		}

		if let error = possibleError {
			println( "Error deleting existing file at destination: \(path) with error: \(error.localizedDescription)" )
			self.cancel()
		}
	}


	/* save the specified context all the way to the root persistent store */
	private func persistentSaveContext(context: NSManagedObjectContext, error errorPtr: NSErrorPointer) -> Bool {
		return self.mainModel.persistentSaveContext(context, error: errorPtr)
	}
}



// MARK: - Download Status Delegate

/* Protocol (applies to classes only) for download status delegation */
@objc protocol DownloadStatusDelegate: class {
	func downloadStatusChanged( status: DownloadStatus )
}



// MARK: - Download Status

/* holds the status of a container or file being downloaded */
class DownloadStatus : NSObject {
	/* remote item being downloaded */
	let remoteItem : RemoteItemStore

	/* container status if any of this status */
	let container : DownloadContainerStatus?

	/* bare download progress */
	dynamic var progress : Double = 0.0
//	{
//		didSet {
//			println("progress updated from \(oldValue) to \(self.progress) for item at: \(self.remoteItem.path)")
//		}
//	}


	/* download progress as a float - convenience property */
	var floatProgress : Float { return Float( self.progress ) }
	
	/* indicates whether the corresponding download is complete */
	dynamic var completed : Bool = false {
		didSet {
			if completed {
				processCompleted()
			}
		}
	}

	/* indicates whether the corresponding download was canceled */
	dynamic var canceled : Bool = false {
		didSet {
			if canceled {
				processCanceled()
			}
		}
	}

	/* download error if any */
	var possibleError : NSError?

	/* delegate for download status changes */
	weak var delegate : DownloadStatusDelegate?


	/* description of this status */
	override var description : String {
		return "location: \(self.remoteItem.remoteLocation), progress: \(self.progress), complete: \(self.completed)"
	}


	init(remoteItem: RemoteItemStore, container: DownloadContainerStatus?) {
		self.remoteItem = remoteItem
		self.container = container

		super.init()

		container?.addChildStatus(self)
	}


	private func processCompleted() {
		// important for the following code to block since marking ready must complete before setting the progress which in turn propagates progress state
		self.remoteItem.managedObjectContext!.performBlockAndWait{ () -> Void in
			if self.possibleError == nil && !self.canceled {	// normal completion
				self.remoteItem.markReady()
			}

			if let container = self.container {
				let remoteContainer = container.remoteItem
				// force any fetched properties of the containing object to refresh
				self.remoteItem.managedObjectContext!.refreshObject(remoteContainer, mergeChanges: true)
			}
		}

		self.setAndPropagateProgress(1.0, forcePropagation: true)
	}


	/* set the canceled property */
	private func processCanceled() {
		// we're done and post event
		self.completed = true
	}


	/* set progress and force propagation on change or if flag is true */
	func setAndPropagateProgress(progress: Double, forcePropagation: Bool=true) {
		// only need to propagate changes if there is actually a change or forced to do so
		if progress != self.progress || forcePropagation {
			self.progress = progress
			propagateProgress()
		}
	}


	/* propagate progress up to the container */
	private func propagateProgress() {
		self.container?.updateProgress()
		self.delegate?.downloadStatusChanged(self)
	}


	/* determine whether this object's remote item matches (same objectID) the other remote item */
	func matchesRemoteItem(otherRemoteItem: RemoteItemStore) -> Bool {
		if self.remoteItem == otherRemoteItem {		// reference identity is sufficient
			return true
		} else {
			var remoteItemID : NSManagedObjectID?
			self.remoteItem.managedObjectContext!.performBlockAndWait{ () -> Void in
				remoteItemID = self.remoteItem.objectID
			}

			var otherRemoteItemID: NSManagedObjectID?
			otherRemoteItem.managedObjectContext!.performBlockAndWait{ () -> Void in
				otherRemoteItemID = otherRemoteItem.objectID
			}

			return remoteItemID == otherRemoteItemID
		}
	}
}



// MARK: - Download Container Status

/* download status for a container */
class DownloadContainerStatus : DownloadStatus {
	/* indicates whether the corresponding remote item was submitted for download */
	var submitted : Bool = false {
		didSet {
			if submitted {
				self.updateProgress()
			}
		}
	}

	/* child status items keyed by child status' remote item object ID */
	let childStatusItems : ConcurrentDictionary<String,DownloadStatus>


	override init(remoteItem: RemoteItemStore, container: DownloadContainerStatus?) {
		self.childStatusItems = ConcurrentDictionary()

		super.init(remoteItem: remoteItem, container: container)
	}


	/* description of this status */
	override var description : String {
		return super.description + ", submitted: \(self.submitted)"
	}


	/* update the progress */
	private func updateProgress() {
		if self.childStatusItems.count > 0 {
			var childCount = 0
			var completionCount = 0
			var progressSum = 0.0			// cumulative progress of all children
			var possibleChildError : NSError?

			for (_,childStatus) in self.childStatusItems {
				++childCount

				progressSum += childStatus.progress

				// count the number of child items completed
				if childStatus.completed {
					++completionCount
				}

				if childStatus.possibleError != nil {
					possibleChildError = childStatus.possibleError
				}
			}

			// the progress of this container is the average progress over all children
			self.setAndPropagateProgress(childCount > 0 ? progressSum / Double(childCount) : 1.0, forcePropagation: false)

			// bubble error up if this is the causal error
			if self.possibleError == nil && possibleChildError != nil {
				self.possibleError = possibleChildError
			}

			if self.submitted && completionCount == childCount {
				self.completed = true
			}
		} else if self.submitted {
			self.completed = true
		}
	}


	/* set the canceled property */
	override private func processCanceled() {
		// push events down
		for (_,childStatus) in self.childStatusItems {
			childStatus.canceled = true
		}

		super.processCanceled()
	}


	/* add the specified status as a child status */
	func addChildStatus(childStatus: DownloadStatus) {
		var possibleChildPath : String?
		let remoteChildItem = childStatus.remoteItem
		remoteChildItem.managedObjectContext!.performBlockAndWait { () -> Void in
			possibleChildPath = remoteChildItem.path
		}

		if let childPath = possibleChildPath {
			self.childStatusItems[childPath] = childStatus
			self.updateProgress()
		}
	}


	/* get the child status if any for the specified remote item path */
	func childStatusForRemoteItemPath(path: String) -> DownloadStatus? {
		return self.childStatusItems[path]
	}


	/* get the child status corresponding to the specified child remote item */
	func childStatusForRemoteItem(remoteItem: RemoteItemStore) -> DownloadStatus? {
		var path : String?
		remoteItem.managedObjectContext!.performBlockAndWait { () -> Void in
			path = remoteItem.path
		}

		return path != nil ? self.childStatusForRemoteItemPath(path!) : nil
	}


	/* set a common delegate on each child */
	func setChildrenDelegate(childrenDelegate: DownloadStatusDelegate) {
		for (_,childStatus) in self.childStatusItems {
			childStatus.delegate = childrenDelegate
		}
	}


	/* print child info */
	func printChildInfo() {
		println("Child count: \(self.childStatusItems.count)")
		for (path,_) in self.childStatusItems {
			println("Child Path: \(path)")
		}
	}
}



// MARK: - Download File Status

/* download status for a file */
class DownloadFileStatus : DownloadStatus {}



// MARK: - Remote Directory Item Protocol
// protocol for remote directory items (RemoteFile or RemoteDirectory)
protocol RemoteDirectoryItem {
	/* remote location of the item */
	var location : NSURL { get }

	/* indicates whether this item is a directory */
	var isDirectory : Bool { get }
}



// MARK: - Remote Parsed Item Protocol
// parsed item for a remote (either NSURL representing a directory or RemoteFile)
private protocol RemoteParsedItem {}



// MARK: - NSRUL Extension - Remote Parsed Item
// extend NSURL to conform to the RemoteParsedItem protocol used in parsing
extension NSURL : RemoteParsedItem {}



// MARK: Remote File
/* Represents a file on a remote server */
class RemoteFile : NSObject, RemoteDirectoryItem, RemoteParsedItem {
	/* remote location of the file */
	private(set) var location: NSURL

	/* indicates whether this item is a directory (always returns false) */
	var isDirectory: Bool { return false }

	/* information about the file from the remote directory */
	private(set) var info : String


	/* description of this remote file including the location and info */
	override var description : String {
		return "location: \(self.location.absoluteString), info: \(self.info)"
	}


	init(location: NSURL, info: String) {
		self.location = location
		self.info = info
	}
}



// MARK: Remote Directory
/* Represents a directory on a remote server */
class RemoteDirectory : NSObject, RemoteDirectoryItem {
	/* remote location of the file */
	private(set) var location: NSURL

	/* indicates whether this item is a directory (always returns false) */
	var isDirectory: Bool { return true }

	/* array of remote directory items (files and subdirectories) */
	private(set) var items = [RemoteDirectoryItem]()

	/* array of those items that are simple files */
	private(set) var files = [RemoteFile]()

	/* array of those items that are subdirectories */
	private(set) var subdirectories = [RemoteDirectory]()


	private init(location: NSURL) {
		self.location = location
	}


	/* parse the specified URL to generate a remote directory */
	class func parseDirectoryAtURL(directoryURL: NSURL, error errorPtr: NSErrorPointer) -> RemoteDirectory? {
		return RemoteDirectoryParser.parseDirectoryAtURL(directoryURL, error: errorPtr)
	}


	/* description of this remote directory */
	override var description : String {
		var description = "location: \(self.location.absoluteString)\n"
		description += "\n"

		// include the description of each directory item (files and subdirectories)
		for item in self.items {
			description += "\t\(item)\n"
		}

		description += "\n"
		return description
	}
}


// MARK: Remote Directory Parser
/* generates a remote directory from a remote location and the content of the associated HTML directory pages */
private class RemoteDirectoryParser : NSObject, NSXMLParserDelegate {
	/* location of the the dremote directory to parse */
	let directoryURL : NSURL

	/* indicates whether there are any items */
	var isEmpty : Bool { return self.items.count == 0 }

	/* an item may either be RemoteFile (ordinary file) or NSURL (subdirectory) */
	private var items = [RemoteParsedItem]()

	/* current file link being parsed */
	private var currentFileLink : NSURL?

	/* text of element sibling of the current anchor */
	private var currentFileLinkText: String?


	init(location: NSURL) {
		self.directoryURL = location
	}


	/* Parse the directory at the specified loation */
	class func parseDirectoryAtURL(directoryURL: NSURL, error errorPtr: NSErrorPointer) -> RemoteDirectory? {
		let remoteDirectory = RemoteDirectory(location: directoryURL)
		var error: NSError?
		var usedEncoding: UnsafeMutablePointer<UInt> = nil

		let rawDirectoryContents = NSString(contentsOfURL: directoryURL, usedEncoding: usedEncoding, error: &error)

		if error != nil {
			// propagate the error
			if errorPtr != nil {
				errorPtr.memory = error
			}

			return nil
		}

		// if there are directory contents to process convert to XHTML and parse it
		if let directoryContents = rawDirectoryContents?.toXHTMLWithError(&error) {
			if error != nil {
				if errorPtr != nil {
					errorPtr.memory = error
				}

				return nil
			}

			if let directoryData = directoryContents.dataUsingEncoding(NSUTF8StringEncoding) {
				let xmlParser = NSXMLParser(data: directoryData)
				let directoryParser = RemoteDirectoryParser(location: directoryURL)
				xmlParser.delegate = directoryParser

				// if parsing succeeds construct the remote directory
				if xmlParser.parse() {
					// a remote item may either be a RemoteFile (ordinary file) or RemoteDirectory (subdirectory)
					var directoryItems = [RemoteDirectoryItem]()
					var files = [RemoteFile]()
					var subdirectories = [RemoteDirectory]()

					// pass files to remote directory and parse subdirectory URLs converting them to subdirectories and passing them on to the remote directory
					for parserItem in directoryParser.items {
						switch parserItem {
						case let subdirectoryURL as NSURL:
							var subError : NSError?
							if let subdirectory = RemoteDirectory.parseDirectoryAtURL(subdirectoryURL, error: &subError) {
								directoryItems.append(subdirectory)
								subdirectories.append(subdirectory)
							} else if ( subError != nil ) {
								println("Subdirectory parsing error: \(subError)")
							}
						case let remoteFile as RemoteFile:
							directoryItems.append(remoteFile)
							files.append(remoteFile)
						default:
							// getting here is an error
							println( "Error: parser item is neither an URL nor remote file." )
							break
						}
					}
					remoteDirectory.items = directoryItems
					remoteDirectory.files = files
					remoteDirectory.subdirectories = subdirectories
				} else {
					if errorPtr != nil {
						errorPtr.memory = xmlParser.parserError
					}
					return nil
				}
			}
		}

		return remoteDirectory
	}


	/* enter a new element */
	func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
		if elementName.uppercaseString == "A" {
			// convert all keys to uppercase so we can grab an attribute by key unambiguously
			var anchorAttributes = [String: String]()
			for (key, attribute) in attributeDict as! [String: String] {
				anchorAttributes[key.uppercaseString] = attribute
			}

			// get the href attribute
			if let href = anchorAttributes["HREF"] {
				if let anchorURL = NSURL(string: href, relativeToURL: self.directoryURL) {
					// reject query URLs
					if anchorURL.query != nil {
						self.closeFileLinkInfo()
						return
					}

					// test whether the referenced item is a direct child of the directory otherwise reject it
					if anchorURL.path?.stringByDeletingLastPathComponent == self.directoryURL.path {
						if anchorURL.absoluteString!.hasSuffix("/") {	// it is a directory
							self.closeFileLinkInfo()
							self.items.append(anchorURL)
						} else {
							self.currentFileLink = anchorURL
						}
					}
				}
			}
		} else {
			// whenever a new element other than an anchor starts, the anchor's sibling text node ends
			self.closeFileLinkInfo()
		}
	}


	/* used to complete the current file link if any */
	func closeFileLinkInfo() {
		if let currentFileLink = self.currentFileLink {
			let remoteFile = RemoteFile(location: currentFileLink, info: self.currentFileLinkText!)
			self.items.append(remoteFile)
			self.currentFileLink = nil
		}

		self.currentFileLinkText = nil
	}


	/* process text associated with the current element */
	func parser(parser: NSXMLParser!, foundCharacters string: String!) {
		if let currentFileLinkText = self.currentFileLinkText {
			self.currentFileLinkText = currentFileLinkText + string
		} else {
			self.currentFileLinkText = string
		}
	}
}


