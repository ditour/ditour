//
//  ILobbyStoreRemoteContainer.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/27/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteItem.h"
#import "ILobbyRemoteFile.h"

@class ConfigurationStore;


@interface ILobbyStoreRemoteContainer : ILobbyStoreRemoteItem {
	NSDictionary *_effectiveConfiguration;
}

@property (nonatomic, retain) ConfigurationStore *configuration;
@end



// custom additions
@interface ILobbyStoreRemoteContainer ()

@property (nonatomic, readonly) NSDictionary *effectiveConfiguration;
- (NSDictionary *)parseConfiguration;

- (void)processRemoteFile:(ILobbyRemoteFile *)remoteFile;

@end