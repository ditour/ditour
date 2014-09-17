//
//  ILobbyStoreMain.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ILobbyStoreConfiguration.h"


@class ILobbyStoreTrackConfiguration, ILobbyStorePresentationGroup, ILobbyStorePresentation;


@interface ILobbyStoreRoot : NSManagedObject

@property (nonatomic, retain) ILobbyStorePresentation *currentPresentation;
@property (nonatomic, retain) NSOrderedSet *groups;
@property (nonatomic, retain) ILobbyStoreConfiguration *configuration;
@end



@interface ILobbyStoreRoot (CoreDataGeneratedAccessors)

- (void)insertObject:(ILobbyStorePresentationGroup *)value inGroupsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromGroupsAtIndex:(NSUInteger)idx;
- (void)insertGroups:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeGroupsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInGroupsAtIndex:(NSUInteger)idx withObject:(ILobbyStorePresentationGroup *)value;
- (void)replaceGroupsAtIndexes:(NSIndexSet *)indexes withGroups:(NSArray *)values;
- (void)addGroupsObject:(ILobbyStorePresentationGroup *)value;
- (void)removeGroupsObject:(ILobbyStorePresentationGroup *)value;
- (void)addGroups:(NSOrderedSet *)values;
- (void)removeGroups:(NSOrderedSet *)values;
@end





// custom additions
@interface ILobbyStoreRoot ()

+ (instancetype)insertNewRootStoreInContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSString *)entityName;

- (ILobbyStorePresentationGroup *)addNewPresentationGroup;
- (void)moveGroupAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

@end
