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


// indicates whether the candidate URL matches a type supported by the class
+ (BOOL)matches:(NSURL *)candidateURL {
	// TODO: for now just hard code the file types, but need to place this set in a common location
	static NSSet *supportedExtensions = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		supportedExtensions = [NSSet setWithArray:@[@"png", @"jpg", @"jpeg", @"gif", @"pdf", @"m4v", @"mp4"]];
	});

	return [supportedExtensions containsObject:[[candidateURL.path pathExtension] lowercaseString]];
}

@end
