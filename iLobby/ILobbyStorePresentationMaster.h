//
//  ILobbyStorePresentationMaster.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ILobbyStorePresentation.h"
#import "ILobbyStoreRemoteItem.h"

@class ILobbyStorePresentationGroup;


@interface ILobbyStorePresentationMaster : ILobbyStoreRemoteItem

@property (nonatomic, retain) ILobbyStorePresentation *currentPresentation;
@property (nonatomic, retain) NSOrderedSet *presentations;
@property (nonatomic, retain) ILobbyStorePresentationGroup *group;
@property (nonatomic, retain) ILobbyStorePresentationGroup *groupForCurrent;
@end



@interface ILobbyStorePresentationMaster (CoreDataGeneratedAccessors)

- (void)insertObject:(ILobbyStorePresentation *)value inPresentationsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromPresentationsAtIndex:(NSUInteger)idx;
- (void)insertPresentations:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removePresentationsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInPresentationsAtIndex:(NSUInteger)idx withObject:(ILobbyStorePresentation *)value;
- (void)replacePresentationsAtIndexes:(NSIndexSet *)indexes withPresentations:(NSArray *)values;
- (void)addPresentationsObject:(ILobbyStorePresentation *)value;
- (void)removePresentationsObject:(ILobbyStorePresentation *)value;
- (void)addPresentations:(NSOrderedSet *)values;
- (void)removePresentations:(NSOrderedSet *)values;
@end



