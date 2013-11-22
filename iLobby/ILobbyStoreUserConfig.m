//
//  ILobbyStoreMain.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreUserConfig.h"
#import "ILobbyStorePresentation.h"
#import "ILobbyStoreSlideConfiguration.h"


@implementation ILobbyStoreUserConfig

@dynamic defaultPresentation;
@dynamic configuraton;


+ (instancetype)insertNewUserConfigInContext:(NSManagedObjectContext *)managedObjectContext {
    return [NSEntityDescription insertNewObjectForEntityForName:@"UserConfig" inManagedObjectContext:managedObjectContext];
}

@end
