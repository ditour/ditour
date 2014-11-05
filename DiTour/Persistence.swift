//
//  Persistence.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 10/30/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import CoreData



/* local persistent store of a reference to a file on a remote server */
class RemoteFileStore : ILobbyStoreRemoteItem {
	/* class constants */
	private struct Constants {
		/* format for writing timestamps */
		static private let DATE_FORMATTER : NSDateFormatter = {
			let formatter = NSDateFormatter()
			formatter.timeStyle = .MediumStyle
			formatter.dateStyle = .MediumStyle
			return formatter
		}()
	}

	/* name of the file without the directory path */
	var name : String { return self.path.lastPathComponent }

	/* full summary including both the remote and local summaries */
	var summary : String {
		return "\(self.remoteSummary)\n\n\n\(self.localSummary)"
	}


	/* summary about the local file */
	var localSummary : String {
		let defaultLocalSummary = "No Local Info..."

		let fileManager = NSFileManager.defaultManager()
		if fileManager.fileExistsAtPath(self.absolutePath()) {
			var error : NSError? = nil
			let fileAttributes = fileManager.attributesOfItemAtPath(self.absolutePath(), error: &error) as [String:NSObject]
			if ( error == nil ) {
				let modDate = fileAttributes[NSFileModificationDate] as NSDate
				let fileSize = fileAttributes[NSFileSize] as NSNumber
				let fileSizeString = NSByteCountFormatter.stringFromByteCount(fileSize.longLongValue, countStyle: .File)
				return "Local ModificationDate:\n\t\(Constants.DATE_FORMATTER.stringFromDate(modDate))\n\nLocal File Size:\n\t\(fileSizeString)\n\n\(self.localDataSummary)"
			}
		}

		return defaultLocalSummary
	}

	/* summary of the local file's data */
	var localDataSummary : String { return "" }

	/* summary about the remote file */
	var remoteSummary : String { return "Remote Location:\n\t\(self.remoteLocation)\n\nRemote Info:\n\t\(self.remoteInfo)" }

	// indicates whether the candidate URL matches a type supported by the class
	class func matches(candidateURL: NSURL) -> Bool {
		return true
	}
}



/* persistent store for a configuration */
class ConfigurationStore : RemoteFileStore {
	@NSManaged var container : ILobbyStoreRemoteContainer?


	/* generate a new instance */
	class func newConfigurationInContainer(container: ILobbyStoreRemoteContainer, at remoteFile: ILobbyRemoteFile) -> ConfigurationStore {
		let configuration = NSEntityDescription.insertNewObjectForEntityForName( "Configuration", inManagedObjectContext: container.managedObjectContext!) as ConfigurationStore

		configuration.container = container
		configuration.status = NSNumber(short: REMOTE_ITEM_STATUS_PENDING)
		configuration.remoteLocation = remoteFile.location.absoluteString
		configuration.remoteInfo = remoteFile.info
		configuration.path = container.path.stringByAppendingPathComponent(remoteFile.location.lastPathComponent)

		return configuration
	}


	// indicates whether the candidate URL matches a type supported by the class
	override class func matches(candidateURL: NSURL) -> Bool {
		return candidateURL.lastPathComponent.lowercaseString == "config.json"
	}
}



/* persistent store for remote media */
class RemoteMediaStore : RemoteFileStore {
	@NSManaged var track : TrackStore


	class func newRemoteMediaInTrack(track: TrackStore, at remoteFile: ILobbyRemoteFile) -> RemoteMediaStore {
		let mediaStore = NSEntityDescription.insertNewObjectForEntityForName("RemoteMedia", inManagedObjectContext: track.managedObjectContext!) as RemoteMediaStore

		mediaStore.track = track
		mediaStore.status = NSNumber(short: REMOTE_ITEM_STATUS_PENDING)
		mediaStore.remoteLocation = remoteFile.location.absoluteString
		mediaStore.remoteInfo = remoteFile.info
		mediaStore.path = track.path.stringByAppendingPathComponent(remoteFile.location.lastPathComponent)

		return mediaStore
	}


