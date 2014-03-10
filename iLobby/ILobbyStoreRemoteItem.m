//
//  ILobbyStoreRemoteItem.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteItem.h"

@implementation ILobbyStoreRemoteItem

@dynamic remoteInfo;
@dynamic remoteLocation;
@dynamic path;


- (NSURL *)remoteURL {
	NSString *remoteLocation = self.remoteLocation;
	return remoteLocation ? [NSURL URLWithString:remoteLocation] : nil;
}

@end
