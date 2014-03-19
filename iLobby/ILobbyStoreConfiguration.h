//
//  ILobbyStoreConfiguration.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/19/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "ILobbyStoreRemoteItem.h"
#import "ILobbyStoreSlideTransition.h"
#import "ILobbyStoreTrackConfiguration.h"


@interface ILobbyStoreConfiguration : ILobbyStoreRemoteItem

// attributes
@property (nonatomic, retain) NSNumber * refreshPeriod;		// refresh period in minutes (applies to active presentation)

// relationships
@property (nonatomic, retain) ILobbyStoreRemoteItem *remoteItem;
@property (nonatomic, retain) ILobbyStoreSlideTransition *slideTransition;
@property (nonatomic, retain) ILobbyStoreTrackConfiguration *trackConfiguration;

@end
