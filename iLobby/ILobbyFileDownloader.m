//
//  ILobbyFileDownloader.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/22/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyFileDownloader.h"


@interface ILobbyFileDownloader () <NSURLConnectionDataDelegate>
@property (strong, nonatomic) NSURLConnection *connection;
@property (strong, nonatomic) NSURLResponse *response;
@property (readwrite, strong, nonatomic) NSURL *sourceURL;
@property (readwrite, copy, nonatomic) NSString *outputFilePath;
@property (readwrite, copy, nonatomic) NSString *archivePath;
@property (readwrite, copy) ILobbyFileDownloadHandler progressHandler;
@property (readwrite) float progress;
@property (readwrite) BOOL complete;
@end


@implementation ILobbyFileDownloader


static NSURL *LIBRARY_FOLDER_URL = nil;
static NSString *DOWNLOADS_PATH = nil;


// class initializer
+(void)initialize {
	if ( self == [ILobbyFileDownloader class] ) {
//		NSLog( @"Performing File Downloader class initialization..." );

		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSError *error;
		
		LIBRARY_FOLDER_URL = [fileManager URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
		if ( error ) {
			NSLog( @"Error getting to library: %@", error );
		}
//		else {
//			NSLog( @"library: %@", LIBRARY_FOLDER_URL );
//		}

		DOWNLOADS_PATH = [[LIBRARY_FOLDER_URL path] stringByAppendingPathComponent:@"Downloads"];
	}
}


// path to the downloads directory
+ (NSString *)downloadsPath {
	return DOWNLOADS_PATH;
}


// instance initialization
- (id)initWithSourceURL:(NSURL *)sourceURL subdirectory:(NSString *)rootSubdirectory archivePath:(NSString *)archivePath progressHandler:(ILobbyFileDownloadHandler)handler {
    self = [super init];
    if (self) {
		self.archivePath = archivePath;
		self.complete = NO;
		self.progress = 0.0f;
		self.response = nil;
		self.sourceURL = sourceURL;
		self.progressHandler = handler;

		NSFileManager *fileManager = [NSFileManager defaultManager];

		// root directory in Downloads relative to which the output file path should be rooted
		NSString *rootDirectory = [DOWNLOADS_PATH stringByAppendingPathComponent:rootSubdirectory];

		// generate the output file path relative to the root directory
		self.outputFilePath = [rootDirectory stringByAppendingPathComponent:[sourceURL relativePath]];

		// if the file has already been downloaded there is no need to download again
		if ( ![fileManager fileExistsAtPath:self.outputFilePath] ) {
			// get the full path to the directory which will contain the output file and create it if necessary
			NSString *contentDirectory = [self.outputFilePath stringByDeletingLastPathComponent];
			if ( ![fileManager fileExistsAtPath:contentDirectory] ) {
				NSError *error;
				[fileManager createDirectoryAtPath:contentDirectory withIntermediateDirectories:YES attributes:nil error:&error];
			}

//			NSLog( @"Output file path: %@", self.outputFilePath );
			NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:sourceURL];
			self.connection = [NSURLConnection connectionWithRequest:downloadRequest delegate:self];
		}
		else {
			self.complete = YES;
			self.progress = 1.0f;
			handler( self, nil );
		}
    }
    return self;
}


// cancel the download
- (void)cancel {
	[self.connection cancel];
}


// update the progress
- (void)updateProgress {
	if ( self.response ) {
		long long remoteSize = self.response.expectedContentLength;
		if ( remoteSize > 0 ) {
			long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.outputFilePath error:nil] fileSize];
			float progress = (double)fileSize / remoteSize;
			self.progress = progress <= 1.0 ? progress : 1.0;
		}
	}
}


#pragma mark -
#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	self.response = response;
//	NSLog( @"Connection received response for %@: %lld", self.outputFilePath, response.expectedContentLength );
//	NSLog( @"Response header: %@", [(NSHTTPURLResponse *)response allHeaderFields] );

	// log the file's modification on the server
	NSString *modified = [(NSHTTPURLResponse *)response allHeaderFields][@"Last-Modified"];
	NSDateFormatter *formatter = [NSDateFormatter new];
	// response "Last-Modified" value format is of the form: TUE, 30 Oct 2012 14:32:10 GMT
	formatter.dateFormat = @"EEE, d MMM yyyy K:mm:ss z";
	[formatter setLenient:YES];
	NSDate *sourceModification = [formatter dateFromString:modified];
//	NSLog( @"Source Modification date: %@", sourceModification );
	NSString *archiveFilePath = [self.archivePath stringByAppendingPathComponent:self.sourceURL.relativePath];
//	NSLog( @"Archive File Path: %@", archiveFilePath );

	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ( [fileManager fileExistsAtPath:archiveFilePath] ) {
		NSError *fileError;
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:archiveFilePath error:&fileError];
		if ( !fileError ) {
			NSDate *archiveModification = [fileAttributes fileCreationDate];
//			NSLog( @"Archive Date: %@", archiveModification );
			NSComparisonResult comparison = [archiveModification compare:sourceModification];
			switch ( comparison ) {
				case NSOrderedDescending:
					[fileManager copyItemAtPath:archiveFilePath toPath:self.outputFilePath error:&fileError];
//					NSLog( @"Copying file from local archive..." );
					if ( !fileError ) {
//						NSLog( @"Cancelling connection..." );
						[connection cancel];
						self.progress = 1.0f;
						self.complete = YES;
						self.progressHandler( self, nil );
					}
					else {
						NSLog( @"File error: %@", fileError );
					}
					break;
				default:
					break;
			}
		}
	}
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ( ![fileManager fileExistsAtPath:self.outputFilePath]) {
		[fileManager createFileAtPath:self.outputFilePath contents:nil attributes:nil];
	}
	
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.outputFilePath];
	[fileHandle seekToEndOfFile];
	[fileHandle writeData:data];
	[fileHandle closeFile];
//	NSLog( @"Wrote data to: %@", self.outputFilePath );

	[self updateProgress];
	self.progressHandler( self, nil );
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
//	NSLog( @"Connection finished loading: %@", self.outputFilePath );
	self.progress = 1.0f;
	self.complete = YES;
	self.progressHandler( self, nil );
}

@end
