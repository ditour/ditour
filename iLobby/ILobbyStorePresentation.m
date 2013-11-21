//
//  ILobbyStorePresentation.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentation.h"
#import "ILobbyStoreUserConfig.h"
#import "ILobbyStorePresentation.h"
#import "ILobbyStoreSlideConfiguration.h"
#import "ILobbyStoreTrack.h"


@implementation ILobbyStorePresentation

@dynamic name;
@dynamic path;
@dynamic status;
@dynamic timestamp;
@dynamic remoteLocation;
@dynamic userConfig;
@dynamic configuration;
@dynamic tracks;
@dynamic origin;
@dynamic revision;


- (BOOL)isReady {
	return self.status.intValue == PRESENTATION_STATUS_READY;
}

@end
