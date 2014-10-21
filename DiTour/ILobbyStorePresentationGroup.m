//
//  ILobbyStorePresentationGroup.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentationGroup.h"
#import "ILobbyRemoteDirectory.h"
#import "ILobbyStorePresentation.h"

@implementation ILobbyStorePresentationGroup

@dynamic presentations;
@dynamic root;


+ (instancetype)insertNewPresentationGroupInContext:(NSManagedObjectContext *)managedObjectContext {
    ILobbyStorePresentationGroup *group = [NSEntityDescription insertNewObjectForEntityForName:@"PresentationGroup" inManagedObjectContext:managedObjectContext];

	// generate a unique path for the group based on the timestamp when the group was created
	NSDateFormatter *formatter = [NSDateFormatter new];
	formatter.dateFormat = @"yyyyMMdd'-'HHmmss";
	group.path = [NSString stringWithFormat:@"Group-%@", [formatter stringFromDate:[NSDate date]]];
//	NSLog( @"group path: %@", group.absolutePath );

	return group;
}


- (NSString *)shortName {
	return [self.remoteLocation lastPathComponent];
}


- (NSArray *)pendingPresentations {
	NSString *query = [NSString stringWithFormat:@"(group = %%@) AND status = %hd OR status = %hd", REMOTE_ITEM_STATUS_PENDING, REMOTE_ITEM_STATUS_DOWNLOADING];
	return [self fetchPresentationsWithFormat:query];
}


- (NSArray *)activePresentations {
	NSString *query = [NSString stringWithFormat:@"(group = %%@) AND status = %hd", REMOTE_ITEM_STATUS_READY];
	return [self fetchPresentationsWithFormat:query];
}


- (NSArray *)fetchPresentationsWithFormat:(NSString *)format {
	NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:[ILobbyStorePresentation entityName]];
	fetch.predicate = [NSPredicate predicateWithFormat:format argumentArray:@[self]];
	fetch.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
	return [self.managedObjectContext executeFetchRequest:fetch error:nil];
}

@end