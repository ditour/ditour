//
//  ILobbyStorePresentationGroup.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentationGroup.h"
#import "ILobbyRemoteDirectory.h"

@implementation ILobbyStorePresentationGroup

@dynamic presentations;
@dynamic root;

@dynamic activePresentations;
@dynamic pendingPresentations;


+ (instancetype)insertNewPresentationGroupInContext:(NSManagedObjectContext *)managedObjectContext {
    ILobbyStorePresentationGroup *group = [NSEntityDescription insertNewObjectForEntityForName:@"PresentationGroup" inManagedObjectContext:managedObjectContext];
	return group;
}


- (NSString *)shortName {
	return [self.remoteLocation lastPathComponent];
}


- (void)fetchPresentationsWithCompletion:(void (^)(ILobbyStorePresentationGroup *group, NSError *error))completionBlock {
	dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
		NSError *error = nil;
		ILobbyRemoteDirectory *remoteGroup = [ILobbyRemoteDirectory parseDirectoryAtURL:self.remoteURL error:&error];

		if ( !error ) {
			[self.managedObjectContext performBlockAndWait:^{
				NSArray *remotePresentations = remoteGroup.subdirectories;
				for ( ILobbyRemoteDirectory *remotePresentation in remotePresentations ) {
					[ILobbyStorePresentation newPresentationInGroup:self location:remotePresentation.location];
				}
				[self.managedObjectContext refreshObject:self mergeChanges:YES];
				NSLog( @"group presentations: %@", self.presentations );
			}];
		}

		completionBlock( self, error );
	});
}

@end