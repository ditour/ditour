//
//  ILobbyConcurrentDictionary.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/4/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>


// Mutable dictionary that is safe for concurrent modifications
@interface ILobbyConcurrentDictionary : NSObject

- (id)objectForKey:(id<NSCopying>)key;
- (id)objectForKeyedSubscript:(id<NSCopying>)key;

- (void)setObject:(id)item forKey:(id<NSCopying>)key;
- (void)setObject:(id)item forKeyedSubscript:(id<NSCopying>)key;

- (void)removeObjectForKey:(id<NSCopying>)key;

@end
