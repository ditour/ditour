//
//  ILobbyPresentationMasterTableController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/18/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>


@class DitourModel, PresentationGroupStore;


@interface ILobbyPresentationGroupDetailController : UITableViewController

@property (nonatomic, readwrite) DitourModel *ditourModel;
@property (nonatomic, readwrite) PresentationGroupStore *group;

@end
