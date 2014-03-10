//
//  ILobbyStorePresentation.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentation.h"
#import "ILobbyStoreUserConfig.h"
#import "ILobbyStorePresentation.h"
#import "ILobbyStoreTrackConfiguration.h"
#import "ILobbyStoreTrack.h"


@implementation ILobbyStorePresentation

@dynamic path;
@dynamic status;
@dynamic timestamp;
@dynamic master;
@dynamic tracks;
@dynamic trackConfiguration;


+ (instancetype)insertNewPresentationInContext:(NSManagedObjectContext *)managedObjectContext {
    ILobbyStorePresentation *presentation = [NSEntityDescription insertNewObjectForEntityForName:@"Presentation" inManagedObjectContext:managedObjectContext];
	presentation.timestamp = [NSDate date];
	return presentation;
}


- (BOOL)isReady {
	return self.status.intValue == PRESENTATION_STATUS_READY;
}

@end
