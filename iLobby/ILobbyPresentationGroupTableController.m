//
//  ILobbyPresentationGroupTableController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/12/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresentationGroupTableController.h"
#import "ILobbyStoreUserConfig.h"
#import "ILobbyStorePresentationGroup.h"
#import "ILobbyPresentationGroupCell.h"


// enum of table sections
enum :NSInteger {
	GROUP_VIEW_SECTION,		// section to display each cell corresponding to a presentation group
	GROUP_ADD_SECTION,		// section to display a cell for adding a new presentation group
	SECTION_COUNT			// number of sections
};


static NSString * const GROUP_VIEW_CELL_ID = @"PresentationGroupCell";
static NSString * const GROUP_EDIT_CELL_ID = @"PresentationGroupEditCell";
static NSString * const GROUP_ADD_CELL_ID = @"PresentationGroupAddCell";


@interface ILobbyPresentationGroupTableController ()
@property (nonatomic, readwrite, strong) ILobbyStoreUserConfig *userConfig;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *editContext;

// indicates which group is being edited
@property (nonatomic, readwrite, strong) ILobbyStorePresentationGroup *editingGroup;

@end


@implementation ILobbyPresentationGroupTableController
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

	// initialize instance variables
	self.editingGroup = nil;

	// setup the local edit context and its managed objects
	[self setupEditContext];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	[self updateControls];
}


- (void)setupEditContext {
	// create an edit context using the main queue and backed by the model context
	self.editContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	self.editContext.parentContext = self.lobbyModel.managedObjectContext;

	__block NSManagedObjectID *userConfigID = nil;
	void (^transferCall)() = ^{
		userConfigID = self.lobbyModel.userConfig.objectID;
	};

	// if the master context is on the main queue then perform the transfer directly otherwise perform on the context's queue
	if ( self.lobbyModel.managedObjectContext.concurrencyType == NSMainQueueConcurrencyType ) {
		transferCall();
	}
	else {
		[self.lobbyModel.managedObjectContext performBlockAndWait:transferCall];
	}

	NSError *error = nil;
	self.userConfig = (ILobbyStoreUserConfig *)[self.editContext existingObjectWithID:userConfigID error:&error];
	if ( error ) {
		NSLog( @"Error getting user config in edit context: %@", error );
	}
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)updateControls {
	if ( self.editingGroup ) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAdd)];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(confirmAdd)];
	}
	else {
		if ( self.editing ) {
			self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissEditing)];
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteSelectedRows)];
		}
		else {
			self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTable)];;
			self.navigationItem.rightBarButtonItem = nil;
		}
	}
}


- (void)editTable {
	self.editing = YES;
	[self updateControls];
}


- (void)dismissEditing {
	self.editing = NO;
	[self updateControls];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return SECTION_COUNT;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.

	switch ( section ) {
		case GROUP_VIEW_SECTION:
			return self.userConfig.groups.count;

		case GROUP_ADD_SECTION:
			return 1;

		default:
			break;
	}

    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch ( indexPath.section ) {
		case GROUP_VIEW_SECTION:
			return [self groupViewCellAtIndexPath:indexPath];

		case GROUP_ADD_SECTION:
			return [self groupAddCellAtIndexPath:indexPath];

		default:
			break;
	}

	// failed to find a matching section
	return nil;
}


- (UITableViewCell *)groupViewCellAtIndexPath:(NSIndexPath *)indexPath {
	ILobbyPresentationGroupCell *cell = [self.tableView dequeueReusableCellWithIdentifier:GROUP_VIEW_CELL_ID forIndexPath:indexPath];
	return cell;
}


- (UITableViewCell *)groupAddCellAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:GROUP_ADD_CELL_ID forIndexPath:indexPath];

	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:NO];

	switch ( indexPath.section ) {
		case GROUP_ADD_SECTION:
			self.editingGroup = [self.userConfig addNewPresentationGroup];
			[self updateControls];
			[self.tableView reloadData];
			break;

		default:
			NSLog( @"Did select data row at path: %@", indexPath );
			break;
	}
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	switch ( indexPath.section ) {
		case GROUP_VIEW_SECTION:
			return YES;

		default:
			return NO;
	}

    return NO;
}


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
