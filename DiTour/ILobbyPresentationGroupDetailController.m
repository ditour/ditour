//
//  ILobbyPresentationMasterTableController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/18/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresentationGroupDetailController.h"
#import "ILobbyDownloadStatusCell.h"
#import "ILobbyLabelCell.h"
#import "ILobbyPresentationDetailController.h"
#import "ILobbyFileInfoController.h"


enum : NSInteger {
	SECTION_CONFIG,
	SECTION_ACTIVE_PRESENTATIONS,
	SECTION_PENDING_PRESENTATIONS,
	SECTION_COUNT
};


static NSString *ACTIVE_PRESENTATION_CELL_ID = @"GroupDetailActivePresentationCell";
static NSString *PENDING_PRESENTATION_CELL_ID = @"GroupDetailPendingPresentationCell";


static NSString *SEGUE_SHOW_ACTIVE_PRESENTATION_DETAIL_ID = @"ShowActivePresentationDetail";
static NSString *SEGUE_SHOW_PENDING_PRESENTATION_DETAIL_ID = @"ShowPendingPresentationDetail";
static NSString *SEGUE_SHOW_FILE_INFO_ID = @"GroupDetailShowFileInfo";
static NSString *SEGUE_SHOW_PENDING_FILE_INFO_ID = @"GroupDetailShowPendingFileInfo";


@interface ILobbyPresentationGroupDetailController () <ILobbyDownloadStatusDelegate>

// TODO: add property for configuration

@property (weak, readwrite) IBOutlet UIActivityIndicatorView *downloadIndicator;

- (IBAction)downloadPresentations:(id)sender;
- (IBAction)cancelGroupDownload:(id)sender;

@property ILobbyDownloadContainerStatus *groupDownloadStatus;

@end


@implementation ILobbyPresentationGroupDetailController {
	BOOL _updateScheduled;		// indicates whether an update has been scheduled
	NSArray *_pendingPresentations;
	NSArray *_activePresentations;
}


- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

	_updateScheduled = NO;

	_activePresentations = nil;
	_pendingPresentations = nil;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	self.title = [NSString stringWithFormat:@"Group: %@", self.group.shortName];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Now Playing" style:UIBarButtonItemStyleDone target:self action:@selector(popToPlaying)];

	self.groupDownloadStatus = [self.ditourModel downloadStatusForGroup:self.group];
	if ( self.groupDownloadStatus != nil ) {
		self.groupDownloadStatus.delegate = self;
	}

	[self updateDownloadIndicator];
}


- (void)popToPlaying {
	[self.navigationController popToRootViewControllerAnimated:YES];
}


- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	// allow updates to be scheduled immediately
	_updateScheduled = NO;

	// need to force reload to update presentations whose state changed (e.g. currently playing state)
	[self.tableView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)downloadPresentations:(id)sender {
	[self.tableView reloadData];
	
	if ( self.ditourModel.downloading ) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't Download" message:@"You attempted to download a group which is already downloading. You need to cancel first." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
		[alert show];
	}
	else {
		self.groupDownloadStatus = [self.ditourModel downloadGroup:self.group delegate:self];

		if ( self.groupDownloadStatus.error != nil ) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download Error" message:self.groupDownloadStatus.error.localizedDescription delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
			[alert show];
		}

		[self updateDownloadIndicator];
		[self.tableView reloadData];
	}
}


- (IBAction)cancelGroupDownload:(id)sender {
	[self.ditourModel cancelDownload];
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
			[self updateDownloadIndicator];
			[self.tableView reloadData];
		});
	}
}


- (void)updateDownloadIndicator {
	if ( self.ditourModel.downloading && !self.downloadIndicator.isAnimating ) {
		[self.downloadIndicator startAnimating];
	}
	else if ( !self.ditourModel.downloading && self.downloadIndicator.isAnimating ) {
		[self.downloadIndicator stopAnimating];
	}
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	_activePresentations = [self.group.activePresentations copy];
	_pendingPresentations = [self.group.pendingPresentations copy];

    // Return the number of sections.
    return SECTION_COUNT;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_CONFIG:
			return [self heightForRemoteItemAtIndexPath:indexPath];

		case SECTION_ACTIVE_PRESENTATIONS: case SECTION_PENDING_PRESENTATIONS:
			return [self heightForPresentationAtIndexPath:indexPath];

		default:
			return [ILobbyLabelCell defaultHeight];
	}
}


- (CGFloat)heightForPresentationAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_ACTIVE_PRESENTATIONS:
			return [ILobbyLabelCell defaultHeight];

		case SECTION_PENDING_PRESENTATIONS:
			return [ILobbyDownloadStatusCell defaultHeight];

		default:
			return [self heightForRemoteItemAtIndexPath:indexPath];
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
		ILobbyDownloadStatus *downloadStatus = [self.groupDownloadStatus childStatusForRemoteItem:remoteItem];
		return downloadStatus != nil && !downloadStatus.completed ? YES : NO;
	}
}


