//
//  DiTourTidyWrapper.h
//  DiTour
//
//  Created by Pelaia II, Tom on 11/6/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>


/* wraps the Tidy C-calls due to conflict with Swift Bool in buffio.h */
@interface NSString (TidyAdditions)

/* convert the raw HTML to proper XHTML using the tidy library */
- (NSString *)toXHTMLWithError:(NSError * __autoreleasing *)errorPtr;

@end
