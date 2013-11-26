//
//  ILobbyStoreSlideTransition.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ILobbyStoreTrackConfiguration;

@interface ILobbyStoreSlideTransition : NSManagedObject

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * subType;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) ILobbyStoreTrackConfiguration *configuration;

+ (instancetype)insertNewtrackConfigurationInContext:(NSManagedObjectContext *)managedObjectContext;

@end
