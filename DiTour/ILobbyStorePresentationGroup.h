//
//  ILobbyStorePresentationGroup.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ILobbyStoreRemoteContainer.h"
#import "ILobbyStoreRoot.h"


@interface ILobbyStorePresentationGroup : ILobbyStoreRemoteContainer

@property (nonatomic, retain) NSSet *presentations;
@property (nonatomic, retain) ILobbyStoreRoot *root;
@end



@interface ILobbyStorePresentationGroup (CoreDataGeneratedAccessors)

- (void)addPresentationsObject:(id)value;
- (void)removePresentationsObject:(id)value;
- (void)addPresentations:(NSSet *)values;
- (void)removePresentations:(NSSet *)values;
@end



// custom additions
@interface ILobbyStorePresentationGroup ()

@property (nonatomic, readonly) NSString *shortName;
@property (nonatomic, readonly) NSArray *activePresentations;
@property (nonatomic, readonly) NSArray *pendingPresentations;

+ (instancetype)insertNewPresentationGroupInContext:(NSManagedObjectContext *)managedObjectContext;

@end
