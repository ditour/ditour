//
//  ILobbyStoreRemoteContainer.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/27/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteItem.h"
#import "ILobbyStoreConfiguration.h"


@interface ILobbyStoreRemoteContainer : ILobbyStoreRemoteItem

@property (nonatomic, retain) ILobbyStoreConfiguration *configuration;
@end
