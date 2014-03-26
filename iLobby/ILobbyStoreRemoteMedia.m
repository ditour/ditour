//
//  ILobbyStoreRemoteMedia.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteMedia.h"
#import "ILobbyStoreTrack.h"

@implementation ILobbyStoreRemoteMedia
@dynamic track;
@dynamic slides;


+ (instancetype)newRemoteMediaInTrack:(ILobbyStoreTrack *)track at:(ILobbyRemoteFile *)remoteFile {
	ILobbyStoreRemoteMedia *remoteMedia = [NSEntityDescription insertNewObjectForEntityForName:@"RemoteMedia" inManagedObjectContext:track.managedObjectContext];

	remoteMedia.track = track;
	remoteMedia.status = @( REMOTE_ITEM_STATUS_PENDING );
	remoteMedia.remoteLocation = remoteFile.location.absoluteString;
	remoteMedia.remoteInfo = remoteFile.info;
	NSLog( @"Fetching Media: %@", remoteMedia.remoteURL.lastPathComponent );

	return remoteMedia;
}


@end
