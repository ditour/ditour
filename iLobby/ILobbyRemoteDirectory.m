//
//  ILobbyRemoteDirectoryInfo.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/31/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyRemoteDirectory.h"
#import "ILobbyRemoteFile.h"

#include <stdio.h>
#include <errno.h>

#include "tidy/tidy.h"
#include "tidy/buffio.h"


@interface ILobbyRemoteDirectory ()
@property(readwrite) NSURL *location;			// URL location for this directory
@property(readwrite) NSArray *items;	// array of ILobbyRemoteDirectoryItem (files and subdirectories)
@end



@interface ILobbyRemoteDirectoryParser : NSObject <NSXMLParserDelegate>
+ (ILobbyRemoteDirectory *)parseDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)errorPtr;
@end



@implementation ILobbyRemoteDirectory

+ (ILobbyRemoteDirectory *) parseDirectoryAtURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)errorPtr {
	return [ILobbyRemoteDirectoryParser parseDirectoryAtURL:directoryURL error:errorPtr];
}


- (NSString *)description {
	return [NSString stringWithFormat:@"{ location: %@, items: %@ }", self.location.absoluteString, self.items ];
}

@end



@interface ILobbyRemoteDirectoryParser () <NSXMLParserDelegate>
@property(copy, nonatomic) NSURL *directoryURL;

// an item may either be ILobbyRemoteFile (ordinary file) or NSURL (subdirectory)
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
	NSLog( @"Raw Directory Contents for %@:\n %@\n\n\n", directoryURL, rawDirectoryContents );

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

	NSString *directoryContents = [self toXHTML:rawDirectoryContents error:&error];
	NSLog( @"Directory Contents:\n %@\n\n\n", directoryContents );
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
		// a remote item may either be a ILobbyRemoteFile (ordinary file) or ILobbyRemoteDirectory (subdirectory)
		NSMutableArray *directoryItems = [NSMutableArray new];

		// pass files to remote directory and parse subdirectory URLs converting them to subdirectories and passing them on to the remote directory
		for ( id parserItem in directoryParser.items ) {
			if ( [parserItem isKindOfClass:[NSURL class]] ) {		// must be a subdirectory
				NSURL *subdirectoryURL = (NSURL *)parserItem;
				NSError *subError;
				NSLog( @"Parsing subdirectory URL: %@", subdirectoryURL );
				ILobbyRemoteDirectory *subdirectory = [ILobbyRemoteDirectory parseDirectoryAtURL:subdirectoryURL error:&subError];
				NSLog( @"Subdirectory: %@", subdirectory );
				if ( subError )  NSLog( @"sub error: %@", subError );
				if ( subdirectory )  [directoryItems addObject:subdirectory];
			}
			else {		// ordinary file
				[directoryItems addObject:parserItem];
			}
		}
		remoteDirectory.items = directoryItems;
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
		ILobbyRemoteFile *remoteFile = [[ILobbyRemoteFile alloc] initWithLocation:self.currentFileLink info:self.currentFileLinkText];
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


// Convert raw HTML to XHTML based on example code at: http://tidy.sourceforge.net/libintro.html#example
+ (NSString *)toXHTML:(NSString *)rawHTML error:(NSError * __autoreleasing *)errorPtr {
	const char* input = [rawHTML UTF8String];

	TidyBuffer output = {0};
	TidyBuffer errbuf = {0};
	int returnCode = -1;
	Bool ok;

	TidyDoc tdoc = tidyCreate();                     // Initialize "document"
	//	printf( "Tidying:\t%s\n", input );

	ok = tidyOptSetBool( tdoc, TidyXhtmlOut, yes );  // Convert to XHTML
	if ( ok )
		returnCode = tidySetErrorBuffer( tdoc, &errbuf );      // Capture diagnostics
	if ( returnCode >= 0 )
		returnCode = tidyParseString( tdoc, input );           // Parse the input
	if ( returnCode >= 0 )
		returnCode = tidyCleanAndRepair( tdoc );               // Tidy it up!
	if ( returnCode >= 0 )
		returnCode = tidyRunDiagnostics( tdoc );               // Kvetch
	if ( returnCode > 1 )                                    // If error, force output.
		returnCode = ( tidyOptSetBool(tdoc, TidyForceOutput, yes) ? returnCode : -1 );
	if ( returnCode >= 0 )
		returnCode = tidySaveBuffer( tdoc, &output );          // Pretty Print

	unsigned outputSize;
	char *outbuffer = nil;
	if ( returnCode >= 0 ) {
		outputSize = 0;
		returnCode = tidySaveString( tdoc, nil, &outputSize );			// need this to get the output size
		outbuffer = (char *)malloc( outputSize + 1 );
		returnCode = tidySaveString( tdoc, outbuffer, &outputSize );
	}
	else {
		NSLog( @"Error with return code: %d", returnCode );
	}

	NSString *outputXHTML = nil;
	if ( returnCode >= 0 ) {
//		NSLog( @"Output size: %u, output length: %lu", outputSize, (unsigned long)strlen(outbuffer) );
		// need to be careful as the outbuffer is not null terminated and so we must make sure to only copy the characters specified by the output size
		outputXHTML = [[NSString alloc] initWithBytes:outbuffer length:outputSize encoding:NSUTF8StringEncoding];
	}
	else if ( errorPtr ) {
		*errorPtr = [NSError errorWithDomain:@"Tidy XML processing error" code:returnCode userInfo:nil];
	}
	if ( outbuffer )  free( outbuffer );
	
	tidyBufFree( &output );
	tidyBufFree( &errbuf );
	tidyRelease( tdoc );

	return outputXHTML;
}

@end
