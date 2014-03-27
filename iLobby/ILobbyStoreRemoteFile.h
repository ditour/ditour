//
//  ILobbyStoreRemoteFile.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/27/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteItem.h"

@interface ILobbyStoreRemoteFile : ILobbyStoreRemoteItem

@end



// Custom additions
@interface ILobbyStoreRemoteFile ()

// indicates whether the candidate URL matches a type supported by the class
+ (BOOL)matches:(NSURL *)candidateURL;

@end