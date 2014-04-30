//
//  ILobbyLabelCell.h
//  iLobby
//
//  Created by Pelaia II, Tom on 4/24/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ILobbyLabelCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;

+ (CGFloat)defaultHeight;

- (void)setTitle:(NSString *)title;
- (void)setSubtitle:(NSString *)subtitle;

@end
