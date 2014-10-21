//
//  ILobbyPresentationDelegate.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/25/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

@import Foundation;
@import AVFoundation;
@import UIKit;

@protocol ILobbyPresentationDelegate <NSObject>

@property( strong, readwrite ) id currentRunID;
@property( readonly ) CGRect externalBounds;

- (void)beginTransition:(CATransition *)transition;

- (void)displayMediaView:(UIView *)mediaView;

@end
