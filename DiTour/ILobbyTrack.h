//
//  ILobbyTrack.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "ILobbyStoreTrack.h"

@protocol PresentationDelegate;
@class TransitionSource;

@class ILobbyTrack;
typedef void (^ILobbyTrackCompletionHandler)(ILobbyTrack *);


@interface ILobbyTrack : NSObject

@property (nonatomic, readonly, strong) UIImage *icon;
@property (nonatomic, readonly, copy) NSString *label;
@property (nonatomic, readonly, assign) float defaultSlideDuration;
@property (nonatomic, readonly, strong) NSArray *slides;
@property (nonatomic, readonly, strong) TransitionSource *defaultTransitionSource;

- (instancetype)initWithTrackStore:(ILobbyStoreTrack *)trackStore;

- (void)presentTo:(id<PresentationDelegate>)presenter completionHandler:(ILobbyTrackCompletionHandler)handler;
- (void)cancelPresentation;

@end
