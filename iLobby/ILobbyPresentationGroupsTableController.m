//
//  ILobbyPresentationGroupTableController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/12/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresentationGroupsTableController.h"
#import "ILobbyStoreRoot.h"
#import "ILobbyStorePresentationGroup.h"
#import "ILobbyPresentationGroupCell.h"
#import "ILobbyPresentationGroupEditCell.h"
#import "ILobbyPresentationGroupDetailController.h"


// enum of table sections
enum :NSInteger {
	GROUP_VIEW_SECTION,		// section to display each cell corresponding to a presentation group
	GROUP_ADD_SECTION,		// section to display a cell for adding a new presentation group
	SECTION_COUNT			// number of sections
};


static NSString * const GROUP_VIEW_CELL_ID = @"PresentationGroupCell";
static NSString * const GROUP_EDIT_CELL_ID = @"PresentationGroupEditCell";
static NSString * const GROUP_ADD_CELL_ID = @"PresentationGroupAddCell";

static NSString *SEGUE_SHOW_PRESENTAION_MASTERS_ID = @"GroupToPresentationMasters";

@interface ILobbyPresentationGroupsTableController ()
@property (nonatomic, readwrite, strong) ILobbyStoreRoot *rootStore;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *editContext;

// indicates which group is being edited
@property (nonatomic, readwrite, strong) ILobbyStorePresentationGroup *editingGroup;
@property (nonatomic, readwrite, strong) ILobbyPresentationGroupEditCell *editingCell;

@end


@implementation ILobbyPresentationGroupsTableController
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

	self.tableView.allowsMultipleSelectionDuringEditing = YES;

	// initialize instance variables
	self.editingGroup = nil;
	self.editingCell = nil;

	// setup the local edit context and its managed objects
	self.editContext = self.lobbyModel.mainManagedObjectContext;
	self.rootStore = self.lobbyModel.mainStoreRoot;

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	[self updateControls];
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
			self.navigationItem.leftBarButtonItem = nil;
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTable)];;
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

	[self saveChanges:nil];

	[self.editingCell.locationField resignFirstResponder];

	self.editing = NO;
	self.editingGroup = nil;
	self.editingCell = nil;
	[self updateControls];
	[self.tableView reloadData];
}


- (BOOL)saveChanges:(NSError * __autoreleasing *)errorPtr {
	return [self.lobbyModel saveChanges:errorPtr];
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


- (void)deleteSelectedRows {
	NSMutableIndexSet *groupsToDeleteIndexes = [NSMutableIndexSet new];
	for ( NSIndexPath *path in self.tableView.indexPathsForSelectedRows ) {
		switch ( path.section ) {
			case GROUP_VIEW_SECTION:
				[groupsToDeleteIndexes addIndex:path.row];
				break;

			default:
				break;
		}
	}

	if ( groupsToDeleteIndexes.count > 0 ) {
		[self.rootStore removeGroupsAtIndexes:[groupsToDeleteIndexes copy]];
		if ( [self saveChanges:nil] ) {
			[self.tableView deleteRowsAtIndexPaths:self.tableView.indexPathsForSelectedRows withRowAnimation:UITableViewRowAnimationAutomatic];
		}
		else {
			NSLog( @"Error deleting selected rows..." );
			[self.editContext rollback];
		}
	}
}


- (BOOL)deleteGroupAtIndex:(NSInteger)index {
	if ( index >= 0 ) {
		[self.rootStore removeObjectFromGroupsAtIndex:index];
		return [self saveChanges:nil];
	}
	else {
		return NO;
	}
}


- (BOOL)moveGroupAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
	[self.rootStore moveGroupAtIndex:fromIndex toIndex:toIndex];
	return [self saveChanges:nil];
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
			return self.rootStore.groups.count;

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
	ILobbyStorePresentationGroup *group = self.rootStore.groups[indexPath.row];
	if ( group == self.editingGroup ) {
		if ( !self.editingCell ) {
			self.editingCell = [self.tableView dequeueReusableCellWithIdentifier:GROUP_EDIT_CELL_ID forIndexPath:indexPath];
			ILobbyPresentationGroupsTableController * __weak weakSelf = self;
			[self.editingCell setDoneHandler:^(ILobbyPresentationGroupEditCell *source, NSString *text) {
				ILobbyPresentationGroupsTableController *strongSelf = weakSelf;
				if ( strongSelf ) {
					[strongSelf confirmGroupEditing];
				}
			}];
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
	if ( !self.editing ) {		// only allow editing of a group if the table is not in the editing mode (i.e. delete/move mode)
		[self.tableView deselectRowAtIndexPath:indexPath animated:NO];

		switch ( indexPath.section ) {
			case GROUP_ADD_SECTION:
				// create a new group and enable editing
				self.editingGroup = [self.rootStore addNewPresentationGroup];
				break;

			case GROUP_VIEW_SECTION:
				// enable editing for the corresponding group
				self.editingGroup = self.rootStore.groups[indexPath.row];
				break;

			default:
				NSLog( @"Error. Did select data row for unknown section at path: %@", indexPath );
				break;
		}

		[self updateControls];
		[self.tableView reloadData];
	}
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	if ( !self.editing ) {
		switch ( indexPath.section ) {
			case GROUP_VIEW_SECTION:
				[self performSegueWithIdentifier:SEGUE_SHOW_PRESENTAION_MASTERS_ID sender:self.rootStore.groups[indexPath.row]];
				break;

			default:
				break;
		}
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
	switch ( fromIndexPath.section ) {
		case GROUP_VIEW_SECTION:
			[self moveGroupAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
			break;

		default:
			break;
	}
}


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    NSString *segueID = [segue identifier];

    if ( [segueID isEqualToString:SEGUE_SHOW_PRESENTAION_MASTERS_ID] ) {
		ILobbyStorePresentationGroup *group = sender;

		ILobbyPresentationGroupDetailController *masterTableController = segue.destinationViewController;
		masterTableController.lobbyModel = self.lobbyModel;
		masterTableController.group = group;
    }
    else {
        NSLog( @"SegueID: \"%@\" does not match a known ID in prepareForSegue method.", segueID );
    }
}

@end
