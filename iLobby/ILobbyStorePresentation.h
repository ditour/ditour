//
//  ILobbyStorePresentation.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ILobbyStoreRemoteItem.h"


typedef NS_ENUM( NSInteger, PRESENTATION_STATUS	) { PRESENTATION_STATUS_NEW=0, PRESENTATION_STATUS_READY, PRESENTATION_STATUS_CANCELED };


@class ILobbyStoreUserConfig, ILobbyStorePresentation, ILobbyStoreTrackConfiguration, ILobbyStoreTrack;

@interface ILobbyStorePresentation : ILobbyStoreRemoteItem
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSDate * timestamp;

@property (nonatomic, retain) ILobbyStorePresentation *origin;
@property (nonatomic, retain) ILobbyStorePresentation *revision;
@property (nonatomic, retain) ILobbyStoreTrackConfiguration *trackConfiguration;
@property (nonatomic, retain) NSOrderedSet *tracks;
@property (nonatomic, retain) ILobbyStoreUserConfig *userConfig;

@property (nonatomic, readonly) BOOL isReady;

+ (instancetype)insertNewPresentationInContext:(NSManagedObjectContext *)managedObjectContext;

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

