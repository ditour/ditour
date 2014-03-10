//
//  ILobbyStoreRemoteItem.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface ILobbyStoreRemoteItem : NSManagedObject

@property (nonatomic, retain) NSString * remoteInfo;
@property (nonatomic, retain) NSString * remoteLocation;
@property (nonatomic, retain) NSString * path;

@property (nonatomic, readonly) NSURL *remoteURL;

@end
