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
#import "ILobbyStoreTrack.h"


typedef enum : short {
	PRESENTATION_STATUS_PENDING,
	PRESENTATION_STATUS_READY,
	PRESENTATION_STATUS_CANCELED
} PresentationStatus;


@class ILobbyStoreRoot, ILobbyStorePresentationGroup;


@interface ILobbyStorePresentation : ILobbyStoreRemoteItem

// attributes
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSDate * timestamp;

// relationships
@property (nonatomic, retain) ILobbyStorePresentationGroup *group;
@property (nonatomic, retain) ILobbyStorePresentation *parent;
@property (nonatomic, retain) ILobbyStorePresentation *revision;
@property (nonatomic, retain) NSOrderedSet *tracks;
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



// custom additions
@interface ILobbyStorePresentation ()

@property (nonatomic, readonly) BOOL isReady;

+ (instancetype)newPresentationInGroup:(ILobbyStorePresentationGroup *)group location:(NSURL *)remoteURL;

@end
