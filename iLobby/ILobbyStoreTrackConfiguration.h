//
//  ILobbyStoreTrackConfiguration.h
//  iLobby
//
//  Created by Pelaia II, Tom on 11/20/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class ILobbyStoreConfiguration;


@interface ILobbyStoreTrackConfiguration : NSManagedObject

@property (nonatomic, retain) NSNumber * slideDuration;
@property (nonatomic, retain) NSNumber * trackChangeDelay;

@property (nonatomic, retain) ILobbyStoreConfiguration *configuration;
@end



// custom additions
@interface ILobbyStoreTrackConfiguration ()

+ (instancetype)insertNewtrackConfigurationInContext:(NSManagedObjectContext *)managedObjectContext;
@end