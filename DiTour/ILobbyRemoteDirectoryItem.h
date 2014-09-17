//
//  ILobbyRemoteDirectoryItem.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ILobbyRemoteDirectoryItem <NSObject>
@property(readonly, copy) NSURL *location;			// URL location for this item
@property(readonly) BOOL isDirectory;				// indicates whether this item is a directory rather than just a simple file

@end
