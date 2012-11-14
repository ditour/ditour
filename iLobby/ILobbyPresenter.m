//
//  ILobbyPresenter.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/19/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresenter.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>


@interface ILobbyPresenter ()
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) CALayer *mediaLayer;
@property (strong, nonatomic) CALayer *imageLayer;
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


- (void)beginTransition:(CATransition *)transition {
	if ( transition != nil && self.externalWindow != nil ) {
		[self.contentView.layer addAnimation:transition forKey:nil];
	}
}


- (void)displayImage:(UIImage *)image {
	if ( self.externalWindow ) {		
		self.imageLayer.contents = (__bridge id)([image CGImage]);

		if ( self.mediaLayer != self.imageLayer ) {
			[self.contentView.layer replaceSublayer:self.mediaLayer with:self.imageLayer];
			self.mediaLayer = self.imageLayer;
		}
	}
}


- (void)displayVideo:(AVPlayer *)player {
	CALayer *videoLayer = [AVPlayerLayer playerLayerWithPlayer:player];
	videoLayer.contentsGravity = kCAGravityResizeAspect;
	videoLayer.frame = self.contentView.frame;
	videoLayer.backgroundColor = [[UIColor blackColor] CGColor];

	[self.contentView.layer replaceSublayer:self.mediaLayer with:videoLayer];
	self.mediaLayer = videoLayer;

	[player play];
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
		UIScreen *externalScreen = [screens objectAtIndex:1];
		externalScreen.currentMode = externalScreen.preferredMode;

		self.externalWindow = [[UIWindow alloc] initWithFrame:externalScreen.bounds];
		self.externalWindow.screen = externalScreen;
		self.externalWindow.backgroundColor = [UIColor blackColor];

		UIView *contentView = [[UIView alloc] initWithFrame:[externalScreen bounds]];
		contentView.layer.borderWidth = 0;
		self.contentView = contentView;

		self.imageLayer = [CALayer new];
		self.imageLayer.contentsGravity = kCAGravityResizeAspect;
		self.imageLayer.frame = contentView.frame;
		self.imageLayer.backgroundColor = [[UIColor blackColor] CGColor];

		self.mediaLayer = self.imageLayer;
		[self.contentView.layer addSublayer:self.mediaLayer];

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
