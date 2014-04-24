//
//  ILobbyDownloadStatusCell.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/24/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyDownloadStatusCell.h"

@implementation ILobbyDownloadStatusCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)awakeFromNib {
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



+ (CGFloat)defaultHeight {
	return 68;
}


- (void)setDownloadStatus:(ILobbyDownloadStatus *)status {
	self.progressView.progress = status != nil ? status.progress : 0.0;
}

@end
