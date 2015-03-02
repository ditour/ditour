//
//  TidyWrapper.h
//  DiTour
//
//  Created by Pelaia II, Tom on 3/2/15.
//  Copyright (c) 2015 UT-Battelle ORNL. All rights reserved.
//

#ifndef __DiTour__TidyWrapper__
#define __DiTour__TidyWrapper__

/* 
 Convert the raw HTML to proper XHTML using the tidy library.
 Returns a pointer to the XHTML buffer which the caller owns and is responsible for freeing. 
 */
char *ConvertC_HTML_TO_XHTML(const char *rawHTML);

#endif /* defined(__DiTour__TidyWrapper__) */
