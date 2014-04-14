//
//  ILobbyStoreRemoteItem.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteItem.h"

@implementation ILobbyStoreRemoteItem

@dynamic status;
@dynamic remoteInfo;
@dynamic remoteLocation;
@dynamic path;


- (NSURL *)remoteURL {
	NSString *remoteLocation = self.remoteLocation;
	return remoteLocation ? [NSURL URLWithString:remoteLocation] : nil;
}


- (BOOL)isPending {
	return self.status.shortValue == REMOTE_ITEM_STATUS_PENDING;
}


- (BOOL)isDownloading {
	return self.status.shortValue == REMOTE_ITEM_STATUS_DOWNLOADING;
}


- (BOOL)isReady {
	return self.status.shortValue == REMOTE_ITEM_STATUS_READY;
}


- (void)markPending {
	self.status = @( REMOTE_ITEM_STATUS_PENDING );
}


- (void)markDownloading {
	self.status = @( REMOTE_ITEM_STATUS_DOWNLOADING );
}


- (void)markReady {
	self.status = @( REMOTE_ITEM_STATUS_READY );
}


- (void)prepareForDeletion {
	// delete the associated directory if any
	if ( self.path ) {
	//	NSLog( @"Deleting store item at path: %@", self.path );

		NSError *error = nil;
		NSFileManager *fileManager = [NSFileManager defaultManager];

		if ( [fileManager fileExistsAtPath:self.path] ) {
			BOOL success = [fileManager removeItemAtPath:self.path error:&error];
			if ( !success ) {
				NSLog( @"Error deleting store remote item at path: %@ due to error: %@", self.path, error );
			}
		}
	}

	// call the default implementation
	[super prepareForDeletion];
}


@end
