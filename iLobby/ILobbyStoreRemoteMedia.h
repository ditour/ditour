//
//  ILobbyStoreRemoteMedia.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ILobbyStoreRemoteFile.h"
#import "ILobbyRemoteFile.h"


@class ILobbyStoreSlide, ILobbyStoreTrack;


@interface ILobbyStoreRemoteMedia : ILobbyStoreRemoteFile

@property (nonatomic, retain) ILobbyStoreTrack *track;
@property (nonatomic, retain) NSOrderedSet *slides;
@end



@interface ILobbyStoreRemoteMedia (CoreDataGeneratedAccessors)

- (void)insertObject:(ILobbyStoreSlide *)value inSlidesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromSlidesAtIndex:(NSUInteger)idx;
- (void)insertSlides:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeSlidesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInSlidesAtIndex:(NSUInteger)idx withObject:(ILobbyStoreSlide *)value;
- (void)replaceSlidesAtIndexes:(NSIndexSet *)indexes withSlides:(NSArray *)values;
- (void)addSlidesObject:(ILobbyStoreSlide *)value;
- (void)removeSlidesObject:(ILobbyStoreSlide *)value;
- (void)addSlides:(NSOrderedSet *)values;
- (void)removeSlides:(NSOrderedSet *)values;
@end



// custom additions
@interface ILobbyStoreRemoteMedia ()

+ (instancetype)newRemoteMediaInTrack:(ILobbyStoreTrack *)track at:(ILobbyRemoteFile *)remoteFile;

@end