	// indicates whether the candidate URL matches a type supported by the class
	override class func matches(candidateURL: NSURL) -> Bool {
		let supportedExtensions = Slide.allSupportedExtensions()
		if let fileExtension = candidateURL.path?.pathExtension.lowercaseString {
			return supportedExtensions.containsObject(fileExtension)
		}
		else {
			return false
		}
	}
}



/* persistent store for a track */
class TrackStore : ILobbyStoreRemoteContainer {
	@NSManaged var title: String
	@NSManaged var presentation: PresentationStore
	@NSManaged var remoteMedia: NSOrderedSet

	/* Compute and store the effective configuration */
	// TODO: this property should be renamed and replace effectiveConfiguration()
	// TODO: the property type should be changed to [String: AnyObject]
	lazy var effectiveConfigurationProperty : NSDictionary = {
		var effectiveConfig = NSMutableDictionary()

		// first append the configuration inherited from the enclosing presentation
		if let persentationConfig = self.presentation.effectiveConfiguration {
			effectiveConfig.addEntriesFromDictionary(persentationConfig)
		}

		// now merge in the configuration directly specified for this track
		if let trackConfig = self.parseConfiguration() {
			effectiveConfig.addEntriesFromDictionary(trackConfig)
		}

		return effectiveConfig.copy() as NSDictionary
	}()


	/* construct a new track in the specified presentation from the specified remote directory */
	class func newTrackInPresentation(presentation: PresentationStore, from remoteDirectory: ILobbyRemoteDirectory) -> TrackStore {
		let track = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: presentation.managedObjectContext!) as TrackStore

		track.presentation = presentation
		track.status = NSNumber(short: REMOTE_ITEM_STATUS_PENDING)
		track.remoteLocation = remoteDirectory.location.absoluteString

		let rawName = remoteDirectory.location.lastPathComponent
		track.path = presentation.path.stringByAppendingPathComponent(rawName)

		// remove leading digits, replace underscores with spaces and trasnform to title case
		track.title = rawName.toTrackTitle()

		for remoteFile in remoteDirectory.files as [ILobbyRemoteFile] {
			track.processRemoteFile( remoteFile )
		}

		return track
	}


	override func processRemoteFile(remoteFile: ILobbyRemoteFile!) {
		let location = remoteFile.location
		if RemoteMediaStore.matches(location) {
			RemoteMediaStore.newRemoteMediaInTrack(self, at: remoteFile)
		}
		else {
			super.processRemoteFile(remoteFile)
		}
	}


	/* Get the effective configuration at the level of this track inheriting from this track's container */
	// TODO: this should be reimplemented completely as a lazy property
	// TODO: when enough relevant classes are ported to Swift the return type should change to [String: AnyObject]
	func effectiveConfiguration() -> NSDictionary {
		return self.effectiveConfigurationProperty
	}
}



// regular expression to match a series of consecutive digits followed by a single underscore
private let REGEX_DIGITS_UNDERSCORE: NSRegularExpression = {
	return NSRegularExpression(pattern: "\\d+_", options:.CaseInsensitive, error: nil)!
}()

/* extend String to add convenience methods for Track name processing */
extension String {
	/* 
		Transform a raw track name into a title suitable for display 
		- Leading digits and underscore are stripped
		- Remaining underscores are converted to spaces
	*/
	func toTrackTitle() -> String {
		return self.stripLeadingDigitsAndUnderscore().toSpacesFromUnderscores()
	}


	/* strip leading digits and underscore */
	func stripLeadingDigitsAndUnderscore() -> String {
		let stringLength = (self as NSString).length
		if let match = REGEX_DIGITS_UNDERSCORE.firstMatchInString(self, options: NSMatchingOptions(0), range: NSMakeRange(0, stringLength)) {
			if ( match.range.location == 0 && match.range.length < stringLength ) {
				return (self as NSString).substringFromIndex(match.range.length)
			}
			else {
				return self
			}
		}
		else {
			return self
		}
	}


	/* underscores to spaces */
	func toSpacesFromUnderscores() -> String {
		return self.stringByReplacingOccurrencesOfString("_", withString: " ")
	}
}



/* persistent store for a presentation */
class PresentationStore : ILobbyStoreRemoteContainer {
	/* class constants */
	private struct Constants {
		/* entity name */
		static let ENTITY_NAME = "Presentation"


