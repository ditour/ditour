//
//  ILobbyDownloadStatusCell.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/24/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyDownloadStatusCell.h"
#import "DiTour-Swift.h"


static NSNumberFormatter *PROGRESS_FORMAT = nil;


@implementation ILobbyDownloadStatusCell


+ (void)initialize {
	if ( self == [ILobbyDownloadStatusCell class] ) {
		PROGRESS_FORMAT = [NSNumberFormatter new];
		PROGRESS_FORMAT.numberStyle = NSNumberFormatterPercentStyle;
		PROGRESS_FORMAT.minimumFractionDigits = 2;
		PROGRESS_FORMAT.maximumFractionDigits = 2;
	}
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)awakeFromNib {
    // Initialization code
	[super awakeFromNib];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



+ (CGFloat)defaultHeight {
	return 68;
}


- (void)setDownloadStatus:(DownloadStatus *)status {
	float progress = status != nil ? status.progress : 0.0;

	self.progressView.progress = progress;
	self.progressLabel.text = [PROGRESS_FORMAT stringFromNumber:@(progress)];
}

@end
