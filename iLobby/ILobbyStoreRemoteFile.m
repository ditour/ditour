//
//  ILobbyStoreRemoteFile.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/27/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreRemoteFile.h"

@implementation ILobbyStoreRemoteFile

// indicates whether the candidate URL matches a type supported by the class
+ (BOOL)matches:(NSURL *)candidateURL {
	return YES;
}


- (NSString *)name {
	return [self.path lastPathComponent];
}


- (NSString *)summary {
	return [NSString stringWithFormat:@"%@\n\n\n%@", self.remoteSummary, self.localSummary];
}


- (NSString *)localSummary {
	NSString *localSummary = @"No Local Info...";

	static NSDateFormatter *dateFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [NSDateFormatter new];
		dateFormatter.timeStyle = NSDateFormatterMediumStyle;
		dateFormatter.dateStyle = NSDateFormatterMediumStyle;
	});

	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ( [fileManager fileExistsAtPath:self.absolutePath] ) {
		NSError *error = nil;
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:self.absolutePath error:&error];
		if ( !error ) {
			NSDate *modDate = fileAttributes[NSFileModificationDate];
			NSNumber *fileSize = fileAttributes[NSFileSize];
			NSString *fileSizeString = [NSByteCountFormatter stringFromByteCount:fileSize.longValue countStyle:NSByteCountFormatterCountStyleFile];
			localSummary = [NSString stringWithFormat:@"Local ModificationDate:\n\t%@\n\nLocal File Size:\n\t%@\n\n%@", [dateFormatter stringFromDate:modDate], fileSizeString, self.localDataSummary];
		}
	}

	return localSummary;
}


- (NSString *)localDataSummary {
	return @"";
}


- (NSString *)remoteSummary {
	return [NSString stringWithFormat:@"Remote Location:\n\t%@\n\nRemote Info:\n\t%@", self.remoteLocation, self.remoteInfo];
}

@end
