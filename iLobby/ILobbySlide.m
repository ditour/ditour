//
//  ILobbySlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/24/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbySlide.h"
@import AVFoundation;
@import QuartzCore;



@interface ILobbySlide ()

+ (NSSet *)supportedExtensions;

@property (nonatomic, readwrite) float duration;
@property (nonatomic, readwrite, copy) NSString *mediaFile;

- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler;

@end



@interface ILobbyImageSlide : ILobbySlide
@end



@interface ILobbyPDFSlide : ILobbySlide
@end



@interface ILobbyVideoSlide : ILobbySlide
@property (nonatomic, readwrite, strong) ILobbySlideCompletionHandler completionHandler;
@end



static NSSet *ALL_SUPPORTED_EXTENSIONS = nil;
static NSDictionary *SLIDE_CLASS_NAMES_BY_EXTENSION = nil;


@implementation ILobbySlide

- (id)initWithFile:(NSString *)file duration:(float)duration {
    self = [super init];
    if (self) {
		self.duration = duration;
		self.mediaFile = file;
    }
    return self;
}


+ (id)slideWithFile:(NSString *)file duration:(float)duration {
	NSString *extension = [file pathExtension].lowercaseString;

	NSString *slideClassName = SLIDE_CLASS_NAMES_BY_EXTENSION[extension];
	if ( slideClassName != nil ) {
		Class slideClass = NSClassFromString( slideClassName );
		if ( slideClass != nil ) {
			return [[slideClass alloc] initWithFile:file duration:duration];
		}
		else {
			return nil;
		}
	}
	else {
		return nil;
	}
}


+ (NSSet *)supportedExtensions {
	return nil;
}


+ (NSSet *)allSupportedExtensions {
	return [ALL_SUPPORTED_EXTENSIONS copy];
}


// called by subclasses to register themselves
+ (void)registerSlideClass:(Class)slideClass {
	// store the class names keyed by lower case extension for later use when instantiating slides
	NSString *className = NSStringFromClass( slideClass );
	NSMutableDictionary *slideClassNamesByExtension = SLIDE_CLASS_NAMES_BY_EXTENSION != nil ? [SLIDE_CLASS_NAMES_BY_EXTENSION mutableCopy] : [NSMutableDictionary new];
	NSSet *extensions = [slideClass supportedExtensions];
	for ( NSString *extension in extensions ) {
		NSString *extensionKey = extension.lowercaseString;
		slideClassNamesByExtension[extensionKey] = className;
	}
	SLIDE_CLASS_NAMES_BY_EXTENSION = [slideClassNamesByExtension copy];

	[self appendSupportedExtensions:extensions];
}


// append the supported extensions to ALL_SUPPORTED_EXTENSIONS
+ (void)appendSupportedExtensions:(NSSet *)extensions {
	if ( extensions != nil ) {
		if ( ALL_SUPPORTED_EXTENSIONS != nil ) {
			NSMutableSet *allExtensions = [ALL_SUPPORTED_EXTENSIONS mutableCopy];
			[allExtensions unionSet:extensions];
			ALL_SUPPORTED_EXTENSIONS = [allExtensions copy];
		}
		else {
			ALL_SUPPORTED_EXTENSIONS = [extensions copy];
		}
	}
}


- (UIImage *)icon {
	return nil;
}


- (BOOL)isSingleFrame {
	return NO;
}


+ (BOOL)matchesExtension:(NSString *)extension {
	return [[self supportedExtensions] containsObject:extension];
}


- (void)presentTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	ILobbyTransitionSource *transitionSource = self.transitionSource;
	if ( transitionSource ) {
		CATransition *transition = [transitionSource generate];
		if ( transition ) {
			[presenter beginTransition:transition];
		}
	}

	[self displayTo:presenter completionHandler:handler];
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {}

- (void)cancelPresentation {}

@end



static NSSet *IMAGE_EXTENSIONS;

@implementation ILobbyImageSlide

