//
//  ILobbyStorePresentationGroup.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ILobbyStorePresentation.h"
#import "ILobbyStoreRemoteItem.h"


@interface ILobbyStorePresentationGroup : ILobbyStoreRemoteItem

@property (nonatomic, retain) NSSet *presentations;
@property (nonatomic, retain) ILobbyStoreRoot *root;
@end



@interface ILobbyStorePresentationGroup (CoreDataGeneratedAccessors)

- (void)addPresentationsObject:(ILobbyStorePresentation *)value;
- (void)removePresentationsObject:(ILobbyStorePresentation *)value;
- (void)addPresentations:(NSSet *)values;
- (void)removePresentations:(NSSet *)values;
@end



// custom additions
@interface ILobbyStorePresentationGroup ()

@property (nonatomic, readonly) NSString *shortName;
@property (nonatomic, strong) NSArray *activePresentations;
@property (nonatomic, strong) NSArray *pendingPresentations;

+ (instancetype)insertNewPresentationGroupInContext:(NSManagedObjectContext *)managedObjectContext;

@end
