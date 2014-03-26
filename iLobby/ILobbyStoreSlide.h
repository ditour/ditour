//
//  ILobbyStoreSlide.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class ILobbyStoreTrack, ILobbyStoreRemoteMedia;


@interface ILobbyStoreSlide : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) ILobbyStoreRemoteMedia *remoteMedia;

@end



@interface ILobbyStoreSlide ()

//+ (instancetype)newSlideInTrack:(ILobbyStoreTrack *)track location:(NSURL *)remoteURL;

@end