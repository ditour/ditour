//
//  TidyWrapper.c
//  DiTour
//
//  Created by Pelaia II, Tom on 3/2/15.
//  Copyright (c) 2015 UT-Battelle ORNL. All rights reserved.
//

#include "TidyWrapper.h"

#include <stdio.h>
#include <errno.h>

// the project (see the build settings) adds the Mac's /usr/include/tidy to the header search path to pickup
// these two tidy headers which are included in the iOS Simulator SDK but not the iOS iPhone SDK
#include <tidy.h>
#include <buffio.h>


/*
 Convert the raw HTML to proper XHTML using the tidy library.
 Returns a pointer to the XHTML buffer which the caller owns and is responsible for freeing.
 */
char *ConvertC_HTML_TO_XHTML(const char *input) {
	if ( input == NULL || strlen(input) == 0 )  return NULL;	// no content to process so no valid XHTML possible

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

	unsigned outputSize = 0;
	char *outbuffer = NULL;
	if ( success ) {
		outputSize = 0;
		returnCode = tidySaveString( tdoc, NULL, &outputSize );			// need this to get the output size

		if ( returnCode == -ENOMEM ) {
			outbuffer = (char *)malloc( outputSize + 1 );
			outbuffer[outputSize] = '\0';			// terminate the string with a null character
			returnCode = tidySaveString( tdoc, outbuffer, &outputSize );
		}
		else {
			printf( "Tidy error with return code: %d", returnCode );
			success = 0;
		}
	}
	else {
		printf( "Tidy error with return code: %d", returnCode );
	}

	// buffer to hold output XHTML plus null termination character
	char *outputXHTML = NULL;
	if ( success && outputSize > 0 ) {
		// need to be careful as the outbuffer is not null terminated and so we must make sure to only copy the characters specified by the output size
		outputXHTML = (char *)malloc( outputSize + 1 );		// this pointer must be freed by the caller
		memcpy( outputXHTML, outbuffer, outputSize );
		outputXHTML[outputSize] = NULL;		// NULL termination
	}
	
	if ( outbuffer )  free( outbuffer );

	tidyBufFree( &output );
	tidyBufFree( &errbuf );
	tidyRelease( tdoc );

	return outputXHTML;
}



