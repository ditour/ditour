//
//  ILobbyStoreTrack.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ILobbyStoreRemoteContainer.h"
#import "ILobbyStoreRemoteMedia.h"
#import "ILobbyRemoteDirectory.h"


@class ILobbyStorePresentation;

@interface ILobbyStoreTrack : ILobbyStoreRemoteContainer

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) ILobbyStorePresentation *presentation;
@property (nonatomic, retain) NSOrderedSet *remoteMedia;
@end



@interface ILobbyStoreTrack (CoreDataGeneratedAccessors)

- (void)insertObject:(ILobbyStoreRemoteMedia *)value inRemoteMediaAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRemoteMediaAtIndex:(NSUInteger)idx;
- (void)insertRemoteMedia:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRemoteMediaAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRemoteMediaAtIndex:(NSUInteger)idx withObject:(ILobbyStoreRemoteMedia *)value;
- (void)replaceRemoteMediaAtIndexes:(NSIndexSet *)indexes withRemoteMedia:(NSArray *)values;
- (void)addRemoteMediaObject:(ILobbyStoreRemoteMedia *)value;
- (void)removeRemoteMediaObject:(ILobbyStoreRemoteMedia *)value;
- (void)addRemoteMedia:(NSOrderedSet *)values;
- (void)removeRemoteMedia:(NSOrderedSet *)values;
@end



// custom additions
@interface ILobbyStoreTrack ()

+ (instancetype)newTrackInPresentation:(ILobbyStorePresentation *)presentation from:(ILobbyRemoteDirectory *)remoteDirectory;

@end