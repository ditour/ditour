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


+ (instancetype)newPresentationInGroup:(ILobbyStorePresentationGroup *)group location:(NSURL *)remoteURL {
    ILobbyStorePresentation *presentation = [NSEntityDescription insertNewObjectForEntityForName:@"Presentation" inManagedObjectContext:group.managedObjectContext];

	presentation.status = @( PRESENTATION_STATUS_PENDING );
	presentation.timestamp = [NSDate date];
	presentation.remoteLocation = remoteURL.absoluteString;
	presentation.name = remoteURL.lastPathComponent;
	presentation.group = group;

	return presentation;
}


- (BOOL)isReady {
	return self.status.shortValue == PRESENTATION_STATUS_READY;
}


- (void)fetchRemoteTracksFrom:(ILobbyRemoteDirectory *)remoteDirectory {
	for ( ILobbyRemoteDirectory *remoteTrackDirectory in remoteDirectory.subdirectories ) {
		//NSLog( @"Track URL: %@", remoteTrackDirectory.location );
		[ILobbyStoreTrack newTrackInPresentation:self location:remoteTrackDirectory.location];
	}

	NSLog( @"Tracks: %@", self.tracks );
}

@end
