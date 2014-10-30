//
//  Persistence.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 10/30/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import CoreData


/* persistent store for a configuration */
class ConfigurationStore : ILobbyStoreRemoteFile {
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

