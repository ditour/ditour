//
//  ILobbyStorePresentationMaster.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentationMaster.h"
#import "ILobbyStorePresentation.h"


@implementation ILobbyStorePresentationMaster

@dynamic name;
@dynamic group;
@dynamic presentations;


- (ILobbyStorePresentation *)currentPresentation {
	for ( ILobbyStorePresentation *presentation in self.presentations ) {
		if ( presentation.isReady ) {
			return presentation;
		}
	}
	return nil;
}

@end
