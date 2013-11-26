//
//  ILobbyStoreTrackConfiguration.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreTrackConfiguration.h"
#import "ILobbyStoreUserConfig.h"
#import "ILobbyStorePresentation.h"
#import "ILobbyStoreSlideTransition.h"
#import "ILobbyStoreTrack.h"


@implementation ILobbyStoreTrackConfiguration

@dynamic slideDuration;
@dynamic trackChangeDelay;
@dynamic mainConfig;
@dynamic presentation;
@dynamic track;
@dynamic transition;


+ (instancetype)insertNewtrackConfigurationInContext:(NSManagedObjectContext *)managedObjectContext {
    return [NSEntityDescription insertNewObjectForEntityForName:@"trackConfiguration" inManagedObjectContext:managedObjectContext];
}

@end
