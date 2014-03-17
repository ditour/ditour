//
//  ILobbyStoreRemoteMedia.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ILobbyStoreRemoteItem.h"


@class ILobbyStoreSlide;


@interface ILobbyStoreRemoteMedia : ILobbyStoreRemoteItem
@property (nonatomic, retain) NSSet *slides;
@end



@interface ILobbyStoreRemoteMedia (CoreDataGeneratedAccessors)

- (void)addSlidesObject:(ILobbyStoreSlide *)value;
- (void)removeSlidesObject:(ILobbyStoreSlide *)value;
- (void)addSlides:(NSSet *)values;
- (void)removeSlides:(NSSet *)values;

@end
