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
@property (nonatomic, readonly) BOOL completed;
@property (weak) id<ILobbyDownloadStatusDelegate> delegate;

- (instancetype)initWithItem:(ILobbyStoreRemoteItem *)remoteItem container:(ILobbyDownloadContainerStatus *)container;
+ (instancetype)statusForRemoteItem:(ILobbyStoreRemoteItem *)remoteItem container:(ILobbyDownloadContainerStatus *)container;

// determine whether this object's remote item matches (same objectID) the other remote item
- (BOOL)matchesRemoteItem:(ILobbyStoreRemoteItem *)otherRemoteItem;

@end



@interface ILobbyDownloadContainerStatus : ILobbyDownloadStatus

@property BOOL submitted;

- (void)addChildStatus:(ILobbyDownloadStatus *)childStatus;
- (ILobbyDownloadStatus *)childStatusForRemoteItemID:(NSManagedObjectID *)remoteID;
- (ILobbyDownloadStatus *)childStatusForRemoteItem:(ILobbyStoreRemoteItem *)remoteItem;

- (void)updateProgress;

// set a common delegate for each child
- (void)setChildrenDelegate:(id<ILobbyDownloadStatusDelegate>)childrenDelegate;

@end



@interface ILobbyDownloadFileStatus : ILobbyDownloadStatus

- (void)setProgress:(float)progress;
- (void)setCompleted:(BOOL)completionState;

@end