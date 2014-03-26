//
//  ILobbyStoreTrack.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreTrack.h"
#import "ILobbyStorePresentation.h"


@implementation ILobbyStoreTrack

@dynamic title;
@dynamic presentation;
@dynamic remoteMedia;


+ (instancetype)newTrackInPresentation:(ILobbyStorePresentation *)presentation from:(ILobbyRemoteDirectory *)remoteDirectory {
	ILobbyStoreTrack *track = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:presentation.managedObjectContext];

	track.presentation = presentation;
	track.remoteLocation = remoteDirectory.location.absoluteString;

	// TODO: remove any leading numbers used for ordering and handle spaces and capitalization
	track.title = remoteDirectory.location.lastPathComponent;

	NSLog( @"Fetching Track: %@", track.title );

	for ( ILobbyRemoteFile *remoteMediaFile in remoteDirectory.files ) {
		[ILobbyStoreRemoteMedia newRemoteMediaInTrack:track at:remoteMediaFile];
	}

	return track;
}


@end
