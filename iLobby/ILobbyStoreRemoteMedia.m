//
//  ILobbyStoreRemoteMedia.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteMedia.h"


@implementation ILobbyStoreRemoteMedia

// attributes
@dynamic remoteInfo;
@dynamic remoteLocation;

// relationships
@dynamic slides;
@dynamic track;


+ (instancetype)insertNewSlideInContext:(NSManagedObjectContext *)managedObjectContext {
    return [NSEntityDescription insertNewObjectForEntityForName:@"RemoteMedia" inManagedObjectContext:managedObjectContext];
}

@end
