//
//  ILobbyViewController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

@import UIKit;
#import "ILobbyModelContainer.h"

@interface ILobbyViewController : UICollectionViewController <ILobbyModelContainer>

@property (nonatomic, strong) ILobbyModel *lobbyModel;

- (IBAction)reloadPresentation:(id)sender;

@end
