//
//  ILobbyDownloadItemStatus.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/3/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyDownloadStatus.h"
#import "ILobbyConcurrentDictionary.h"



@interface ILobbyDownloadStatus ()

@property (weak, readwrite) ILobbyDownloadContainerStatus *container;
@property (nonatomic, strong, readwrite) ILobbyStoreRemoteItem *remoteItem;
@property (readwrite) float progress;

@end



@interface ILobbyDownloadContainerStatus ()

@property (strong) ILobbyConcurrentDictionary *childStatusItems;	// child status items keyed by child status' remote item object ID
- (void)updateProgress;

@end



@implementation ILobbyDownloadStatus

- (instancetype)initWithItem:(ILobbyStoreRemoteItem *)remoteItem container:(ILobbyDownloadContainerStatus *)container {
    self = [super init];
    if (self) {
		self.progress = 0.0;
        self.remoteItem = remoteItem;
		self.container = container;
		[container addChildStatus:self];
    }
    return self;
}


+ (instancetype)statusForRemoteItem:(ILobbyStoreRemoteItem *)remoteItem container:(ILobbyDownloadContainerStatus *)container {
	return [[self alloc] initWithItem:remoteItem container:container];
}


// determine whether this object's remote item matches (same objectID) the other remote item
- (BOOL)matchesRemoteItem:(ILobbyStoreRemoteItem *)otherRemoteItem {
	if ( self.remoteItem == otherRemoteItem ) {		// pointer identity is sufficient
		return YES;
	}
	else {
		__block NSManagedObjectID *remoteItemID = nil;
		[self.remoteItem.managedObjectContext performBlockAndWait:^{
			remoteItemID = self.remoteItem.objectID;
		}];

		__block NSManagedObjectID *otherRemoteItemID = nil;
		[otherRemoteItem.managedObjectContext performBlockAndWait:^{
			otherRemoteItemID = otherRemoteItem.objectID;
		}];

		return remoteItemID == otherRemoteItemID;
	}
}


- (void)setProgress:(float)progress {
	_progress = progress;

	if ( self.container ) {
		[self.container updateProgress];
	}

	id<ILobbyDownloadStatusDelegate> delegate = self.delegate;
	if ( delegate ) {
		[delegate downloadStatusChanged:self];
	}
}

@end



@implementation ILobbyDownloadContainerStatus

- (instancetype)initWithItem:(ILobbyStoreRemoteItem *)remoteItem container:(ILobbyDownloadContainerStatus *)container {
	self = [super initWithItem:remoteItem container:container];
	if ( self ) {
		self.childStatusItems = [ILobbyConcurrentDictionary new];
	}

	return self;
}


- (void)setChildrenDelegate:(id<ILobbyDownloadStatusDelegate>)childrenDelegate {
	[self.childStatusItems.dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		ILobbyDownloadStatus *statusItem = (ILobbyDownloadStatus *)object;
		statusItem.delegate = childrenDelegate;
	}];
}


- (void)addChildStatus:(ILobbyDownloadStatus *)childStatus {
	__block NSManagedObjectID *childID = nil;
	ILobbyStoreRemoteItem *childItem = childStatus.remoteItem;
	[childItem.managedObjectContext performBlockAndWait:^{
		childID = childItem.objectID;
	}];
	if ( childID != nil ) {
		self.childStatusItems[childID] = childStatus;
		[self updateProgress];
	}
}


- (ILobbyDownloadStatus *)childStatusForRemoteItemID:(NSManagedObjectID *)remoteID {
	return remoteID != nil ? self.childStatusItems[remoteID] : nil;
}


- (ILobbyDownloadStatus *)childStatusForRemoteItem:(ILobbyStoreRemoteItem *)remoteItem {
	__block NSManagedObjectID *childID = nil;
	[remoteItem.managedObjectContext performBlockAndWait:^{
		childID = remoteItem.objectID;
	}];

	return [self childStatusForRemoteItemID:childID];
}


// update the progress as the average of the current progress of each child status
- (void)updateProgress {
	NSInteger count = self.childStatusItems.count;
	__block float progressSum = 0.0;

	if ( count > 0 ) {
		[self.childStatusItems.dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
			ILobbyDownloadStatus *statusItem = (ILobbyDownloadStatus *)object;
			progressSum += statusItem.progress;
		}];

		self.progress = progressSum / count;
	}
	else {
		self.progress = 1.0;
	}

//	NSLog( @"Container progress: %f", self.progress );
}

@end



@implementation ILobbyDownloadFileStatus

- (void)setProgress:(float)progress {
	super.progress = progress;
}

@end
