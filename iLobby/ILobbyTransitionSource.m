//
//  ILobbyTransitionSource.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/13/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyTransitionSource.h"


@implementation ILobbyTransitionSource

- (CATransition *)generate {
	CATransition *transition = [CATransition animation];
	transition.type = self.type;
	transition.subtype = self.subType;
	transition.duration = self.duration;

	return transition;
}


+ (ILobbyTransitionSource *)parseTransitionSource:(id)config {
	if ( config == nil )  return nil;

	if ( [config isKindOfClass:[NSDictionary class]] ) {
		ILobbyTransitionSource *transitionSource = [ILobbyTransitionSource new];

		id type = config[ @"type" ];
		if ( type != nil && [type isKindOfClass:[NSString class]] ) {
			transitionSource.type = type;
		}

		id subType = config[ @"subtype" ];
		if ( subType != nil && [subType isKindOfClass:[NSString class]] ) {
			transitionSource.subType = subType;
		}

		id duration = config[ @"duration" ];
		if ( duration != nil && [duration isKindOfClass:[NSNumber class]] ) {
			transitionSource.duration = [duration doubleValue];
		}

		return transitionSource;
	}
	else {
		NSLog( @"Cannot parse the transition source from config of class: %@", [config class] );
		return nil;
	}
}

@end
