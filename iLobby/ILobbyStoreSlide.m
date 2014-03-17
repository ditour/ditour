//
//  ILobbyStoreSlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreSlide.h"


@implementation ILobbyStoreSlide

@dynamic path;
@dynamic remoteMedia;
@dynamic track;


+ (instancetype)insertNewSlideInContext:(NSManagedObjectContext *)managedObjectContext {
    return [NSEntityDescription insertNewObjectForEntityForName:@"Slide" inManagedObjectContext:managedObjectContext];
}

@end
