//
//  ILobbyTrackViewCell.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

@import UIKit;

@interface ILobbyTrackViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *label;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@property (nonatomic) BOOL outlined;

@end
