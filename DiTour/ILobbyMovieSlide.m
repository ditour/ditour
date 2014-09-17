//
//  ILobbyMovieSlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 5/5/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyMovieSlide.h"
#import "ILobbySlideFamily.h"


@import AVFoundation;


static NSSet *MOVIE_EXTENSIONS;


@interface ILobbyMovieSlide ()

@property (nonatomic, strong) ILobbySlideCompletionHandler completionHandler;

@end



@implementation ILobbyMovieSlide

+ (void)load {
	if ( self == [ILobbyMovieSlide class] ) {
		MOVIE_EXTENSIONS = [NSSet setWithArray:@[ @"m4v", @"mp4", @"mov" ]];
		[self registerSlideClass:self];
	}
}


+ (NSSet *)supportedExtensions {
	return MOVIE_EXTENSIONS;
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	self.completionHandler = handler;

	NSURL *mediaURL = [NSURL fileURLWithPath:self.mediaFile];
    AVAsset *asset = [AVURLAsset URLAssetWithURL:mediaURL options:nil];
    AVPlayerItem *videoItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:videoItem];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayerCompletion:) name:AVPlayerItemDidPlayToEndTimeNotification object:videoItem];

	UIView *videoView = [[UIView alloc] initWithFrame:presenter.externalBounds];
	CALayer *videoLayer = [AVPlayerLayer playerLayerWithPlayer:player];
	videoLayer.contentsGravity = kCAGravityResizeAspect;
	videoLayer.frame = videoView.frame;
	videoLayer.backgroundColor = [[UIColor blackColor] CGColor];
	[videoView.layer addSublayer:videoLayer];

	[presenter displayMediaView:videoView];

	[player play];
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