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



private let PRESENTATION_GROUP_ROOT = fetchDocumentDirectoryURL().path!.stringByAppendingPathComponent( "PresentationGroups" )


// MARK: -
// MARK: Main Model
// main model for DiTour where the primary state is maintained
public class MainModel : NSObject {
	// container of static properties
	private struct StaticProps {
		// static initialization
		private static let initializer :Void = {
			performVersionInitialization()
		}()
	}


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

	var presentationDelegate : ILobbyPresentationDelegate? = nil

	var canPlay : Bool { return self.tracks.count > 0 }

	var downloadSession : ILobbyDownloadSession? = nil

	var downloading : Bool { return self.downloadSession?.active ?? false }


	override init() {
		// setup the data model
		( self.managedObjectModel, self.mainManagedObjectContext ) = MainModel.setupDataModel()

		self.mainStoreRoot = MainModel.fetchRootStore( self.mainManagedObjectContext )

		super.init()

		self.loadDefaultPresentation()
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


	// MARK: -
	// MARK: Loading presentations


	func loadDefaultPresentation() -> Bool {
		self.hasPresentationUpdate = false

		var success = false
		self.mainStoreRoot.managedObjectContext?.performBlockAndWait(){ () -> Void in
			success = self.loadPresentation( self.mainStoreRoot.currentPresentation )
		}

		return success
	}


	func loadPresentation( possiblePresentationStore : ILobbyStorePresentation? ) -> Bool {
		if let presentationStore = possiblePresentationStore  {
			if presentationStore.isReady {
				var tracks = [ILobbyTrack]()
				for trackStore in presentationStore.tracks.array {
					let track = ILobbyTrack( trackStore: trackStore as ILobbyStoreTrack )
					tracks.append( track )
				}

				self.tracks = tracks
				self.defaultTrack = tracks.count > 0 ? tracks[0] : nil

				// remove any disposable presentations such as the one (if any) marked current at the time it was replaced
				self.cleanupDisposablePresentations()

				return true
			}
			else {
				return false
			}
		}
		else {
			return false
		}
	}


	func reloadPresentation() {
		self.stop()
		self.loadDefaultPresentation()
		self.play()
	}


	func reloadPresentationNextCycle() {
		// if not playing then just reload now otherwise mark for reloading on next cycle
		if !self.playing {
			self.reloadPresentation()
		}
		else {
			self.hasPresentationUpdate = true
		}
	}


	//MARK: -
	//MARK: Download session support

	func cancelDownload() {
		self.downloadSession?.cancel()
		self.downloadSession = nil
	}


	func handleEventsForBackgroundURLSession( identifier : String, completionHandler : ()->Void ) {
		if let session = self.downloadSession {
			session.handleEventsForBackgroundURLSession( identifier, completionHandler )
		}
	}


	func downloadGroup( group: ILobbyStorePresentationGroup, delegate: ILobbyDownloadStatusDelegate ) -> ILobbyDownloadContainerStatus {
		let downloadSession = ILobbyDownloadSession(model: self)
		self.downloadSession = downloadSession
		return downloadSession.downloadGroup( group, withDelegate: delegate )
	}


	func downloadStatusForGroup( group : ILobbyStorePresentationGroup ) -> ILobbyDownloadContainerStatus? {
		if let status = self.downloadSession?.groupStatus {
			return status.matchesRemoteItem( group ) ? status : nil
		}
		else {
			return nil
		}
	}


	//MARK: -
	//MARK: Playback

	func play() -> Bool {
		if self.canPlay {
			if let defaultTrack = self.defaultTrack {
				self.playTrack( defaultTrack, cancelCurrent: true )
				self.playing = true
				return true
			}
			else {
				return false
			}
		}
		else {
			return false
		}
	}


	func stop() {
		self.playing = false
		self.currentTrack?.cancelPresentation()
	}


	func performShutdown() {
		self.stop()
		self.cleanup()

		self.saveChanges( nil )
	}


	func playTrackAtIndex( trackIndex : UInt ) {
		let track = self.tracks[ Int(trackIndex) ]
		self.playTrack( track, cancelCurrent: true )
	}


	func playTrack( track : ILobbyTrack, cancelCurrent : Bool ) {
		let oldTrack = self.currentTrack
		if ( cancelCurrent && oldTrack != nil ) {
			oldTrack!.cancelPresentation()
		}

		if let presentationDelegate = self.presentationDelegate {
			self.currentTrack = track
			track.presentTo(presentationDelegate, completionHandler: { (theTrack) -> Void in
				// if playing, present the default track after any track completes on its own (no need to cancel)
				if self.playing {
					// check whether a new presentation download is ready and install and load it if so
					if self.hasPresentationUpdate {
						self.reloadPresentation()
					}
					else {
						// play the default track
						if let defaultTrack = self.defaultTrack {
							self.playTrack( defaultTrack, cancelCurrent: false )
						}
					}
				}
			})
		}
	}


	//MARK: -
	//MARK: Directory paths

	class func presentationGroupsRoot() -> String {
		return PRESENTATION_GROUP_ROOT
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

	private class func setupDataModel() -> ( model: NSManagedObjectModel, context: NSManagedObjectContext) {
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

		var error :NSErrorPointer = nil
		let rootStores = managedObjectContext.executeFetchRequest( mainFetchRequest, error: error )!

		if rootStores.count > 0 {
			return (rootStores[0] as ILobbyStoreRoot)
		}
		else {
			let rootStore = ILobbyStoreRoot.insertNewRootStoreInContext( managedObjectContext )
			managedObjectContext.save( error )
			return rootStore
		}
	}

	// save changes down to the persistent store
	func persistentSaveContext( editContext :NSManagedObjectContext, error :NSErrorPointer ) -> Bool {
		var success = false
		var parentContext :NSManagedObjectContext? = nil

		// first save to the edit context
		editContext.performBlockAndWait {
			success = editContext.save( error )
			parentContext = editContext.parentContext
		}

		// propagate the save until we get to the persistent store (i.e. no parent context)
		if ( success && parentContext != nil ) {
			return self.persistentSaveContext(parentContext!, error: error)
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
	var error : NSErrorPointer = nil

	let documentDirectoryURL = fileManager.URLForDirectory( NSSearchPathDirectory.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true, error: error )

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






