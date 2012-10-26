//
//  ILobbyProgress.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILobbyProgress : NSObject

@property (readonly) float fraction;
@property (readonly, copy) NSString *label;

- (id)initWithFraction:(float)fraction label:(NSString *)label;
+ (id)progressWithFraction:(float)fraction label:(NSString *)label;

@end
