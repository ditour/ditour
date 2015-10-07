//
//  DitourModel.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 9/18/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import CoreData


// MARK: - Main Model Container
// Objects that contain the main model
@objc protocol DitourModelContainer {
	var ditourModel: DitourModel? { get set }
}



private let PRESENTATION_GROUP_ROOT = fetchDocumentDirectoryURL().path!.stringByAppendingPathComponent( "PresentationGroups" )


// MARK: - Main Model
// main model for DiTour where the primary state is maintained
public class DitourModel : NSObject, PresenterDelegate {
	// indicates whether a track is being presented
	private(set) var playing = false

	// all tracks that are available and key-value observable (dynamic)
	private(set) dynamic var tracks:[Track] = []

	// track scheduled to play automatically at the end of the current track
	private var defaultTrack :Track?

	// track that is currently playing and key-value observable (dynamic)
	private(set) dynamic var currentTrack :Track?

	// indicates whether there is a presentation update
	private var hasPresentationUpdate = false

	// managed object model for the persistent store
	let managedObjectModel : NSManagedObjectModel
	let mainManagedObjectContext : NSManagedObjectContext

	let mainStoreRoot : RootStore

	var presenter : Presenter?

	var canPlay : Bool { return self.tracks.count > 0 && presenter?.available ?? false }

	var downloadSession : PresentationGroupDownloadSession? = nil

	var downloading : Bool { return self.downloadSession?.active ?? false }


	override init() {
		// setup the data model
		( self.managedObjectModel, self.mainManagedObjectContext ) = DitourModel.setupDataModel()

		self.mainStoreRoot = DitourModel.fetchRootStore( self.mainManagedObjectContext )
		self.presenter = ExternalPresenter()

		super.init()

		self.loadDefaultPresentation()

		// handle presenter events
		self.presenter?.delegate = self
	}


	func cleanup() {
		self.cleanupDisposablePresentations()
	}


	func cleanupDisposablePresentations() {
		//	NSLog( @"cleaning up disposable presentations..." );
		let fetch = NSFetchRequest( entityName: PresentationStore.entityName )
		// fetch presentations explicitly marked disposable or that have no group assignment
		fetch.predicate = NSPredicate( format: "(status = %d) || (group = nil)", RemoteItemStatus.Disposable.rawValue )

		do {
			let presentations = try self.mainManagedObjectContext.executeFetchRequest(fetch) as! [PresentationStore]

			if ( presentations.count > 0 ) {	// check if there are any presentations to delete so we can use a single save at the end outside the for loop
				for presentation in presentations {
					presentation.managedObjectContext?.deleteObject(presentation)
				}

				try self.saveChanges()
			}
		} catch {
			fatalError("Error fetching presentations for cleanup: \(error)")
		}
	}


	// MARK: - Loading presentations

	func loadDefaultPresentation() -> Bool {
		self.hasPresentationUpdate = false

		var success = false
		self.mainStoreRoot.managedObjectContext?.performBlockAndWait(){ () -> Void in
			success = self.loadPresentation( self.mainStoreRoot.currentPresentation )
		}

		return success
	}


