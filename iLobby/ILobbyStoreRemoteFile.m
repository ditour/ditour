//
//  ILobbyStoreRemoteFile.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/27/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteFile.h"

@implementation ILobbyStoreRemoteFile

// indicates whether the candidate URL matches a type supported by the class
+ (BOOL)matches:(NSURL *)candidateURL {
	return YES;
}

@end
