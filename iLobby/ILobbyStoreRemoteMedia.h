//
//  ILobbyStoreRemoteMedia.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ILobbyStoreLocalMedia;

@interface ILobbyStoreRemoteMedia : NSManagedObject

@property (nonatomic, retain) NSString * remoteInfo;
@property (nonatomic, retain) NSString * remoteLocation;
@property (nonatomic, retain) NSOrderedSet *localMedia;
@end

@interface ILobbyStoreRemoteMedia (CoreDataGeneratedAccessors)

- (void)insertObject:(ILobbyStoreLocalMedia *)value inLocalMediaAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLocalMediaAtIndex:(NSUInteger)idx;
- (void)insertLocalMedia:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLocalMediaAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLocalMediaAtIndex:(NSUInteger)idx withObject:(ILobbyStoreLocalMedia *)value;
- (void)replaceLocalMediaAtIndexes:(NSIndexSet *)indexes withLocalMedia:(NSArray *)values;
- (void)addLocalMediaObject:(ILobbyStoreLocalMedia *)value;
- (void)removeLocalMediaObject:(ILobbyStoreLocalMedia *)value;
- (void)addLocalMedia:(NSOrderedSet *)values;
- (void)removeLocalMedia:(NSOrderedSet *)values;
@end