		/* format for writing base paths */
		static private let BASE_PATH_DATE_FORMATTER : NSDateFormatter = {
			let formatter = NSDateFormatter()
			formatter.dateFormat = "yyyyMMdd'-'HHmmss"
			return formatter
		}()
	}

	@NSManaged var name: String
	@NSManaged var timestamp: NSDate

	@NSManaged var group: PresentationGroupStore
	@NSManaged var parent: PresentationStore?
	@NSManaged var revision: PresentationStore?
	@NSManaged var rootForCurrent: ILobbyStoreRoot?
	@NSManaged var tracks: NSOrderedSet

	// indicates whether this presenation is the current one being displayed
	var current: Bool {
		get {
			return self.rootForCurrent != nil
		}
		set {
			if newValue {
				if !self.current {
					self.group.root.currentPresentation = self
				}
			} else {
				if self.current {
					self.rootForCurrent = nil
				}
			}
		}
	}

	// synonymm for current
	var isCurrent: Bool { return self.current }

	class var entityName: String { return Constants.ENTITY_NAME }


	/* Compute and store the effective configuration */
	// TODO: this property should be renamed and replace effectiveConfiguration()
	// TODO: the property type should be changed to [String: AnyObject]
	lazy var effectiveConfigurationProperty : NSDictionary = {
		var effectiveConfig = NSMutableDictionary()

		// first append the configuration inherited from the enclosing group
		if let groupConfig = self.group.effectiveConfiguration {
			effectiveConfig.addEntriesFromDictionary(groupConfig)
		}

		// now merge in the configuration directly specified for this presentation
		if let presentationConfig = self.parseConfiguration() {
			effectiveConfig.addEntriesFromDictionary(presentationConfig)
		}

		return effectiveConfig.copy() as NSDictionary
	}()


	/* construct a new presentation in the specified group from the specified remote directory */
	class func newPresentationInGroup(group: PresentationGroupStore, from remoteDirectory: ILobbyRemoteDirectory) -> PresentationStore {
		let presentation = NSEntityDescription.insertNewObjectForEntityForName(Constants.ENTITY_NAME, inManagedObjectContext: group.managedObjectContext!) as PresentationStore

		presentation.status = NSNumber(short: REMOTE_ITEM_STATUS_PENDING)
		presentation.timestamp = NSDate()
		presentation.remoteLocation = remoteDirectory.location.absoluteString
		presentation.name = remoteDirectory.location.lastPathComponent
		presentation.group = group

		let dateString = Constants.BASE_PATH_DATE_FORMATTER.stringFromDate( NSDate() )
		let basePath = "\(presentation.name)-\(dateString)"

		presentation.path = group.path.stringByAppendingPathComponent(basePath)

		// fetch the tracks
		// TODO: cleanup code once all code is in Swift
		for remoteTrackDirectory in (remoteDirectory.subdirectories as [ILobbyRemoteDirectory]) {
			TrackStore.newTrackInPresentation(presentation, from: remoteTrackDirectory)
		}

		for remoteFile in (remoteDirectory.files as [ILobbyRemoteFile]) {
			presentation.processRemoteFile(remoteFile)
		}

		return presentation
	}


	/* Get the effective configuration at the level of this track inheriting from this track's container */
	// TODO: this should be reimplemented completely as a lazy property
	// TODO: when enough relevant classes are ported to Swift the return type should change to [String: AnyObject]
	func effectiveConfiguration() -> NSDictionary {
		return self.effectiveConfigurationProperty
	}


	/* mark this presentation as ready replacing an older parent presentation if necessary */
	override func markReady() {
		super.markReady()

		// if this presentation has a parent then replace the parent with this one since it is ready
		if let parentPresentation = self.parent {
			let current = parentPresentation.isCurrent
			self.group.removePresentation(parentPresentation)

			// if the parent was current this presentation should also be current
			if ( current ) {
				self.current = current;
			}

			self.parent = nil

			// mark the presentation as disposable so it can be cleaned up later if necessary (e.g. if it is current we can't delete until the new presentation is loaded for playback)
			parentPresentation.markDisposable()

			// don't delete the resources of any currently playing presentation; we can clean them up later
			if !current {
				parentPresentation.managedObjectContext?.deleteObject(parentPresentation)
			}
		}
	}


