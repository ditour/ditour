//
//  ILobbyPresentationGroupTableController.m
//  iLobby
//
//  Created by Pelaia II, Tom on 3/12/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyPresentationGroupsTableController.h"
#import "ILobbyPresentationGroupCell.h"
#import "ILobbyPresentationGroupEditCell.h"
#import "ILobbyPresentationGroupDetailController.h"
#import "DiTour-Swift.h"


// enum of table sections
enum :NSInteger {
	GROUP_VIEW_SECTION,		// section to display each cell corresponding to a presentation group
	GROUP_ADD_SECTION,		// section to display a cell for adding a new presentation group
	SECTION_COUNT			// number of sections
};


// enum of editing states
typedef enum :short {
	EDIT_MODE_NONE,			// no editing
	EDIT_MODE_BATCH_EDIT,	// deleting multiple groups
	EDIT_MODE_GROUP_EDIT,	// edit the name of one group
	EDIT_MODE_COUNT
} EditMode;


static NSString * const GROUP_VIEW_CELL_ID = @"PresentationGroupCell";
static NSString * const GROUP_EDIT_CELL_ID = @"PresentationGroupEditCell";
static NSString * const GROUP_ADD_CELL_ID = @"PresentationGroupAddCell";

static NSString *SEGUE_SHOW_PRESENTAION_MASTERS_ID = @"GroupToPresentationMasters";

@interface ILobbyPresentationGroupsTableController ()

@property (nonatomic, readwrite, strong) RootStore *mainRootStore;
@property (nonatomic, readwrite, strong) RootStore *editingRootStore;
@property (nonatomic, readwrite, strong) RootStore *currentStoreRoot;
@property (nonatomic, readwrite, strong) NSManagedObjectContext *editContext;

// indicates which group is being edited
@property (nonatomic, readwrite, strong) PresentationGroupStore *editingGroup;
@property (nonatomic, readwrite, strong) ILobbyPresentationGroupEditCell *editingCell;

@property (nonatomic, assign) EditMode editMode;

@end


@implementation ILobbyPresentationGroupsTableController

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
	self.editMode = EDIT_MODE_NONE;
	self.editingGroup = nil;
	self.editingCell = nil;

	// setup the local edit context and its managed objects
	self.mainRootStore = self.ditourModel.mainStoreRoot;
	self.currentStoreRoot = self.mainRootStore;

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


- (void)setupForEditing {
	// create a new edit context
	self.editContext = [self.ditourModel createEditContextOnMain];

	// get the current root ID
	__block NSManagedObjectID *storeRootID = nil;
	[self.mainRootStore.managedObjectContext performBlockAndWait:^{
		storeRootID = self.mainRootStore.objectID;
	}];

	// create a new root store corresponding to the same current root
	[self.editContext performBlockAndWait:^{
		self.editingRootStore = (RootStore *)[self.editContext objectWithID:storeRootID];
	}];

	self.currentStoreRoot = self.editingRootStore;
}


- (void)closeEditingMode {
	self.editMode = EDIT_MODE_NONE;

	self.editContext = nil;

	self.currentStoreRoot = self.mainRootStore;
	self.editingRootStore = nil;

	self.editing = NO;
	self.editingGroup = nil;
	self.editingCell = nil;
}


- (IBAction)openGroupURL:(id)sender {
	CGPoint senderPoint = [sender bounds].origin;		// point in the button's own coordinates
	CGPoint pointInTable = [sender convertPoint:senderPoint toView:self.tableView];		// point in the table view
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pointInTable];

	if ( indexPath != nil ) {
		PresentationGroupStore *group = self.currentStoreRoot.groups[indexPath.row];
		NSURL *url = group.remoteURL;
		[[UIApplication sharedApplication] openURL:url];
	}
}


- (IBAction)editGroup:(id)sender {
	CGPoint senderPoint = [sender bounds].origin;		// point in the button's own coordinates
	CGPoint pointInTable = [sender convertPoint:senderPoint toView:self.tableView];		// point in the table view
	NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pointInTable];

	if ( indexPath != nil ) {
		// enable editing for the corresponding group
		self.editMode = EDIT_MODE_GROUP_EDIT;
		[self setupForEditing];
		self.editingGroup = [self editingGroupForGroup:self.mainRootStore.groups[indexPath.row]];

		[self updateControls];
		[self.tableView reloadData];
	}
}


// get a group on the edit context corresponding to the specified group
- (PresentationGroupStore *)editingGroupForGroup:(PresentationGroupStore *)group {
	// get the current root ID
	__block NSManagedObjectID *groupID = nil;
	[self.mainRootStore.managedObjectContext performBlockAndWait:^{
		groupID = group.objectID;
	}];

	// create a new root store corresponding to the same current root
	__block PresentationGroupStore *editingGroup = nil;
	[self.editContext performBlockAndWait:^{
		editingGroup = (PresentationGroupStore *)[self.editContext objectWithID:groupID];
	}];

	return editingGroup;
}


