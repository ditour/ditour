//
//  ILobbyPresenter.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/19/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresenter.h"
@import QuartzCore;
@import UIKit;


@interface ILobbyPresenter ()
@property (strong, nonatomic) UIView *contentView;
@property (weak, nonatomic) CALayer *mediaLayer;
@property (weak, nonatomic) UIView *mediaView;

@end


@implementation ILobbyPresenter

@synthesize currentRunID;


// initializer
- (id)init {
    self = [super init];
    if (self) {
		// Override point for customization after application launch.
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreensChange:) name:UIScreenDidConnectNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreensChange:) name:UIScreenDidDisconnectNotification object:nil];
    }
    return self;
}


- (CGRect)externalBounds {
	return self.externalWindow.bounds;
}


- (void)beginTransition:(CATransition *)transition {
	if ( transition != nil && self.externalWindow != nil ) {
		[self.contentView.layer addAnimation:transition forKey:nil];
	}
}


- (void)displayVideo:(AVPlayer *)player {
	if ( self.externalWindow ) {
		if ( self.mediaView ) {
			[self.mediaView removeFromSuperview];
			self.mediaView = nil;
		}

		CALayer *videoLayer = [AVPlayerLayer playerLayerWithPlayer:player];
		videoLayer.contentsGravity = kCAGravityResizeAspect;
		videoLayer.frame = self.contentView.frame;
		videoLayer.backgroundColor = [[UIColor blackColor] CGColor];

		if ( self.mediaLayer )  [self.mediaLayer removeFromSuperlayer];
		[self.contentView.layer addSublayer:videoLayer];
		self.mediaLayer = videoLayer;

		[player play];
	}
}


- (void)displayMediaView:(UIView *)mediaView {
	if ( self.mediaView ) {
		[self.mediaView removeFromSuperview];
	}

	self.mediaView = mediaView;
	[self.contentView addSubview:mediaView];
}


// update the configuration
- (void)updateConfiguration {
	[self configureExternalDisplay];
}


// configure the external display if any
- (void)configureExternalDisplay {
	NSArray *screens = [UIScreen screens];
	NSUInteger screenCount = [screens count];

	if ( screenCount > 1 ) {
		UIScreen *externalScreen = screens[1];
		externalScreen.currentMode = externalScreen.preferredMode;

		self.externalWindow = [[UIWindow alloc] initWithFrame:externalScreen.bounds];
		self.externalWindow.screen = externalScreen;
		self.externalWindow.backgroundColor = [UIColor blackColor];

		UIView *contentView = [[UIView alloc] initWithFrame:[externalScreen bounds]];
		contentView.layer.borderWidth = 0;
		self.contentView = contentView;

		UIViewController *contentViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
		contentViewController.view = contentView;
		self.externalWindow.rootViewController = contentViewController;

		self.externalWindow.hidden = NO;
	}
	else {
		NSLog( @"no external screen..." );
		self.externalWindow = nil;
	}
}


// handle the change in screens
- (void)handleScreensChange:(NSNotification *)notification {
	[self updateConfiguration];
}

@end
