//
//  ILobbyStoreMain.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ILobbyStoreTrackConfiguration, ILobbyStorePresentationGroup, ILobbyStorePresentationMaster;


@interface ILobbyStoreUserConfig : NSManagedObject

@property (nonatomic, retain) ILobbyStorePresentationMaster *currentPresentationMaster;
@property (nonatomic, retain) NSOrderedSet *groups;
@property (nonatomic, retain) ILobbyStoreTrackConfiguration *trackConfiguration;

@end



@interface ILobbyStoreUserConfig (CoreDataGeneratedAccessors)

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
@interface ILobbyStoreUserConfig ()

+ (instancetype)insertNewUserConfigInContext:(NSManagedObjectContext *)managedObjectContext;

- (ILobbyStorePresentationGroup *)addNewPresentationGroup;
- (void)moveGroupAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

@end
