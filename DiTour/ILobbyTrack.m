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
#import "DiTour-Swift.h"


#define DEFAULT_SLIDE_DURATION 5.0f
#define DEFAULT_SINGLE_IMAGE_SLIDE_DURATION 600.0f


@interface ILobbyTrack ()
@property (nonatomic, readwrite, strong) UIImage *icon;
@property (nonatomic, readwrite, copy) NSString *label;
@property (nonatomic, readwrite, assign) float extraTrackDuration;
@property (nonatomic, readwrite, assign) float defaultSlideDuration;
@property (nonatomic, readwrite, strong) NSArray *slides;
@property (nonatomic, readwrite, strong) ILobbySlide *currentSlide;
@property (nonatomic, readwrite, strong) ILobbyTransitionSource *defaultTransitionSource;
@property (nonatomic, readwrite, assign) BOOL playing;
@end


@implementation ILobbyTrack


- (instancetype)initWithTrackStore:(ILobbyStoreTrack *)trackStore {
	self = [super init];

	if ( self ) {
		self.playing = NO;
		self.currentSlide = nil;

		self.label = trackStore.title;

		NSDictionary *config = trackStore.effectiveConfiguration;
//		NSLog( @"Config for %@: %@", self.label, config );

		NSNumber *slideDurationNum = config[@"slideDuration"];
		float defaultSlideDuration = slideDurationNum != nil ? slideDurationNum.floatValue : DEFAULT_SLIDE_DURATION;
		self.defaultSlideDuration = defaultSlideDuration;

		ILobbyTransitionSource *defaultTransitionSource = [ILobbyTransitionSource parseTransitionSource:config[@"slideTransition"]];
		self.defaultTransitionSource = defaultTransitionSource;

		NSMutableArray *slides = [NSMutableArray new];
		for ( ILobbyStoreRemoteMedia *media in trackStore.remoteMedia ) {
			// if the filename is Icon.* then it is the icon and all others are slides
			if ( [[[media.name stringByDeletingPathExtension] lowercaseString] isEqualToString:@"icon"] ) {
				NSString *iconPath = media.absolutePath;
//				NSLog( @"Assigning icon with path: %@", iconPath );
				self.icon = [UIImage imageWithContentsOfFile:iconPath];
			}
			else {
				NSString *slidePath = media.absolutePath;
				ILobbySlide *slide = [ILobbySlide slideWithFile:slidePath duration:defaultSlideDuration];
				if ( defaultTransitionSource != nil ) {
					slide.transitionSource = defaultTransitionSource;
				}
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


		// if there is only one slide and it is an image slide then the slide duration may be extended if the config file specifies it
		if ( slides.count == 1 ) {
			ILobbySlide *slide = slides[0];
			if ( slide.isSingleFrame ) {
				NSNumber *singleImageSlideTrackDurationNum = config[@"singleImageSlideTrackDuration"];
				if ( singleImageSlideTrackDurationNum != nil ) {
					float trackDuration = [singleImageSlideTrackDurationNum floatValue];
					[self setSingleImageSlideDuration:trackDuration];
				}
				else {
					float trackDuration = DEFAULT_SINGLE_IMAGE_SLIDE_DURATION;
					[self setSingleImageSlideDuration:trackDuration];
				}
			}
		}
		else {
			self.extraTrackDuration = 0.0;
		}

		self.slides = [slides copy];
	}

	return self;
}


// if the track duration is greater than the slide duration we must allow for the extra time otherwise no extra time is needed
- (void)setSingleImageSlideDuration:(float)trackDuration {
	float slideDuration = self.defaultSlideDuration;
	self.extraTrackDuration = ( trackDuration > slideDuration ) ? trackDuration - slideDuration : 0.0;;
}


- (void)presentTo:(id<PresentationDelegate>)presenter completionHandler:(ILobbyTrackCompletionHandler)handler {
//	NSLog( @"Presenting track: %@", self.label );
	self.playing = YES;

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


- (void)presentSlideAt:(NSUInteger)slideIndex to:(id<PresentationDelegate>)presenter forRun:runID completionHandler:(ILobbyTrackCompletionHandler)trackCompletionHandler {
//	NSLog( @"Presenting slide at index: %d", slideIndex );
	NSArray *slides = self.slides;
	ILobbySlide *slide = (ILobbySlide *)slides[slideIndex];
	self.currentSlide = slide;
	[slide presentTo:presenter completionHandler:^(ILobbySlide *theSlide) {
		if ( self.playing ) {
			NSUInteger nextSlideIndex = slideIndex + 1;
			if ( runID == presenter.currentRunID ) {
				if ( nextSlideIndex < slides.count ) {
					[self presentSlideAt:nextSlideIndex to:presenter forRun:runID completionHandler:trackCompletionHandler];
				}
				else {
					float trackDelay = self.extraTrackDuration;

					// if there is an extra track delay then we will delay calling the completion handler
					if ( trackDelay > 0.0 ) {
						int64_t delayInSeconds = trackDelay;
						dispatch_time_t popTime = dispatch_time( DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC );
						dispatch_after( popTime, dispatch_get_main_queue(), ^(void){
							trackCompletionHandler( self );
						});
					}
					else {
						trackCompletionHandler( self );
					}
				}
			}
		}
	}];
}


- (void)cancelPresentation {
	self.playing = NO;
	ILobbySlide *currentSlide = self.currentSlide;
	if ( currentSlide )  [currentSlide cancelPresentation];

	// clear the current slide to avoid unnecessary slide cancelation
	self.currentSlide = nil;
}

@end
