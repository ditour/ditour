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


@interface ILobbyWebSlide ()

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIWindow *webWindow;

@end


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
	self.webWindow = [[UIWindow alloc] initWithFrame:viewSize];
	self.webView = [[UIWebView alloc] initWithFrame:viewSize];
	[self.webWindow addSubview:self.webView];
	self.webView.scalesPageToFit = YES;

	//NSLog( @"Loading slide for URL: %@", slideURL );
	[self.webView loadRequest:[NSURLRequest requestWithURL:slideURL]];

	[presenter displayMediaLayer:self.webView.layer];

	int64_t delayInSeconds = self.duration;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after( popTime, dispatch_get_main_queue(), ^(void){
		handler( self );
		[self cleanup];
	});
}


- (void)cleanup {
	self.webWindow = nil;
	self.webView = nil;
}


- (void)cancelPresentation {
	[self cleanup];
}


- (BOOL)isSingleFrame {
	return YES;
}

@end
