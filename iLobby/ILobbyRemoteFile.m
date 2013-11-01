//
//  ILobbyRemoteFileInfo.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/31/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyRemoteFile.h"

@interface ILobbyRemoteFile ()
@property(readwrite) NSURL *location;
@property(readwrite) NSString *info;
@end


@implementation ILobbyRemoteFile

- (instancetype)initWithLocation:(NSURL *)location info:(NSString *)info {
    self = [super init];
    if (self) {
		self.location = location;
		self.info = info;
    }
    return self;
}


- (NSString *)description {
	return [NSString stringWithFormat:@"{ location: %@, info: %@ }", self.location.absoluteString, self.info ];
}

@end
