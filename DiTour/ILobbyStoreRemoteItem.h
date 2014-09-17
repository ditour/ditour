//
//  ILobbyStoreRemoteItem.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>


enum : short {
	REMOTE_ITEM_STATUS_PENDING,
	REMOTE_ITEM_STATUS_DOWNLOADING,
	REMOTE_ITEM_STATUS_READY,
	REMOTE_ITEM_STATUS_DISPOSABLE
};


@interface ILobbyStoreRemoteItem : NSManagedObject

@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * remoteInfo;
@property (nonatomic, retain) NSString * remoteLocation;
@property (nonatomic, retain) NSString * path;
@end



// custom additions
@interface ILobbyStoreRemoteItem ()

@property (nonatomic, readonly) NSURL *remoteURL;

@property (nonatomic, readonly) BOOL isPending;
@property (nonatomic, readonly) BOOL isDownloading;
@property (nonatomic, readonly) BOOL isReady;
@property (nonatomic, readonly) BOOL isDisposable;

- (void)markPending;
- (void)markDownloading;
- (void)markReady;
- (void)markDisposable;

// get the full path (path is relative to the Presentation Groups Root directory whose absolute path can move when the app is updated since the document directory moves)
- (NSString *)absolutePath;

@end
