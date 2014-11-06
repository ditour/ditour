//
//  ILobbyRemoteDirectoryInfo.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/31/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyRemoteDirectory.h"
#import "DiTourTidyWrapper.h"
#import "DiTour-Swift.h"


@interface ILobbyRemoteDirectory ()
@property(readwrite) NSURL *location;			// URL location for this directory
@property(readwrite) NSArray *items;			// array of ILobbyRemoteDirectoryItem (files and subdirectories)
@property(readwrite) NSArray *files;			// array of items that are simple files
@property(readwrite) NSArray *subdirectories;	// array of items that are sudirectories
@end



@interface ILobbyRemoteDirectoryParser : NSObject <NSXMLParserDelegate>
+ (ILobbyRemoteDirectory *)parseDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)errorPtr;
@end



@implementation ILobbyRemoteDirectory

+ (ILobbyRemoteDirectory *) parseDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)errorPtr {
	return [ILobbyRemoteDirectoryParser parseDirectoryAtURL:directoryURL error:errorPtr];
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithCapacity:100];
	[description appendFormat:@"location: %@\n", self.location.absoluteString];
	[description appendString:@"[\n"];
	for ( id<ILobbyRemoteDirectoryItem> item in self.items ) {
		[description appendFormat:@"\t%@\n", item];
	}
	[description appendString:@"]\n"];
	return [description copy];
}


- (BOOL)isDirectory {
	return YES;
}


@end



@interface ILobbyRemoteDirectoryParser () <NSXMLParserDelegate>
@property(copy, nonatomic) NSURL *directoryURL;

// an item may either be RemoteFile (ordinary file) or NSURL (subdirectory)
@property(nonatomic) NSMutableArray *items;

@property(copy, nonatomic) NSURL *currentFileLink;
@property(copy, nonatomic) NSString *currentFileLinkText;		// text of element sibling of the current anchor element being parsed
@end


@implementation ILobbyRemoteDirectoryParser

- (id)initWithDirectoryURL:(NSURL *)directoryURL {
    self = [super init];
    if (self) {
		self.directoryURL = directoryURL;
		self.items = [NSMutableArray new];
    }
    return self;
}


- (BOOL)isEmpty {
	return self.items.count == 0;
}


+ (ILobbyRemoteDirectory *) parseDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)errorPtr {
	ILobbyRemoteDirectory *remoteDirectory = [ILobbyRemoteDirectory new];
	remoteDirectory.location = directoryURL;

	NSError * __autoreleasing error;
	NSStringEncoding usedEncoding;
	NSString *rawDirectoryContents = [NSString stringWithContentsOfURL:directoryURL usedEncoding:&usedEncoding error:errorPtr];
//	printf( "\n------------------------------------------------\n" );
//	NSLog( @"Raw Directory Contents for %@:\n %@\n\n\n", directoryURL, rawDirectoryContents );
//	printf( "------------------------------------------------\n\n" );

	// if there was an error then propagate the error if necessary and return nil
	if ( error ) {
		if ( errorPtr ) {
			*errorPtr = error;
		}
		return nil;
	}
	else if ( rawDirectoryContents == nil || rawDirectoryContents.length == 0 ) {
		return remoteDirectory;		// return an empty directory
	}

	NSString *directoryContents = [rawDirectoryContents toXHTMLWithError:&error];
//	printf( "\n------------------------------------------------\n" );
//	NSLog( @"XHTML Directory Contents:\n %@\n\n\n", directoryContents );
//	printf( "------------------------------------------------\n\n" );
	if ( error ) {
		if ( errorPtr ) {
			*errorPtr = error;
		}
		return nil;
	}
	
	NSData *directoryData = [directoryContents dataUsingEncoding:NSUTF8StringEncoding];
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:directoryData];
	ILobbyRemoteDirectoryParser *directoryParser = [[ILobbyRemoteDirectoryParser alloc] initWithDirectoryURL:directoryURL];
	xmlParser.delegate = directoryParser;

	// if parsing succeeds construct the remote directory
	if ( [xmlParser parse] ) {
		// a remote item may either be a RemoteFile (ordinary file) or ILobbyRemoteDirectory (subdirectory)
		NSMutableArray *directoryItems = [NSMutableArray new];
		NSMutableArray *files = [NSMutableArray new];
		NSMutableArray *subdirectories = [NSMutableArray new];

		// pass files to remote directory and parse subdirectory URLs converting them to subdirectories and passing them on to the remote directory
		for ( id parserItem in directoryParser.items ) {
			if ( [parserItem isKindOfClass:[NSURL class]] ) {		// must be a subdirectory
				NSURL *subdirectoryURL = (NSURL *)parserItem;
				NSError * __autoreleasing subError;
				//NSLog( @"Parsing subdirectory URL: %@", subdirectoryURL );
				ILobbyRemoteDirectory *subdirectory = [ILobbyRemoteDirectory parseDirectoryAtURL:subdirectoryURL error:&subError];
				//NSLog( @"Subdirectory: %@", subdirectory );

				if ( subError )  NSLog( @"sub error: %@", subError );

				if ( subdirectory ) {
					[directoryItems addObject:subdirectory];
					[subdirectories addObject:subdirectory];
				}
			}
			else {		// ordinary file
				[directoryItems addObject:parserItem];
				[files addObject:parserItem];
			}
		}
		remoteDirectory.items = directoryItems;
		remoteDirectory.files = files;
		remoteDirectory.subdirectories = subdirectories;
	}
	else {
		if ( errorPtr ) {
			*errorPtr = xmlParser.parserError;
		}
		return nil;
	}


	return remoteDirectory;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	if ( [[elementName uppercaseString] isEqualToString:@"A"] ) {
		// convert all keys to uppercase so we can grab an attribute by key unambiguously
		NSMutableDictionary *anchorAttributes = [NSMutableDictionary new];
		for ( NSString *key in attributeDict.allKeys ) {
			anchorAttributes[key.uppercaseString] = attributeDict[key];
		}

		NSString *href = anchorAttributes[@"HREF"];
		if ( href ) {
			NSURL *anchorURL = [NSURL URLWithString:href relativeToURL:self.directoryURL];

			// reject query URLs
			if ( anchorURL.query ) {
				[self closeFileLinkInfo];
			}
			else {
				// test whether the referenced item is a direct child of the directory otherwise reject it
				if ( [[anchorURL.path stringByDeletingLastPathComponent] isEqualToString:self.directoryURL.path] ) {
					if ( [anchorURL.absoluteString hasSuffix:@"/"] ) {	// it is a directory
						[self closeFileLinkInfo];
						[self.items addObject:anchorURL];
					}
					else {
						self.currentFileLink = anchorURL;
					}
				}
				else {
					[self closeFileLinkInfo];
				}
			}
		}
	}
	else {
		// whenever a new element other than an anchor starts the anchor's sibling text node ends
		[self closeFileLinkInfo];
	}
}


- (void)closeFileLinkInfo {
	if ( self.currentFileLink ) {
		RemoteFile *remoteFile = [[RemoteFile alloc] initWithLocation:self.currentFileLink info:self.currentFileLinkText];
		[self.items addObject:remoteFile];
		self.currentFileLink = nil;
	}
	self.currentFileLinkText = nil;
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if ( self.currentFileLinkText ) {
		self.currentFileLinkText = [self.currentFileLinkText stringByAppendingString:string];
	}
	else {
		self.currentFileLinkText = string;
	}
}

@end
