//
//  ILobbyStoreRemoteMedia.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteMedia.h"
#import "ILobbyStoreTrack.h"
#import "ILobbySlide.h"


@implementation ILobbyStoreRemoteMedia
@dynamic track;


+ (instancetype)newRemoteMediaInTrack:(ILobbyStoreTrack *)track at:(ILobbyRemoteFile *)remoteFile {
	ILobbyStoreRemoteMedia *remoteMedia = [NSEntityDescription insertNewObjectForEntityForName:@"RemoteMedia" inManagedObjectContext:track.managedObjectContext];

	remoteMedia.track = track;
	remoteMedia.status = @( REMOTE_ITEM_STATUS_PENDING );
	remoteMedia.remoteLocation = remoteFile.location.absoluteString;
	remoteMedia.remoteInfo = remoteFile.info;
	remoteMedia.path = [track.path stringByAppendingPathComponent:remoteFile.location.lastPathComponent];

//	NSLog( @"Fetching Media: %@", remoteMedia.remoteURL.lastPathComponent );
//	NSLog( @"Media Path: %@", remoteMedia.path );

	return remoteMedia;
}


// indicates whether the candidate URL matches a type supported by the class
+ (BOOL)matches:(NSURL *)candidateURL {
	static NSSet *supportedExtensions = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		supportedExtensions = [ILobbySlide allSupportedExtensions];
	});

	return [supportedExtensions containsObject:[[candidateURL.path pathExtension] lowercaseString]];
}

@end
