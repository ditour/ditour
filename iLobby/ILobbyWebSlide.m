//
//  ILobbyWebSlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 7/16/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

@import JavaScriptCore;

#import "ILobbyWebSlide.h"
#import "ILobbySlideFamily.h"


typedef enum : NSInteger {
	ZOOM_NONE,
	ZOOM_WIDTH,
	ZOOM_HEIGHT,
	ZOOM_BOTH
} ZoomMode;


static NSSet *WEB_EXTENSIONS;


@interface ILobbyWebSlide () <UIWebViewDelegate>
@property (assign) BOOL canceled;
@property (strong) UIWebView *webView;
@property (assign) ZoomMode zoomMode;
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

	NSString *query = slideURL.query;
	NSDictionary *queryDictionary = [ILobbyWebSlide dictionaryForQuery:query];
//	NSLog( @"query dictionary: %@", queryDictionary );
	NSString *zoomModeID = queryDictionary[@"ditour-zoom"];

	if ( zoomModeID != nil ) {
		zoomModeID = zoomModeID.lowercaseString;

		if ( [zoomModeID isEqualToString:@"none"] ) {
			self.zoomMode = ZOOM_NONE;
		}
		else if ( [zoomModeID isEqualToString:@"width"] ) {
			self.zoomMode = ZOOM_WIDTH;
		}
		else if ( [zoomModeID isEqualToString:@"height"] ) {
			self.zoomMode = ZOOM_HEIGHT;
		}
		else if ( [zoomModeID isEqualToString:@"both"] ) {
			self.zoomMode = ZOOM_BOTH;
		}
		else {
			self.zoomMode = ZOOM_NONE;
		}
	}
	else {
		self.zoomMode = ZOOM_BOTH;
	}

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

		if ( contentSize.width > 0 && contentSize.height > 0 ) {
			CGSize viewSize = webView.bounds.size;
			double widthZoom = viewSize.width / contentSize.width;
			double heightZoom = viewSize.height / contentSize.height;
			double zoomScale = 1.0;

			switch ( self.zoomMode ) {
				case ZOOM_WIDTH:
					zoomScale = widthZoom;
					break;

				case ZOOM_HEIGHT:
					zoomScale = heightZoom;
					break;

				case ZOOM_BOTH:
					// use the minimum zoom to fit both the width and height on the page
					zoomScale = widthZoom < heightZoom ? widthZoom : heightZoom;
					break;

				default:
					break;
			}

			if ( zoomScale != 1.0 ) {
				[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.body.style.zoom=%f", zoomScale]];
			}

//			webView.scrollView.minimumZoomScale = zoomScale;
//			webView.scrollView.maximumZoomScale = zoomScale;
//			webView.scrollView.zoomScale = zoomScale;
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


// extract the key value pairs for the raw URL query and return then in a dictionary
+ (NSDictionary *)dictionaryForQuery:(NSString *)query {
	if ( query != nil ) {
		JSContext *scriptContext = [JSContext new];
		NSArray *records = [query componentsSeparatedByString:@"&"];
		NSMutableDictionary *dictionary = [NSMutableDictionary new];
		for ( NSString *record in records ) {
			NSArray *fields = [record componentsSeparatedByString:@"="];
			if ( fields != nil && fields.count == 2 ) {
				NSString *key = fields[0];
				if ( key ) {
					NSString *scriptCommand = [NSString stringWithFormat:@"decodeURIComponent( \"%@\" )", fields[1]];
					JSValue *scriptResult = [scriptContext evaluateScript:scriptCommand];
					dictionary[ key ] = scriptResult.toString;
				}
			}
		}

		return [NSDictionary dictionaryWithDictionary:dictionary];
	}
	else {
		return [NSDictionary dictionary];
	}
}


@end
