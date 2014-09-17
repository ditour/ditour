//
//  ILobbyStoreRemoteContainer.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/27/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteItem.h"
#import "ILobbyStoreConfiguration.h"


@interface ILobbyStoreRemoteContainer : ILobbyStoreRemoteItem {
	NSDictionary *_effectiveConfiguration;
}

@property (nonatomic, retain) ILobbyStoreConfiguration *configuration;
@end



// custom additions
@interface ILobbyStoreRemoteContainer ()

@property (nonatomic, readonly) NSDictionary *effectiveConfiguration;
- (NSDictionary *)parseConfiguration;

- (void)processRemoteFile:(ILobbyRemoteFile *)remoteFile;

@end