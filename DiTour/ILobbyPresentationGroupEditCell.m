//
//  ILobbyPresentationGroupEditCell.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/13/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresentationGroupEditCell.h"


@interface ILobbyPresentationGroupEditCell () <UITextFieldDelegate>

@end



@implementation ILobbyPresentationGroupEditCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)awakeFromNib {
    // Initialization code
	self.locationField.delegate = self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if ( self.doneHandler ) {
		self.doneHandler( self, textField.text );
	}

	[textField resignFirstResponder];

	return YES;
}

@end
