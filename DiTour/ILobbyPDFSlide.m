//
//  ILobbyPDFSlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 5/5/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPDFSlide.h"
#import "ILobbySlideFamily.h"
#import "DiTour-Swift.h"

@import QuartzCore;


static NSSet *PDF_EXTENSIONS;

static UIImageView *IMAGE_VIEW = nil;


@implementation ILobbyPDFSlide {
	id _currentRunID;
}

+ (void)load {
	if ( self == [ILobbyPDFSlide class] ) {
		PDF_EXTENSIONS = [NSSet setWithObject:@"pdf"];
		[self registerSlideClass];
	}
}


+ (NSSet *)supportedExtensions {
	return PDF_EXTENSIONS;
}


- (id)initWithFile:(NSString *)file duration:(float)duration {
    self = [super initWithFile:file duration:duration];

    if (self) {
		// custom PDF Slide initialization
    }
    return self;
}


- (void)cancelPresentation {
	_currentRunID = nil;
}


- (CGPDFDocumentRef)newDocument {
	NSURL *mediaURL = [NSURL fileURLWithPath:self.mediaFile];
	return CGPDFDocumentCreateWithURL( (__bridge CFURLRef)mediaURL );
}


- (void)displayTo:(id<PresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)completionHandler {
	_currentRunID = [NSDate date];
	id currentRunID = _currentRunID;

	CGPDFDocumentRef documentRef = [self newDocument];
	size_t pageCount = CGPDFDocumentGetNumberOfPages( documentRef );
	CGPDFDocumentRelease( documentRef );

	if ( pageCount > 0 ) {
		// pages begin with 1
		[self displayPage:1 toPresenter:presenter completionHandler:completionHandler runID:currentRunID];
	}
	else {
		completionHandler( self );	// nothing to do so we're done
	}
}


- (void)displayPage:(size_t)pageNumber toPresenter:(id<PresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)completionHandler runID:(id)currentRunID {
	CGPDFDocumentRef documentRef = [self newDocument];
	size_t pageCount = CGPDFDocumentGetNumberOfPages( documentRef );

	CGPDFPageRef pageRef = CGPDFDocumentGetPage( documentRef, pageNumber );
	UIImage *image = [self imageFromPageRef:pageRef];
	CGPDFDocumentRelease( documentRef );

	if ( IMAGE_VIEW == nil ) {
		IMAGE_VIEW = [[UIImageView alloc] initWithFrame:presenter.externalBounds];
	}

	IMAGE_VIEW.image = image;

	[presenter displayMediaView:IMAGE_VIEW];

	size_t nextPageNumber = pageNumber + 1;
	int64_t delayInSeconds = self.duration;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after( popTime, dispatch_get_main_queue(), ^(void){
		if ( currentRunID == _currentRunID ) {		// make sure the user hasn't switched to another track
			// if the page number is valid display the image for the page otherwise we are done
			if ( nextPageNumber <= pageCount ) {
				[self performTransition:presenter];
				[self displayPage:nextPageNumber toPresenter:presenter completionHandler:completionHandler runID:currentRunID];
			}
			else {
				completionHandler( self );
			}
		}
	});
}


- (UIImage *)icon {
	CGPDFDocumentRef documentRef = [self newDocument];
	size_t pageCount = CGPDFDocumentGetNumberOfPages( documentRef );

	UIImage *image = nil;
	if ( pageCount > 0 ) {
		CGPDFPageRef pageRef = CGPDFDocumentGetPage( documentRef, 1 );
		image = [self imageFromPageRef:pageRef];
	}

	CGPDFDocumentRelease( documentRef );

	return image;
}


- (BOOL)isSingleFrame {
	CGPDFDocumentRef document = [self newDocument];
	size_t pageCount = CGPDFDocumentGetNumberOfPages( document );
	CGPDFDocumentRelease( document );
	return pageCount == 1;
}


- (UIImage *)imageFromPageRef:(CGPDFPageRef)pageRef {
	CGRect bounds = CGPDFPageGetBoxRect( pageRef, kCGPDFCropBox );
	size_t width = CGRectGetWidth( bounds );
	size_t height = CGRectGetHeight( bounds );
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate( NULL, width, height, 8, 0, colorSpaceRef, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrderDefault );
	CGContextDrawPDFPage( context, pageRef );

	CGImageRef imageRef = CGBitmapContextCreateImage( context );
	UIImage *image = [UIImage imageWithCGImage:imageRef];

	CGImageRelease( imageRef );
	CGColorSpaceRelease( colorSpaceRef );
	CGContextRelease( context );

	return image;
}

@end
