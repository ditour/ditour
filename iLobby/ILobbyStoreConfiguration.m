//
//  ILobbyStoreConfiguration.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/19/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreConfiguration.h"


@implementation ILobbyStoreConfiguration
@dynamic refreshPeriod;
@dynamic slideDuration;
@dynamic trackChangeDelay;
@dynamic slideTransition;


// indicates whether the candidate URL matches a type supported by the class
+ (BOOL)matches:(NSURL *)candidateURL {
	return [[candidateURL.lastPathComponent lowercaseString] isEqualToString:@"config.json"];
}

@end
