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

	// store a local copy to compare during post processing
	id currentRunID = presenter.currentRunID;

	NSString *slideWebSpec = [[NSString stringWithContentsOfFile:self.mediaFile encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSURL *slideURL = [NSURL URLWithString:slideWebSpec];

	CGRect viewSize = presenter.externalBounds;

	if ( WEB_VIEW == nil ) {
		WEB_VIEW = [[UIWebView alloc] initWithFrame:viewSize];
		WEB_VIEW.scalesPageToFit = YES;
	}

	WEB_VIEW.delegate = self;

	//NSLog( @"Loading slide for URL: %@", slideURL );

	[presenter displayMediaView:WEB_VIEW];
	[WEB_VIEW loadRequest:[NSURLRequest requestWithURL:slideURL]];

	int64_t delayInSeconds = self.duration;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after( popTime, dispatch_get_main_queue(), ^(void){
		// since the web slides share a common web view we should not perform and cleanup upon cancelation as this may interrupt another web slide
		if ( !self.canceled && currentRunID == presenter.currentRunID ) {
			[self cleanup];
			handler( self );
		}
	});
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	// scale the web view's scroll zoom to match the content width so we can see the whole width
	if ( !self.canceled && WEB_VIEW == webView ) {
		CGSize contentSize = webView.scrollView.contentSize;

		if ( contentSize.width > 0 ) {
			CGSize viewSize = webView.bounds.size;
			double zoomScale = viewSize.width / contentSize.width;
			webView.scrollView.minimumZoomScale = zoomScale;
			webView.scrollView.maximumZoomScale = zoomScale;
			webView.scrollView.zoomScale = zoomScale;
		}
	}
}


- (void)cleanup {
	if ( WEB_VIEW ) {
		// reset the zoom
		WEB_VIEW.scrollView.minimumZoomScale = 1.0;
		WEB_VIEW.scrollView.maximumZoomScale = 1.0;
		WEB_VIEW.scrollView.zoomScale = 1.0;

		[WEB_VIEW loadHTMLString:@"" baseURL:nil];	// stop loading new content
		WEB_VIEW.delegate = nil;
	}
}


- (void)cancelPresentation {
	if ( !self.canceled ) {		// prevent unnecessary cleanup
		self.canceled = YES;
		[self cleanup];
	}
}


- (BOOL)isSingleFrame {
	return YES;
}

@end
