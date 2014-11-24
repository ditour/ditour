//
//  ILobbyTrackDetailController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/24/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyTrackDetailController.h"
#import "DiTour-Swift.h"



enum : NSInteger {
	SECTION_CONFIG,
	SECTION_REMOTE_MEDIA,
	SECTION_COUNT
};


static NSString *SEGUE_SHOW_FILE_INFO_ID = @"TrackDetailShowFileInfo";
static NSString *SEGUE_SHOW_PENDING_FILE_INFO_ID = @"TrackDetailShowPendingFileInfo";


@interface ILobbyTrackDetailController () <DownloadStatusDelegate>

@end


@implementation ILobbyTrackDetailController {
	BOOL _updateScheduled;		// indicates whether an update has been scheduled
	__weak DitourModel *_ditourModel;	// model ivar specified directly to avoid warning against Swift protocol since we want it to be weak here
}


- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


// get the underlying ditour model (needed due to weak Objective-C ivar and Swift protocol)
- (DitourModel *)ditourModel {
	return _ditourModel;
}


// set the ditour model (needed due to weak Objective-C ivar and Swift protocol)
- (void)setDitourModel:(DitourModel *)ditourModel {
	_ditourModel = ditourModel;
}


- (void)setTrackDownloadStatus:(DownloadContainerStatus *)trackDownloadStatus {
	_trackDownloadStatus = trackDownloadStatus;
	trackDownloadStatus.delegate = self;
	_updateScheduled = NO;
}


- (void)viewDidLoad {
    [super viewDidLoad];

	_updateScheduled = NO;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Now Playing" style:UIBarButtonItemStyleDone target:self action:@selector(popToPlaying)];

	self.title = [NSString stringWithFormat:@"Track: %@", self.track.title];
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
- (void)downloadStatusChanged:(DownloadStatus *)status {
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return SECTION_COUNT;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if ( [self tableView:tableView numberOfRowsInSection:section] > 0 ) {	// only display a section title if there are any rows to display
		switch ( section ) {
			case SECTION_CONFIG:
				return @"Configuration";

			case SECTION_REMOTE_MEDIA:
				return @"Media";

			default:
				return nil;
		}
	}
	else {
		return nil;
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

	switch ( section) {
		case SECTION_CONFIG:
			return self.track.configuration != nil ? 1 : 0;
			
		case SECTION_REMOTE_MEDIA:
			return self.track.remoteMedia.count;

		default:
			break;
	}

    return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_CONFIG: case SECTION_REMOTE_MEDIA:
			return [self heightForRemoteItemAtIndexPath:indexPath];

		default:
			return [LabelCell defaultHeight];
	}
}


- (CGFloat)heightForRemoteItemAtIndexPath:(NSIndexPath *)indexPath {
	RemoteItemStore *remoteItem = [self remoteItemAtIndexPath:indexPath];

	if ( [self isRemoteItemDownloading:remoteItem] ) {
		return [DownloadStatusCell defaultHeight];
	}
	else {
		return [LabelCell defaultHeight];
	}
}


- (BOOL)isRemoteItemDownloading:(RemoteItemStore *)remoteItem {
	if ( remoteItem.isReady ) {
		return NO;
	}
	else {
		DownloadStatus *downloadStatus = [self.trackDownloadStatus childStatusForRemoteItem:remoteItem];
		return downloadStatus != nil && !downloadStatus.completed ? YES : NO;
	}
}


- (RemoteItemStore *)remoteItemAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_CONFIG:
			return self.track.configuration;

		case SECTION_REMOTE_MEDIA:
			return self.track.remoteMedia[indexPath.row];

		default:
			return nil;
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_CONFIG:
			return [self tableView:tableView configurationCellForRowAtIndexPath:indexPath];

		case SECTION_REMOTE_MEDIA:
			return [self tableView:tableView remoteMediaCellForRowAtIndexPath:indexPath];

		default:
			return nil;
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView remoteMediaCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	RemoteMediaStore *media = self.track.remoteMedia[indexPath.row];

	if ( [self isRemoteItemDownloading:media] ) {
		return [self tableView:tableView pendingRemoteFileCellForRowAtIndexPath:indexPath];
	}
	else {
		return [self tableView:tableView readyRemoteFileCellForRowAtIndexPath:indexPath];
	}
}




- (UITableViewCell *)tableView:(UITableView *)tableView configurationCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ConfigurationStore *configuration = self.track.configuration;

	if ( [self isRemoteItemDownloading:configuration] ) {
		return [self tableView:tableView pendingRemoteFileCellForRowAtIndexPath:indexPath];
	}
	else {
		return [self tableView:tableView readyRemoteFileCellForRowAtIndexPath:indexPath];
	}
}



- (UITableViewCell *)tableView:(UITableView *)tableView readyRemoteFileCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	RemoteFileStore *remoteFile = (RemoteFileStore *)[self remoteItemAtIndexPath:indexPath];

    LabelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActiveFileCell" forIndexPath:indexPath];
	cell.title = remoteFile.name;

	return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView pendingRemoteFileCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	RemoteFileStore *remoteFile = (RemoteFileStore *)[self remoteItemAtIndexPath:indexPath];

    DownloadStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PendingFileCell" forIndexPath:indexPath];

	DownloadStatus *downloadStatus = [self.trackDownloadStatus childStatusForRemoteItem:remoteFile];

	cell.downloadStatus = downloadStatus;
	cell.title = remoteFile.name;
	
	if ( downloadStatus.possibleError != nil ) {
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	NSString *segueID = [segue identifier];

	if ( [segueID isEqualToString:SEGUE_SHOW_FILE_INFO_ID] || [segueID isEqualToString:SEGUE_SHOW_PENDING_FILE_INFO_ID] ) {
		RemoteFileStore *remoteFile = (RemoteFileStore *)[self remoteItemAtIndexPath:self.tableView.indexPathForSelectedRow];
		FileInfoController *fileInfoController = segue.destinationViewController;
		fileInfoController.ditourModel = self.ditourModel;
		fileInfoController.remoteFile = remoteFile;
		fileInfoController.downloadStatus = [self.trackDownloadStatus childStatusForRemoteItem:remoteFile];
	}
    else {
        NSLog( @"SegueID: \"%@\" does not match a known ID in prepareForSegue method.", segueID );
    }
}

@end
