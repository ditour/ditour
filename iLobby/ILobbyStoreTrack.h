//
//  ILobbyStoreTrack.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "ILobbyStoreRemoteItem.h"
#import "ILobbyStoreSlide.h"


@class ILobbyStorePresentation;

@interface ILobbyStoreTrack : ILobbyStoreRemoteItem

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) ILobbyStorePresentation *presentation;
@property (nonatomic, retain) NSOrderedSet *slides;

@end



@interface ILobbyStoreTrack (CoreDataGeneratedAccessors)

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