- (ILobbyStoreRemoteItem *)remoteItemAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_CONFIG:
			return self.group.configuration;

		case SECTION_ACTIVE_PRESENTATIONS: SECTION_PENDING_PRESENTATIONS:
			return [self presentationAtIndexPath:indexPath];

		default:
			return nil;
	}
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

	switch ( section ) {
		case SECTION_CONFIG:
			return self.group.configuration != nil ? 1 : 0;

		case SECTION_ACTIVE_PRESENTATIONS:
			return _activePresentations.count;

		case SECTION_PENDING_PRESENTATIONS:
			return _pendingPresentations.count;

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

			case SECTION_ACTIVE_PRESENTATIONS:
				return @"Active Presentations";

			case SECTION_PENDING_PRESENTATIONS:
				return @"Pending Presentations";

			default:
				return nil;
		}
	}
	else {
		return nil;
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_CONFIG:
			return [self tableView:tableView configurationCellForRowAtIndexPath:indexPath];

		case SECTION_ACTIVE_PRESENTATIONS:
			return [self tableView:tableView activePresentationCellForRowAtIndexPath:indexPath];

		case SECTION_PENDING_PRESENTATIONS:
			return [self tableView:tableView pendingPresentationCellForRowAtIndexPath:indexPath];

		default:
			break;
	}

	return nil;
}


- (ILobbyStorePresentation *)presentationAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_ACTIVE_PRESENTATIONS:
			return [self activePresentationAtSectionRow:indexPath.row];

		case SECTION_PENDING_PRESENTATIONS:
			return [self pendingPresentationAtSectionRow:indexPath.row];

		default:
			break;
	}

	return nil;
}


- (ILobbyStorePresentation *)activePresentationAtSectionRow:(NSInteger)row {
	return _activePresentations[row];
}


- (ILobbyStorePresentation *)pendingPresentationAtSectionRow:(NSInteger)row {
	return _pendingPresentations[row];
}


- (UITableViewCell *)tableView:(UITableView *)tableView activePresentationCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ILobbyLabelCell *cell = [tableView dequeueReusableCellWithIdentifier:ACTIVE_PRESENTATION_CELL_ID forIndexPath:indexPath];

	static NSDateFormatter *timestampFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		timestampFormatter = [NSDateFormatter new];
		timestampFormatter.dateStyle = NSDateFormatterMediumStyle;
		timestampFormatter.timeStyle = NSDateFormatterMediumStyle;
	});

    // Configure the cell...
	ILobbyStorePresentation *presentation = _activePresentations[indexPath.row];
	cell.marked = presentation.isCurrent;
	cell.title = presentation.name;
	cell.subtitle = [timestampFormatter stringFromDate:presentation.timestamp];

//	NSLog( @"Active presentation %@, status: %@, path: %@", presentation.name, presentation.status, presentation.absolutePath );

    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView pendingPresentationCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ILobbyDownloadStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:PENDING_PRESENTATION_CELL_ID forIndexPath:indexPath];

    // Configure the cell...
	ILobbyStorePresentation *presentation = _pendingPresentations[indexPath.row];
	cell.title = presentation.name;
	cell.subtitle = nil;

	ILobbyDownloadStatus *downloadStatus = [self.groupDownloadStatus childStatusForRemoteItem:presentation];
	cell.downloadStatus = downloadStatus;

	if ( downloadStatus.error != nil ) {
		cell.subtitle = @"Failed";
	}
	else if ( downloadStatus.canceled ) {
		cell.subtitle = @"Canceled";
	}
	else {
		cell.subtitle = nil;
	}

	//	NSLog( @"Pending presentation %@, status: %@, path: %@", presentation.name, presentation.status, presentation.absolutePath );

    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView configurationCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreConfiguration *configuration = self.group.configuration;

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
	cell.subtitle = nil;

	return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView pendingRemoteFileCellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyStoreRemoteFile *remoteFile = (ILobbyStoreRemoteFile *)[self remoteItemAtIndexPath:indexPath];

    ILobbyDownloadStatusCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PendingFileCell" forIndexPath:indexPath];

	ILobbyDownloadStatus *downloadStatus = [self.groupDownloadStatus childStatusForRemoteItem:remoteFile];

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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
	NSString *segueID = [segue identifier];

    if ( [segueID isEqualToString:SEGUE_SHOW_ACTIVE_PRESENTATION_DETAIL_ID] || [segueID isEqualToString:SEGUE_SHOW_PENDING_PRESENTATION_DETAIL_ID] ) {
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		ILobbyStorePresentation *presentation = [self presentationAtIndexPath:indexPath];

		ILobbyPresentationDetailController *presentationController = segue.destinationViewController;
		presentationController.ditourModel = self.ditourModel;
		presentationController.presentation = presentation;

		if ( [segueID isEqualToString:SEGUE_SHOW_PENDING_PRESENTATION_DETAIL_ID] ) {
			ILobbyDownloadContainerStatus *downloadStatus = (ILobbyDownloadContainerStatus *)[self.groupDownloadStatus childStatusForRemoteItem:presentation];
			presentationController.presentationDownloadStatus = downloadStatus;
		}
    }
	else if ( [segueID isEqualToString:SEGUE_SHOW_FILE_INFO_ID] || [segueID isEqualToString:SEGUE_SHOW_PENDING_FILE_INFO_ID] ) {
		ILobbyStoreRemoteFile *remoteFile = (ILobbyStoreRemoteFile *)[self remoteItemAtIndexPath:self.tableView.indexPathForSelectedRow];
		ILobbyFileInfoController *fileInfoController = segue.destinationViewController;
		fileInfoController.ditourModel = self.ditourModel;
		fileInfoController.remoteFile = remoteFile;
		fileInfoController.downloadStatus = [self.groupDownloadStatus childStatusForRemoteItem:remoteFile];
	}
    else {
        NSLog( @"SegueID: \"%@\" does not match a known ID in prepareForSegue method.", segueID );
    }
}

@end
