//
//  ILobbyStorePresentationGroup.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStorePresentationGroup.h"
#import "ILobbyRemoteDirectory.h"
#import "ILobbyModel.h"

@implementation ILobbyStorePresentationGroup

@dynamic presentations;
@dynamic root;

@dynamic activePresentations;
@dynamic pendingPresentations;


+ (instancetype)insertNewPresentationGroupInContext:(NSManagedObjectContext *)managedObjectContext {
    ILobbyStorePresentationGroup *group = [NSEntityDescription insertNewObjectForEntityForName:@"PresentationGroup" inManagedObjectContext:managedObjectContext];

	// generate a unique path for the group based on the timestamp when the group was created
	NSDateFormatter *formatter = [NSDateFormatter new];
	formatter.dateFormat = @"yyyyMMdd'-'HHmmss";
	NSString *basePath = [NSString stringWithFormat:@"Group-%@", [formatter stringFromDate:[NSDate date]]];
	group.path = [[ILobbyModel presentationGroupsRoot] stringByAppendingPathComponent:basePath];
	NSLog( @"group path: %@", group.path );

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
				// process any files (e.g. config files)
				for ( ILobbyRemoteFile *remoteFile in remoteGroup.files ) {
					[self processRemoteFile:remoteFile];
				}

				// store the active presentations by name so they can be used as parents if necessary
				NSMutableDictionary *activePresentationsByName = [NSMutableDictionary new];
				for ( ILobbyStorePresentation *presentation in self.activePresentations ) {
					activePresentationsByName[presentation.name] = presentation;
				}

				// fetch presentations
				for ( ILobbyRemoteDirectory *remotePresentationDirectory in remoteGroup.subdirectories ) {
					ILobbyStorePresentation *presentation = [ILobbyStorePresentation newPresentationInGroup:self from:remotePresentationDirectory];

					// if an active presentation has the same name then assign it as a parent
					ILobbyStorePresentation *presentationParent = activePresentationsByName[presentation.name];
					if ( presentationParent != nil ) {
						presentation.parent = presentationParent;
					}
				}

				// updates fetched properties
				[self.managedObjectContext refreshObject:self mergeChanges:YES];
			}];
		}

		completionBlock( self, error );
	});
}

@end