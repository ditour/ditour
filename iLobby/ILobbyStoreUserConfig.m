//
//  ILobbyStoreMain.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreUserConfig.h"
#import "ILobbyStorePresentationMaster.h"
#import "ILobbyStorePresentationGroup.h"
#import "ILobbyStoreTrackConfiguration.h"


static NSString *GROUPS_KEY = @"Groups";


@implementation ILobbyStoreUserConfig

@dynamic currentPresentationMaster;
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


// implement group removal and setting the current group to nil if necessary
- (void)removeObjectFromGroupsAtIndex:(NSUInteger)index {
	NSMutableOrderedSet *groups = [self mutableOrderedSetValueForKey:GROUPS_KEY];

	ILobbyStorePresentationGroup *group = [groups objectAtIndex:index];

	// if the group for the current presentation is the group marked for removal then remove set the current master to nil
	if ( self.currentPresentationMaster.group == group ) {
		self.currentPresentationMaster = nil;
	}

	[groups removeObjectAtIndex:index];

	// the group no longer has a user config, so remove it
	[group.managedObjectContext deleteObject:group];
}


// remove the groups corresponding to the specified indexes
- (void)removeGroupsAtIndexes:(NSIndexSet *)indexes {
	[indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger index, BOOL *stop) {
		[self removeObjectFromGroupsAtIndex:index];
	}];
}


// move the group from the fromIndex to the toIndex
- (void)moveGroupAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
	NSMutableOrderedSet *groups = [self mutableOrderedSetValueForKey:GROUPS_KEY];
	[groups moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] toIndex:toIndex];
}

@end
