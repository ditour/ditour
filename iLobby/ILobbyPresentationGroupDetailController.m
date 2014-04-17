//
//  ILobbyPresentationMasterTableController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/18/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresentationGroupDetailController.h"
#import "ILobbyGroupDetailActivePresentationCell.h"
#import "ILobbyGroupDetailPendingPresentationCell.h"


enum : NSInteger {
	SECTION_ACTIVE_PRESENTATIONS_VIEW,
	SECTION_PENDING_PRESENTATIONS_VIEW,
	SECTION_COUNT
};


static NSString *ACTIVE_PRESENTATION_CELL_ID = @"GroupDetailActivePresentationCell";
static NSString *PENDING_PRESENTATION_CELL_ID = @"GroupDetailPendingPresentationCell";



@interface ILobbyPresentationGroupDetailController () <ILobbyDownloadStatusDelegate>

@property (weak, readwrite) IBOutlet UIActivityIndicatorView *downloadIndicator;

- (IBAction)downloadPresentations:(id)sender;
- (IBAction)cancelGroupDownload:(id)sender;

@property ILobbyDownloadContainerStatus *groupDownloadStatus;

@end


@implementation ILobbyPresentationGroupDetailController {
	BOOL _hasPendingUpdate;
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

	_hasPendingUpdate = NO;

	_activePresentations = nil;
	_pendingPresentations = nil;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	self.title = [NSString stringWithFormat:@"Group: %@", self.group.shortName];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	self.groupDownloadStatus = [self.lobbyModel downloadStatusForGroup:self.group];
	if ( self.groupDownloadStatus != nil ) {
		self.groupDownloadStatus.delegate = self;
	}

	[self updateDownloadIndicator];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)downloadPresentations:(id)sender {
	[self.tableView reloadData];
	
	if ( self.lobbyModel.downloading ) {
		// TODO: need to display alert view
		NSLog( @"Attempting to download a group when already downloading. You need to cancel first." );
	}
	else {
		self.groupDownloadStatus = [self.lobbyModel downloadGroup:self.group withDelegate:self];
		[self updateDownloadIndicator];
		[self.tableView reloadData];
	}
}


- (IBAction)cancelGroupDownload:(id)sender {
	[self.lobbyModel cancelDownload];
}


- (void)downloadStatusChanged:(ILobbyDownloadStatus *)status {
	if ( !_hasPendingUpdate ) {
		_hasPendingUpdate = YES;

		static dispatch_time_t delay = 1000 * 1000 * 1000 * 0.2;	// refresh the display every 0.2 seconds
		dispatch_time_t runTime = dispatch_time( DISPATCH_TIME_NOW, delay );
		dispatch_after( runTime, dispatch_get_main_queue(), ^{
			_hasPendingUpdate = NO;
			[self updateDownloadIndicator];
			[self.tableView reloadData];
		});
	}
}


- (void)updateDownloadIndicator {
	if ( self.lobbyModel.downloading && !self.downloadIndicator.isAnimating ) {
		[self.downloadIndicator startAnimating];
	}
	else if ( !self.lobbyModel.downloading && self.downloadIndicator.isAnimating ) {
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


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

	switch ( section ) {
		case SECTION_ACTIVE_PRESENTATIONS_VIEW:
			return _activePresentations.count;

		case SECTION_PENDING_PRESENTATIONS_VIEW:
			return _pendingPresentations.count;

		default:
			break;
	}

    return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch ( section ) {
		case SECTION_ACTIVE_PRESENTATIONS_VIEW:
			return @"Active Presentations";

		case SECTION_PENDING_PRESENTATIONS_VIEW:
			return @"Pending Presentations";

		default:
			break;
	}

	return nil;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case SECTION_ACTIVE_PRESENTATIONS_VIEW:
			return [self tableView:tableView activePresentationCellForRowAtIndexPath:indexPath];

		case SECTION_PENDING_PRESENTATIONS_VIEW:
			return [self tableView:tableView pendingPresentationCellForRowAtIndexPath:indexPath];

		default:
			break;
	}

	return nil;
}


- (UITableViewCell *)tableView:(UITableView *)tableView activePresentationCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ILobbyGroupDetailActivePresentationCell *cell = [tableView dequeueReusableCellWithIdentifier:ACTIVE_PRESENTATION_CELL_ID forIndexPath:indexPath];

    // Configure the cell...
	ILobbyStorePresentation *presentation = _activePresentations[indexPath.row];
	cell.nameLabel.text = presentation.name;
//	NSLog( @"Active presentation %@, status: %@, path: %@", presentation.name, presentation.status, presentation.path );

    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView pendingPresentationCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ILobbyGroupDetailPendingPresentationCell *cell = [tableView dequeueReusableCellWithIdentifier:PENDING_PRESENTATION_CELL_ID forIndexPath:indexPath];

    // Configure the cell...
	ILobbyStorePresentation *presentation = _pendingPresentations[indexPath.row];
	cell.nameLabel.text = presentation.name;

	ILobbyDownloadStatus *downloadStatus = [self.groupDownloadStatus childStatusForRemoteItem:presentation];
	float downloadProgress = downloadStatus != nil ? downloadStatus.progress : 0.0;
	cell.progressView.progress = downloadProgress;

//	NSLog( @"Pending presentation %@, status: %@, path: %@", presentation.name, presentation.status, presentation.path );

    return cell;
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
