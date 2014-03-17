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
#import "ILobbyPresentationGroupEditCell.h"


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
@property (nonatomic, readwrite, strong) ILobbyPresentationGroupEditCell *editingCell;

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
	self.editingCell = nil;

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
	[self.lobbyModel.managedObjectContext performBlockAndWait:transferCall];

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
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelGroupEditing)];
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(confirmGroupEditing)];
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


- (void)cancelGroupEditing {
	[self.editContext rollback];

	[self.editingCell.locationField resignFirstResponder];

	self.editing = NO;
	self.editingGroup = nil;
	self.editingCell = nil;
	[self updateControls];
	[self.tableView reloadData];
}


- (void)confirmGroupEditing {
	self.editingGroup.remoteLocation = self.editingCell.locationField.text;

	[self saveChanges];

	[self.editingCell.locationField resignFirstResponder];

	self.editing = NO;
	self.editingGroup = nil;
	self.editingCell = nil;
	[self updateControls];
	[self.tableView reloadData];
}


- (BOOL)saveChanges {
	// saves the changes to the parent context
	__block NSError *error = nil;
	__block BOOL success;

	success = [self.editContext save:&error];
	if ( !success ) {
		NSLog( @"Failed to save group edit to edit context: %@", error );
		return NO;
	}

	// saves the changes to the parent's persistent store
	[self.editContext performBlockAndWait:^{
		success = [self.editContext.parentContext save:&error];
		if ( !success ) {
			NSLog( @"Failed to save main context after group edit: %@", error );
		}
	}];

	return success;
}


- (void)setEditing:(BOOL)editing {
	[super setEditing:editing];
	[self updateControls];
	[self.tableView reloadData];
}


- (void)editTable {
	self.editing = YES;
}


- (void)dismissEditing {
	self.editing = NO;
}


- (BOOL)deleteGroupAtIndex:(NSInteger)index {
	if ( index >= 0 ) {
		[self.userConfig removeObjectFromGroupsAtIndex:index];
		return [self saveChanges];
	}
	else {
		return NO;
	}
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
			// if we are editing the table or a cell, hide the "add" cell
			return self.editing || self.editingGroup != nil ? 0 : 1;

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
	ILobbyStorePresentationGroup *group = self.userConfig.groups[indexPath.row];
	if ( group == self.editingGroup ) {
		if ( !self.editingCell ) {
			self.editingCell = [self.tableView dequeueReusableCellWithIdentifier:GROUP_EDIT_CELL_ID forIndexPath:indexPath];
		}

		// configure the editing cell
		ILobbyPresentationGroupEditCell *editingCell = self.editingCell;
		editingCell.locationField.text = group.remoteLocation;
		[editingCell.locationField becomeFirstResponder];

		return editingCell;
	}
	else {
		ILobbyPresentationGroupCell *viewCell = [self.tableView dequeueReusableCellWithIdentifier:GROUP_VIEW_CELL_ID forIndexPath:indexPath];
		viewCell.locationLabel.text = group.remoteLocation;
		return viewCell;
	}

	// should never reach here
	return nil;
}


- (UITableViewCell *)groupAddCellAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:GROUP_ADD_CELL_ID forIndexPath:indexPath];

	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:NO];

	switch ( indexPath.section ) {
		case GROUP_ADD_SECTION:
			// create a new group and enable editing
			self.editingGroup = [self.userConfig addNewPresentationGroup];
			break;

		case GROUP_VIEW_SECTION:
			// enable editing for the corresponding group
			self.editingGroup = self.userConfig.groups[indexPath.row];
			break;

		default:
			NSLog( @"Error. Did select data row for unknown section at path: %@", indexPath );
			break;
	}

	[self updateControls];
	[self.tableView reloadData];
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


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		switch ( indexPath.section ) {
			case GROUP_VIEW_SECTION:
				[self deleteGroupAtIndex:indexPath.row];
				[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
				break;

			default:
				return;
		}
    }
	else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
