//
//  ILobbyFileInfoController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/29/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ILobbyStoreRemoteFile.h"
#import "ILobbyModelContainer.h"
#import "ILobbyDownloadStatus.h"


@interface ILobbyFileInfoController : UIViewController <ILobbyModelContainer>

@property (nonatomic, strong) ILobbyStoreRemoteFile *remoteFile;
@property (nonatomic, strong) ILobbyDownloadStatus *downloadStatus;
@property (nonatomic, readwrite, strong) ILobbyModel *lobbyModel;

@end
