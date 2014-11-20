//
//  ILobbyFileInfoController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/29/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ILobbyDownloadStatus.h"
#import "DiTour-Swift.h"


@interface ILobbyFileInfoController : UIViewController <DitourModelContainer>

@property (nonatomic, strong) RemoteFileStore *remoteFile;
@property (nonatomic, strong) DownloadStatus *downloadStatus;
@property (nonatomic, readwrite, strong) DitourModel *ditourModel;

@end
