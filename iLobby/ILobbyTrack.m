//
//  ILobbyTrack.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyTrack.h"
#import "ILobbySlide.h"
#import "ILobbyStoreRemoteMedia.h"

#define DEFAULT_SLIDE_DURATION 5.0f


@interface ILobbyTrack ()
@property (nonatomic, readwrite, strong) UIImage *icon;
@property (nonatomic, readwrite, copy) NSString *label;
@property (nonatomic, readwrite, assign) float defaultSlideDuration;
@property (nonatomic, readwrite, strong) NSArray *slides;
@property (nonatomic, readwrite, strong) ILobbySlide *currentSlide;
@property (nonatomic, readwrite, strong) ILobbyTransitionSource *defaultTransitionSource;
@end


@implementation ILobbyTrack


- (instancetype)initWithTrackStore:(ILobbyStoreTrack *)trackStore {
	self = [super init];

	if ( self ) {
		self.currentSlide = nil;

		self.label = trackStore.title;

		// TODO: get the slide duration and transition from the config store
		self.defaultSlideDuration = DEFAULT_SLIDE_DURATION;

//		ILobbyTransitionSource *defaultTransitionSource = [ILobbyTransitionSource parseTransitionSource:trackConfig[@"defaultTransition"]];
//		self.defaultTransitionSource = defaultTransitionSource;

		NSMutableArray *slides = [NSMutableArray new];
		for ( ILobbyStoreRemoteMedia *media in trackStore.remoteMedia ) {
			// if the filename is Icon.* then it is the icon and all others are slides
			if ( [[[media.name stringByDeletingPathExtension] lowercaseString] isEqualToString:@"icon"] ) {
				NSString *iconPath = media.path;
//				NSLog( @"Assigning icon with path: %@", iconPath );
				self.icon = [UIImage imageWithContentsOfFile:iconPath];
			}
			else {
				// TODO: add support for a single PDF file mapping to multiple slides
				NSString *slidePath = media.path;
				ILobbySlide *slide = [ILobbySlide slideWithFile:slidePath duration:self.defaultSlideDuration];
				[slides addObject:slide];
			}
		}

		// if there was no explicit icon file provided then use first image if any
		if ( self.icon == nil ) {
			for ( ILobbySlide *slide in slides ) {
				UIImage *icon = slide.icon;
				if ( icon != nil ) {
					self.icon = icon;
					break;
				}
			}
		}


		// if there is still no icon provide a default one from this application's main bundle
		if ( self.icon == nil ) {
			self.icon = [UIImage imageNamed:@"DefaultSlideIcon"];
		}

		self.slides = [slides copy];
	}

	return self;
}


- (void)presentTo:(id<ILobbyPresentationDelegate>)presenter completionHandler:(ILobbyTrackCompletionHandler)handler {
//	NSLog( @"Presenting track: %@", self.label );
	NSArray *slides = self.slides;
	id runID = [NSDate new];
	if ( slides != nil && slides.count > 0 ) {
		presenter.currentRunID = runID;
		[self presentSlideAt:0 to:presenter forRun:runID completionHandler:handler];
	}
	else {
		handler( self );
	}
}


- (void)presentSlideAt:(NSUInteger)slideIndex to:(id<ILobbyPresentationDelegate>)presenter forRun:runID completionHandler:(ILobbyTrackCompletionHandler)trackCompletionHandler {
//	NSLog( @"Presenting slide at index: %d", slideIndex );
	NSArray *slides = self.slides;
	ILobbySlide *slide = (ILobbySlide *)slides[slideIndex];
	self.currentSlide = slide;
	[slide presentTo:presenter completionHandler:^(ILobbySlide *theSlide) {
		NSUInteger nextSlideIndex = slideIndex + 1;
		if ( runID == presenter.currentRunID ) {
			if ( nextSlideIndex < slides.count ) {
				[self presentSlideAt:nextSlideIndex to:presenter forRun:runID completionHandler:trackCompletionHandler];
			}
			else {
				trackCompletionHandler( self );
			}
		}
	}];
}


- (void)cancelPresentation {
	ILobbySlide *currentSlide = self.currentSlide;
	if ( currentSlide )  [currentSlide cancelPresentation];
}

@end
