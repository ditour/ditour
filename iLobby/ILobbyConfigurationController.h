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
@property (weak, nonatomic) IBOutlet UISwitch *staleDownloadSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *delayInstallSwitch;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelDownloadButton;

@property (nonatomic, strong) ILobbyModel *lobbyModel;

- (IBAction)downloadPresentation:(id)sender;
- (IBAction)cancelPresentationDownload:(id)sender;

- (IBAction)delayInstallSwitchChanged:(id)sender;
- (IBAction)presentationLocationChanged:(id)sender;

@end
