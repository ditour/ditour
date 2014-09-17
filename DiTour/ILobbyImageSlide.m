//
//  ILobbyImageSlide.m
//  iLobby
//
//  Created by Pelaia II, Tom on 5/5/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyImageSlide.h"
#import "ILobbySlideFamily.h"


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
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:presenter.externalBounds];
	imageView.image = [UIImage imageWithContentsOfFile:self.mediaFile];
	
	[presenter displayMediaView:imageView];

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
