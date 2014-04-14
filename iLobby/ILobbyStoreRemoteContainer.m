//
//  ILobbyStoreRemoteContainer.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/27/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteContainer.h"

@implementation ILobbyStoreRemoteContainer
@dynamic configuration;


- (void)processRemoteFile:(ILobbyRemoteFile *)remoteFile {
	NSURL *location = remoteFile.location;
	if ( [ILobbyStoreConfiguration matches:location] ) {
		[ILobbyStoreConfiguration newConfigurationInContainer:self at:remoteFile];
	}
//	else {
//		NSLog( @"****************************************************************" );
//		NSLog( @"NO Match for remote file: %@", location.lastPathComponent );
//		NSLog( @"****************************************************************" );
//	}
}


@end
