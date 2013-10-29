//
//  ILobbyRemoteDirectory.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/26/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyDirectory.h"
#import "ILobbyXMLAttributeParser.h"

@class ILobbyDirectory;


@interface ILobbyRemoteDirectory : ILobbyDirectory

@property (strong, nonatomic, readwrite) NSURL *location;

- (id)initWithURL:(NSURL *)location;

@end


@interface ILobbyLocalDirectory : ILobbyDirectory

@property (strong, nonatomic, readwrite) NSString *directory;

- (id)initWithPath:(NSString *)directory;

@end



@interface ILobbyDirectory ()
@property (strong, nonatomic, readwrite) NSArray *files;
@end


@implementation ILobbyDirectory

- (id)init {
    self = [super init];
    if (self) {
        self.files = nil;
    }
    return self;
}


+ (ILobbyDirectory *)remoteDirectoryWithURL:(NSURL *)location {
	return [[ILobbyRemoteDirectory alloc] initWithURL:location];
}


+ (ILobbyDirectory *)localDirectoryWithPath:(NSString *)path {
	return [[ILobbyLocalDirectory alloc] initWithPath:path];
}


- (NSArray *)filesMatching:(NSString *)pattern {
	NSMutableArray *matchingFiles = [NSMutableArray new];

	for ( NSString *file in self.files ) {
		NSRange matchingRange = [file rangeOfString:pattern options:NSRegularExpressionSearch];
		if ( matchingRange.location != NSNotFound ) {
			[matchingFiles addObject:file];
		}
	}

	return [NSArray arrayWithArray:matchingFiles];
}

@end



@implementation ILobbyLocalDirectory

- (id)initWithPath:(NSString *)directory {
    self = [super init];
    if (self) {
        self.directory = directory;
    }
    return self;
}


- (NSArray *)files {
	NSArray *files = _files;

	if ( !files ) {
		NSError *error;
		_files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.directory error:&error];
		if ( error ) {
			NSLog( @"Error getting contents of directory: %@ resulting in error: %@", self.directory, error );
		}
	}

	return _files;
}

@end



@interface NSString (ILobbyMatching)
- (NSRange)findMatch:(NSString *)regex inRange:(NSRange)range;
- (NSArray *)findMatches:(NSString *)regex;
@end


@implementation NSString (ILobbyMatching)

- (NSRange)findMatch:(NSString *)regex inRange:(NSRange)searchRange {
	return [self rangeOfString:regex options:(NSRegularExpressionSearch|NSCaseInsensitiveSearch) range:searchRange];
}


- (NSArray *)findMatches:(NSString *)regex {
	if ( self.length == 0 )  return @[];

	NSMutableArray *matches = [NSMutableArray new];
	NSRange searchRange = NSMakeRange( 0, self.length );
	while ( searchRange.length > 0 ) {
		NSRange matchRange = [self findMatch:regex inRange:searchRange];
		if ( matchRange.length == 0 )  break;

		NSString *match = [self substringWithRange:matchRange];
		[matches addObject:match];

		NSUInteger nextLocation = matchRange.location + matchRange.length;

		if ( self.length <= nextLocation )  break;

		searchRange = NSMakeRange( nextLocation, self.length - nextLocation );
	}

	return [NSArray arrayWithArray:matches];
}

@end



@interface ILobbyRemoteDirectory ()
@end


@implementation ILobbyRemoteDirectory

- (id)initWithURL:(NSURL *)location {
    self = [super init];
    if (self) {
        self.location = location;
    }
    return self;
}


- (NSArray *)files {
	NSArray *files = _files;
	
	if ( !files ) {
		_files = [self fetchFiles];
	}

	return _files;
}


- (NSArray *)fetchFiles {
	NSArray *pageLinks = [self.class linksOnPageURL:self.location];

	if ( pageLinks == nil )  return nil;

	NSMutableArray *files = [NSMutableArray new];
	for ( NSURL *link in pageLinks ) {
		NSString *path = link.path;
		if ( ![path hasSuffix:@"/"] ) {		// only accept files (reject directories)
			NSString *file = [path lastPathComponent];	// strip any leading references
			[files addObject:file];
		}
	}

	return [files copy];
}


// Get the links on the page using a regular expression to fetch each anchor element and the XML Parser to fetch the href attribute inside the element
+ (NSArray *)linksOnPageURL:(NSURL *)pageURL {
	NSError * __autoreleasing error;
	NSStringEncoding usedEncoding;
	NSString *page = [NSString stringWithContentsOfURL:pageURL.absoluteURL usedEncoding:&usedEncoding error:&error];

	if ( error ) {
		return nil;
	}

	if ( page == nil || page.length == 0 )  return @[];

	// pattern is:  anchor tag - one space - any characters except < - closing angle bracket - any characters except < - closing anchor tag
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<a\\s[^<]+?>[^<]+?</a>" options:NSRegularExpressionCaseInsensitive error:nil];
	NSMutableArray *pageLinks = [NSMutableArray new];
	[regex enumerateMatchesInString:page options:0 range:NSMakeRange( 0, page.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
		NSString *anchorElementXML = [page substringWithRange:match.range];
		NSDictionary *attributeCache = [ILobbyXMLAttributeParser fetchElementsAttributesForXML:anchorElementXML error:nil];
		NSString *href = attributeCache[@"A"][@"HREF"];
		[pageLinks addObject:[NSURL URLWithString:href relativeToURL:pageURL]];
	}];

	return [pageLinks copy];
}

@end
