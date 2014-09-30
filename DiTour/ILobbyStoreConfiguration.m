//
//  ILobbyStoreConfiguration.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/19/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreConfiguration.h"
#import "ILobbyStoreRemoteContainer.h"


@implementation ILobbyStoreConfiguration
@dynamic container;


+ (instancetype)newConfigurationInContainer:(ILobbyStoreRemoteContainer	*)container at:(ILobbyRemoteFile *)remoteFile {
	ILobbyStoreConfiguration *configuration = [NSEntityDescription insertNewObjectForEntityForName:@"Configuration" inManagedObjectContext:container.managedObjectContext];

	configuration.container = container;
	configuration.status = @( REMOTE_ITEM_STATUS_PENDING );
	configuration.remoteLocation = remoteFile.location.absoluteString;
	configuration.remoteInfo = remoteFile.info;
	configuration.path = [container.path stringByAppendingPathComponent:remoteFile.location.lastPathComponent];
	
//	NSLog( @"Fetching Configuration: %@", configuration.remoteURL.lastPathComponent );
//	NSLog( @"Config File: %@", configuration.absolutePath );

	return configuration;
}


// indicates whether the candidate URL matches a type supported by the class
+ (BOOL)matches:(NSURL *)candidateURL {
	return [[candidateURL.lastPathComponent lowercaseString] isEqualToString:@"config.json"];
}

@end