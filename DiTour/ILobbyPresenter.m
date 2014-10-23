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



@interface ExternalViewController : UIViewController
@end


@interface ILobbyPresenter ()

@property (strong, nonatomic) UIView *contentView;

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


- (void)displayMediaView:(UIView *)mediaView {
	// remove all subviews from the content view (should just be the last media view but just in case remove all subviews)
	for ( UIView *subview in self.contentView.subviews ) {
		[subview removeFromSuperview];
	}

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

		UIViewController *contentViewController = [[ExternalViewController alloc] initWithNibName:nil bundle:nil];
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



@implementation ExternalViewController

- (NSUInteger)supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}


- (BOOL)shouldAutorotate {
	return NO;
}

@end
