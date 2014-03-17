//
//  ILobbyStorePresentationMaster.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ILobbyStorePresentation.h"
#import "ILobbyStoreRemoteItem.h"

@class ILobbyStorePresentationGroup;


@interface ILobbyStorePresentationMaster : ILobbyStoreRemoteItem
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) ILobbyStorePresentationGroup *group;
@property (nonatomic, retain) NSSet *presentations;
@end


@interface ILobbyStorePresentationMaster (CoreDataGeneratedAccessors)

- (void)addPresentationsObject:(ILobbyStorePresentation *)value;
- (void)removePresentationsObject:(ILobbyStorePresentation *)value;
- (void)addPresentations:(NSSet *)values;
- (void)removePresentations:(NSSet *)values;

@end



@interface ILobbyStorePresentationMaster ()

@property (nonatomic, readonly) ILobbyStorePresentation *currentPresentation;

@end




