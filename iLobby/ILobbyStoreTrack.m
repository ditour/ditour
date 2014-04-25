//
//  ILobbyStoreTrack.m
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyStoreTrack.h"
#import "ILobbyStorePresentation.h"


@interface NSString (ILobbyTrackTransforms)
- (NSString *)toTrackTitle;
- (NSString *)stripLeadingDigitsAndUnderscore;
- (NSString *)toSpacesFromUnderscores;
@end



@implementation ILobbyStoreTrack

@dynamic title;
@dynamic presentation;
@dynamic remoteMedia;


+ (instancetype)newTrackInPresentation:(ILobbyStorePresentation *)presentation from:(ILobbyRemoteDirectory *)remoteDirectory {
	ILobbyStoreTrack *track = [NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:presentation.managedObjectContext];

	track.presentation = presentation;
	track.status = @( REMOTE_ITEM_STATUS_PENDING );
	track.remoteLocation = remoteDirectory.location.absoluteString;

	NSString *rawName = remoteDirectory.location.lastPathComponent;
	track.path = [presentation.path stringByAppendingPathComponent:rawName];

	// remove leading digits, replace underscores with spaces and trasnform to title case
	track.title = [rawName toTrackTitle];

//	NSLog( @"Fetching Track: %@", track.title );
//	NSLog( @"Track Path: %@", track.path );

	for ( ILobbyRemoteFile *remoteFile in remoteDirectory.files ) {
		[track processRemoteFile:remoteFile];
	}

	return track;
}


- (void)processRemoteFile:(ILobbyRemoteFile *)remoteFile {
	NSURL *location = remoteFile.location;
	if ( [ILobbyStoreRemoteMedia matches:location] ) {
		[ILobbyStoreRemoteMedia newRemoteMediaInTrack:self at:remoteFile];
	}
	else {
		[super processRemoteFile:remoteFile];
	}
}


- (void)markDownloading {
	[super markDownloading];
//	NSLog( @"Mark Downloading for track: %@, status: %@, pointer: %@, context: %@", self.title, self.status, self, self.managedObjectContext );
}


- (void)markReady {
	[super markReady];
//	NSLog( @"Mark Ready for track: %@, status: %@, pointer: %@, context: %@", self.title, self.status, self, self.managedObjectContext );
}


@end



@implementation NSString (ILobbyTrackTransforms)

- (NSString *)toTrackTitle {
	return [[self stripLeadingDigitsAndUnderscore] toSpacesFromUnderscores];
}


- (NSString *)stripLeadingDigitsAndUnderscore {
	static NSRegularExpression *digitsRegex = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		digitsRegex = [NSRegularExpression regularExpressionWithPattern:@"\\d+_" options:NSRegularExpressionCaseInsensitive error:nil];
	});

	NSTextCheckingResult *match = [digitsRegex firstMatchInString:self options:0 range:NSMakeRange( 0, self.length )];

	if ( match ) {
		// the match must begin at the start of the string and the string must be strictly longer than the match
		if ( match.range.location == 0 && match.range.length < self.length ) {
			return [self substringFromIndex:match.range.length];
		}
		else {
			return self;
		}
	}
	else {
		return self;
	}
}


- (NSString *)toSpacesFromUnderscores {
	return [self stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}


@end