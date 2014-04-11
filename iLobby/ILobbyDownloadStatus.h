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

- (void)downloadStatusChanged:(ILobbyDownloadStatus *)status;

@end



@class ILobbyDownloadContainerStatus;


@interface ILobbyDownloadStatus : NSObject

@property (weak, readonly) ILobbyDownloadContainerStatus *container;
@property (strong, readonly) ILobbyStoreRemoteItem *remoteItem;
@property (nonatomic, readonly) float progress;
@property (weak) id<ILobbyDownloadStatusDelegate> delegate;

- (instancetype)initWithItem:(ILobbyStoreRemoteItem *)remoteItem container:(ILobbyDownloadContainerStatus *)container;
+ (instancetype)statusForRemoteItem:(ILobbyStoreRemoteItem *)remoteItem container:(ILobbyDownloadContainerStatus *)container;

@end



@interface ILobbyDownloadContainerStatus : ILobbyDownloadStatus

- (void)addChildStatus:(ILobbyDownloadStatus *)childStatus;
- (ILobbyDownloadStatus *)childStatusForRemoteItemID:(NSManagedObjectID *)remoteID;
- (ILobbyDownloadStatus *)childStatusForRemoteItem:(ILobbyStoreRemoteItem *)remoteItem;

// set a common delegate for each child
- (void)setChildrenDelegate:(id<ILobbyDownloadStatusDelegate>)childrenDelegate;

@end



@interface ILobbyDownloadFileStatus : ILobbyDownloadStatus

- (void)setProgress:(float)progress;

@end