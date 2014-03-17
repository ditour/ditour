//
//  ILobbyStorePresentation.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentation.h"
#import "ILobbyStorePresentationMaster.h"


@implementation ILobbyStorePresentation

@dynamic path;
@dynamic status;
@dynamic timestamp;
@dynamic master;
@dynamic trackConfiguration;
@dynamic tracks;


+ (instancetype)insertNewPresentationInContext:(NSManagedObjectContext *)managedObjectContext {
    ILobbyStorePresentation *presentation = [NSEntityDescription insertNewObjectForEntityForName:@"Presentation" inManagedObjectContext:managedObjectContext];
	presentation.timestamp = [NSDate date];
	return presentation;
}


- (NSString *)name {
	return self.master.name;
}


- (NSString *)remoteLocation {
	return self.master.remoteLocation;
}


- (NSURL *)remoteURL {
	NSString *remoteLocation = self.remoteLocation;
	return remoteLocation ? [NSURL URLWithString:remoteLocation] : nil;
}


- (BOOL)isReady {
	return self.status.intValue == PRESENTATION_STATUS_READY;
}

@end
