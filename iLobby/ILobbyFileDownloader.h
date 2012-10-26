//
//  ILobbyFileDownloader.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/22/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ILobbyFileDownloader;
typedef void (^ILobbyFileDownloadHandler)(ILobbyFileDownloader *, NSError *);


@interface ILobbyFileDownloader : NSObject

@property (readonly, strong, nonatomic) NSURL *sourceURL;
@property (readonly, strong, nonatomic) NSString *outputFilePath;
@property (readonly) float progress;
@property (readonly) BOOL complete;

+ (NSString *)downloadsPath;

- (id)initWithSourceURL:(NSURL *)sourceURL subdirectory:(NSString *)subdirectory progressHandler:(ILobbyFileDownloadHandler)handler;
- (void)cancel;

@end
