//
//  ILobbyViewController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

@import UIKit;
#import "ILobbyModelContainer.h"

@class MainModel;


@interface ILobbyViewController : UICollectionViewController <ILobbyModelContainer>

@property (nonatomic, strong) MainModel *lobbyModel;

- (IBAction)reloadPresentation:(id)sender;

@end
