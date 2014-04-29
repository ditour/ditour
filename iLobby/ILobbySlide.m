//
//  ILobbySlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/24/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbySlide.h"
@import AVFoundation;
@import QuartzCore;



@interface ILobbySlide ()

+ (NSSet *)supportedExtensions;

@property (nonatomic, readwrite) float duration;
@property (nonatomic, readwrite, copy) NSString *mediaFile;

- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler;

@end



@interface ILobbyImageSlide : ILobbySlide
@end



@interface ILobbyVideoSlide : ILobbySlide
@property (nonatomic, readwrite, strong) ILobbySlideCompletionHandler completionHandler;
@end


static NSSet *ALL_SUPPORTED_EXTENSIONS = nil;


@implementation ILobbySlide

- (id)initWithFile:(NSString *)file duration:(float)duration {
    self = [super init];
    if (self) {
		self.duration = duration;
		self.mediaFile = file;
    }
    return self;
}


+ (id)slideWithFile:(NSString *)file duration:(float)duration {
	NSString *extension = [file pathExtension];

	if ( [ILobbyImageSlide matchesExtension:extension] ) {
		return [[ILobbyImageSlide alloc] initWithFile:file duration:duration];
	}
	else if ( [ILobbyVideoSlide matchesExtension:extension] ) {
		return [[ILobbyVideoSlide alloc] initWithFile:file duration:duration];
	}
	else {
		return nil;
	}
}


+ (NSSet *)supportedExtensions {
	return nil;
}


+ (NSSet *)allSupportedExtensions {
	return [ALL_SUPPORTED_EXTENSIONS copy];
}


// called by subclasses to register their supported extensions by appending them to ALL_SUPPORTED_EXTENSIONS
+ (void)registerSupportedExtensions {
	NSSet *extensions = [self supportedExtensions];

	if ( extensions != nil ) {
		if ( ALL_SUPPORTED_EXTENSIONS != nil ) {
			NSMutableSet *allExtensions = [ALL_SUPPORTED_EXTENSIONS mutableCopy];
			[allExtensions unionSet:extensions];
			ALL_SUPPORTED_EXTENSIONS = [allExtensions copy];
		}
		else {
			ALL_SUPPORTED_EXTENSIONS = [extensions copy];
		}
	}
}


- (UIImage *)icon {
	return nil;
}


- (BOOL)isImageSlide {
	return NO;
}


+ (BOOL)matchesExtension:(NSString *)extension {
	return NO;
}


- (void)presentTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	ILobbyTransitionSource *transitionSource = self.transitionSource;
	if ( transitionSource ) {
		CATransition *transition = [transitionSource generate];
		if ( transition ) {
			[presenter beginTransition:transition];
		}
	}

	[self displayTo:presenter completionHandler:handler];
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {}

- (void)cancelPresentation {}

@end



static NSSet *IMAGE_EXTENSIONS;

@implementation ILobbyImageSlide

+ (void)load {
	if ( self == [ILobbyImageSlide class] ) {
		IMAGE_EXTENSIONS = [NSSet setWithArray:@[ @"png", @"jpg", @"jpeg", @"gif" ]];
		[self registerSupportedExtensions];
	}
}


+ (NSSet *)supportedExtensions {
	return IMAGE_EXTENSIONS;
}


+ (BOOL)matchesExtension:(NSString *)extension {
	return [IMAGE_EXTENSIONS containsObject:extension];
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	[presenter displayImage:[UIImage imageWithContentsOfFile:self.mediaFile]];
	
	int64_t delayInSeconds = self.duration;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after( popTime, dispatch_get_main_queue(), ^(void){
		handler( self );
	});
}


- (UIImage *)icon {
	return [UIImage imageWithContentsOfFile:self.mediaFile];
}


- (BOOL)isImageSlide {
	return YES;
}

@end



static NSSet *VIDEO_EXTENSIONS;

@implementation ILobbyVideoSlide

+ (void)load {
	if ( self == [ILobbyVideoSlide class] ) {
		VIDEO_EXTENSIONS = [NSSet setWithArray:@[ @"m4v", @"mp4", @"mov" ]];
		[self registerSupportedExtensions];
	}
}


+ (NSSet *)supportedExtensions {
	return VIDEO_EXTENSIONS;
}


+ (BOOL)matchesExtension:(NSString *)extension {
	return [VIDEO_EXTENSIONS containsObject:extension];
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	self.completionHandler = handler;
	
	NSURL *mediaURL = [NSURL fileURLWithPath:self.mediaFile];
    AVAsset *asset = [AVURLAsset URLAssetWithURL:mediaURL options:nil];
    AVPlayerItem *videoItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:videoItem];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayerCompletion:) name:AVPlayerItemDidPlayToEndTimeNotification object:videoItem];
	[presenter displayVideo:player];
}


- (void)clearNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)cancelPresentation {
	[self clearNotifications];
}


- (void)handlePlayerCompletion:(NSNotification *)notification {
	[self clearNotifications];
	
	ILobbySlideCompletionHandler handler = self.completionHandler;
	if ( handler ) {
		handler( self );
	}
}

@end