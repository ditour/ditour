//
//  ILobbyModelContainer.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/12/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILobbyModel.h"

@class MainModel;


@protocol ILobbyModelContainer <NSObject>

- (MainModel *)lobbyModel;
- (void)setLobbyModel:(MainModel *)model;

@end
