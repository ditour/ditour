//
//  ILobbyStorePresentation.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentation.h"


@implementation ILobbyStorePresentation

// attributes
@dynamic name;
@dynamic status;
@dynamic timestamp;

// relationships
@dynamic group;
@dynamic parent;
@dynamic revision;
@dynamic root;
@dynamic tracks;


+ (instancetype)insertNewPresentationInContext:(NSManagedObjectContext *)managedObjectContext {
    ILobbyStorePresentation *presentation = [NSEntityDescription insertNewObjectForEntityForName:@"Presentation" inManagedObjectContext:managedObjectContext];
	presentation.status = PRESENTATION_STATUS_NEW;
	presentation.timestamp = [NSDate date];
	return presentation;
}


- (BOOL)isReady {
	return self.status.shortValue == PRESENTATION_STATUS_READY;
}

@end
