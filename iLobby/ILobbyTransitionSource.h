//
//  ILobbyTransitionSource.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/13/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface ILobbyTransitionSource : NSObject

@property( assign ) CFTimeInterval duration;
@property( copy ) NSString *type;
@property( copy ) NSString *subType;

+ (ILobbyTransitionSource *)parseTransitionSource:(id)config;

- (CATransition *)generate;

@end
