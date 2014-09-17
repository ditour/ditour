//
//  ILobbyFileInfoController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/29/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

@import QuickLook;

#import "ILobbyFileInfoController.h"


@interface ILobbyFileInfoController () <ILobbyDownloadStatusDelegate, QLPreviewItem, QLPreviewControllerDataSource>

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UIButton *previewButton;

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *progressLabel;

@property (nonatomic, weak) IBOutlet UITextView *infoView;

@end


static NSNumberFormatter *PROGRESS_FORMAT = nil;


@implementation ILobbyFileInfoController {
	BOOL _updateScheduled;		// indicates whether an update has been scheduled
}


+ (void)initialize {
	if ( self == [ILobbyFileInfoController class] ) {
		PROGRESS_FORMAT = [NSNumberFormatter new];
		PROGRESS_FORMAT.numberStyle = NSNumberFormatterPercentStyle;
		PROGRESS_FORMAT.minimumFractionDigits = 2;
		PROGRESS_FORMAT.maximumFractionDigits = 2;
	}
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)setDownloadStatus:(ILobbyDownloadStatus *)downloadStatus {
	if ( downloadStatus ) {
		downloadStatus.delegate = self;
	}

	_downloadStatus = downloadStatus;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Now Playing" style:UIBarButtonItemStyleDone target:self action:@selector(popToPlaying)];

	self.nameLabel.text = self.remoteFile.name;

	if ( self.downloadStatus == nil	) {
		self.progressLabel.hidden = YES;
		self.progressView.hidden = YES;
	}

	self.previewButton.hidden = ![self canPreview];

	[self updateView];
}


// the download state has changed (can be called at a very high frequency)
- (void)downloadStatusChanged:(ILobbyDownloadStatus *)status {
	// throttle the updates to dramatically lower CPU load and reduce backlog of events
	if ( !_updateScheduled ) {		// skip if an update has already been scheduled since the display will be refreshed
		_updateScheduled = YES;		// indicate that an update will be scheduled

		static dispatch_time_t nanoSecondDelay = 1000 * 1000 * 1000 * 0.25;	// refresh the display at most every 0.25 seconds
		dispatch_time_t runTime = dispatch_time( DISPATCH_TIME_NOW, nanoSecondDelay );
		dispatch_after( runTime, dispatch_get_main_queue(), ^{
			_updateScheduled = NO;	// allow another update to be scheduled since we will begin processing the current one
			[self updateView];
		});
	}
}


- (void)updateView {
	if ( self.downloadStatus != nil	) {
		float progress = self.downloadStatus.progress;

		self.progressView.progress = progress;
		self.progressLabel.text = [PROGRESS_FORMAT stringFromNumber:@( progress )];

		if ( progress == 1.0 ) {
			self.progressView.hidden = YES;
		}

		self.previewButton.hidden = ![self canPreview];
	}

	self.infoView.text = self.remoteFile.summary;
}


- (void)popToPlaying {
	[self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Preview

- (BOOL)canPreview {
	if ( self.remoteFile.absolutePath != nil ) {
		if ( [[NSFileManager defaultManager] fileExistsAtPath:self.remoteFile.absolutePath] ) {
			return [QLPreviewController canPreviewItem:self];
		}
		else {
			return NO;
		}
	}
	else {
		return NO;
	}
}


- (NSString *)previewItemTitle {
	return self.remoteFile.name;
}


- (NSURL *)previewItemURL {
	return [NSURL fileURLWithPath:self.remoteFile.absolutePath];
}


- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
	return 1;
}


- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
	return self;
}


- (IBAction)displayPreview:(id)sender {
	QLPreviewController *previewController = [QLPreviewController new];
	previewController.dataSource = self;
	[self presentViewController:previewController animated:YES completion:nil];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
