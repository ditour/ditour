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
	private(set) var playing = false

	// all tracks that are available
	private(set) var tracks:[ILobbyTrack] = []

	// track scheduled to play automatically at the end of the current track
	private var defaultTrack :ILobbyTrack?

	// track that is currently playing
	private(set) var currentTrack :ILobbyTrack?

	// indicates whether there is a presentation update
	private var hasPresentationUpdate = false

	// managed object model for the persistent store
	let managedObjectModel : NSManagedObjectModel
	let mainManagedObjectContext : NSManagedObjectContext

	let mainStoreRoot : ILobbyStoreRoot


	init() {
		// setup the data model
		( self.managedObjectModel, self.mainManagedObjectContext ) = MainModel.setupDataModel()

		self.mainStoreRoot = MainModel.fetchRootStore( self.mainManagedObjectContext )

		//self.loadDefaultPresentation()
	}


	func cleanup() {
		self.cleanupDisposablePresentations()
	}


	func cleanupDisposablePresentations() {
		//	NSLog( @"cleaning up disposable presentations..." );
		let fetch = NSFetchRequest( entityName: ILobbyStorePresentation.entityName() )
		// fetch presentations explicitly marked disposable or that have no group assignment
		fetch.predicate = NSPredicate( format: "(status = %d) || (group = nil)", REMOTE_ITEM_STATUS_DISPOSABLE )
		let presentations = self.mainManagedObjectContext.executeFetchRequest( fetch, error: nil ) as [ILobbyStorePresentation]

		if ( presentations.count > 0 ) {	// check if there are any presentations to delete so we can use a single save at the end outside the for loop
			for presentation in presentations {
				presentation.managedObjectContext?.deleteObject(presentation)
			}

			self.saveChanges(nil)
		}
	}


//	func loadDefaultPresentation() -> Bool {
//		self.hasPresentationUpdate = false
//
//		var success = false
//		self.mainStoreRoot.managedObjectContext?.performBlockAndWait(){ () -> Void in
//			success = self.loadPresentation( self.mainStoreRoot.currentPresentation )
//		}
//
//		return success
//	}


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


	private class func setupDataModel() -> (NSManagedObjectModel, NSManagedObjectContext) {
		let storeURL = NSURL.fileURLWithPath( MainModel.applicationDocumentsDirectory().stringByAppendingPathComponent("iLobby.db") )
		let options = [ NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true ]

		let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(nil)
		assert( managedObjectModel != nil, "Error, managed object model is nil..." )

		var error :NSError? = nil
		let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel!)
		let persistentStore :NSPersistentStore? = persistentStoreCoordinator.addPersistentStoreWithType(NSBinaryStoreType, configuration: nil, URL: storeURL, options: options, error: &error)

		/* TODO: Replace this implementation with code to handle the error appropriately.
		Typical reasons for an error here include:
		* The persistent store is not accessible
		* The schema for the persistent store is incompatible with current managed object model
		Check the error message to determine what the actual problem was.
		*/
		assert( persistentStore != nil, "Unresolved error: \(error) generating a persistent store: \(error?.userInfo)" )
		let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

		return (managedObjectModel!,managedObjectContext)
	}


	func createEditContextOnMain() -> NSManagedObjectContext {
		let editContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
		editContext.parentContext = self.mainManagedObjectContext
		return editContext
	}


	class private func fetchRootStore( managedObjectContext : NSManagedObjectContext ) -> ILobbyStoreRoot {
		let mainFetchRequest = NSFetchRequest(entityName: ILobbyStoreRoot.entityName() )

		var rootStore :ILobbyStoreRoot? = nil
		var error :NSError? = nil
		let rootStores = managedObjectContext.executeFetchRequest( mainFetchRequest, error: &error )

		return rootStore!
	}

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
	func saveChanges( error :NSErrorPointer ) -> Bool {
		var success = false

		// first save to the managed object context on Main
		self.mainManagedObjectContext.performBlockAndWait { () -> Void in
			success = self.mainManagedObjectContext.save( error )
		}

		if !success {
			if error != nil {
				println( "Failed to save group edit to the main edit context: \(error)" )
			}

			return false
		}

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






