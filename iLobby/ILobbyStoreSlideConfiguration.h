//
//  ILobbyStoreSlideConfiguration.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ILobbyStoreUserConfig, ILobbyStorePresentation, ILobbyStoreSlideTransition, ILobbyStoreTrack;

@interface ILobbyStoreSlideConfiguration : NSManagedObject

@property (nonatomic, retain) NSNumber * slideDuration;
@property (nonatomic, retain) NSNumber * trackChangeDelay;
@property (nonatomic, retain) NSSet *mainConfig;
@property (nonatomic, retain) NSSet *presentation;
@property (nonatomic, retain) NSSet *track;
@property (nonatomic, retain) ILobbyStoreSlideTransition *transition;
@end

@interface ILobbyStoreSlideConfiguration (CoreDataGeneratedAccessors)

- (void)addMainConfigObject:(ILobbyStoreUserConfig *)value;
- (void)removeMainConfigObject:(ILobbyStoreUserConfig *)value;
- (void)addMainConfig:(NSSet *)values;
- (void)removeMainConfig:(NSSet *)values;

- (void)addPresentationObject:(ILobbyStorePresentation *)value;
- (void)removePresentationObject:(ILobbyStorePresentation *)value;
- (void)addPresentation:(NSSet *)values;
- (void)removePresentation:(NSSet *)values;

- (void)addTrackObject:(ILobbyStoreTrack *)value;
- (void)removeTrackObject:(ILobbyStoreTrack *)value;
- (void)addTrack:(NSSet *)values;
- (void)removeTrack:(NSSet *)values;

@end
