//
//  ILobbyPresenter.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/19/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ILobbyModel.h"

@interface ILobbyPresenter : NSObject <ILobbyPresentationDelegate>

@property (strong, nonatomic) UIWindow *externalWindow;

- (void)updateConfiguration;

@end
