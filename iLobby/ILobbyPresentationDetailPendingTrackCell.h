//
//  ILobbyPresentationDetailPendingTrackCell.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILobbyPresentationDetailActiveTrackCell.h"

@interface ILobbyPresentationDetailPendingTrackCell : ILobbyPresentationDetailActiveTrackCell

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

- (void)setDownloadProgress:(float)progress;

@end
