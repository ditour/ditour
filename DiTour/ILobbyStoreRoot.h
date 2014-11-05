//
//  ILobbyStoreMain.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class TrackConfiguration, PresentationGroupStore, PresentationStore;
@class ConfigurationStore;

@interface ILobbyStoreRoot : NSManagedObject

// TODO: really a PresentationStore
@property (nonatomic, retain) PresentationStore *currentPresentation;
@property (nonatomic, retain) NSOrderedSet *groups;
@property (nonatomic, retain) ConfigurationStore *configuration;
@end



@interface ILobbyStoreRoot (CoreDataGeneratedAccessors)

- (void)removeObjectFromGroupsAtIndex:(NSUInteger)idx;
- (void)removeGroupsAtIndexes:(NSIndexSet *)indexes;
@end





// custom additions
@interface ILobbyStoreRoot ()

+ (instancetype)insertNewRootStoreInContext:(NSManagedObjectContext *)managedObjectContext;
+ (NSString *)entityName;

- (PresentationGroupStore *)addNewPresentationGroup;
- (void)moveGroupAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

@end
