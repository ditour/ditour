//
//  ILobbyStoreRemoteContainer.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/27/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteContainer.h"

@implementation ILobbyStoreRemoteContainer

@dynamic configuration;


- (void)processRemoteFile:(ILobbyRemoteFile *)remoteFile {
	NSURL *location = remoteFile.location;
	if ( [ILobbyStoreConfiguration matches:location] ) {
		[ILobbyStoreConfiguration newConfigurationInContainer:self at:remoteFile];
	}
//	else {
//		NSLog( @"****************************************************************" );
//		NSLog( @"NO Match for remote file: %@", location.lastPathComponent );
//		NSLog( @"****************************************************************" );
//	}
}


- (NSDictionary *)effectiveConfiguration {
	if ( _effectiveConfiguration == nil ) {
		_effectiveConfiguration = [self parseConfiguration];
	}

	return [_effectiveConfiguration copy];
}


- (NSDictionary *)parseConfiguration {
//	NSLog( @"Parsing configuration with path: %@", self.configuration.absolutePath );
	if ( self.configuration != nil && self.configuration.absolutePath != nil ) {
		NSData *jsonData = [NSData dataWithContentsOfFile:self.configuration.absolutePath];
		if ( jsonData == nil )  return nil;
		NSError *error = nil;
		NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
		if ( error ) {
			NSLog( @"Error parsing json: %@", error );
		}
//		else {
//			NSLog( @"Parsed config: %@", json );
//		}
		return [json copy];
	}
	else {
		return @{};
	}
}

@end
