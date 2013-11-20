//
//  ILobbyStoreLocalMedia.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ILobbyStoreRemoteMedia, ILobbyStoreSlide;

@interface ILobbyStoreLocalMedia : NSManagedObject

@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) ILobbyStoreRemoteMedia *remoteMedia;
@property (nonatomic, retain) ILobbyStoreSlide *slide;

@end
