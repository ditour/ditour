//
//  ILobbyConfigurationController.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ILobbyModel.h"

@interface ILobbyConfigurationController : UIViewController

@property (nonatomic, weak) IBOutlet UITextField *presentationLocationField;
@property (nonatomic, weak) IBOutlet UILabel *downloadProgressLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *downloadProgressView;

@property (nonatomic, strong) ILobbyModel *lobbyModel;

- (IBAction)downloadFullPresentation:(id)sender;
- (IBAction)downloadPresentationUpdates:(id)sender;
- (IBAction)cancelPresentationDownload:(id)sender;

- (IBAction)presentationLocationChanged:(id)sender;

@end
