//
//  ILobbyStoreTrack.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreTrack.h"
#import "ILobbyStorePresentation.h"
#import "ILobbyStoreSlideConfiguration.h"
#import "IlobbyStoreTrackItem.h"


@implementation ILobbyStoreTrack

@dynamic title;
@dynamic presentation;
@dynamic configuration;
@dynamic children;


+ (instancetype)insertNewTrackInContext:(NSManagedObjectContext *)managedObjectContext {
	return [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:managedObjectContext];
}


@end
