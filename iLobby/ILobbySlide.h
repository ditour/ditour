//
//  ILobbySlide.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/24/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILobbyModel.h"

@class ILobbySlide;
typedef void (^ILobbySlideCompletionHandler)(ILobbySlide *);


@interface ILobbySlide : NSObject

@property (nonatomic, readonly) float duration;
@property (nonatomic, readonly, copy) NSString *mediaFile;

- (id)initWithFile:(NSString *)file duration:(float)duration;
+ (id)slideWithFile:(NSString *)file duration:(float)duration;

+ (NSArray *)filesFromConfig:(id)config;

- (void)presentTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler;
- (void)cancelPresentation;

@end
