//
//  ILobbyDownloadSession.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/3/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyDownloadSession.h"
#import "ILobbyConcurrentDictionary.h"


@interface ILobbyDownloadSession () <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (readwrite, nonatomic, copy) NSString *backgroundIdentifier;

@property (copy) void (^backgroundSessionCompletionHandler)();
@property NSURLSession *downloadSession;
@property (nonatomic) ILobbyConcurrentDictionary *downloadTaskRemoteItems;

@end



@implementation ILobbyDownloadSession


- (instancetype)init {
    self = [super init];
    if (self) {
		self.downloadTaskRemoteItems = [ILobbyConcurrentDictionary new];
		self.backgroundIdentifier = [self createBackgroundIdenfier];
		[self createBackgroundSession];
    }
    return self;
}


- (NSString *)createBackgroundIdenfier {
	// every background session within a single process must have its own identifier
	static NSDateFormatter *formatter = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		formatter = [NSDateFormatter new];
		formatter.dateFormat = @"yyyyMMdd'-'HHmmss.SSSS";
	});

	return [NSString stringWithFormat:@"gov.ornl.neutrons.iLobby.PresentationDownloads_%@", [formatter stringFromDate:[NSDate date]]];
}


- (void)createBackgroundSession {
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:self.backgroundIdentifier];
	configuration.HTTPMaximumConnectionsPerHost = 4;
	self.downloadSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
}


- (BOOL)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
	NSLog( @"Handle events for background session with ID: %@", identifier );
	if ( [identifier isEqualToString:self.backgroundIdentifier] ) {
		self.backgroundSessionCompletionHandler = completionHandler;
		return YES;
	}
	else {
		return NO;
	}
}


- (void)cancel {
	[self.downloadSession invalidateAndCancel];
}


- (void)downloadGroup:(ILobbyStorePresentationGroup *)group {
	[group.managedObjectContext performBlock:^{
		if ( group.configuration ) {
			[self downloadRemoteFile:group.configuration];
		}

		for ( ILobbyStorePresentation *pendingPresentation in group.pendingPresentations ) {
			[self downloadPresentation:pendingPresentation];
		}
	}];
}


- (void)downloadPresentation:(ILobbyStorePresentation *)presentation {
	[presentation.managedObjectContext performBlock:^{
		NSError * __autoreleasing error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:presentation.path withIntermediateDirectories:YES attributes:nil error:&error];

		if ( error ) {
			NSLog( @"Error creating presentation directory: %@", [error localizedDescription] );
		}
		else {
			if ( presentation.configuration ) {
				[self downloadRemoteFile:presentation.configuration];
			}

			for ( ILobbyStoreTrack *track in presentation.tracks ) {
				[self downloadTrack:track];
			}
		}
	}];
}


- (void)downloadTrack:(ILobbyStoreTrack	*)track {
	[track.managedObjectContext performBlock:^{
		NSError * __autoreleasing error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:track.path withIntermediateDirectories:YES attributes:nil error:&error];

		if ( error ) {
			NSLog( @"Error creating track directory: %@", [error localizedDescription] );
		}
		else {
			if ( track.configuration ) {
				[self downloadRemoteFile:track.configuration];
			}

			for ( ILobbyStoreRemoteMedia *remoteMedia in track.remoteMedia ) {
				[self downloadRemoteFile:remoteMedia];
			}
		}
	}];
}


- (void)downloadRemoteFile:(ILobbyStoreRemoteFile *)remoteFile {
	[remoteFile.managedObjectContext performBlock:^{
		if ( remoteFile && remoteFile.isPending ) {
			//Create a new download task using the URL session. Tasks start in the “suspended” state; to start a task you need to explicitly call -resume on a task after creating it.
			NSURL *downloadURL = remoteFile.remoteURL;
			NSLog( @"scheduling download of remote file from: %@", downloadURL );
			NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
			NSURLSessionDownloadTask *downloadTask = [self.downloadSession downloadTaskWithRequest:request];

			self.downloadTaskRemoteItems[downloadTask] = remoteFile;
			remoteFile.status = @( REMOTE_ITEM_STATUS_DOWNLOADING );

			[downloadTask resume];
		}
	}];
}


- (NSURLSession *)backgroundSession {
	// If you want to support multiple background sessions within a single process, you should create each session with its own identifier.
	static NSURLSession *session = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"gov.ornl.neutrons.iLobby.PresentationDownloads.BackgroundSession"];
		configuration.HTTPMaximumConnectionsPerHost = 4;
		session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
	});
	return session;
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    /*
     Report progress on the task.
     If you created more than one task, you might keep references to them and report on them individually.
     */

	//	double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
	//	NSLog( @"DownloadTask: %@ progress: %lf", downloadTask, progress );
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL {
	//TODO: save the downloaded file here...
	NSLog( @"Finished downloading file to %@", downloadURL );

	// TODO: need to manage thread safety for both dictionary access and remote file access
	ILobbyStoreRemoteFile *remoteFile = self.downloadTaskRemoteItems[downloadTask];
	if ( remoteFile ) {
		NSError * __autoreleasing error = nil;
		[[NSFileManager defaultManager] copyItemAtPath:downloadURL.path toPath:remoteFile.path error:&error];
		if ( error ) {
			NSLog( @"Error copying file: %@", [error localizedDescription] );
		}
	}
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	ILobbyStoreRemoteFile *remoteFile = self.downloadTaskRemoteItems[task];

    if (error == nil) {
        NSLog(@"Task: %@ completed successfully", task);

		if ( remoteFile ) {
			[remoteFile.managedObjectContext performBlock:^{
				remoteFile.status = @( REMOTE_ITEM_STATUS_READY );
			}];
		}
    }
    else {
        NSLog(@"Task: %@ completed with error: %@", task, [error localizedDescription]);

		if ( remoteFile ) {
			[remoteFile.managedObjectContext performBlock:^{
				remoteFile.status = @( REMOTE_ITEM_STATUS_PENDING );
			}];
		}
    }

	if ( remoteFile ) {
		// TODO: need to manage thread safety for the dictionary access
		[self.downloadTaskRemoteItems removeObjectForKey:task];
	}

    //double progress = (double)task.countOfBytesReceived / (double)task.countOfBytesExpectedToReceive;
	// TODO: do something with the progress
}


/*
 If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message, the session delegate will receive this message to indicate that all messages previously enqueued for this session have been delivered. At this time it is safe to invoke the previously stored completion handler, or to begin any internal updates that will result in invoking the completion handler.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if ( self.backgroundSessionCompletionHandler ) {
        void (^completionHandler)() = self.backgroundSessionCompletionHandler;
        self.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }

    NSLog(@"All tasks are finished");
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
	NSLog( @"URL Session did resume..." );
}

@end
