//
//  ILobbyPresentationMasterTableController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/18/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ILobbyModelContainer.h"
#import "ILobbyStorePresentationGroup.h"


@interface ILobbyPresentationGroupDetailController : UITableViewController <ILobbyModelContainer>

@property (nonatomic, readwrite) ILobbyModel *lobbyModel;
@property (nonatomic, readwrite) ILobbyStorePresentationGroup *group;

@end
