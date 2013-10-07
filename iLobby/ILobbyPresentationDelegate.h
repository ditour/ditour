//
//  ILobbyPresentationDelegate.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/25/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

@import Foundation;
@import AVFoundation;

@protocol ILobbyPresentationDelegate <NSObject>

@property( strong, readwrite ) id currentRunID;

- (void)beginTransition:(CATransition *)transition;

- (void)displayImage:(UIImage *)image;
- (void)displayVideo:(AVPlayer *)player;

@end