- (void)cancelGroupEditing {
	[self.editingCell.locationField resignFirstResponder];

	[self closeEditingMode];

	[self updateControls];
	[self.tableView reloadData];
}


- (void)confirmGroupEditing {
	// strip white space
	NSString *groupUrlSpec = [self.editingCell.locationField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	// validate whether the URL is well formed
	if ( groupUrlSpec == nil || groupUrlSpec.length == 0 ) {
		// empty URL so just throw it away
		[self cancelGroupEditing];
	}
	else {
		NSURL *groupURL = [NSURL URLWithString:groupUrlSpec];

		// since the URL is not empty verify that it is well formed
		if ( groupURL != nil && groupURL.scheme != nil && groupURL.host != nil && groupURL.path != nil ) {	// well formed
			// save changes and dismiss editing
			if ( [groupURL.scheme isEqualToString:@"http"] || [groupURL.scheme isEqualToString:@"https"] ) {
				self.editingGroup.remoteLocation = groupUrlSpec;
				[self saveChanges:nil];
				[self cancelGroupEditing];
			}
			else {
				// alert the user that the URL is malformed and allow them to continue editing
				NSString *message = [NSString stringWithFormat:@"The URL scheme must be either \"http\" or \"https\", but you have specified one with scheme: \"%@\"", groupURL.scheme];
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid URL Scheme" message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
				[alertView show];
			}
		}
		else if ( groupUrlSpec != nil ) {	// malformed but not nil
			// alert the user that the URL is malformed and allow them to continue editing
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Malformed URL" message:@"The URL specified is malformed." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
			[alertView show];
		}
	}
}


- (BOOL)saveChanges:(NSError * __autoreleasing *)errorPtr {
	switch ( self.editMode ) {
		case EDIT_MODE_NONE:
			return [self.ditourModel saveChanges:errorPtr];

		default:
			return [self.ditourModel persistentSaveContext:self.editContext error:errorPtr];
	}
}


- (void)setEditing:(BOOL)editing {
	[super setEditing:editing];

	self.editMode = editing ? EDIT_MODE_BATCH_EDIT : EDIT_MODE_NONE;
	if ( editing ) {
		[self setupForEditing];
	}

	[self updateControls];
	[self.tableView reloadData];
}


- (void)editTable {
	self.editing = YES;
}


- (void)dismissEditing {
	[self saveChanges:nil];
	[self closeEditingMode];
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
		[self.currentStoreRoot removeGroupsAtIndexes:[groupsToDeleteIndexes copy]];
		[self.tableView deleteRowsAtIndexPaths:self.tableView.indexPathsForSelectedRows withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}


- (BOOL)deleteGroupAtIndex:(NSInteger)index {
	if ( index >= 0 ) {
		[self.currentStoreRoot removeObjectFromGroupsAtIndex:index];
		return YES;
	}
	else {
		return NO;
	}
}


- (BOOL)moveGroupAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
	[self.currentStoreRoot moveGroupAtIndex:fromIndex toIndex:toIndex];
	return YES;
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
			return self.currentStoreRoot.groups.count;

		case GROUP_ADD_SECTION:
			// if we are editing the table or a cell, hide the "add" cell
			return self.editMode == EDIT_MODE_NONE ? 1 : 0;

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
	PresentationGroupStore *group = self.currentStoreRoot.groups[indexPath.row];
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
		viewCell.editButton.hidden = self.editing;		// hide the edit button when editing
		viewCell.openURLButton.hidden = self.editing;	// hide the open URL button when editing

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
				self.editMode = EDIT_MODE_GROUP_EDIT;
				[self setupForEditing];
				self.editingGroup = [self.editingRootStore addNewPresentationGroup];
				break;

			case GROUP_VIEW_SECTION:
				[self performSegueWithIdentifier:SEGUE_SHOW_PRESENTAION_MASTERS_ID sender:self.mainRootStore.groups[indexPath.row]];
				break;

			default:
				NSLog( @"Error. Did select data row for unknown section at path: %@", indexPath );
				break;
		}

		[self updateControls];
		[self.tableView reloadData];
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
		PresentationGroupStore *group = sender;

		ILobbyPresentationGroupDetailController *masterTableController = segue.destinationViewController;
		masterTableController.ditourModel = self.ditourModel;
		masterTableController.group = group;
    }
    else {
        NSLog( @"SegueID: \"%@\" does not match a known ID in prepareForSegue method.", segueID );
    }
}

@end
