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


@interface ILobbyWebSlide () <UIWebViewDelegate>
@property (assign) BOOL canceled;
@property (strong) UIWebView *webView;
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


- (void)dealloc {
	[self cleanup];
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	self.canceled = NO;

	// store a local copy to compare during post processing
	id currentRunID = presenter.currentRunID;

	NSString *slideWebSpec = [[NSString stringWithContentsOfFile:self.mediaFile encoding:NSUTF8StringEncoding error:nil] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSURL *slideURL = [NSURL URLWithString:slideWebSpec];

	CGRect viewSize = presenter.externalBounds;

	self.webView = [[UIWebView alloc] initWithFrame:viewSize];
	self.webView.scalesPageToFit = YES;
	self.webView.delegate = self;

	//NSLog( @"Loading slide for URL: %@", slideURL );

	[presenter displayMediaView:self.webView];
	[self.webView loadRequest:[NSURLRequest requestWithURL:slideURL]];

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
	if ( !self.canceled && self.webView == webView ) {
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
	if ( self.webView ) {
		self.webView.delegate = nil;
		[self.webView stopLoading];
		self.webView = nil;
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
