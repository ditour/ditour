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
	int returnCode = -1;

	// create the tidy document
	TidyDoc tidyDocument = tidyCreate();

	// configure the tidy options: generate XHTML
	short success = tidyOptSetBool( tidyDocument, TidyXhtmlOut, yes ) == 1;

	// parse the input
	if ( success )  returnCode = tidyParseString( tidyDocument, input );

	// attempt to cleanup and repair HTML
	if ( returnCode >= 0 )  returnCode = tidyCleanAndRepair( tidyDocument );

	// save the document to the output buffer
	if ( returnCode >= 0 )  returnCode = tidySaveBuffer( tidyDocument, &output );

	success = success && returnCode >= 0;

	// write the Tidy Buffer data to outbuffer which is a simple character buffer
	unsigned outputSize = 0;
	char *outbuffer = NULL;
	if ( success ) {
		outputSize = 0;
		returnCode = tidySaveString( tidyDocument, NULL, &outputSize );			// need this to get the output size (should return error since buffer not yet allocated)

		// now that we know the outputSize, really save the save string
		if ( returnCode == -ENOMEM ) {		// we expect this error since we haven't allocated any space to our buffer yet
			outbuffer = (char *)malloc( outputSize + 1 );
			outbuffer[outputSize] = '\0';			// terminate the string with a null character
			printf("outputSize: %d, buffer size: %d", outputSize, output.size);
			returnCode = tidySaveString( tidyDocument, outbuffer, &outputSize );
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
	tidyRelease( tidyDocument );

	return outputXHTML;
}



