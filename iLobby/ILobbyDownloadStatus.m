//
//  ILobbyDownloadItemStatus.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/3/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyDownloadStatus.h"



@interface ILobbyDownloadStatus ()

@property (weak, readwrite) ILobbyDownloadContainerStatus *container;
@property (nonatomic, strong, readwrite) ILobbyStoreRemoteItem *remoteItem;
@property (readwrite) float progress;

@end



@interface ILobbyDownloadContainerStatus ()

@property (strong) NSMutableSet *childStatusItems;
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


- (void)setProgress:(float)progress {
	_progress = progress;

	if ( self.container ) {
		[self.container updateProgress];
	}

	id<ILobbyDownloadStatusDelegate> delegate = self.delegate;
	if ( delegate ) {
		[delegate statusChanged:self];
	}
}

@end



@implementation ILobbyDownloadContainerStatus

- (instancetype)initWithItem:(ILobbyStoreRemoteItem *)remoteItem container:(ILobbyDownloadContainerStatus *)container {
	self = [super initWithItem:remoteItem container:container];
	if ( self ) {
		self.childStatusItems = [NSMutableSet new];
	}

	return self;
}


- (void)addChildStatus:(ILobbyDownloadStatus *)childStatus {
	[self.childStatusItems addObject:childStatus];
}


// update the progress as the average of the current progress of each child status
- (void)updateProgress {
	NSInteger count = self.childStatusItems.count;
	float progressSum = 0.0;

	if ( count > 0 ) {
		for ( ILobbyDownloadStatus *statusItem in self.childStatusItems ) {
			progressSum += statusItem.progress;
		}
		self.progress = progressSum / count;
	}
	else {
		self.progress = 1.0;
	}
}

@end



@implementation ILobbyDownloadFileStatus

- (void)setProgress:(float)progress {
	super.progress = progress;
}

@end
