//
//  ILobbySlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/24/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbySlide.h"
#import <AVFoundation/AVFoundation.h>

@interface ILobbySlide ()
@property (nonatomic, readwrite) float duration;
@property (nonatomic, readwrite, copy) NSString *mediaFile;
@end


@interface ILobbyImageSlide : ILobbySlide
@end



@interface ILobbyVideoSlide : ILobbySlide
@property (nonatomic, readwrite, strong) ILobbySlideCompletionHandler completionHandler;
@end



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


+ (NSArray *)filesFromConfig:(id)config {
	if ( [config isKindOfClass:[NSString class]] )  return [NSArray arrayWithObject:config];
	
	NSNumber *startNumber = config[@"start"];
	NSNumber *endNumber = config[@"end"];
	NSNumber *incrementNumber = config[@"increment"];
	NSString *pattern = config[@"pattern"];
	NSNumber *zeroPaddingNumber = config[@"zeropadding"];

	NSUInteger start = startNumber != nil ? [startNumber unsignedIntegerValue] : 1;
	NSUInteger end = endNumber != nil ? [endNumber unsignedIntegerValue] : start;
	NSUInteger increment = incrementNumber != nil ? [incrementNumber unsignedIntegerValue] : 1;
	NSUInteger zeroPadding = zeroPaddingNumber != nil ? [zeroPaddingNumber unsignedIntegerValue] : 0;

	if ( pattern ) {
		NSMutableArray *files = [NSMutableArray new];
		for ( NSUInteger index = start ; index <= end ; index += increment ) {
			NSString *rawIndexString = [[NSNumber numberWithUnsignedInteger:index] description];
			NSInteger zeroPaddingNeeded = zeroPadding - [rawIndexString length];
			NSMutableString *indexString = [NSMutableString new];
			while ( zeroPaddingNeeded > indexString.length ) {
				[indexString appendString:@"0"];
			}
			[indexString appendString:rawIndexString];
			NSString *file = [pattern stringByReplacingOccurrencesOfString:@"${index}" withString:indexString];
			[files addObject:file];
		}
		return [NSArray arrayWithArray:files];
	}
	else {
		return [NSArray array];
	}
}


+ (BOOL)matchesExtension:(NSString *)extension {
	return NO;
}


- (void)presentTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {}

- (void)cancelPresentation {}

@end



static NSArray *IMAGE_EXTENSIONS;

@implementation ILobbyImageSlide

+ (void)initialize {
	if ( self == [ILobbyImageSlide class] ) {
		IMAGE_EXTENSIONS = @[ @"png", @"jpg", @"jpeg", @"gif" ];
	}
}


+ (BOOL)matchesExtension:(NSString *)extension {
	return [IMAGE_EXTENSIONS containsObject:extension];
}


- (void)presentTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
//	NSLog( @"presenting slide with medial file: %@", self.mediaFile );
	[presenter displayImage:[UIImage imageWithContentsOfFile:self.mediaFile]];
	
	int64_t delayInSeconds = self.duration;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after( popTime, dispatch_get_main_queue(), ^(void){
		handler( self );
	});
}

@end



static NSArray *VIDEO_EXTENSIONS;

@implementation ILobbyVideoSlide

+ (void)initialize {
	if ( self == [ILobbyVideoSlide class] ) {
		VIDEO_EXTENSIONS = @[ @"m4v", @"mp4", @"mov" ];
	}
}


+ (BOOL)matchesExtension:(NSString *)extension {
	return [VIDEO_EXTENSIONS containsObject:extension];
}


- (void)presentTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
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