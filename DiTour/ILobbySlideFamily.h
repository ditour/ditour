//
//  ILobbySlideFamily.h
//  iLobby
//
//  Created by Pelaia II, Tom on 5/5/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//


#import "ILobbySlide.h"


// ILobbySlide extension for internal use by the family of slides
@interface ILobbySlide ()

+ (NSSet *)supportedExtensions;
+ (void)registerSlideClass:(Class)slideClass;

@property (nonatomic, readwrite) float duration;
@property (nonatomic, readwrite, copy) NSString *mediaFile;

- (void)displayTo:(id<PresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler;
- (void)performTransition:(id<PresentationDelegate>)presenter;

@end
