//
//  ILobbyStoreRemoteMedia.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ILobbyStoreTrack;
@class ILobbyStoreSlide;


@interface ILobbyStoreRemoteMedia : NSManagedObject

@property (nonatomic, retain) NSString * remoteInfo;
@property (nonatomic, retain) NSString * remoteLocation;
@property (nonatomic, retain) NSSet *slides;
@property (nonatomic, retain) ILobbyStoreTrack *track;

+ (instancetype)insertNewSlideInContext:(NSManagedObjectContext *)managedObjectContext;

@end

@interface ILobbyStoreRemoteMedia (CoreDataGeneratedAccessors)

- (void)addSlidesObject:(ILobbyStoreSlide *)value;
- (void)removeSlidesObject:(ILobbyStoreSlide *)value;
- (void)addSlides:(NSSet *)values;
- (void)removeSlides:(NSSet *)values;

@end
