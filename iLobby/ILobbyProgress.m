//
//  ILobbyProgress.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyProgress.h"

@interface ILobbyProgress ()
@property (readwrite) float fraction;
@property (readwrite, copy) NSString *label;
@end

@implementation ILobbyProgress

- (id)initWithFraction:(float)fraction label:(NSString *)label {
    self = [super init];
    if (self) {
        self.fraction = fraction;
		self.label = label;
    }
    return self;
}


+ (id)progressWithFraction:(float)fraction label:(NSString *)label {
	return [[ILobbyProgress alloc] initWithFraction:fraction label:label];
}

@end
