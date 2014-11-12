//
//  Download.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 11/6/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import CoreData


/* manages a session for downloading presentation media from the remote server */
class PresentationDownloadSession : NSObject, NSURLSessionDelegate {
	/* main model */
	let mainModel : DitourModel

	/* unique background session identifier */
	let backgroundSessionID : String

	/* indicates whether the session is actively downloading */
	var active = true

	/* indicates whether the session has been canceled */
	var canceled = false

	/* file download status keyed by task */
	let downloadTaskRemoteItems = ConcurrentDictionary<String,String>()

	/* URL Session for managing the download */
	let downloadSession : NSURLSession!

	/* completion handler for background session */
	private var backgroundSessionCompletionHandler : ( ()->Void )?

	/* download status of the group */
	private(set) var groupStatus : ILobbyDownloadContainerStatus?


	init(mainModel: DitourModel) {
		self.mainModel = mainModel

		self.backgroundSessionID = PresentationDownloadSession.makeBackgroundSessionID()

		let configuration = PresentationDownloadSession.makeBackgroundConfiguration(self.backgroundSessionID)
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


	/* save the specified context all the way to the root persistent store */
	func persistentSaveContext(context: NSManagedObjectContext, error errorPtr: NSErrorPointer) -> Bool {
		return self.mainModel.persistentSaveContext(context, error: errorPtr)
	}
}



// protocol for remote directory items (RemoteFile or RemoteDirectory)
protocol RemoteDirectoryItem {
	/* remote location of the item */
	var location : NSURL { get }

	/* indicates whether this item is a directory */
	var isDirectory : Bool { get }
}



// parsed item for a remote (either NSURL representing a directory or RemoteFile)
private protocol RemoteParsedItem {}



// extend NSURL to conform to the RemoteParsedItem protocol used in parsing
extension NSURL : RemoteParsedItem {}



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
			for (key, attribute) in attributeDict as [String: String] {
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


