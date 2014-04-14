//
//  ILobbyStorePresentation.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentation.h"
#import "ILobbyStorePresentationGroup.h"
#import "ILobbyStoreRoot.h"


@implementation ILobbyStorePresentation

// attributes
@dynamic name;
@dynamic status;
@dynamic timestamp;

// relationships
@dynamic group;
@dynamic parent;
@dynamic revision;
@dynamic rootForCurrent;
@dynamic tracks;


+ (instancetype)newPresentationInGroup:(ILobbyStorePresentationGroup *)group from:(ILobbyRemoteDirectory *)remoteDirectory {

    ILobbyStorePresentation *presentation = [NSEntityDescription insertNewObjectForEntityForName:@"Presentation" inManagedObjectContext:group.managedObjectContext];

	presentation.status = @( REMOTE_ITEM_STATUS_PENDING );
	presentation.timestamp = [NSDate date];
	presentation.remoteLocation = remoteDirectory.location.absoluteString;
	presentation.name = remoteDirectory.location.lastPathComponent;
	presentation.group = group;

	// generate a unique path for the presentation based on the name and timestamp when the presentation was created
	NSDateFormatter *formatter = [NSDateFormatter new];
	formatter.dateFormat = @"yyyyMMdd'-'HHmmss";
	NSString *basePath = [NSString stringWithFormat:@"%@-%@", presentation.name, [formatter stringFromDate:[NSDate date]]];
	presentation.path = [group.path stringByAppendingPathComponent:basePath];

//	NSLog( @"Fetching presentation: %@", presentation.name );

	// fetch the tracks
	for ( ILobbyRemoteDirectory *remoteTrackDirectory in remoteDirectory.subdirectories ) {
		[ILobbyStoreTrack newTrackInPresentation:presentation from:remoteTrackDirectory];
	}

	for ( ILobbyRemoteFile *remoteFile in remoteDirectory.files ) {
		[presentation processRemoteFile:remoteFile];
	}

	return presentation;
}


- (void)markReady {
	[super markReady];

	// if the presentation has a parent then replace it with this one since it is ready
	ILobbyStorePresentation *parentPresentation = self.parent;
	if ( parentPresentation != nil ) {
		BOOL current = parentPresentation.isCurrent;
		[self.group removePresentationsObject:parentPresentation];

		// if the parent was current this presentation should also be current
		if ( current ) {
			self.current = current;
		}

		self.parent = nil;

		[parentPresentation.managedObjectContext deleteObject:parentPresentation];
	}
}


- (void)setCurrent:(BOOL)current {
	if ( current ) {
		if ( !self.isCurrent ) {
			self.group.root.currentPresentation = self;
		}
	}
	else {
		if ( self.isCurrent ) {
			self.rootForCurrent = nil;
		}
	}
}


- (BOOL)isCurrent {
	return self.rootForCurrent != nil;
}

@end
