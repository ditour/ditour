//
//  ILobbyPresentationDownloader.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/22/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILobbyProgress.h"

@class ILobbyPresentationDownloader;
typedef void (^ILobbyPresentationDownloadHandler)(ILobbyPresentationDownloader *);


@interface ILobbyPresentationDownloader : NSObject

@property (assign, readonly) BOOL complete;
@property (strong, readonly) ILobbyProgress *progress;

-(id)initWithIndexURL:(NSURL *)indexAbsoluteURL archivePath:(NSString *)archivePath completionHandler:(ILobbyPresentationDownloadHandler)handler;

+ (NSString *)presentationPath;

@end

