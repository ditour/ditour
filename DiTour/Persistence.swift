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
	@NSManaged var track : ILobbyStoreTrack


	class func newRemoteMediaInTrack(track: ILobbyStoreTrack, at remoteFile: ILobbyRemoteFile) -> RemoteMediaStore {
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

