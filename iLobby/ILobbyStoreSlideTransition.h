//
//  ILobbyStoreSlideTransition.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ILobbyStoreConfiguration;

@interface ILobbyStoreSlideTransition : NSManagedObject

// attributes
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * subType;
@property (nonatomic, retain) NSString * type;

// relationships
@property (nonatomic, retain) ILobbyStoreConfiguration *configuration;

+ (instancetype)insertNewSlideConfigurationInContext:(NSManagedObjectContext *)managedObjectContext;

@end
