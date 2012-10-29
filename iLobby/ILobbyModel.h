//
//  ILobbyModel.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ILobbyProgress.h"
#import "ILobbyTrack.h"
#import "ILobbyPresentationDelegate.h"


@interface ILobbyModel : NSObject

@property (strong, nonatomic) NSURL *presentationLocation;
@property (strong, readonly) ILobbyProgress *downloadProgress;
@property (strong, readonly) NSArray *tracks;
@property (strong, readonly) ILobbyTrack *currentTrack;
@property (weak, readwrite, nonatomic) id<ILobbyPresentationDelegate> presentationDelegate;

- (void)downloadPresentation;
- (BOOL)play;
- (void)playTrackAtIndex:(NSUInteger)trackIndex;
- (void)performShutdown;

@end
