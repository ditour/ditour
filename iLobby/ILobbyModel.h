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

#import "ILobbyProgress.h"
#import "ILobbyTrack.h"
#import "ILobbyPresentationDelegate.h"


@interface ILobbyModel : NSObject

@property (strong, nonatomic) NSURL *presentationLocation;
@property (strong, readonly) ILobbyProgress *downloadProgress;
@property (strong, readonly) NSArray *tracks;
@property (strong, readonly) ILobbyTrack *currentTrack;
@property (weak, readwrite, nonatomic) id<ILobbyPresentationDelegate> presentationDelegate;
@property BOOL delayInstall;
@property (readonly) BOOL downloading;

// Download the presenation from the web server. If fullDownload then force a download of all media regardless of date; otherwise, download only stale media.
- (void)downloadPresentationForcingFullDownload:(BOOL)forceFullDownload;
- (void)cancelPresentationDownload;

- (BOOL)play;
- (void)playTrackAtIndex:(NSUInteger)trackIndex;
- (void)performShutdown;

// document information
+ (NSURL *)documentDirectoryURL;


// managed object support
@property (readonly) NSManagedObjectModel *managedObjectModel;
@property (readonly) NSManagedObjectContext *managedObjectContext;
@property (readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
