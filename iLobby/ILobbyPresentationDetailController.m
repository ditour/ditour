//
//  ILobbyPresentationDetailController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/17/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresentationDetailController.h"
#import "ILobbyDownloadStatusCell.h"
#import "ILobbyLabelCell.h"
#import "ILobbyTrackDetailController.h"



enum : NSInteger {
	SECTION_TRACKS_VIEW,
	SECTION_COUNT
};


static NSString *SEGUE_SHOW_ACTIVE_TRACK_DETAIL_ID = @"ShowActiveTrackDetail";
static NSString *SEGUE_SHOW_PENDING_TRACK_DETAIL_ID = @"ShowPendingTrackDetail";


@interface ILobbyPresentationDetailController () <ILobbyDownloadStatusDelegate>

// TODO: add property for configuration

@property (nonatomic, weak) IBOutlet UISwitch *defaultPresentationSwitch;

@end



@implementation ILobbyPresentationDetailController {
	BOOL _updateScheduled;		// indicates whether an update has been scheduled
}


- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)setPresentationDownloadStatus:(ILobbyDownloadContainerStatus *)presentationDownloadStatus {
	_presentationDownloadStatus = presentationDownloadStatus;
	presentationDownloadStatus.delegate = self;
	_updateScheduled = NO;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Now Playing" style:UIBarButtonItemStyleDone target:self action:@selector(popToPlaying)];

	self.title = [NSString stringWithFormat:@"Presentation: %@", self.presentation.name];
	[self updateView];
}


- (void)popToPlaying {
	[self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	// allow updates to be scheduled immediately
	_updateScheduled = NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
			[self.tableView reloadData];
		});
	}
}


- (IBAction)changeDefaultPresentation:(id)sender {
	self.presentation.current = self.defaultPresentationSwitch.on;
	[self.lobbyModel saveChanges:nil];
	[self.lobbyModel reloadPresentation];
}


- (void)updateView {
	_updateScheduled = NO;	// allow another update to be scheduled since we will begin processing the current one

	[self.tableView reloadData];

	self.defaultPresentationSwitch.on = self.presentation.isCurrent;
	self.defaultPresentationSwitch.enabled = self.presentation.isReady;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return SECTION_COUNT;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

	switch ( section ) {
		case SECTION_TRACKS_VIEW:
			return self.presentation.tracks.count;

		default:
			break;
	}
    return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_TRACKS_VIEW:
			return [self estimateHeightForTrackAtIndexPath:indexPath];

		default:
			return [ILobbyLabelCell defaultHeight];
	}
}


- (CGFloat)estimateHeightForTrackAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreTrack *track = self.presentation.tracks[indexPath.row];

	if ( track.isReady ) {
		return [ILobbyLabelCell defaultHeight];
	}
	else {
		return [ILobbyDownloadStatusCell defaultHeight];
	}

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_TRACKS_VIEW:
			return [self tableView:tableView trackCellForRowAtIndexPath:indexPath];
			break;

		default:
			return nil;
	}

}


- (UITableViewCell *)tableView:(UITableView *)tableView trackCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreTrack *track = self.presentation.tracks[indexPath.row];

	if ( track.isReady ) {
		return [self tableView:tableView readyTrackCellForRowAtIndexPath:indexPath];
	}
	else {
		return [self tableView:tableView pendingTrackCellForRowAtIndexPath:indexPath];
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView readyTrackCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreTrack *track = self.presentation.tracks[indexPath.row];

    ILobbyLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PresentationDetailActiveTrackCell" forIndexPath:indexPath];
	cell.title = track.title;

	return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView pendingTrackCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreTrack *track = self.presentation.tracks[indexPath.row];

    ILobbyDownloadStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PresentationDetailPendingTrackCell" forIndexPath:indexPath];

	ILobbyDownloadStatus *downloadStatus = [self.presentationDownloadStatus childStatusForRemoteItem:track];
	//NSLog( @"Track: %@, Ready: %@, Download status: %@, Pointer: %@, Context: %@", track.title, track.status, downloadStatus, track, track.managedObjectContext );

	cell.downloadStatus = downloadStatus;
	cell.title = track.title;

	return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation


- (ILobbyStoreTrack *)trackAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_TRACKS_VIEW:
			return self.presentation.tracks[indexPath.row];

		default:
			break;
	}

	return nil;
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	NSString *segueID = [segue identifier];

    if ( [segueID isEqualToString:SEGUE_SHOW_ACTIVE_TRACK_DETAIL_ID] || [segueID isEqualToString:SEGUE_SHOW_PENDING_TRACK_DETAIL_ID] ) {
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		ILobbyStoreTrack *track = [self trackAtIndexPath:indexPath];

		ILobbyTrackDetailController *trackController = segue.destinationViewController;
		trackController.lobbyModel = self.lobbyModel;
		trackController.track = track;

		if ( [segueID isEqualToString:SEGUE_SHOW_PENDING_TRACK_DETAIL_ID] ) {
			ILobbyDownloadContainerStatus *downloadStatus = (ILobbyDownloadContainerStatus *)[self.presentationDownloadStatus childStatusForRemoteItem:track];
			trackController.trackDownloadStatus = downloadStatus;
		}
    }
    else {
        NSLog( @"SegueID: \"%@\" does not match a known ID in prepareForSegue method.", segueID );
    }
}


@end
