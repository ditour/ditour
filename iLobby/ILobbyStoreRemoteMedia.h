//
//  ILobbyStoreRemoteMedia.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ILobbyStoreRemoteFile.h"
#import "ILobbyRemoteFile.h"


@class ILobbyStoreSlide, ILobbyStoreTrack;


@interface ILobbyStoreRemoteMedia : ILobbyStoreRemoteFile

@property (nonatomic, retain) ILobbyStoreTrack *track;
@end



// custom additions
@interface ILobbyStoreRemoteMedia ()

+ (instancetype)newRemoteMediaInTrack:(ILobbyStoreTrack *)track at:(ILobbyRemoteFile *)remoteFile;

@end