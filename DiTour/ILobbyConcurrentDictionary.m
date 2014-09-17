//
//  ILobbyConcurrentDictionary.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/4/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyConcurrentDictionary.h"


@interface ILobbyConcurrentDictionary ()

@property NSMutableDictionary *store;
@property dispatch_queue_t queue;

@end



@implementation ILobbyConcurrentDictionary


- (instancetype)init {
    self = [super init];
    if (self) {
        self.store = [NSMutableDictionary new];

		// queue modfications using a barrier and allow concurrent read operations
		self.queue = dispatch_queue_create( "dictionary access", DISPATCH_QUEUE_CONCURRENT );
    }
    return self;
}


- (NSDictionary *)dictionary {
	__block NSDictionary *dictionary = nil;

	dispatch_sync( self.queue, ^{
		dictionary = [self.store copy];
	});

	return dictionary;
}


- (NSInteger)count {
	__block NSInteger count = 0;
	dispatch_sync( self.queue, ^{
		count = self.store.count;
	});

	return count;
}


- (id)objectForKey:(id<NSCopying>)key {
	__block id value = nil;
	dispatch_sync( self.queue, ^{
		value = [self.store objectForKey:key];
	});

	return value;
}


- (id)objectForKeyedSubscript:(id<NSCopying>)key {
	return [self objectForKey:key];
}


- (void)setObject:(id)item forKey:(id<NSCopying>)key {
	dispatch_barrier_async( self.queue, ^{
		[self.store setObject:item forKey:key];
	});
}


- (void)setObject:(id)item forKeyedSubscript:(id<NSCopying>)key {
	[self setObject:item forKey:key];
}


- (void)removeObjectForKey:(id<NSCopying>)key {
	dispatch_barrier_async( self.queue, ^{
		[self.store removeObjectForKey:key];
	});
}

@end
