//
//  ILobbyTrackDetailController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 4/24/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyTrackDetailController.h"
#import "ILobbyDownloadStatusCell.h"
#import "ILobbyLabelCell.h"



enum : NSInteger {
	// TODO: add section for the config file
	SECTION_REMOTE_MEDIA,
	SECTION_COUNT
};


@interface ILobbyTrackDetailController () <ILobbyDownloadStatusDelegate>

@end


@implementation ILobbyTrackDetailController {
	BOOL _updateScheduled;		// indicates whether an update has been scheduled
}


- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)setTrackDownloadStatus:(ILobbyDownloadContainerStatus *)trackDownloadStatus {
	_trackDownloadStatus = trackDownloadStatus;
	trackDownloadStatus.delegate = self;
	_updateScheduled = NO;
}


- (void)viewDidLoad {
    [super viewDidLoad];

	_updateScheduled = NO;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	self.title = [NSString stringWithFormat:@"Track: %@", self.track.title];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return SECTION_COUNT;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

	switch ( section) {
		case SECTION_REMOTE_MEDIA:
			return self.track.remoteMedia.count;

		default:
			break;
	}

    return 0;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_REMOTE_MEDIA:
			return [self estimateHeightForRemoteMediaAtIndexPath:indexPath];

		default:
			return [ILobbyLabelCell defaultHeight];
	}
}


- (CGFloat)estimateHeightForRemoteMediaAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreRemoteMedia *media = self.track.remoteMedia[indexPath.row];

	if ( media.isReady ) {
		return [ILobbyLabelCell defaultHeight];
	}
	else {
		return [ILobbyDownloadStatusCell defaultHeight];
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_REMOTE_MEDIA:
			return [self tableView:tableView remoteMediaCellForRowAtIndexPath:indexPath];
			break;

		default:
			return nil;
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView remoteMediaCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreRemoteMedia *media = self.track.remoteMedia[indexPath.row];

	if ( media.isReady ) {
		return [self tableView:tableView readyRemoteMediaCellForRowAtIndexPath:indexPath];
	}
	else {
		return [self tableView:tableView pendingRemoteMediaCellForRowAtIndexPath:indexPath];
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView readyRemoteMediaCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreRemoteMedia *media = self.track.remoteMedia[indexPath.row];

    ILobbyLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TrackDetailActiveTrackCell" forIndexPath:indexPath];
	cell.title = media.name;

	return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView pendingRemoteMediaCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreRemoteMedia *media = self.track.remoteMedia[indexPath.row];

    ILobbyDownloadStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TrackDetailPendingTrackCell" forIndexPath:indexPath];

	ILobbyDownloadStatus *downloadStatus = [self.trackDownloadStatus childStatusForRemoteItem:media];
	//NSLog( @"Track: %@, Ready: %@, Download status: %@, Pointer: %@, Context: %@", track.title, track.status, downloadStatus, track, track.managedObjectContext );

	cell.downloadStatus = downloadStatus;
	cell.title = media.name;

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
