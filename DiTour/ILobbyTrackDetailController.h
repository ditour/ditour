//
//  ILobbyTrackDetailController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/24/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ILobbyModelContainer.h"
#import "ILobbyStoreTrack.h"
#import "ILobbyDownloadStatus.h"

@class MainModel;


@interface ILobbyTrackDetailController : UITableViewController <ILobbyModelContainer>

@property (nonatomic, weak) MainModel *lobbyModel;
@property (nonatomic, strong) ILobbyStoreTrack *track;
@property (nonatomic, strong) ILobbyDownloadContainerStatus *trackDownloadStatus;

@end
