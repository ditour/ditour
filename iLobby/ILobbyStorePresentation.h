//
//  ILobbyStorePresentation.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class ILobbyStorePresentationMaster;


typedef enum : NSInteger {
	PRESENTATION_STATUS_NEW,
	PRESENTATION_STATUS_READY,
	PRESENTATION_STATUS_CANCELED
} PresentationStatus;


@class ILobbyStoreUserConfig, ILobbyStorePresentation, ILobbyStoreTrackConfiguration, ILobbyStoreTrack;

@interface ILobbyStorePresentation : NSManagedObject
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * status;

@property (nonatomic, retain) ILobbyStorePresentationMaster *master;
@property (nonatomic, retain) NSOrderedSet *tracks;
@property (nonatomic, retain) ILobbyStoreTrackConfiguration *trackConfiguration;

@property (nonatomic, readonly) BOOL isReady;
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

+ (instancetype)insertNewPresentationInContext:(NSManagedObjectContext *)managedObjectContext;

@end
