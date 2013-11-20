//
//  ILobbyStoreTrack.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "IlobbyStoreTrackItem.h"

@class ILobbyStorePresentation, ILobbyStoreSlideConfiguration, IlobbyStoreTrackItem;

@interface ILobbyStoreTrack : IlobbyStoreTrackItem

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) ILobbyStorePresentation *presentation;
@property (nonatomic, retain) ILobbyStoreSlideConfiguration *configuration;
@property (nonatomic, retain) IlobbyStoreTrackItem *children;

@end
