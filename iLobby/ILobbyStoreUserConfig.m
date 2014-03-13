//
//  ILobbyStoreMain.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreUserConfig.h"
#import "ILobbyStorePresentationGroup.h"
#import "ILobbyStoreTrackConfiguration.h"


@implementation ILobbyStoreUserConfig

@dynamic currentGroup;
@dynamic groups;
@dynamic trackConfiguration;


// create a new user configuration in the specified context
+ (instancetype)insertNewUserConfigInContext:(NSManagedObjectContext *)managedObjectContext {
    return [NSEntityDescription insertNewObjectForEntityForName:@"UserConfig" inManagedObjectContext:managedObjectContext];
}


// create a new presentation group and add it to this user configuration
- (ILobbyStorePresentationGroup *)addNewPresentationGroup {
	ILobbyStorePresentationGroup *group = [ILobbyStorePresentationGroup insertNewPresentationGroupInContext:self.managedObjectContext];
	group.userConfig = self;
	return group;
}


@end
