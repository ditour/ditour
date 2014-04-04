//
//  ILobbyDownloadSession.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/3/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILobbyStorePresentationGroup.h"


@interface ILobbyDownloadSession : NSObject

@property (readonly, nonatomic, copy) NSString *backgroundIdentifier;

- (void)downloadGroup:(ILobbyStorePresentationGroup *)group;
- (void)cancel;


/*!
 @abstract Handle events for the background session with the specified identifier
 @param identifier the background session identifier
 @param completionHandler block to call when this session is finished processing events for the background session
 @return YES if the identifier matches and events will be handled and NO if not
 */
- (BOOL)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;

@end
