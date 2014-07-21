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


@interface ILobbyWebSlide () <UIWebViewDelegate>
@property (assign) BOOL canceled;
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
	self.canceled = NO;

	NSString *slideWebSpec = [[NSString stringWithContentsOfFile:self.mediaFile encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSURL *slideURL = [NSURL URLWithString:slideWebSpec];

	CGRect viewSize = presenter.externalBounds;

	if ( WEB_VIEW == nil ) {
		WEB_WINDOW = [[UIWindow alloc] initWithFrame:viewSize];
		WEB_VIEW = [[UIWebView alloc] initWithFrame:viewSize];
		WEB_VIEW.delegate = self;
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
		// since the web slides share a common web view we should not perform and cleanup upon cancelation as this may interrupt another web slide
		if ( !self.canceled ) {
			[self cleanup];
			handler( self );
		}
	});
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	// scale the web view's scroll zoom to match the content view so we can see the whole image

	CGSize contentSize = webView.scrollView.contentSize;

	if ( contentSize.width > 0 ) {
		CGSize viewSize = webView.bounds.size;
		double zoomScale = viewSize.width / contentSize.width;
		webView.scrollView.minimumZoomScale = zoomScale;
		webView.scrollView.maximumZoomScale = zoomScale;
		webView.scrollView.zoomScale = zoomScale;
	}
}


- (void)cleanup {
	WEB_VIEW.scrollView.minimumZoomScale = 1.0;
	WEB_VIEW.scrollView.maximumZoomScale = 1.0;
	WEB_VIEW.scrollView.zoomScale = 1.0;

	// clear the web slide to stop loading content and prevent artifacts during the track loop
	[WEB_VIEW loadHTMLString:@"<html><body></body></html>" baseURL:[NSURL URLWithString:@"http://localhost"]];
}


- (void)cancelPresentation {
	self.canceled = YES;
	[self cleanup];
}


- (BOOL)isSingleFrame {
	return YES;
}

@end
