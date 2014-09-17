//
//  ILobbyRemoteDirectoryInfo.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/31/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILobbyRemoteDirectoryItem.h"


@interface ILobbyRemoteDirectory : NSObject <ILobbyRemoteDirectoryItem>
@property(readonly, copy) NSArray *items;		// array of ILobbyRemoteDirectoryItem (files and subdirectories)
@property(readonly, copy) NSArray *files;				// array of those items that are simple files
@property(readonly, copy) NSArray *subdirectories;	// array of those items that are subdirectories

+ (ILobbyRemoteDirectory *)parseDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)errorPtr;

@end
