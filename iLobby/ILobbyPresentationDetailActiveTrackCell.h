//
//  ILobbyPresentationDetailActiveTrackCell.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ILobbyPresentationDetailActiveTrackCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

- (void)setTitle:(NSString *)label;

@end
