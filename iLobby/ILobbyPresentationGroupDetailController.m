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

- (IBAction)downloadPresentations:(id)sender;

@property ILobbyDownloadContainerStatus *groupDownloadStatus;

@end


@implementation ILobbyPresentationGroupDetailController
@synthesize lobbyModel=_lobbyModel;


- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	self.title = [NSString stringWithFormat:@"Group: %@", self.group.shortName];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	self.groupDownloadStatus = [self.lobbyModel downloadStatusForGroup:self.group];
	if ( self.groupDownloadStatus != nil ) {
		self.groupDownloadStatus.delegate = self;
	}
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)downloadPresentations:(id)sender {
	[self.group fetchPresentationsWithCompletion:^(ILobbyStorePresentationGroup *group, NSError *error) {
		dispatch_async( dispatch_get_main_queue(), ^{
			[self.tableView reloadData];
			if ( self.lobbyModel.downloading ) {
				// TODO: need to display alert view
				NSLog( @"Attempting to download a group when already downloading. You need to cancel first." );
			}
			else {
				self.groupDownloadStatus = [self.lobbyModel downloadGroup:self.group withDelegate:self];
			}
		});
	}];
}


- (void)downloadStatusChanged:(ILobbyDownloadStatus *)status {
	dispatch_async( dispatch_get_main_queue(), ^{
		[self.tableView reloadData];
	});
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return SECTION_COUNT;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

	switch ( section ) {
		case SECTION_ACTIVE_PRESENTATIONS_VIEW:
			return self.group.activePresentations.count;

		case SECTION_PENDING_PRESENTATIONS_VIEW:
			return self.group.pendingPresentations.count;

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
	ILobbyStorePresentation *presentation = self.group.activePresentations[indexPath.row];
	cell.nameLabel.text = presentation.name;
//	NSLog( @"Active presentation %@, status: %@", presentation.name, presentation.status );

    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView pendingPresentationCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ILobbyGroupDetailPendingPresentationCell *cell = [tableView dequeueReusableCellWithIdentifier:PENDING_PRESENTATION_CELL_ID forIndexPath:indexPath];

    // Configure the cell...
	ILobbyStorePresentation *presentation = self.group.pendingPresentations[indexPath.row];
	cell.nameLabel.text = presentation.name;

	ILobbyDownloadStatus *downloadStatus = [self.groupDownloadStatus childStatusForRemoteItem:presentation];
	float downloadProgress = downloadStatus != nil ? downloadStatus.progress : 0.0;
	cell.progressView.progress = downloadProgress;

//	NSLog( @"Pending presentation %@, status: %@", presentation.name, presentation.status );

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
