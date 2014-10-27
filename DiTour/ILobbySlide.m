//
//  ILobbySlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/24/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbySlide.h"
#import "ILobbySlideFamily.h"
#import "DiTour-Swift.h"


static NSSet *ALL_SUPPORTED_EXTENSIONS = nil;
static NSDictionary *SLIDE_CLASS_NAMES_BY_EXTENSION = nil;


@implementation ILobbySlide

- (instancetype)initWithFile:(NSString *)file duration:(float)duration {
    self = [super init];
    if (self) {
		self.duration = duration;
		self.mediaFile = file;
    }
    return self;
}


+ (instancetype)makeSlideWithFile:(NSString *)file duration:(float)duration {
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


- (void)presentTo:(id<PresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {
	[self performTransition:presenter];
	[self displayTo:presenter completionHandler:handler];
}


- (void)performTransition:(id<PresentationDelegate>)presenter {
	TransitionSource *transitionSource = self.transitionSource;
	if ( transitionSource ) {
		CATransition *transition = [transitionSource generate];
		if ( transition ) {
			[presenter beginTransition:transition];
		}
	}
}


- (void)displayTo:(id<PresentationDelegate>)presenter completionHandler:(ILobbySlideCompletionHandler)handler {}

- (void)cancelPresentation {}

@end
