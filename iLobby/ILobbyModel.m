//
//  ILobbyModel.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyModel.h"
#import "ILobbyPresentationDownloader.h"


// path to the installed presentation
static NSString *PRESENTATION_PATH;


@interface ILobbyModel ()
@property (strong, nonatomic) ILobbyPresentationDownloader *presentationDownloader;
@property (strong, readwrite) ILobbyProgress *downloadProgress;
@property (strong, readwrite) NSArray *tracks;
@property (strong, readwrite) ILobbyTrack *defaultTrack;
@property (strong, readwrite) ILobbyTrack *currentTrack;
@end


@implementation ILobbyModel

// class initializer
+(void)initialize {
	if ( self == [ILobbyModel class] ) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSError *error;

		NSURL *libraryURL = [fileManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
		if ( error ) {
			NSLog( @"Error getting to library: %@", error );
		}

		PRESENTATION_PATH = [[libraryURL path] stringByAppendingPathComponent:@"Presentation"];
	}
}


- (id)init {
    self = [super init];
    if (self) {
		self.downloadProgress = [ILobbyProgress progressWithFraction:0.0f label:@""];
		[self loadPresentation];
    }
    return self;
}


- (void)setPresentationDelegate:(id<ILobbyPresentationDelegate>)presentationDelegate {
	_presentationDelegate = presentationDelegate;
}


- (BOOL)canPlay {
	NSArray *tracks = self.tracks;
	return tracks != nil && tracks.count > 0;
}


- (BOOL)play {
	if ( [self canPlay] ) {
		[self playTrack:self.defaultTrack cancelCurrent:YES];
		return YES;
	}
	else {
		return NO;
	}
}


- (void)stop {
	[self.currentTrack cancelPresentation];
}


- (void)playTrackAtIndex:(NSUInteger)trackIndex {
//	NSLog( @"Play track at index: %d", trackIndex );
	ILobbyTrack *track = self.tracks[trackIndex];
	[self playTrack:track cancelCurrent:YES];
}


- (void)playTrack:(ILobbyTrack *)track cancelCurrent:(BOOL)cancelCurrent {
	ILobbyTrack *oldTrack = self.currentTrack;
	if ( cancelCurrent && oldTrack )  [oldTrack cancelPresentation];

	id<ILobbyPresentationDelegate> presentationDelegate = self.presentationDelegate;
	if ( presentationDelegate ) {
		self.currentTrack = track;
		[track presentTo:presentationDelegate completionHandler:^(ILobbyTrack *track) {
			// after a track completes on its own (no need to cancel), revert to the default track
			[self playTrack:self.defaultTrack cancelCurrent:NO];
		}];
	}
}


- (void)installPresentation {
	NSError *error;
	NSFileManager *fileManager = [NSFileManager defaultManager];

	// if a presentation is already installed, delete it
	if ( [fileManager fileExistsAtPath:PRESENTATION_PATH] ) {
		[fileManager removeItemAtPath:PRESENTATION_PATH error:&error];
	}

	NSString *downloadPath = [ILobbyPresentationDownloader presentationPath];
	[fileManager moveItemAtPath:downloadPath toPath:PRESENTATION_PATH error:&error];

}


- (void)loadPresentation {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *indexPath = [PRESENTATION_PATH stringByAppendingPathComponent:@"index.json"];

	if ( [fileManager fileExistsAtPath:indexPath] ) {
		NSError *jsonError;
		NSData *data = [NSData dataWithContentsOfFile:indexPath];
		NSDictionary *config = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
//		NSLog( @"Presentation config: %@", config );

		NSMutableArray *tracks = [NSMutableArray new];
		NSString *trackPath = [PRESENTATION_PATH stringByAppendingPathComponent:@"tracks"];
		for ( NSDictionary *trackConfig in config[@"tracks"] ) {
			ILobbyTrack *track = [[ILobbyTrack alloc] initWithConfiguration:trackConfig relativeTo:trackPath];
			[tracks addObject:track];
		}

		self.tracks = [NSArray arrayWithArray:tracks];
		self.defaultTrack = tracks.count > 0 ? tracks[0] : nil;
	}
}


- (NSURL *)presentationLocation {
	return [[NSUserDefaults standardUserDefaults] URLForKey:@"presentationLocation"];
}


- (void)setPresentationLocation:(NSURL *)presentationLocation {
	[[NSUserDefaults standardUserDefaults] setURL:presentationLocation forKey:@"presentationLocation"];
}


- (void)downloadPresentation {
	self.presentationDownloader = [[ILobbyPresentationDownloader alloc] initWithIndexURL:self.presentationLocation completionHandler:^(ILobbyPresentationDownloader *downloader) {
		if ( self.presentationDownloader.complete ) {
			// stop observing progress
			[downloader removeObserver:self forKeyPath:@"progress"];
			
			[self updateProgress:downloader];
			[self installPresentation];
			[self loadPresentation];
		}
	}];
	[self.presentationDownloader addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ( [object isKindOfClass:[ILobbyPresentationDownloader class]] ) {
		[self updateProgress:(ILobbyPresentationDownloader *)object];
	}
}


- (void)updateProgress:(ILobbyPresentationDownloader *)downloader {
	self.downloadProgress = downloader.progress;
}

@end
