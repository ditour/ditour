//
//  ILobbyModel.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

@import Foundation;
@import AVFoundation;
@import CoreData;

#import "ILobbyTrack.h"
#import "ILobbyPresentationDelegate.h"
#import "ILobbyStoreRoot.h"
#import "ILobbyDownloadStatus.h"


@interface ILobbyModel : NSObject

@property (nonatomic, readonly) ILobbyStoreRoot *mainStoreRoot;		// user config for main queue context

@property (strong, nonatomic, readonly) NSString *presentationGroupsRoot;	// root location of presentations on the local file system

@property (strong, nonatomic) NSURL *presentationLocation;
@property (strong, readonly) NSArray *tracks;
@property (strong, readonly) ILobbyTrack *currentTrack;
@property (weak, readwrite, nonatomic) id<ILobbyPresentationDelegate> presentationDelegate;
@property BOOL delayInstall;
@property (readonly) BOOL downloading;

- (BOOL)play;
- (void)playTrackAtIndex:(NSUInteger)trackIndex;
- (void)performShutdown;
- (void)reloadPresentation;
- (void)reloadPresentationNextCycle;

// document information
+ (NSURL *)documentDirectoryURL;
+ (NSString *)presentationGroupsRoot;


// managed object support
- (BOOL)saveChanges:(NSError * __autoreleasing *)errorPtr;

// save the specified context all the way to the persistent store
- (BOOL)persistentSaveContext:(NSManagedObjectContext *)editContext error:(NSError * __autoreleasing *)errorPtr;
- (NSManagedObjectContext *)createEditContextOnMain;

@property (readonly) NSManagedObjectContext *mainManagedObjectContext;	// context for the main queue
@property (readonly) NSManagedObjectModel *managedObjectModel;
@property (readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;


// download session management
- (void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;
- (ILobbyDownloadContainerStatus *)downloadGroup:(ILobbyStorePresentationGroup *)group delegate:(id<ILobbyDownloadStatusDelegate>)delegate;
- (ILobbyDownloadContainerStatus *)downloadStatusForGroup:(ILobbyStorePresentationGroup *)group;
- (void)cancelDownload;

@end
