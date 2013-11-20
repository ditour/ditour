//
//  IlobbyStoreTrackItem.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ILobbyStoreTrack;

@interface IlobbyStoreTrackItem : NSManagedObject

@property (nonatomic, retain) ILobbyStoreTrack *parentTrack;

@end
