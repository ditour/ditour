//
//  ILobbyGroupDetailPendingPresentationCell.h
//  iLobby
//
//  Created by Pelaia II, Tom on 3/25/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ILobbyGroupDetailPendingPresentationCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@end
