//
//  ILobbyStoreMain.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreUserConfig.h"
#import "ILobbyStorePresentation.h"
#import "ILobbyStoreTrackConfiguration.h"


@implementation ILobbyStoreUserConfig

@dynamic rootLocation;
@dynamic defaultPresentation;
@dynamic configuraton;


+ (instancetype)insertNewUserConfigInContext:(NSManagedObjectContext *)managedObjectContext {
    return [NSEntityDescription insertNewObjectForEntityForName:@"UserConfig" inManagedObjectContext:managedObjectContext];
}


- (NSURL *)rootURL {
	NSString *rootLocation = self.rootLocation;
	return rootLocation ? [NSURL URLWithString:rootLocation] : nil;
}

@end
