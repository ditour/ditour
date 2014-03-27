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
	track.status = @( REMOTE_ITEM_STATUS_PENDING );
	track.remoteLocation = remoteDirectory.location.absoluteString;

	// TODO: remove any leading numbers used for ordering and handle spaces and capitalization
	track.title = remoteDirectory.location.lastPathComponent;

	NSLog( @"Fetching Track: %@", track.title );

	for ( ILobbyRemoteFile *remoteFile in remoteDirectory.files ) {
		NSURL *location = remoteFile.location;
		if ( [ILobbyStoreRemoteMedia matches:location] ) {
			[ILobbyStoreRemoteMedia newRemoteMediaInTrack:track at:remoteFile];
		}
		else if ( [ILobbyStoreConfiguration matches:location] ) {
			// TODO: create a configuration and add it to the track
		}
		else {
			NSLog( @"****************************************************************" );
			NSLog( @"NO Match for remote file: %@", location.lastPathComponent );
			NSLog( @"****************************************************************" );
		}
	}

	return track;
}


@end