	/* generate a dictionary of every model object associated with this presentation keyed by its remote URL */
	// TODO: NSDictionary is really [String:RemoteFileStore]
	func generateFileDictionaryKeyedByURL() -> NSDictionary {
		let fileManager = NSFileManager.defaultManager()
		var dictionary = NSMutableDictionary()

		// record the presentation configuration if any
		if ( self.configuration != nil && self.configuration.isReady && fileManager.fileExistsAtPath(self.configuration.absolutePath()) ) {
			dictionary[self.configuration.remoteLocation] = self.configuration
		}

		// record files associated with the tracks
		for track in self.tracks.array as [TrackStore] {
			// record each track configurations if any
			if let trackConfig = track.configuration {
				if trackConfig.isReady && fileManager.fileExistsAtPath(trackConfig.absolutePath()) {
					dictionary[trackConfig.remoteLocation] = trackConfig
				}
			}

			// record the each track's slide media
			for media in track.remoteMedia.array as [RemoteMediaStore] {
				if media.isReady && fileManager.fileExistsAtPath(media.absolutePath()) {
					dictionary[media.remoteLocation] = media
				}
			}
		}

		return dictionary.copy() as NSDictionary
	}
}



/* persistent store for a presentation group */
class PresentationGroupStore : ILobbyStoreRemoteContainer {
	/* class constants */
	private struct Constants {
		/* entity name */
		static let ENTITY_NAME = "PresentationGroup"


		// format for the group based on the timestamp when the group was created
		static private let BASE_PATH_DATE_FORMATTER : NSDateFormatter = {
			let formatter = NSDateFormatter()
			formatter.dateFormat = "yyyyMMdd'-'HHmmss"
			return formatter
		}()
	}


	/* entity name */
	class var entityName: String { return Constants.ENTITY_NAME }

	@NSManaged var presentations: NSSet?
	@NSManaged var root: ILobbyStoreRoot


	/* name of the group based on the final component of the remote location */
	var shortName: String {
		return self.remoteLocation.lastPathComponent
	}


	/* get the pending presentations (e.g. still downloading) */
	var pendingPresentations : [PresentationStore] {
		let query = "(group = %@) AND status = \(REMOTE_ITEM_STATUS_PENDING) OR status = \(REMOTE_ITEM_STATUS_DOWNLOADING)"
		return self.fetchPresentationsWithQuery(query)
	}


	/* get the active presentations (i.e. ready for presentation) */
	var activePresentations : [PresentationStore] {
		let query = "(group = %@) AND status = \(REMOTE_ITEM_STATUS_READY)"
		return self.fetchPresentationsWithQuery(query)
	}


	/* construct a new presentation group in the managed context and return it */
	class func insertNewPresentationGroupInContext(managedObjectContext: NSManagedObjectContext!) -> PresentationGroupStore {
		let group = NSEntityDescription.insertNewObjectForEntityForName(Constants.ENTITY_NAME, inManagedObjectContext: managedObjectContext) as PresentationGroupStore

		// generate a unique path for the group based on the timestamp when the group was created
		let timestampString = Constants.BASE_PATH_DATE_FORMATTER.stringFromDate(NSDate())
		group.path = "Group-\(timestampString)"

		return group
	}


	/* fetch presentations with the specified query */
	func fetchPresentationsWithQuery( query: String ) -> [PresentationStore] {
		let fetch = NSFetchRequest(entityName: PresentationStore.entityName)
		fetch.predicate = NSPredicate(format: query, argumentArray: [self])
		fetch.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		var error: NSError?
		return self.managedObjectContext!.executeFetchRequest(fetch, error: &error) as [PresentationStore]
	}


	/* add a presentation to this group */
	func addPresentation(presentation: PresentationStore) {
		self.mutableSetValueForKey("presentations").addObject(presentation)
	}


	/* remove a presentation from this group */
	func removePresentation(presentation: PresentationStore) {
		self.mutableSetValueForKey("presentations").removeObject(presentation)
	}
}



