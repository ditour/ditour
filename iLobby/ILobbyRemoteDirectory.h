//
//  ILobbyRemoteDirectoryInfo.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/31/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILobbyRemoteDirectory : NSObject
@property(readonly, copy) NSURL *location;			// URL location for this directory
@property(readonly, copy) NSArray *files;				// array of ILobbyRemoteFile instances for each file linked in this remote directory
@property(readonly, copy) NSArray *subdirectories;	// array of ILobbyRemoteDirectory instances for each subdirectory linked in this remote directory

+ (ILobbyRemoteDirectory *)parseDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)errorPtr;

@end
