//
//  MainModel.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 9/18/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import CoreData

// MARK: -
// MARK: Main Model Container
// Objects that contain the main model
protocol MainModelContainer {
	var model: MainModel { get set }
}



// MARK: -
// MARK: Main Model
// main model for DiTour where the primary state is maintained
class MainModel {
	// container of static properties
	private struct StaticProps {
		static let PRESENTATION_GROUP_ROOT = fetchDocumentDirectoryURL().path!.stringByAppendingPathComponent( "PresentationGroups" )

		// static initialization
		private static let initializer :Void = {
			performVersionInitialization()
		}()
	}


//	var mainStoreRoot : ILobbyStoreRoot

	// indicates whether a track is being presented
	private var _playing = false
	var playing : Bool { return _playing }

	// all tracks that are available
	private var _tracks:[ILobbyTrack] = []
	var tracks:[ILobbyTrack] { return _tracks }

	// track scheduled to play automatically at the end of the current track
	private var _defaultTrack :ILobbyTrack?

	// track that is currently playing
	private var _currentTrack :ILobbyTrack?
	var currentTrack :ILobbyTrack? { return _currentTrack }

	// managed object model for the persistent store
	let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(nil)
	let mainManagedObjectContext : NSManagedObjectContext


	init() {
		// setup the data model
		let storeURL = NSURL.fileURLWithPath( MainModel.applicationDocumentsDirectory().stringByAppendingPathComponent("iLobby.db") )
		let options = [ NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true ]

		var error :NSError? = nil
		let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
		let persistentStore :NSPersistentStore? = persistentStoreCoordinator.addPersistentStoreWithType(NSBinaryStoreType, configuration: nil, URL: storeURL, options: options, error: &error)

		/* TODO: Replace this implementation with code to handle the error appropriately.
		Typical reasons for an error here include:
		* The persistent store is not accessible
		* The schema for the persistent store is incompatible with current managed object model
		Check the error message to determine what the actual problem was.
		*/
		assert( persistentStore != nil, "Unresolved error: \(error) generating a persistent store: \(error?.userInfo)" )
		self.mainManagedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		self.mainManagedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

//		self.mainStoreRoot = self.fetchRootStore()
//
//		self.loadDefaultPresentation()
	}


	func createEditContextOnMain() -> NSManagedObjectContext {
		let editContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		editContext.parentContext = self.mainManagedObjectContext
		return editContext
	}


	func fetchRootStore() -> ILobbyStoreRoot {
		let mainFetchRequest = NSFetchRequest(entityName: ILobbyStoreRoot.entityName() )

		var rootStore :ILobbyStoreRoot? = nil
		var error :NSError? = nil
		let rootStores = self.mainManagedObjectContext.executeFetchRequest( mainFetchRequest, error: &error )

		return rootStore!
	}


	class func presentationGroupsRoot() -> String {
		return StaticProps.PRESENTATION_GROUP_ROOT
	}


	private func presentationGroupsRoot() -> String {
		return MainModel.presentationGroupsRoot()
	}


	class func documentDirectoryURL() -> NSURL {
		return fetchDocumentDirectoryURL()
	}


	private class func applicationDocumentsDirectory() -> String {
		let documentsDirectories = NSSearchPathForDirectoriesInDomains( .DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true )
		return documentsDirectories.last! as String
	}


	//MARK: -
	//MARK: Persistent store support

	// save changes down to the persistent store
	func persistentSaveContext( editContext :NSManagedObjectContext, inout error :NSError? ) -> Bool {
		var success = false
		var parentContext :NSManagedObjectContext? = nil

		// first save to the edit context
		editContext.performBlockAndWait {
			success = editContext.save( &error )
			parentContext = editContext.parentContext
		}

		// propagate the save until we get to the persistent store (i.e. no parent context)
		if ( success && parentContext != nil ) {
			return self.persistentSaveContext(parentContext!, error: &error)
		}
		else {
			return success
		}
	}


	// save changes in the main managed object context on the correct queue and blocking
	func saveChanges( inout error :NSError? ) -> Bool {
		var success = false

		// perform save on the managed object queue
		// TODO: implement managed object context save

		return success
	}
}




//MARK: -
//MARK: Private functions

private func purgeVersion1Data() {
	let oldPresentationPath = fetchDocumentDirectoryURL().path!.stringByAppendingPathComponent("Presentation")
	let fileManager = NSFileManager.defaultManager()
	if fileManager.fileExistsAtPath( oldPresentationPath ) {
		var error :NSError? = nil
		fileManager.removeItemAtPath( oldPresentationPath, error: &error )
		if ( error != nil ) {
			println( "Error removing version 1.0 presentation directory." )
		}
	}
}


private func fetchDocumentDirectoryURL() -> NSURL {
	let fileManager = NSFileManager.defaultManager()
	var error : NSError?

	let documentDirectoryURL = fileManager.URLForDirectory( NSSearchPathDirectory.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true, error: &error )

	assert( error != nil, "Error determining document directory: \(error)" )

	return documentDirectoryURL!
}


private func performVersionInitialization() {
	let MAJOR_VERSION_KEY = "majorVersion"
	let MINOR_VERSION_KEY = "minorVersion"

	let defaults = NSUserDefaults.standardUserDefaults()
	let majorVersion = defaults.integerForKey( MAJOR_VERSION_KEY )
	let minorVersion = defaults.integerForKey( MINOR_VERSION_KEY )

	switch majorVersion {
	case 0, 1:
		println( "Cleaning up version 1 data..." )
		purgeVersion1Data()
	default:
		break
	}

	// ------- Complete any migration from earlier versions in the above code

	// Check and set the major/minor versions if needed

	var hasChanges = false;
	if majorVersion != 3 {
		defaults.setInteger( 3, forKey: MAJOR_VERSION_KEY )
		hasChanges = true;
	}
	if minorVersion != 0 {
		defaults.setInteger( 0, forKey: MINOR_VERSION_KEY )
		hasChanges = true;
	}

	// if there are any user defaults changes to save, save them now
	if ( hasChanges ) {
		defaults.synchronize()
	}

	// --------- Done processing user defaults for app version
}