	func loadPresentation( possiblePresentationStore : PresentationStore? ) -> Bool {
		if let presentationStore = possiblePresentationStore  {
			if presentationStore.isReady {
				var tracks = [Track]()
				for trackStore in presentationStore.tracks.array {
					let track = Track( trackStore: trackStore as! TrackStore )
					if track.slides.count > 0 {		// only display tracks that have slides
						tracks.append( track )
					}
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


	// handle event indicating that the presenter's availability has changed
	func availabilityChanged(source: Presenter) {
		if source.available {
			if !self.playing {
				self.play()
			}
		} else {
			self.stop()
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


	//MARK: - Download session support

	func cancelDownload() {
		self.downloadSession?.cancel()
		self.downloadSession = nil
	}


	func handleEventsForBackgroundURLSession( identifier : String, completionHandler : ()->Void ) {
		if let session = self.downloadSession {
			session.handleEventsForBackgroundURLSession( identifier, completionHandler: completionHandler )
		}
	}


	func downloadGroup( group: PresentationGroupStore, delegate: DownloadStatusDelegate ) -> DownloadContainerStatus {
		let downloadSession = PresentationGroupDownloadSession(mainModel: self)
		self.downloadSession = downloadSession
		return downloadSession.downloadGroup( group, delegate: delegate )
	}


	func downloadStatusForGroup( group : PresentationGroupStore ) -> DownloadContainerStatus? {
		if let status = self.downloadSession?.groupStatus {
			return status.matchesRemoteItem( group ) ? status : nil
		}
		else {
			return nil
		}
	}


	//MARK: - Playback

	func play() -> Bool {
		if self.playing {
			return true
		}

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

		do {
			try self.saveChanges()
		} catch _ {
		}
	}


	func playTrackAtIndex( trackIndex : UInt ) {
		let track = self.tracks[ Int(trackIndex) ]
		self.playTrack( track, cancelCurrent: true )
	}


	func playTrack( track : Track, cancelCurrent : Bool ) {
		let oldTrack = self.currentTrack
		if ( cancelCurrent && oldTrack != nil ) {
			oldTrack!.cancelPresentation()
		}

		if let presentationDelegate = self.presenter {
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


	//MARK: - Directory paths

	class func presentationGroupsRoot() -> String {
		return PRESENTATION_GROUP_ROOT
	}


	private func presentationGroupsRoot() -> String {
		return DitourModel.presentationGroupsRoot()
	}


	class func documentDirectoryURL() -> NSURL {
		return fetchDocumentDirectoryURL()
	}


	private class func applicationDocumentsDirectory() -> String {
		let documentsDirectories = NSSearchPathForDirectoriesInDomains( .DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true )
		return documentsDirectories.last! as String
	}


	//MARK: - Persistent store support

	private class func setupDataModel() -> ( model: NSManagedObjectModel, context: NSManagedObjectContext) {
		let storeURL = NSURL.fileURLWithPath( DitourModel.applicationDocumentsDirectory().stringByAppendingPathComponent("iLobby.db") )
		let options = [ NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true ]

		let managedObjectModel = NSManagedObjectModel.mergedModelFromBundles(nil)
		assert( managedObjectModel != nil, "Error, managed object model is nil..." )

		var error :NSError? = nil
		let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel!)
		let persistentStore :NSPersistentStore?
		do {
			persistentStore = try persistentStoreCoordinator.addPersistentStoreWithType(NSBinaryStoreType, configuration: nil, URL: storeURL, options: options)
		} catch let error1 as NSError {
			error = error1
			persistentStore = nil
		}

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


	class private func fetchRootStore( managedObjectContext : NSManagedObjectContext ) -> RootStore {
		let mainFetchRequest = NSFetchRequest(entityName: RootStore.entityName )

		let rootStores = try! managedObjectContext.executeFetchRequest( mainFetchRequest)

		if rootStores.count > 0 {
			return (rootStores[0] as! RootStore)
		}
		else {
			let rootStore = RootStore.insertNewRootStoreInContext( managedObjectContext )
			do {
				try managedObjectContext.save()
			} catch let error as NSError {
				fatalError("Error saving new root store: \(error)")
			}
			return rootStore
		}
	}

	// save changes down to the persistent store
	func persistentSaveContext( editContext :NSManagedObjectContext) throws {
		var errorPtr: NSError! = NSError(domain: "Migrator", code: 0, userInfo: nil)
		var success = false
		var parentContext :NSManagedObjectContext? = nil
		var localError : NSError?

		// first save to the edit context
		editContext.performBlockAndWait {
			do {
				try editContext.save()
				success = true
			} catch let error as NSError {
				localError = error
				success = false
			} catch {
				fatalError()
			}
			parentContext = editContext.parentContext
		}

		// propagate the save until we get to the persistent store (i.e. no parent context)
		if ( success && parentContext != nil ) {
			try self.persistentSaveContext(parentContext!)
			return
		}
		else if !success {
			print("Save error: \(localError?.description)")
			errorPtr = localError
			if success {
				return
			}
			throw errorPtr
		}
		else {
			if success {
				return
			}
			throw errorPtr
		}
	}


	// save changes in the main managed object context on the correct queue and blocking
	func saveChanges() throws {
		var success = false
		var localError : NSError?

		self.mainManagedObjectContext.performBlockAndWait {
			do {
				try self.mainManagedObjectContext.save()
				success = true
			} catch {
				localError = error as NSError
				success = false
			}
		}

		if success {
			return
		} else {
			if let error = localError {
				print( "Failed to save group edit to the main edit context: \(error)" )
				throw error
			}

			throw NSError(domain: "Migrator", code: 0, userInfo: nil)
		}
	}
}




//MARK: - Private functions


private func fetchDocumentDirectoryURL() -> NSURL {
	do {
		return try NSFileManager.defaultManager().URLForDirectory( NSSearchPathDirectory.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
	} catch let error as NSError {
		// if the document directory doesn't exist then something really bad has happened
		fatalError("Error fetching document directory URL: \(error)")
	}
}






