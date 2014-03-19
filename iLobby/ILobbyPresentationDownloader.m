//
//  ILobbyPresentationDownloader.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/22/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresentationDownloader.h"
#import "ILobbyFileDownloader.h"
#import "ILobbySlide.h"
#import "ILobbyDirectory.h"
#import "ILobbyRemoteDirectory.h"


@interface ILobbyPresentationDownloader ()
@property (readwrite, strong, nonatomic) NSURL *baseURL;
@property (readwrite, copy) ILobbyPresentationDownloadHandler completionHandler;
@property (readwrite, strong, nonatomic) NSArray *trackConfigs;
@property (assign, readwrite) BOOL complete;
@property (assign, readwrite) BOOL canceled;
@property (strong, readwrite) ILobbyProgress *progress;
@property (strong) ILobbyFileDownloader *currentFileDownloader;
@property (readwrite, copy, nonatomic) NSString *archivePath;
@end


@implementation ILobbyPresentationDownloader


-(instancetype)initWithPresentation:(ILobbyStorePresentation *)presentation completionHandler:(ILobbyPresentationDownloadHandler)handler {
    self = [super init];
    if (self) {
		[[presentation managedObjectContext] performBlockAndWait:^{
			presentation.path = [ILobbyPresentationDownloader pathForPresentation:presentation];
			self.archivePath = presentation.path;
			self.baseURL = presentation.remoteURL;
		}];
		
		self.completionHandler = handler;
		self.complete = NO;
		self.canceled = NO;
		self.progress = [ILobbyProgress progressWithFraction:0.0f label:@"Download starting..."];

		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSError * __autoreleasing error;
		NSString *presentationDirectory = [ILobbyPresentationDownloader pathForPresentation:presentation];
		if ( [fileManager fileExistsAtPath:presentationDirectory] ) {
			[fileManager removeItemAtPath:presentationDirectory error:&error];
			if ( error ) {
				NSLog( @"Error removing the presentation directory: %@", presentationDirectory );
			}
		}

//		ILobbyRemoteDirectory *remoteDirectory = [ILobbyRemoteDirectory parseDirectoryAtURL:self.baseURL error:nil];
		//NSLog( @"Remote directory: %@", remoteDirectory );
		NSLog( @"Will download presenation to: %@", self.archivePath );
    }
    return self;
}


// path to the downloaded presentation
+ (NSString *)pathForPresentation:(ILobbyStorePresentation *)presentation {
	NSString *presentationsDirectory = [[[ILobbyModel documentDirectoryURL] path] stringByAppendingPathComponent:@"Presentations"];
	NSDateFormatter *timestampFormatter = [NSDateFormatter new];
	[timestampFormatter setDateFormat:@"yyyyMMddHHmmss"];
	NSString *timestamp = [timestampFormatter stringFromDate:presentation.timestamp];
	NSString *presentationPath = [[presentationsDirectory stringByAppendingPathComponent:presentation.name] stringByAppendingPathComponent:timestamp];

	return presentationPath;
}


- (void)cancel {
	self.canceled = YES;
	[self.currentFileDownloader cancel];
	self.progress = [ILobbyProgress progressWithFraction:0.0f label:@"Download Canceled..."];
}


-(void)handleIndexDownload:(ILobbyFileDownloader *)downloader error:(NSError *)error {
	NSError * __autoreleasing jsonError;
	NSData *data = [NSData dataWithContentsOfFile:downloader.outputFilePath];
	NSDictionary *config = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

	//	NSLog( @"index: %@", config );
	if ( jsonError ) {
		NSLog( @"Error: %@", jsonError );
	}

	self.trackConfigs = config[@"tracks"];

	NSMutableArray *itemURLs = [NSMutableArray new];
	for ( NSDictionary *trackConfig in config[@"tracks"] ) {
		NSString *trackLocation = trackConfig[@"location"];
		NSString *relativeTrackPath = [@"tracks" stringByAppendingPathComponent:trackLocation];
		NSURL *trackURL = [NSURL URLWithString:relativeTrackPath relativeToURL:self.baseURL];
		ILobbyDirectory *trackDirectory = [ILobbyDirectory serverDirectoryWithURL:trackURL];

		NSString *iconFile = trackConfig[@"icon"];
		NSURL *iconURL = [self itemURLForFile:iconFile inTrack:trackConfig];
		[itemURLs addObject:iconURL];
		NSArray *slidesConfigs = trackConfig[@"slides"];
		for ( id slideConfig in slidesConfigs ) {
			NSArray *slideFiles = [ILobbySlide filesFromConfig:slideConfig inDirectory:trackDirectory];
			for ( NSString *slideFile in slideFiles ) {
				NSURL *slideURL = [self itemURLForFile:slideFile inTrack:trackConfig];
				[itemURLs addObject:slideURL];
			}
		}
	}

	[self downloadItemIn:itemURLs atIndex:0];
}


-(void)downloadItemIn:(NSArray *)itemURLs atIndex:(NSUInteger)index {
//	NSUInteger count = [itemURLs count];
//	if ( count > index ) {
//		NSURL *itemURL = itemURLs[index];
//		self.currentFileDownloader = [[ILobbyFileDownloader alloc] initWithSourceURL:itemURL subdirectory:PRESENTATION_SUBDIRECTORY archivePath:self.archivePath progressHandler:^(ILobbyFileDownloader *downloader, NSError * error) {
//			[self updateProgressForCount:count index:index downloader:downloader];
//			if ( downloader.complete ) {
//				[self downloadItemIn:itemURLs atIndex:(index+1)];
//			}
//		}];
//	}
//	else {
//		self.complete = YES;
//		self.progress = [ILobbyProgress progressWithFraction:1.0f label:@"Download Complete"];
//		self.completionHandler( self );
//	}
}


- (NSURL *)itemURLForFile:(NSString *)itemFile inTrack:(NSDictionary *)trackConfig {
	NSString *location = trackConfig[@"location"];

	NSURL *tracksRelativeURL = [NSURL URLWithString:@"tracks"];
	NSURL *trackRelativeURL = [tracksRelativeURL URLByAppendingPathComponent:location];
	NSURL *itemRelativeURL = [trackRelativeURL URLByAppendingPathComponent:itemFile];

	return [NSURL URLWithString:[itemRelativeURL path] relativeToURL:self.baseURL];
}


- (void)updateProgressForCount:(NSUInteger)count index:(NSUInteger)index downloader:(ILobbyFileDownloader *)downloader {
	float progressFraction = ( downloader.progress + (float)(index - 1) ) / count;
	NSString *progressLabel = [NSString stringWithFormat:@"Downloading: %@", downloader.sourceURL.relativePath];
	self.progress = [ILobbyProgress progressWithFraction:progressFraction label:progressLabel];
}

@end
