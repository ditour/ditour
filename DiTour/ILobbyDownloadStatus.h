//
//  ILobbyDownloadItemStatus.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/3/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ILobbyDownloadStatus;


@protocol ILobbyDownloadStatusDelegate <NSObject>

- (void)downloadStatusChanged:(ILobbyDownloadStatus *)status;

@end



@class ILobbyDownloadContainerStatus;
@class RemoteItemStore;


@interface ILobbyDownloadStatus : NSObject

@property (weak, readonly) ILobbyDownloadContainerStatus *container;
@property (strong, readonly) RemoteItemStore *remoteItem;
@property (nonatomic, readonly) float progress;
@property (nonatomic, readonly) BOOL completed;
@property (nonatomic, readwrite) BOOL canceled;
@property (nonatomic, strong) NSError *error;
@property (weak) id<ILobbyDownloadStatusDelegate> delegate;

- (instancetype)initWithItem:(RemoteItemStore *)remoteItem container:(ILobbyDownloadContainerStatus *)container;
+ (instancetype)statusForRemoteItem:(RemoteItemStore *)remoteItem container:(ILobbyDownloadContainerStatus *)container;

// determine whether this object's remote item matches (same objectID) the other remote item
- (BOOL)matchesRemoteItem:(RemoteItemStore *)otherRemoteItem;

@end



@interface ILobbyDownloadContainerStatus : ILobbyDownloadStatus

@property BOOL submitted;

- (void)addChildStatus:(ILobbyDownloadStatus *)childStatus;
//- (ILobbyDownloadStatus *)childStatusForRemoteItemID:(NSManagedObjectID *)remoteID;
- (ILobbyDownloadStatus *)childStatusForRemoteItem:(RemoteItemStore *)remoteItem;

- (void)updateProgress;

// set a common delegate for each child
- (void)setChildrenDelegate:(id<ILobbyDownloadStatusDelegate>)childrenDelegate;

- (void)printChildInfo;

@end



@interface ILobbyDownloadFileStatus : ILobbyDownloadStatus

- (void)setProgress:(float)progress;
- (void)setCompleted:(BOOL)completionState;

@end