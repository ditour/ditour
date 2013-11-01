//
//  ILobbyRemoteFileInfo.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/31/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILobbyRemoteFile : NSObject

@property(readonly, copy) NSURL *location;
@property(readonly, copy) NSString *info;

- (instancetype)initWithLocation:(NSURL *)location info:(NSString *)info;

@end
