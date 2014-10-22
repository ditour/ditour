//
//  ILobbyPresentationDetailController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ILobbyStorePresentation.h"
#import "ILobbyDownloadStatus.h"
#import "DiTour-Swift.h"


@interface ILobbyPresentationDetailController : UITableViewController <DitourModelContainer>

@property (nonatomic, weak) DitourModel *ditourModel;
@property (nonatomic, strong) ILobbyStorePresentation *presentation;
@property (nonatomic, strong) ILobbyDownloadContainerStatus *presentationDownloadStatus;

@end
