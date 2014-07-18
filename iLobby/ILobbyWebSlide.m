//
//  ILobbyWebSlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 7/16/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyWebSlide.h"
#import "ILobbySlideFamily.h"


static NSSet *WEB_EXTENSIONS;

static UIWebView *WEB_VIEW = nil;
static UIWindow *WEB_WINDOW = nil;
static CALayer *WEB_LAYER = nil;


@implementation ILobbyWebSlide

+ (void)load {
	if ( self == [ILobbyWebSlide class] ) {
		WEB_EXTENSIONS = [NSSet setWithArray:@[ @"urlspec" ]];
		[self registerSlideClass:self];
	}
}


+ (NSSet *)supportedExtensions {
	return WEB_EXTENSIONS;
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	NSString *slideWebSpec = [NSString stringWithContentsOfFile:self.mediaFile encoding:NSUTF8StringEncoding error:nil];
	NSURL *slideURL = [NSURL URLWithString:slideWebSpec];

	CGRect viewSize = presenter.externalBounds;

	if ( WEB_VIEW == nil ) {
		WEB_WINDOW = [[UIWindow alloc] initWithFrame:viewSize];
		WEB_VIEW = [[UIWebView alloc] initWithFrame:viewSize];
		[WEB_WINDOW addSubview:WEB_VIEW];
		WEB_VIEW.scalesPageToFit = YES;
		WEB_LAYER = WEB_VIEW.layer;
	}
	else {
		WEB_WINDOW.frame = viewSize;
		WEB_VIEW.frame = viewSize;
	}

	//NSLog( @"Loading slide for URL: %@", slideURL );
	[WEB_VIEW loadRequest:[NSURLRequest requestWithURL:slideURL]];

	[presenter displayMediaLayer:WEB_LAYER];

	int64_t delayInSeconds = self.duration;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after( popTime, dispatch_get_main_queue(), ^(void){
		handler( self );
		[self cleanup];
	});
}


- (void)cleanup {
	//[WEB_VIEW stopLoading];
}


- (void)cancelPresentation {
	[self cleanup];
}


- (BOOL)isSingleFrame {
	return YES;
}

@end
