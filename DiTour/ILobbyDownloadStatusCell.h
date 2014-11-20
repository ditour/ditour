//
//  ILobbyDownloadStatusCell.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/24/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ILobbyLabelCell.h"
#import "ILobbyDownloadStatus.h"

@class DownloadStatus;


@interface ILobbyDownloadStatusCell : ILobbyLabelCell

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *progressLabel;

- (void)setDownloadStatus:(DownloadStatus *)status;

@end
