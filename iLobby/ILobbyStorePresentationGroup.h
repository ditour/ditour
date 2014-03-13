//
//  ILobbyStorePresentationGroup.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ILobbyStorePresentationMaster.h"
#import "ILobbyStoreRemoteItem.h"

@interface ILobbyStorePresentationGroup : ILobbyStoreRemoteItem

@property (nonatomic, retain) NSNumber * selected;
@property (nonatomic, retain) ILobbyStorePresentationMaster *currentPresentationMaster;
@property (nonatomic, retain) NSSet *presentationMasters;
@property (nonatomic, retain) ILobbyStoreUserConfig *userConfig;

@end



@interface ILobbyStorePresentationGroup (CoreDataGeneratedAccessors)

- (void)addPresentationMastersObject:(ILobbyStorePresentationMaster *)value;
- (void)removePresentationMastersObject:(ILobbyStorePresentationMaster *)value;
- (void)addPresentationMasters:(NSSet *)values;
- (void)removePresentationMasters:(NSSet *)values;

@end



// custom additions
@interface ILobbyStorePresentationGroup ()

+ (instancetype)insertNewPresentationGroupInContext:(NSManagedObjectContext *)managedObjectContext;

@end
