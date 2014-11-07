//
//  DiTourTidyWrapper.m
//  DiTour
//
//  Created by Pelaia II, Tom on 11/6/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "DiTourTidyWrapper.h"

#include <stdio.h>
#include <errno.h>

// the project (see the build settings) adds the Mac's /usr/include/tidy to the header search path to pickup
// these two tidy headers which are included in the iOS Simulator SDK but not the iOS iPhone SDK
#include <tidy.h>
#include <buffio.h>


@implementation NSString (TidyAdditions)

// Convert raw HTML to XHTML based on example code at: http://tidy.sourceforge.net/libintro.html#example
- (NSString *)toXHTMLWithError:(NSError * __autoreleasing *)errorPtr {
	if ( self.length == 0 )  return nil;	// no content to process so no valid XHTML possible

	const char* input = [self UTF8String];

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

	short success = ok == 1 && returnCode >= 0;

	unsigned outputSize;
	char *outbuffer = nil;
	if ( success ) {
		outputSize = 0;
		returnCode = tidySaveString( tdoc, nil, &outputSize );			// need this to get the output size

		if ( returnCode == -ENOMEM ) {
			outbuffer = (char *)malloc( outputSize + 1 );
			outbuffer[outputSize] = '\0';			// terminate the string with a null character
			returnCode = tidySaveString( tdoc, outbuffer, &outputSize );
		}
		else {
			NSLog( @"Tidy error with return code: %d", returnCode );
			success = 0;
		}
	}
	else {
		NSLog( @"Tidy error with return code: %d", returnCode );
	}

	NSString *outputXHTML = nil;
	if ( success ) {
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
