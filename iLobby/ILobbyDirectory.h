//
//  ILobbyRemoteDirectory.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/26/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ILobbyDirectory : NSObject {
@protected
	NSArray *_files;	// make this ivar protected since properties implement private ivars by default
}

@property (strong, nonatomic, readonly) NSArray *files;

+ (ILobbyDirectory *)remoteDirectoryWithURL:(NSURL *)location;
+ (ILobbyDirectory *)localDirectoryWithPath:(NSString *)path;

@end
