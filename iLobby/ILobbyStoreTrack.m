//
//  ILobbyStoreTrack.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreTrack.h"


@implementation ILobbyStoreTrack

@dynamic title;
@dynamic presentation;
@dynamic slides;


+ (instancetype)insertNewTrackInContext:(NSManagedObjectContext *)managedObjectContext {
	return [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:managedObjectContext];
}


@end
