//
//  ILobbyDownloadItemStatus.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/3/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILobbyStoreRemoteItem.h"


@class ILobbyDownloadStatus;


@protocol ILobbyDownloadStatusDelegate <NSObject>

- (void)statusChanged:(ILobbyDownloadStatus *)status;

@end



@interface ILobbyDownloadStatus : NSObject

@property (strong) ILobbyStoreRemoteItem *remoteItem;
@property float progress;
@property (weak) id<ILobbyDownloadStatusDelegate> delegate;

@end
