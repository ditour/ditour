//
//  ILobbyStoreSlideTransition.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreSlideTransition.h"
#import "ILobbyStoreSlideConfiguration.h"


@implementation ILobbyStoreSlideTransition

@dynamic duration;
@dynamic subType;
@dynamic type;
@dynamic configuration;


+ (instancetype)insertNewSlideConfigurationInContext:(NSManagedObjectContext *)managedObjectContext {
    return [NSEntityDescription insertNewObjectForEntityForName:@"SlideTransition" inManagedObjectContext:managedObjectContext];
}

@end
