//
//  ILobbyStoreSlide.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ILobbyStoreRemoteItem.h"

@class ILobbyStoreTrack;


@interface ILobbyStoreSlide : ILobbyStoreRemoteItem

@property (nonatomic, retain) ILobbyStoreTrack *track;

+ (instancetype)insertNewSlideInContext:(NSManagedObjectContext *)managedObjectContext;

@end
