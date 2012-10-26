//
//  ILobbyPresentationDelegate.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/25/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol ILobbyPresentationDelegate <NSObject>

@property( strong, readwrite ) id currentRunID;

- (void)displayImage:(UIImage *)image;
- (void)displayVideo:(AVPlayer *)player;

@end
