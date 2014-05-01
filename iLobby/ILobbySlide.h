//
//  ILobbySlide.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/24/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

@import Foundation;
#import "ILobbyModel.h"
#import "ILobbyTransitionSource.h"

@class ILobbySlide;
typedef void (^ILobbySlideCompletionHandler)(ILobbySlide *);


@interface ILobbySlide : NSObject

@property (nonatomic, readonly) float duration;
@property (nonatomic, readonly, copy) NSString *mediaFile;
@property (readwrite, strong) ILobbyTransitionSource *transitionSource;

- (id)initWithFile:(NSString *)file duration:(float)duration;
+ (id)slideWithFile:(NSString *)file duration:(float)duration;

- (void)presentTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler;
- (void)cancelPresentation;

// provide an icon representation if possible or nil if not
- (UIImage *)icon;

// indicates that the slide represents just a single frame (e.g. image slide vs. movie)
- (BOOL)isSingleFrame;

// get all extensions which are supported by the family of slide classes
+ (NSSet *)allSupportedExtensions;

@end
