//
//  ILobbyStorePresentation.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ILobbyStoreMain, ILobbyStorePresentation, ILobbyStoreSlideConfiguration, ILobbyStoreTrack;

@interface ILobbyStorePresentation : NSManagedObject

@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * remoteLocation;
@property (nonatomic, retain) ILobbyStoreMain *mainStore;
@property (nonatomic, retain) ILobbyStoreSlideConfiguration *configuration;
@property (nonatomic, retain) NSOrderedSet *tracks;
@property (nonatomic, retain) ILobbyStorePresentation *origin;
@property (nonatomic, retain) ILobbyStorePresentation *revision;
@end

@interface ILobbyStorePresentation (CoreDataGeneratedAccessors)

- (void)insertObject:(ILobbyStoreTrack *)value inTracksAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTracksAtIndex:(NSUInteger)idx;
- (void)insertTracks:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTracksAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTracksAtIndex:(NSUInteger)idx withObject:(ILobbyStoreTrack *)value;
- (void)replaceTracksAtIndexes:(NSIndexSet *)indexes withTracks:(NSArray *)values;
- (void)addTracksObject:(ILobbyStoreTrack *)value;
- (void)removeTracksObject:(ILobbyStoreTrack *)value;
- (void)addTracks:(NSOrderedSet *)values;
- (void)removeTracks:(NSOrderedSet *)values;
@end
