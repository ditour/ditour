//
//  ILobbyStoreRemoteItem.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteItem.h"
#import "DiTour-Swift.h"

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


- (BOOL)isDisposable {
	return self.status.shortValue == REMOTE_ITEM_STATUS_DISPOSABLE;
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


- (void)markDisposable {
	self.status = @( REMOTE_ITEM_STATUS_DISPOSABLE );
}


- (void)prepareForDeletion {
	// delete the associated directory if any
	if ( self.path ) {
	//	NSLog( @"Deleting store item at path: %@", self.absolutePath );

		NSError *error = nil;
		NSFileManager *fileManager = [NSFileManager defaultManager];

		if ( [fileManager fileExistsAtPath:self.absolutePath] ) {
			BOOL success = [fileManager removeItemAtPath:self.absolutePath error:&error];
			if ( !success ) {
				NSLog( @"Error deleting store remote item at path: %@ due to error: %@", self.absolutePath, error );
			}
		}
	}

	// call the default implementation
	[super prepareForDeletion];
}


- (NSString *)absolutePath {
	return [[DitourModel presentationGroupsRoot] stringByAppendingPathComponent:self.path];
}


@end
