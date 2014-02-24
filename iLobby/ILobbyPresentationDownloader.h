//
//  ILobbyPresentationDownloader.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/22/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

@import Foundation;
#import "ILobbyProgress.h"
#import "ILobbyStorePresentation.h"

@class ILobbyPresentationDownloader;
typedef void (^ILobbyPresentationDownloadHandler)(ILobbyPresentationDownloader *);


@interface ILobbyPresentationDownloader : NSObject

@property (assign, readonly) BOOL complete;
@property (strong, readonly) ILobbyProgress *progress;
@property (assign, readonly) BOOL canceled;

-(instancetype)initWithPresentation:(ILobbyStorePresentation *)presentation completionHandler:(ILobbyPresentationDownloadHandler)handler;

+ (NSString *)presentationPath;

- (void)cancel;

@end

