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
#import "ILobbyFileInfoController.h"



enum : NSInteger {
	SECTION_CONFIG,
	SECTION_TRACKS,
	SECTION_COUNT
};


static NSString *SEGUE_SHOW_ACTIVE_TRACK_DETAIL_ID = @"ShowActiveTrackDetail";
static NSString *SEGUE_SHOW_PENDING_TRACK_DETAIL_ID = @"ShowPendingTrackDetail";
static NSString *SEGUE_SHOW_FILE_INFO_ID = @"PresentationDetailShowFileInfo";
static NSString *SEGUE_SHOW_PENDING_FILE_INFO_ID = @"PresentationDetailShowPendingFileInfo";


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
		case SECTION_CONFIG:
			return self.presentation.configuration != nil ? 1 : 0;
		case SECTION_TRACKS:
			return self.presentation.tracks.count;

		default:
			break;
	}
    return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if ( [self tableView:tableView numberOfRowsInSection:section] > 0 ) {	// only display a section title if there are any rows to display
		switch ( section ) {
			case SECTION_CONFIG:
				return @"Configuration";

			case SECTION_TRACKS:
				return @"Tracks";

			default:
				return nil;
		}
	}
	else {
		return nil;
	}
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_CONFIG: case SECTION_TRACKS:
			return [self heightForRemoteItemAtIndexPath:indexPath];

		default:
			return [ILobbyLabelCell defaultHeight];
	}
}


- (CGFloat)heightForRemoteItemAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreRemoteItem *remoteItem = [self remoteItemAtIndexPath:indexPath];

	if ( [self isRemoteItemDownloading:remoteItem] ) {
		return [ILobbyDownloadStatusCell defaultHeight];
	}
	else {
		return [ILobbyLabelCell defaultHeight];
	}
}


- (BOOL)isRemoteItemDownloading:(ILobbyStoreRemoteItem *)remoteItem {
	if ( remoteItem.isReady ) {
		return NO;
	}
	else {
		ILobbyDownloadStatus *downloadStatus = [self.presentationDownloadStatus childStatusForRemoteItem:remoteItem];
		return downloadStatus != nil && !downloadStatus.completed ? YES : NO;
	}
}


- (ILobbyStoreRemoteItem *)remoteItemAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_CONFIG:
			return self.presentation.configuration;
			
		case SECTION_TRACKS:
			return self.presentation.tracks[indexPath.row];

		default:
			return nil;
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_CONFIG:
			return [self tableView:tableView configurationCellForRowAtIndexPath:indexPath];
			
		case SECTION_TRACKS:
			return [self tableView:tableView trackCellForRowAtIndexPath:indexPath];

		default:
			return nil;
	}

}


- (UITableViewCell *)tableView:(UITableView *)tableView trackCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreTrack *track = self.presentation.tracks[indexPath.row];

	if ( [self isRemoteItemDownloading:track] ) {
		return [self tableView:tableView pendingTrackCellForRowAtIndexPath:indexPath];
	}
	else {
		return [self tableView:tableView readyTrackCellForRowAtIndexPath:indexPath];
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
	
	if ( downloadStatus.error != nil ) {
		cell.subtitle = @"Failed";
	}
	else if ( downloadStatus.canceled ) {
		cell.subtitle = @"Canceled";
	}
	else {
		cell.subtitle = nil;
	}

	return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView configurationCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreConfiguration *configuration = self.presentation.configuration;

	if ( [self isRemoteItemDownloading:configuration] ) {
		return [self tableView:tableView pendingRemoteFileCellForRowAtIndexPath:indexPath];
	}
	else {
		return [self tableView:tableView readyRemoteFileCellForRowAtIndexPath:indexPath];
	}
}



- (UITableViewCell *)tableView:(UITableView *)tableView readyRemoteFileCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreRemoteFile *remoteFile = (ILobbyStoreRemoteFile *)[self remoteItemAtIndexPath:indexPath];

    ILobbyLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActiveFileCell" forIndexPath:indexPath];
	cell.title = remoteFile.name;

	return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView pendingRemoteFileCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreRemoteFile *remoteFile = (ILobbyStoreRemoteFile *)[self remoteItemAtIndexPath:indexPath];

    ILobbyDownloadStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PendingFileCell" forIndexPath:indexPath];

	ILobbyDownloadStatus *downloadStatus = [self.presentationDownloadStatus childStatusForRemoteItem:remoteFile];

	cell.downloadStatus = downloadStatus;
	cell.title = remoteFile.name;

	if ( downloadStatus.error != nil ) {
		cell.subtitle = @"Failed";
	}
	else if ( downloadStatus.canceled ) {
		cell.subtitle = @"Canceled";
	}
	else {
		cell.subtitle = nil;
	}

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
		case SECTION_TRACKS:
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
	else if ( [segueID isEqualToString:SEGUE_SHOW_FILE_INFO_ID] || [segueID isEqualToString:SEGUE_SHOW_PENDING_FILE_INFO_ID] ) {
		ILobbyStoreRemoteFile *remoteFile = (ILobbyStoreRemoteFile *)[self remoteItemAtIndexPath:self.tableView.indexPathForSelectedRow];
		ILobbyFileInfoController *fileInfoController = segue.destinationViewController;
		fileInfoController.lobbyModel = self.lobbyModel;
		fileInfoController.remoteFile = remoteFile;
		fileInfoController.downloadStatus = [self.presentationDownloadStatus childStatusForRemoteItem:remoteFile];
	}
    else {
        NSLog( @"SegueID: \"%@\" does not match a known ID in prepareForSegue method.", segueID );
    }
}


@end
