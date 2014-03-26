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


+ (instancetype)newRemoteMediaInTrack:(ILobbyStoreTrack *)track location:(NSURL *)remoteURL {
	ILobbyStoreRemoteMedia *remoteMedia = [NSEntityDescription insertNewObjectForEntityForName:@"RemoteMedia" inManagedObjectContext:track.managedObjectContext];

	remoteMedia.track = track;
	remoteMedia.remoteLocation = remoteURL.absoluteString;
//	remoteMedia.remoteInfo = nil;
	NSLog( @"Media: %@", remoteMedia.remoteLocation );

	return remoteMedia;
}


- (void)fetchSlidesFrom:(ILobbyRemoteFile *)remoteFile {

}


@end
