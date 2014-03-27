//
//  ILobbyStorePresentation.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentation.h"
#import "ILobbyStorePresentationGroup.h"


@implementation ILobbyStorePresentation

// attributes
@dynamic name;
@dynamic status;
@dynamic timestamp;

// relationships
@dynamic group;
@dynamic parent;
@dynamic revision;
@dynamic tracks;


+ (instancetype)newPresentationInGroup:(ILobbyStorePresentationGroup *)group from:(ILobbyRemoteDirectory *)remoteDirectory {

    ILobbyStorePresentation *presentation = [NSEntityDescription insertNewObjectForEntityForName:@"Presentation" inManagedObjectContext:group.managedObjectContext];

	presentation.status = @( REMOTE_ITEM_STATUS_PENDING );
	presentation.timestamp = [NSDate date];
	presentation.remoteLocation = remoteDirectory.location.absoluteString;
	presentation.name = remoteDirectory.location.lastPathComponent;
	presentation.group = group;

	NSLog( @"Fetching presentation: %@", presentation.name );

	// fetch the tracks
	for ( ILobbyRemoteDirectory *remoteTrackDirectory in remoteDirectory.subdirectories ) {
		[ILobbyStoreTrack newTrackInPresentation:presentation from:remoteTrackDirectory];
	}

	for ( ILobbyRemoteFile *remoteFile in remoteDirectory.files ) {
		[presentation processRemoteFile:remoteFile];
	}

	return presentation;
}

@end
