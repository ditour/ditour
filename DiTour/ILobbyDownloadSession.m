//
//  ILobbyDownloadSession.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/3/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyDownloadSession.h"
#import "ILobbyConcurrentDictionary.h"
#import "DiTour-Swift.h"


@interface ILobbyDownloadSession () <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>

@property (readwrite, nonatomic, copy) NSString *backgroundIdentifier;

@property (readwrite, nonatomic) BOOL canceled;

@property (copy) void (^backgroundSessionCompletionHandler)();
@property NSURLSession *downloadSession;
@property (nonatomic) ILobbyConcurrentDictionary *downloadTaskRemoteItems;		// file download status keyed by task
@property (nonatomic, readwrite) ILobbyDownloadContainerStatus *groupStatus;
@property (nonatomic, readwrite, weak) DitourModel *lobbyModel;

@end



@implementation ILobbyDownloadSession

- (instancetype)initWithModel:(DitourModel *)lobbyModel {
    self = [super init];
    if (self) {
		self.lobbyModel = lobbyModel;

		self.downloadTaskRemoteItems = [ILobbyConcurrentDictionary new];
		self.backgroundIdentifier = [self createBackgroundIdenfier];

		_active = YES;
		_canceled = NO;
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


// cancel the session due to an explicit request or error
- (void)cancel {
	if ( _active ) {
//		NSLog( @"Canceling the download session..." );
		_active = NO;
		_canceled = YES;

		self.groupStatus.canceled = YES;
		[self.downloadSession invalidateAndCancel];
		[self publishChanges];
	}
}


// stop the session due to normal termination
- (void)stop {
	if ( _active ) {
		_active = NO;

		[self.downloadSession invalidateAndCancel];
		[self publishChanges];
	}
}


- (void)updateStatus {
	// if all tasks have been submitted and no tasks remain then we can cancel the session
	[self.groupStatus updateProgress];

//	NSLog( @"Updating status: %d, download task count: %ld", self.groupStatus.completed, (long)self.downloadTaskRemoteItems.count );
	if ( self.groupStatus.completed && self.downloadTaskRemoteItems.count == 0 ) {
//		NSLog( @"Download session is complete and will be stopped..." );
		[self stop];
		[self publishChanges];
		[self.lobbyModel reloadPresentationNextCycle];
	}
}


- (void)publishChanges {
//	NSLog( @"publishing changes..." );
	PresentationGroupStore *group = (PresentationGroupStore *)self.groupStatus.remoteItem;
	[group.managedObjectContext performBlockAndWait:^{
		[group.managedObjectContext refreshObject:group mergeChanges:YES];
	}];
	[self persistentSaveContext:self.groupStatus.remoteItem.managedObjectContext error:nil];
}


- (ILobbyDownloadContainerStatus *)downloadGroup:(PresentationGroupStore *)group withDelegate:(id<ILobbyDownloadStatusDelegate>)delegate {
	ILobbyDownloadContainerStatus *status = [[ILobbyDownloadContainerStatus alloc] initWithItem:group container:nil];
	status.delegate = delegate;
	self.groupStatus = status;

	[group.managedObjectContext performBlockAndWait:^{
		NSError *error = nil;

		[group markDownloading];

		// cache information about the initial config so we can reuse the file if possible
		ConfigurationStore *initialConfig = group.configuration;
		NSString *initialConfigRemoteInfo = nil;
		NSString *initialConfigPath = nil;
		if ( initialConfig != nil ) {
			initialConfigRemoteInfo = initialConfig.remoteInfo;
			initialConfigPath = initialConfig.absolutePath;
		}
		initialConfig = nil;


		// remove any existing pending presentations as we will create new ones so stale ones are no longer useful
		[group.managedObjectContext refreshObject:group mergeChanges:YES];
		for ( PresentationStore *presentation in group.pendingPresentations ) {
			[group removePresentation:presentation];
			[group.managedObjectContext deleteObject:presentation];
		}
		[self persistentSaveContext:group.managedObjectContext error:&error];


		// ------------- fetch the directory references from the remote URL

		RemoteDirectory *groupRemoteDirectory = [RemoteDirectory parseDirectoryAtURL:group.remoteURL error:&error];

		if ( groupRemoteDirectory != nil && error == nil ) {
			// process any files (e.g. config files)
			for ( RemoteFile *remoteFile in groupRemoteDirectory.files ) {
				[group processRemoteFile:remoteFile];
			}

			// store the active presentations by name so they can be used as parents if necessary
			NSMutableDictionary *activePresentationsByName = [NSMutableDictionary new];
			for ( PresentationStore *presentation in group.activePresentations ) {
				//			NSLog( @"Active presentation at: %@", presentation.absolutePath );
				activePresentationsByName[presentation.name] = presentation;
			}

			// fetch presentations
			for ( RemoteDirectory *remotePresentationDirectory in groupRemoteDirectory.subdirectories ) {
				PresentationStore *presentation = [PresentationStore newPresentationInGroup:group from:remotePresentationDirectory];

				// if an active presentation has the same name then assign it as a parent
				PresentationStore *presentationParent = activePresentationsByName[presentation.name];
				if ( presentationParent != nil ) {
					presentation.parent = presentationParent;
				}
			}

			// any active presentation which does not have a revision should be removed except for the currently playing one if any
			for ( PresentationStore *presentation in group.activePresentations ) {
				if ( presentation.revision == nil ) {
					[presentation markDisposable];

					if ( !presentation.isCurrent ) {
						[group removePresentation:presentation];
						[group.managedObjectContext deleteObject:presentation];
					}
				}
			}

			[self persistentSaveContext:group.managedObjectContext error:&error];


			// updates fetched properties
			[group.managedObjectContext refreshObject:group mergeChanges:YES];

			// ----------- now begin downloading the files

			// if the group has a configuration then determine whether the configuration file can be copied from the initial one
			if ( group.configuration != nil ) {
				// if the intial config exists and is up to date, we can just use it, otherwise download a new copy
				NSFileManager *fileManager = [NSFileManager defaultManager];
				if ( initialConfigRemoteInfo != nil && [initialConfigRemoteInfo isEqualToString:group.configuration.remoteInfo] && [initialConfigPath isEqualToString:group.configuration.absolutePath] && [fileManager fileExistsAtPath:initialConfigPath] ) {
					[group.configuration markReady];
				}
				else {
					if ( initialConfigPath != nil && [fileManager fileExistsAtPath:initialConfigPath] ) {
						[self removeFileAt:initialConfigPath];
					}
					[self downloadRemoteFile:group.configuration container:status usingCache:nil];
				}
			}
			else if ( initialConfig != nil ) {
				[self removeFileAt:initialConfigPath];
			}

			// download the presentations
			for ( PresentationStore *pendingPresentation in group.pendingPresentations ) {
				[self downloadPresentation:pendingPresentation container:status];
			}
			
			status.submitted = YES;
			[self updateStatus];
		}
		else {
			if ( error != nil ) {
				NSLog( @"Error downloading group: %@", error );
				status.error = error;
				[self cancel];
			}
			else {
				[self stop];
			}

			[group markPending];
		}
	}];

	return status;
}


- (void)removeFileAt:(NSString *)path {
	NSError *error;
	NSFileManager *fileManager = [NSFileManager defaultManager];

	if ( [fileManager fileExistsAtPath:path] ) {
		[fileManager removeItemAtPath:path error:&error];
	}

	if ( error ) {
		NSLog( @"Error deleting existing file at destination %@, %@", path, [error localizedDescription] );
		[self cancel];
	}
}


- (void)downloadPresentation:(PresentationStore *)presentation container:(ILobbyDownloadContainerStatus *)groupStatus {
	ILobbyDownloadContainerStatus *status = [ILobbyDownloadContainerStatus statusForRemoteItem:presentation container:groupStatus];

	[presentation.managedObjectContext performBlock:^{
		NSError * __autoreleasing error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:presentation.absolutePath withIntermediateDirectories:YES attributes:nil error:&error];

		if ( error ) {
			status.error = error;
			NSLog( @"Error creating presentation directory: %@", [error localizedDescription] );
		}
		else {
			[presentation markDownloading];

			// generate the cache of local items in the parent if any keyed by URL spec
			NSDictionary *localCacheByURL = presentation.parent != nil ? [presentation.parent generateFileDictionaryKeyedByURL] : nil;

			if ( presentation.configuration ) {
				[self downloadRemoteFile:presentation.configuration container:status usingCache:localCacheByURL];
			}

			for ( TrackStore *track in presentation.tracks ) {
				[self downloadTrack:track container:status usingCache:localCacheByURL];
			}

			status.submitted = YES;
		}
	}];
}


- (void)downloadTrack:(TrackStore	*)track container:(ILobbyDownloadContainerStatus *)presentationStatus usingCache:(NSDictionary *)localCacheByURL {
	ILobbyDownloadContainerStatus *status = [ILobbyDownloadContainerStatus statusForRemoteItem:track container:presentationStatus];

	[track.managedObjectContext performBlock:^{
		NSError * __autoreleasing error = nil;
		[[NSFileManager defaultManager] createDirectoryAtPath:track.absolutePath withIntermediateDirectories:YES attributes:nil error:&error];

		if ( error ) {
			status.error = error;
			NSLog( @"Error creating track directory: %@", [error localizedDescription] );
		}
		else {
			[track markDownloading];
//			NSLog( @"Download track: %@ with status: %@, pointer: %@", track.title, track.status, track );

			if ( track.configuration ) {
				[self downloadRemoteFile:track.configuration container:status usingCache:localCacheByURL];
			}

			for ( RemoteMediaStore *remoteMedia in track.remoteMedia ) {
				[self downloadRemoteFile:remoteMedia container:status usingCache:localCacheByURL];
			}

			status.submitted = YES;
		}
	}];
}


- (void)downloadRemoteFile:(RemoteFileStore *)remoteFile container:(ILobbyDownloadContainerStatus *)container usingCache:(NSDictionary *)localCacheByURL {
	ILobbyDownloadFileStatus *status = [ILobbyDownloadFileStatus statusForRemoteItem:remoteFile container:container];

	[remoteFile.managedObjectContext performBlock:^{
		if ( remoteFile && remoteFile.isPending ) {
			// first see if the local cache has a current version of the file we want
			if ( localCacheByURL != nil ) {
				RemoteFileStore *cachedFile = localCacheByURL[remoteFile.remoteLocation];
				if ( cachedFile != nil ) {
					NSString *cacheInfo = cachedFile.remoteInfo;
					NSString *remoteInfo = remoteFile.remoteInfo;
					if ( remoteInfo != nil && [remoteInfo isEqualToString:cacheInfo] ) {
//						NSLog( @"Simply copying file from local cache for: %@", remoteFile.absolutePath );
						NSFileManager *fileManager = [NSFileManager defaultManager];

						if ( [fileManager fileExistsAtPath:cachedFile.absolutePath] ) {
							NSError *error = nil;
							// create a hard link from the original path to the new path so we save space
							BOOL success = [fileManager linkItemAtPath:cachedFile.absolutePath toPath:remoteFile.absolutePath error:&error];
							if ( success ) {
								[remoteFile markReady];
								status.completed = YES;
								status.progress = 1.0;
								[self updateStatus];
								return;
							}
							else {
								status.error = error;
								NSLog( @"Error creating hard link to remote file: %@ from existing file at: %@", remoteFile.absolutePath, cachedFile.absolutePath );
							}

						}
					}
				}
			}

			// anything that fails in using the cache file will fall through to here which forces a fresh fetch to the server

			//Create a new download task using the URL session. Tasks start in the “suspended” state; to start a task you need to explicitly call -resume on a task after creating it.
			NSURL *downloadURL = remoteFile.remoteURL;
//			NSLog( @"scheduling download of remote file from: %@", downloadURL );

			NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
			NSURLSessionDownloadTask *downloadTask = [self.downloadSession downloadTaskWithRequest:request];

			self.downloadTaskRemoteItems[downloadTask] = status;
			[remoteFile markDownloading];

			[downloadTask resume];
		}
	}];
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	// report progress on the task
	double progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
	ILobbyDownloadFileStatus *downloadStatus = self.downloadTaskRemoteItems[downloadTask];
	downloadStatus.progress = progress;

	//NSLog( @"DownloadTask: %@ progress: %lf", downloadTask, progress );
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL {
	//NSLog( @"Finished downloading file to %@", downloadURL );

	ILobbyDownloadFileStatus *downloadStatus = self.downloadTaskRemoteItems[downloadTask];
	RemoteFileStore *remoteFile = (RemoteFileStore *)downloadStatus.remoteItem;

	if ( remoteFile ) {
		__block NSString *destination = nil;
		__block NSURL *remoteURL = nil;
		[remoteFile.managedObjectContext performBlockAndWait:^{
			destination = remoteFile.absolutePath;
			remoteURL = remoteFile.remoteURL;
		}];

		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSError * __autoreleasing error = nil;

		if ( [fileManager fileExistsAtPath:destination] ) {
			NSLog( @"Error: Existing file at destination %@ for remote %@", destination, remoteURL );
		}
		else {
			[fileManager copyItemAtPath:downloadURL.path toPath:destination error:&error];
		}

		if ( error ) {
			// cached the current cancel state since we will be canceling
			BOOL alreadyCanceled = self.canceled;

			[self cancel];
			downloadStatus.error = error;

			// if not already canceled then this is the causal error for the group since we will get a flood of errors due to the cancel which we can ignore
			if ( !alreadyCanceled ) {
				self.groupStatus.error = error;
				NSLog( @"Error copying file from %@ to %@, %@", remoteURL, destination, [error localizedDescription] );
			}
		}
	}

	downloadStatus.completed = YES;
	downloadStatus.progress = 1.0;

	[self persistentSaveContext:remoteFile.managedObjectContext error:nil];
	[self updateStatus];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
	ILobbyDownloadFileStatus *downloadStatus = self.downloadTaskRemoteItems[task];
	RemoteFileStore *remoteFile = (RemoteFileStore *)downloadStatus.remoteItem;

    if (error == nil) {
//        NSLog(@"Task: %@ completed successfully", task);

		if ( remoteFile ) {
			[remoteFile.managedObjectContext performBlock:^{
				[remoteFile markReady];
			}];
		}
    }
    else {
		// cached the current cancel state since we will be canceling
		BOOL alreadyCanceled = self.canceled;

		[self cancel];
		downloadStatus.error = error;

		// if not already canceled then this is the causal error for the group since we will get a flood of errors due to the cancel which we can ignore
		if ( !alreadyCanceled ) {
			self.groupStatus.error = error;
			NSLog(@"Task: %@ completed with error: %@", task, [error localizedDescription]);
		}

		if ( remoteFile ) {
			[remoteFile.managedObjectContext performBlock:^{
				[remoteFile markPending];
			}];
		}
    }

	// download completed whether successful or not
	downloadStatus.completed = YES;

	if ( remoteFile ) {
		[self.downloadTaskRemoteItems removeObjectForKey:task];
	}

	// if all tasks have been submitted and no tasks remain then we can cancel the session
	if ( self.groupStatus.completed && self.downloadTaskRemoteItems.count == 0 ) {
//		NSLog( @"Download session is complete and will be cancelled..." );
		[self stop];
	}
	
	[self persistentSaveContext:remoteFile.managedObjectContext error:nil];
	[self updateStatus];
}


/*
 If an application has received an -application:handleEventsForBackgroundURLSession:completionHandler: message, the session delegate will receive this message to indicate that all messages previously enqueued for this session have been delivered. At this time it is safe to invoke the previously stored completion handler, or to begin any internal updates that will result in invoking the completion handler.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
	void (^completionHandler)() = self.backgroundSessionCompletionHandler;

    if ( completionHandler ) {
        self.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }

//    NSLog(@"All tasks are finished");
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
//	NSLog( @"URL Session did resume..." );
}


// save the specified context all the way to the root persistent store
- (BOOL)persistentSaveContext:(NSManagedObjectContext *)context error:(NSError * __autoreleasing *)errorPtr {
	return [self.lobbyModel persistentSaveContext:context error:errorPtr];
}


@end
