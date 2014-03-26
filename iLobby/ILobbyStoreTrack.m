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
@dynamic slides;


+ (instancetype)newTrackInPresentation:(ILobbyStorePresentation *)presentation location:(NSURL *)remoteURL {
	ILobbyStoreTrack *track = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:presentation.managedObjectContext];

	track.presentation = presentation;
	track.remoteLocation = remoteURL.absoluteString;

	// TODO: remove any leading numbers used for ordering and handle spaces and capitalization
	track.title = remoteURL.lastPathComponent;

	return track;
}


@end
