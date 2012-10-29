//
//  ILobbyRemoteDirectory.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/26/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyDirectory.h"

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



@interface ILobbyRemoteDirectoryFetch : NSObject
- (id)initWithURL:(NSURL *)location;
- (NSArray *)fetchFiles;
@end



@interface ILobbyRemoteDirectory () <NSXMLParserDelegate>
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
		ILobbyRemoteDirectoryFetch *fetch = [[ILobbyRemoteDirectoryFetch alloc] initWithURL:self.location];
		_files = [fetch fetchFiles];
	}

	return _files;
}

@end



@interface ILobbyRemoteDirectoryFetch () <NSXMLParserDelegate>
@property (strong, nonatomic, readwrite) NSURL *location;
@property (strong, nonatomic, readwrite) NSMutableArray *files;
@end


@implementation ILobbyRemoteDirectoryFetch
- (id)initWithURL:(NSURL *)location {
    self = [super init];
    if (self) {
        self.location = location;
		self.files = [NSMutableArray new];
    }
    return self;
}


- (NSArray *)fetchFiles {
	NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:self.location];
	parser.delegate = self;

	// parser will fail due to unclosed <br> tags when closing </pre> tag is encountered, but after the directory files have been parsed
	[parser parse];

	return [NSArray arrayWithArray:self.files];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if ( [elementName isEqualToString:@"A"] ) {
		NSString *href = attributeDict[@"HREF"];

		if ( ![href hasSuffix:@"/"] ) {		// only accept files (reject directories)
			NSString *file = [href lastPathComponent];	// strip any leading references
			[_files addObject:file];
		}
	}
}

@end