+ (void)load {
	if ( self == [ILobbyImageSlide class] ) {
		IMAGE_EXTENSIONS = [NSSet setWithArray:@[ @"png", @"jpg", @"jpeg", @"gif" ]];
		[self registerSlideClass:self];
	}
}


+ (NSSet *)supportedExtensions {
	return IMAGE_EXTENSIONS;
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	[presenter displayImage:[UIImage imageWithContentsOfFile:self.mediaFile]];
	
	int64_t delayInSeconds = self.duration;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after( popTime, dispatch_get_main_queue(), ^(void){
		handler( self );
	});
}


- (UIImage *)icon {
	return [UIImage imageWithContentsOfFile:self.mediaFile];
}


- (BOOL)isSingleFrame {
	return YES;
}

@end



static NSSet *PDF_EXTENSIONS;

@implementation ILobbyPDFSlide {
	id _currentRunID;
}

+ (void)load {
	if ( self == [ILobbyPDFSlide class] ) {
		PDF_EXTENSIONS = [NSSet setWithObject:@"pdf"];
		[self registerSlideClass:self];
	}
}


+ (NSSet *)supportedExtensions {
	return PDF_EXTENSIONS;
}


- (void)cancelPresentation {
	_currentRunID = nil;
}


- (CGPDFDocumentRef)newDocument {
	NSURL *mediaURL = [NSURL fileURLWithPath:self.mediaFile];
	return CGPDFDocumentCreateWithURL( (__bridge CFURLRef)mediaURL );
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)completionHandler {
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


- (void)displayPage:(size_t)pageNumber toPresenter:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)completionHandler runID:(id)currentRunID {
	CGPDFDocumentRef documentRef = [self newDocument];
	size_t pageCount = CGPDFDocumentGetNumberOfPages( documentRef );

	CGPDFPageRef pageRef = CGPDFDocumentGetPage( documentRef, pageNumber );
	UIImage *image = [self imageFromPageRef:pageRef];
	CGPDFDocumentRelease( documentRef );

	[presenter displayImage:image];

	size_t nextPageNumber = pageNumber + 1;
	int64_t delayInSeconds = self.duration;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after( popTime, dispatch_get_main_queue(), ^(void){
		if ( currentRunID == _currentRunID ) {		// make sure the user hasn't switched to another track
			// if the page number is valid display the image for the page otherwise we are done
			if ( nextPageNumber <= pageCount ) {
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
	CGContextRef context = CGBitmapContextCreate( NULL, width, height, 8, 0, colorSpaceRef, kCGImageAlphaPremultipliedLast );
	CGContextDrawPDFPage( context, pageRef );

	CGImageRef imageRef = CGBitmapContextCreateImage( context );
	UIImage *image = [UIImage imageWithCGImage:imageRef];

	CGImageRelease( imageRef );
	CGColorSpaceRelease( colorSpaceRef );
	CGContextRelease( context );

	return image;
}

@end



static NSSet *VIDEO_EXTENSIONS;

@implementation ILobbyVideoSlide

+ (void)load {
	if ( self == [ILobbyVideoSlide class] ) {
		VIDEO_EXTENSIONS = [NSSet setWithArray:@[ @"m4v", @"mp4", @"mov" ]];
		[self registerSlideClass:self];
	}
}


+ (NSSet *)supportedExtensions {
	return VIDEO_EXTENSIONS;
}


- (void)displayTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	self.completionHandler = handler;
	
	NSURL *mediaURL = [NSURL fileURLWithPath:self.mediaFile];
    AVAsset *asset = [AVURLAsset URLAssetWithURL:mediaURL options:nil];
    AVPlayerItem *videoItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:videoItem];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePlayerCompletion:) name:AVPlayerItemDidPlayToEndTimeNotification object:videoItem];
	[presenter displayVideo:player];
}


- (void)clearNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)cancelPresentation {
	[self clearNotifications];
}


- (void)handlePlayerCompletion:(NSNotification *)notification {
	[self clearNotifications];
	
	ILobbySlideCompletionHandler handler = self.completionHandler;
	if ( handler ) {
		handler( self );
	}
}

@end