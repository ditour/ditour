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
	@NSManaged var presentation: ILobbyStorePresentation
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

	class func newTrackInPresentation(presentation: ILobbyStorePresentation, from remoteDirectory: ILobbyRemoteDirectory) -> TrackStore {
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



