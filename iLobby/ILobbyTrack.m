//
//  ILobbyTrack.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyTrack.h"
#import "ILobbySlide.h"

#define DEFAULT_SLIDE_DURATION 5.0f


@interface ILobbyTrack ()
@property (nonatomic, readwrite, strong) UIImage *icon;
@property (nonatomic, readwrite, copy) NSString *label;
@property (nonatomic, readwrite, assign) float defaultSlideDuration;
@property (nonatomic, readwrite, strong) NSArray *slides;
@property (nonatomic, readwrite, strong) ILobbySlide *currentSlide;
@end


@implementation ILobbyTrack

- (id)initWithConfiguration:(NSDictionary *)trackConfig relativeTo:(NSString *)rootPath {
    self = [super init];
    if (self) {
		self.currentSlide = nil;
		
		NSString *location = trackConfig[@"location"];
		self.label = trackConfig[@"label"];

		NSString *trackPath = [rootPath stringByAppendingPathComponent:location];

		NSString *iconFile = trackConfig[@"icon"];
		NSString *iconPath = [trackPath stringByAppendingPathComponent:iconFile];
		self.icon = [UIImage imageWithContentsOfFile:iconPath];

		NSNumber *defaultDuration = trackConfig[@"defaultDuration"];
		self.defaultSlideDuration = defaultDuration != nil ? [defaultDuration floatValue] : DEFAULT_SLIDE_DURATION;
		
		NSArray *slidesConfigs = trackConfig[@"slides"];
		NSMutableArray *slides = [NSMutableArray new];
		for ( id slideConfig in slidesConfigs ) {
			NSArray *slideFiles = [ILobbySlide filesFromConfig:slideConfig];
			for ( NSString *slideFile in slideFiles ) {
				ILobbySlide *slide = [ILobbySlide slideWithFile:[trackPath stringByAppendingPathComponent:slideFile] duration:self.defaultSlideDuration];
				if ( slide ) {
					[slides addObject:slide];
				}
				else {
					NSLog( @"Cannot generate slide for file: %@", slideFile );
				}
			}
		}
		self.slides = [NSArray arrayWithArray:slides];
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
			if ( nextSlideIndex < slides.count - 1 ) {
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
