//
//  ILobbyPresentationDetailController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PresentationStore, DownloadContainerStatus, DitourModel;

@interface ILobbyPresentationDetailController : UITableViewController

@property (nonatomic) DitourModel *ditourModel;
@property (nonatomic, strong) PresentationStore *presentation;
@property (nonatomic, strong) DownloadContainerStatus *presentationDownloadStatus;

@end
