//
//  ILobbyStoreConfiguration.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/19/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "ILobbyRemoteFile.h"
#import "ILobbyStoreRemoteFile.h"


@class ILobbyStoreRemoteContainer;


@interface ILobbyStoreConfiguration : ILobbyStoreRemoteFile

@property (nonatomic, retain) ILobbyStoreRemoteContainer *container;

@end



// custom additions
@interface ILobbyStoreConfiguration ()

+ (instancetype)newConfigurationInContainer:(ILobbyStoreRemoteContainer	*)container at:(ILobbyRemoteFile *)remoteFile;

@end