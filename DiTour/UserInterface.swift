//
//  Views.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 11/20/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import QuickLook
import CoreData


// segue IDs
private let SEGUE_SHOW_CONFIGURATION_ID = "MainToGroups"
private let SEGUE_SHOW_PRESENTATION_MASTERS_ID = "GroupToPresentationMasters"
private let SEGUE_SHOW_FILE_INFO_ID = "TrackDetailShowFileInfo"
private let SEGUE_SHOW_PENDING_FILE_INFO_ID = "TrackDetailShowPendingFileInfo"
private let SEGUE_SHOW_ACTIVE_TRACK_DETAIL_ID = "ShowActiveTrackDetail"
private let SEGUE_SHOW_PENDING_TRACK_DETAIL_ID = "ShowPendingTrackDetail"
private let SEGUE_SHOW_ACTIVE_PRESENTATION_DETAIL_ID = "ShowActivePresentationDetail"
private let SEGUE_SHOW_PENDING_PRESENTATION_DETAIL_ID = "ShowPendingPresentationDetail"
private let SEGUE_GROUP_SHOW_FILE_INFO_ID = "GroupDetailShowFileInfo";
private let SEGUE_GROUP_SHOW_PENDING_FILE_INFO_ID = "GroupDetailShowPendingFileInfo";


/* formatter for timestamp */
private let TIMESTAMP_FORMATTER : NSDateFormatter = {
	let formatter = NSDateFormatter()
	formatter.dateStyle = .MediumStyle
	formatter.timeStyle = .MediumStyle
	return formatter
}()



/* Main view controller which displays the tracks of a Presentation from which the user can select */
class PresentationViewController : UICollectionViewController, DitourModelContainer {
	var ditourModel: DitourModel? {
		willSet {
			self.ditourModel?.removeObserver(self, forKeyPath: "tracks")
			self.ditourModel?.removeObserver(self, forKeyPath: "currentTrack")
		}

		didSet {
			self.ditourModel?.addObserver(self, forKeyPath: "tracks", options: .New, context: nil)
			self.ditourModel?.addObserver(self, forKeyPath: "currentTrack", options: (.Old | .New), context: nil)
		}
	}


	deinit {
		self.ditourModel = nil
	}


	/* Load the latest version of the current presentation */
	@IBAction func reloadPresentation(sender: AnyObject) {
		self.ditourModel?.reloadPresentation()
	}


	/* handle changes to the model's tracks or current track to update the display accordingly */
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
		// test against the source object and the keyPath
		switch (object, keyPath) {

		// event due to model tracks change
		case (_ as DitourModel, "tracks"):
			// since the model's tracks have changed, relaod the collection view to display the new tracks
			dispatch_async(dispatch_get_main_queue()) {
				self.collectionView!.reloadData()
			}

		// event due to model currentTrack change
		case (let model as DitourModel, "currentTrack"):
			let tracks = model.tracks
			var cellPaths = [NSIndexPath]()		// these are the cell paths to refresh

			// reload just the cells of the collection view that need updating (e.g. to change highlighting)
			switch ( change[NSKeyValueChangeOldKey], change[NSKeyValueChangeNewKey] ) {

			//  old and current track exist and are not equal so we need to update their corresponding cells
			case let ( .Some( oldTrack as Track ), .Some( currentTrack as Track ) ) where oldTrack !== currentTrack :
				if let oldItem = find(tracks, oldTrack) {
					cellPaths.append(NSIndexPath(forItem: oldItem, inSection: 0))
				}
				if let newItem = find(tracks, currentTrack) {
					cellPaths.append(NSIndexPath(forItem: newItem, inSection: 0))
				}

			//  old and current track exist and are equal so we don't need to update any cells
			case let ( .Some( oldTrack as Track ), .Some( currentTrack as Track ) ) where oldTrack === currentTrack :
				break

			// matches the case where oldTrack NSNull and hence only the current track exists so we need to update its cell
			case let ( .Some(oldTrack as NSNull), .Some(currentTrack as Track) ) :
				if let newItem = find(tracks, currentTrack) {
					cellPaths.append(NSIndexPath(forItem: newItem, inSection: 0))
				}

			// only the current track exists so we need to update its cell
			case ( .None, .Some( let currentTrack as Track ) ) :
				if let newItem = find(tracks, currentTrack) {
					cellPaths.append(NSIndexPath(forItem: newItem, inSection: 0))
				}

			// matches the case where currentTrack NSNull and hence only the old track exists and there is no current so update the cell for the old track
			case let ( .Some(oldTrack as Track), .Some(currentTrack as NSNull) ) :
				if let oldItem = find(tracks, oldTrack) {
					cellPaths.append(NSIndexPath(forItem: oldItem, inSection: 0))
				}

			// only the old track exists and there is no current so update the cell for the old track
			case ( .Some( let oldTrack as Track ), .None ) :
				if let oldItem = find(tracks, oldTrack) {
					cellPaths.append(NSIndexPath(forItem: oldItem, inSection: 0))
				}

			default:
				//println("no case match for old track: \(change[NSKeyValueChangeOldKey]) and new track: \(change[NSKeyValueChangeNewKey])")
				break
			}

			// update the affected cells
			if !cellPaths.isEmpty {
				dispatch_async(dispatch_get_main_queue()) {
					self.collectionView!.reloadItemsAtIndexPaths(cellPaths)
				}
			}

		default:
			break
		}
	}


	/* get the number of sections in the collection view */
	override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}


	/* get the number of items to display in the section */
	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.ditourModel?.tracks.count ?? 0
	}


	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TrackCell", forIndexPath: indexPath) as TrackViewCell

		let item = indexPath.item
		if let model = self.ditourModel {
			let track = model.tracks[item]
			cell.label.text = track.label
			cell.imageView.image = track.icon
			cell.outlined = track == model.currentTrack
		}

		return cell
	}


	override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		self.collectionView!.deselectItemAtIndexPath(indexPath, animated: true)

		self.ditourModel?.playTrackAtIndex(UInt(indexPath.item))
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		self.collectionView!.allowsSelection = true
		self.collectionView!.allowsMultipleSelection = false

		self.navigationController?.navigationBar.barStyle = .BlackTranslucent
	}


	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch ( segue.identifier, segue.destinationViewController ) {

		case ( .Some(SEGUE_SHOW_CONFIGURATION_ID), let configController as PresentationGroupsTableController ):
			configController.ditourModel = self.ditourModel

		case ( .Some(SEGUE_SHOW_PENDING_FILE_INFO_ID), let configController as PresentationGroupsTableController ):
			configController.ditourModel = self.ditourModel

		default:
			println("Segue ID: \"\(segue.identifier)\" does not match a known ID in prepare for segue with destination view controller: \(segue.destinationViewController) ")
		}
	}
}



/* cell for displaying a track icon and label which can be selected to change the current track */
class TrackViewCell : UICollectionViewCell {
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var imageView: UIImageView!

	/* indicates whether the cell should be outlined indicating the current track */
	var outlined : Bool = false {
		didSet {
			if outlined {
				// white box
				self.backgroundView = BackgroundView(stroke: UIColor.whiteColor(), fill: UIColor.blackColor())
			} else {
				// no outline
				self.backgroundView = nil
			}
		}
	}


	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		// change to our custom selected background view (pale blue)
		self.selectedBackgroundView = BackgroundView(stroke: UIColor.blackColor(), fill: UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.9))
	}



	/* nested background view for the track view cell to display when the cell is selected our outlined */
	private class BackgroundView : UIView {
		var strokeColor: UIColor
		var fillColor: UIColor


		init(frame: CGRect, stroke: UIColor, fill: UIColor) {
			self.strokeColor = stroke
			self.fillColor = fill

			super.init(frame: frame)
		}


		/* make a background view with zero frame and the specified stroke and fill colors */
		convenience init(stroke: UIColor, fill: UIColor) {
			self.init(frame: CGRectZero, stroke: stroke, fill: fill)
		}


		required init(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}


		/* draw this view */
		override func drawRect(rect: CGRect) {
			// draw a rounded rect bezier path
			let context = UIGraphicsGetCurrentContext()
			CGContextSaveGState(context)
			let bezierPath = UIBezierPath(roundedRect: rect, cornerRadius: 5.0)
			bezierPath.lineWidth = 5.0
			self.fillColor.setFill()
			bezierPath.fill()
			self.strokeColor.setStroke()
			bezierPath.stroke()
			CGContextRestoreGState(context)
		}
	}
}



/* Table View cell for displaying a title and subtitle */
class LabelCell : UITableViewCell {
	/* static constants */
	private struct Constants {
		/* green color used to indicate that a title is marked (e.g. current presentation) */
		static let MARKED_COLOR = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
	}


	/* label for displaying the title */
	@IBOutlet weak var titleLabel: UILabel!

	/* label for displaying the subtitle */
	@IBOutlet weak var subtitleLabel: UILabel!

	/* convenience accessor for the title */
	var title : String? {
		get { return titleLabel.text }
		set { titleLabel.text = newValue }
	}

	/* convenience accessor for the title */
	var subtitle : String? {
		get { return subtitleLabel.text }
		set { subtitleLabel.text = newValue }
	}


	/* default cell height */
	class var defaultHeight : CGFloat {
		return 44.0
	}


	/* override awake from nib to clear the subtitle which is optional and not always provided */
	override func awakeFromNib() {
		super.awakeFromNib()
		self.subtitle = ""		// prevents the placeholder from being displayed
	}


	/* sets whether the specified title should be marked (e.g. current presentation) */
	func setMarked(marked: Bool) {
		self.titleLabel.textColor = marked ? Constants.MARKED_COLOR : UIColor.blackColor()
	}
}



/* format used for displaying the numerical download progress */
private let DOWNLOAD_PROGRESS_FORMAT : NSNumberFormatter = {
	let format = NSNumberFormatter()
	format.numberStyle = .PercentStyle
	format.minimumFractionDigits = 2
	format.maximumFractionDigits = 2
	return format
}()



/* table cell displaying the download status */
class DownloadStatusCell : LabelCell {
	/* progress indicator */
	@IBOutlet weak var progressView: UIProgressView!

	/* label for displaying the progress */
	@IBOutlet weak var progressLabel: UILabel!


	/* default cell height */
	override class var defaultHeight : CGFloat {
		return 68.0
	}


	/* updates the cell to reflect the specified status */
	func setDownloadStatus(status: DownloadStatus?) {
		let progress = status?.progress ?? 0.0
		self.progressView.progress = Float(progress)
		self.progressLabel.text = DOWNLOAD_PROGRESS_FORMAT.stringFromNumber(progress)
	}
}



/* table cell for displaying information about a group along with buttons for performing various actions on it */
class PresentationGroupCell : UITableViewCell {
	/* label displaying the Group's URL */
	@IBOutlet weak var locationLabel : UILabel!

	/* button for editing the group's URL */
	@IBOutlet weak var editButton : UIButton!

	/* button for opening the Group's URL */
	@IBOutlet weak var openURLButton : UIButton!
}



/* table cell for displaying editable information about a group */
class PresentationGroupEditCell : UITableViewCell, UITextFieldDelegate {
	/* text field for editing and displaying the group's URL */
	@IBOutlet weak var locationField: UITextField!

	/* handler to call when editing is complete */
	var editCompletionHandler : ((source: PresentationGroupEditCell, text: String?)->Void)?


	/* custom initialization after loading the cell from the nib */
	override func awakeFromNib() {
		super.awakeFromNib()

		// handle the text field events in this class
		self.locationField.delegate = self
	}


	/* handle the text field delegate return key press to commit the edit */
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		// automatically prefix with "http://" if not already specified
		if let text = textField.text {
			if !text.hasPrefix("http://") {
				textField.text = "http://\(text)"
			}
		}

		// run the completion handler if any
		self.editCompletionHandler?(source: self, text: textField.text)

		// resign focus (e.g. dismiss the keyboard)
		textField.resignFirstResponder()

		return true
	}
}


// MARK: - File Info Controller
/* display information about a media file */
class FileInfoController : UIViewController, DitourModelContainer, DownloadStatusDelegate, QLPreviewItem, QLPreviewControllerDataSource {
	/* label for displaying the file name */
	@IBOutlet weak var nameLabel : UILabel!

	/* button to display a preview of the file if available */
	@IBOutlet weak var previewButton : UIButton!

	/* view for displaying the download progress of the file */
	@IBOutlet weak var progressView : UIProgressView!

	/* label for displaying a numerical representation of the download progress */
	@IBOutlet weak var progressLabel : UILabel!

	/* view to display text information about the file */
	@IBOutlet weak var infoView : UITextView!

	/* reference to the remote file */
	var remoteFile : RemoteFileStore!

	/* download status */
	var downloadStatus : DownloadStatus? {
		willSet {
			newValue?.delegate = self
		}
	}

	/* main model */
	var ditourModel : DitourModel?

	/* flag indicating whether a request to update the file info display has been scheduled */
	private var updateScheduled = false


	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}


	/* handle the view loaded event */
	override func viewDidLoad() {
		super.viewDidLoad()

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Now Playing", style: .Done, target: self, action: Selector("popToPlaying"))

		self.nameLabel.text = self.remoteFile?.name

		// if the file is already downloaded then hide the progress elements
		if self.downloadStatus == nil {
			self.progressLabel.hidden = true
			self.progressView.hidden = true
		}

		// hide the preivew button if the file cannot be previewed
		self.previewButton.hidden = !self.canPreview()

		self.updateView()
	}


	// the download state has changed (can be called at a very high frequency)
	func downloadStatusChanged( status: DownloadStatus ) {
		// throttle the updates to dramatically lower CPU load and reduce backlog of events
		if !self.updateScheduled {	// skip if an update has already been scheduled since the display will be refreshed
			self.updateScheduled = true

			// refresh the display at most every 0.25 seconds = 250 million nanoseconds
			let nanoSecondDelay = 250_000_000 as Int64
			let runTime = dispatch_time(DISPATCH_TIME_NOW, nanoSecondDelay)
			dispatch_after(runTime, dispatch_get_main_queue()) {
				self.updateScheduled = false	// allow further updates to be scheduled
				self.updateView()
			}
		}
	}


	/* update the file info display */
	func updateView() {
		// determine whether the file is being downloaded and update accordingly
		if let downloadStatus = self.downloadStatus {
			let progress = downloadStatus.progress

			self.progressView.progress = Float(progress)
			self.progressLabel.text = DOWNLOAD_PROGRESS_FORMAT.stringFromNumber(progress)

			if progress == 1.0 {
				self.progressView.hidden = true
			}

			// only display the preview button if the file can be previewed
			self.previewButton.hidden = !self.canPreview()
		}

		self.infoView.text = self.remoteFile.summary
	}


	/* pop this view controller back to the playing view */
	func popToPlaying() {
		self.navigationController?.popToRootViewControllerAnimated(true)
	}


	// MARK: - Preview support

	/* indicates whether the file can be previewed */
	func canPreview() -> Bool {
		if let remoteFile = self.remoteFile {
			if NSFileManager.defaultManager().fileExistsAtPath(remoteFile.absolutePath) {
				// query the QuickLook engine to see if the item is a supported type
				return QLPreviewController.canPreviewItem(self)
			} else {
				return false
			}
		} else {
			return false
		}
	}


	/* Local URL of the file */
	var previewItemURL: NSURL! { return NSURL.fileURLWithPath(self.remoteFile.absolutePath) }


	/* title of the file */
	var previewItemTitle: String! { return self.remoteFile.name }


	/* there is only one item to preview */
	func numberOfPreviewItemsInPreviewController(controller: QLPreviewController!) -> Int {
		return 1
	}


	/* this instance also serves as the preview item */
	func previewController(controller: QLPreviewController!, previewItemAtIndex index: Int) -> QLPreviewItem! {
		return self
	}


	@IBAction func displayPreview(sender: AnyObject) {
		let previewController = QLPreviewController()
		previewController.dataSource = self
		self.presentViewController(previewController, animated: true, completion: nil)
	}
}



// MARK: - Presentation Groups Table Controller
/* table controller for displaying presentation groups */
class PresentationGroupsTableController : UITableViewController, DitourModelContainer {
	/* Cell constants */
	private struct Cell {
		static let VIEW_ID = "PresentationGroupCell"
		static let EDIT_ID = "PresentationGroupEditCell"
		static let ADD_ID = "PresentationGroupAddCell"
	}


	/* main model */
	var ditourModel: DitourModel?

	private var mainRootStore : RootStore?
	private var editingRootStore : RootStore?
	private var currentRootStore : RootStore?
	private var editContext : NSManagedObjectContext?

	/* group currently being edited if any */
	private var editingGroup : PresentationGroupStore?

	/* cell for editing if any */
	private var editingCell : PresentationGroupEditCell?

	/* editing mode */
	private var editMode : EditMode = .None

	/* add an observer to the view controller editing property */
	override var editing : Bool {
		didSet {
			self.editMode = editing ? .Batch : .None
			if editing {
				self.setupEditing()
			}

			self.updateControls()
			self.tableView.reloadData()
		}
	}


	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.allowsMultipleSelectionDuringEditing = true

		// initialize properties
		self.editMode = .None
		self.editingGroup = nil
		self.editingCell = nil

		// setup the local edit context and its managed objects
		self.mainRootStore = self.ditourModel?.mainStoreRoot
		self.currentRootStore = self.mainRootStore

		// preserve selection between presentations
		self.clearsSelectionOnViewWillAppear = false

		self.updateControls()
	}


	/* UI action handler for opening the focussed group's URL */
	@IBAction func openGroupURL(sender: UIButton) {
		let senderPoint = sender.bounds.origin		// point in the button's own coordinates
		let pointInTable = sender.convertPoint(senderPoint, toView: self.tableView)		// point in the table view

		if let indexPath = self.tableView.indexPathForRowAtPoint(pointInTable) {
			let group = self.currentRootStore!.groups[indexPath.row] as PresentationGroupStore
			if let url = group.remoteURL {
				UIApplication.sharedApplication().openURL(url)
			}
		}
	}


	/* UI action handler for editing the focussed group */
	@IBAction func editGroup(sender: UIButton) {
		let senderPoint = sender.bounds.origin		// point in the button's own coordinates
		let pointInTable = sender.convertPoint(senderPoint, toView: self.tableView)		// point in the table view

		if let indexPath = self.tableView.indexPathForRowAtPoint(pointInTable) {
			// enable editing for the corresponding group
			self.editMode = .Single
			self.setupEditing()

			let group = self.mainRootStore?.groups[indexPath.row] as PresentationGroupStore
			self.editingGroup = self.editingGroupForGroup(group)

			self.updateControls()
			self.tableView.reloadData()
		}
	}



	/* get a group on the edit context corresponding to the specified group */
	private func editingGroupForGroup(group: PresentationGroupStore) -> PresentationGroupStore {
		var groupID : NSManagedObjectID!
		group.managedObjectContext?.performBlockAndWait{
			groupID = group.objectID
		}

		var editingGroup : PresentationGroupStore!
		self.editContext?.performBlockAndWait{
			editingGroup = self.editContext?.objectWithID(groupID) as PresentationGroupStore
		}

		return editingGroup
	}


	/* update the controls display */
	private func updateControls() {
		switch ( self.editingGroup, self.editing ) {
		case (.Some, _):	// there is an editing group (e.g. editing the group name)
			self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "cancelGroupEditing")
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "confirmGroupEditing")
		case (.None, true):		// no editing group, but editing (e.g. moving or deleting groups)
			self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "dismissEditing")
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: "deleteSelectedRows")
		case (.None, false):	// no editing group, not editing (e.g. not editing)
			self.navigationItem.leftBarButtonItem = nil
			self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "editTable")
		default:
			break		// the default case should never be reached
		}
	}


	/* cancel the editing mode */
	func cancelGroupEditing() {
		self.editingCell?.locationField.resignFirstResponder()

		self.exitEditMode()

		self.updateControls()
		self.tableView.reloadData()
	}


	/* validate the user's group edit and commit if valid otherwise alert the user ignoring empty edits */
	func confirmGroupEditing() {
		// get the group Location and strip white space
		switch self.editingCell?.locationField.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) {
		case .Some(let groupLocationSpec) where countElements(groupLocationSpec) > 0:
			switch NSURL(string: groupLocationSpec) {
			case .Some(let groupURL) where groupURL.scheme != nil && groupURL.host != nil && groupURL.path != nil:
				// validated so URL so save changes and dismiss editing
				if groupURL.scheme == "http" || groupURL.scheme == "https" {
					self.editingGroup?.remoteLocation = groupLocationSpec
					self.saveChanges(nil)
					self.cancelGroupEditing()
				} else {
					// alert the user that the URL is malformed and allow them to continue editing
					let message = "The URL scheme must be either \"http\" or \"https\", but you have specified one with scheme: \"\(groupURL.scheme!)\""
					let alertView = UIAlertView(title: "Unsupported URL Scheme", message: message, delegate: nil, cancelButtonTitle: "Dismiss")
					alertView.show()
				}
			default:
				// must be a malformed URL
				let alertView = UIAlertView(title: "Malformed URL", message: "The URL specified is malformed.", delegate: nil, cancelButtonTitle: "Dismiss")
				alertView.show()
			}
		default:
			// empty Location -> just throw it away
			self.cancelGroupEditing()
		}
	}


	/* save changes to the persistent store */
	private func saveChanges(error: NSErrorPointer) -> Bool {
		switch self.editMode {
		case .None:		// if there is no local edit mode just perform the default save
			return self.ditourModel?.saveChanges(error) ?? false
		default:
			return self.ditourModel?.persistentSaveContext(self.editContext!, error: error) ?? false
		}
	}


	/* configure the editing state */
	private func setupEditing() {
		// create a new edit context
		self.editContext = self.ditourModel!.createEditContextOnMain()

		// get the current root ID
		var storeRootID : NSManagedObjectID! = nil
		self.mainRootStore!.managedObjectContext!.performBlockAndWait{
			storeRootID = self.mainRootStore?.objectID
		}

		// create a new root store corresponding to the same current root
		self.editContext?.performBlockAndWait{
			self.editingRootStore = self.editContext!.objectWithID(storeRootID) as? RootStore
		}

		self.currentRootStore = self.editingRootStore
	}


	/* exit the editing mode */
	private func exitEditMode() {
		self.editMode = .None

		self.editContext = nil

		self.currentRootStore = self.mainRootStore
		self.editingRootStore = nil

		self.editing = false
		self.editingGroup = nil
		self.editingCell = nil
	}


	/* enter the batch editing mode */
	func editTable() {
		self.editing = true
	}


	/* save changes and exit the edit mode */
	func dismissEditing() {
		self.saveChanges(nil)
		self.exitEditMode()
	}


	/* delete the selected rows */
	func deleteSelectedRows() {
		if let selectedPaths = self.tableView.indexPathsForSelectedRows() {
			// gather the indexes of the selected groups
			let groupsToDeleteIndexes = NSMutableIndexSet()
			for path in selectedPaths as [NSIndexPath] {
				switch path.section {
				case Section.GroupView.rawValue:
					groupsToDeleteIndexes.addIndex(path.row)
				default:
					break
				}
			}

			// delete the groups corresponding to the selected indexes
			if groupsToDeleteIndexes.count > 0 {
				self.currentRootStore?.removeGroupsAtIndexes( NSIndexSet(indexSet: groupsToDeleteIndexes) )
				self.tableView.deleteRowsAtIndexPaths(selectedPaths, withRowAnimation: .Automatic)
			}
		}
	}


	/* delete the group at the specified index returning true for a valid index and false otherwise */
	private func deleteGroupAtIndex(index: Int) -> Bool {
		if index > 0 {
			self.currentRootStore?.removeObjectFromGroupsAtIndex(UInt(index))
			return true
		} else {
			return false
		}
	}


	/* move the group at the specified index to another specified index */
	func moveGroupAtIndex(fromIndex: Int, toIndex: Int) {
		self.currentRootStore?.moveGroupAtIndex(fromIndex, toIndex: toIndex)
	}


	//MARK: - Presentation Group Table view data source

	/* number of sections in the table */
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return Section.Count.rawValue
	}


	/* number of rows in the specified section */
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch (section, self.editMode) {
		case (Section.GroupView.rawValue, _):
			// one row per group in the view section
			return self.currentRootStore?.groups.count ?? 0
		case (Section.GroupAdd.rawValue, .None):
			return 1	// there is one row in the Add section if we aren't editing
		case (Section.GroupAdd.rawValue, _):
			return 0	// if we are editing the table or a cell, hide the "add" cell
		default:
			return 0
		}
	}


	/* get the cell at the specified index path */
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		switch indexPath.section {
		case Section.GroupView.rawValue:
			return self.groupViewCellAtIndexPath(indexPath)
		case Section.GroupAdd.rawValue:
			return self.groupAddCellAtIndexPath(indexPath)
		default:
			fatalError("No support to get a cell for presentation group section: \(indexPath.section)")
		}
	}


	private func groupViewCellAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell {
		let group = self.currentRootStore!.groups[indexPath.row] as PresentationGroupStore

		if group === self.editingGroup {		// this is group currently being edited
			// if the editing cell is nil then create one and assign it
			if self.editingCell == nil {
				self.editingCell = self.tableView.dequeueReusableCellWithIdentifier(Cell.EDIT_ID, forIndexPath: indexPath) as? PresentationGroupEditCell
				self.editingCell?.editCompletionHandler = { [weak self] source, text in
					if let strongSelf = self {
						strongSelf.confirmGroupEditing()
					}
				}
			}

			// configure the editing cell
			let editingCell = self.editingCell!
			editingCell.locationField.text = group.remoteLocation
			editingCell.locationField.becomeFirstResponder()

			return editingCell
		} else {
			let viewCell = self.tableView.dequeueReusableCellWithIdentifier(Cell.VIEW_ID, forIndexPath: indexPath) as PresentationGroupCell
			viewCell.locationLabel.text = group.remoteLocation
			viewCell.editButton.hidden = self.editing			// hide the edit button when editing
			viewCell.openURLButton.hidden = self.editing		// hide the open URL button when editing

			return viewCell
		}
	}


	/* get the group add cell at the specified index path */
	private func groupAddCellAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell {
		return self.tableView.dequeueReusableCellWithIdentifier(Cell.ADD_ID, forIndexPath: indexPath) as UITableViewCell
	}


	/* handle selection of a group or the add group row */
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if !self.editing {	// only allow editing of a group if the table is not in the editing mode (i.e. delete/move mode)
			self.tableView.deselectRowAtIndexPath(indexPath, animated: false)

			switch indexPath.section {
			case Section.GroupAdd.rawValue:
				// create a new group and enable editing
				self.editMode = EditMode.Single	// edit the name of the group
				self.setupEditing()
				self.editingGroup = self.editingRootStore?.addNewPresentationGroup()
			case Section.GroupView.rawValue:
				// view the selected group in the detail view
				self.performSegueWithIdentifier(SEGUE_SHOW_PRESENTATION_MASTERS_ID, sender: self.mainRootStore!.groups[indexPath.row])
			default:
				println("Error. Did select data row for unknown section at path: \(indexPath)")
			}

			self.updateControls()
			self.tableView.reloadData()
		}
	}


	/* Override to support conditional editing of the table view */
	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		switch indexPath.section {
		case Section.GroupView.rawValue:
			return true
		default:
			return false
		}
	}


	/* Override to support editing the table view. */
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		switch( editingStyle, indexPath.section ) {
		case (.Delete, Section.GroupView.rawValue ):
			// Delete the row from the data source
			self.deleteGroupAtIndex(indexPath.row)
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
		default:
			break
		}
	}


	/* move the groups from the source row to the destination row based on the drag event */
	override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
		switch sourceIndexPath.section {
		case Section.GroupView.rawValue:
			self.moveGroupAtIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
		default:
			break
		}
	}


	/* support rearranging rows in the table view */
	override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		switch indexPath.section {
		case Section.GroupView.rawValue:
			return true
		default:
			return false
		}
	}


	// MARK: - Navigation

	/* prepare to navigate to a new view controller */
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch (segue.identifier, sender) {
		case (.Some(SEGUE_SHOW_PRESENTATION_MASTERS_ID), let group as PresentationGroupStore):
			let masterTableController = segue.destinationViewController as PresentationGroupDetailController
			masterTableController.ditourModel = self.ditourModel
			masterTableController.group = group
		default:
			println("Prepare for segue with ID: \(segue.identifier) does not match a known case...")
		}
	}



	//MARK: - Presentation Group Nested Enumerations

	/* enum of sections within the table */
	private enum Section : Int {
		case GroupView		// section to display each cell corresponding to a presentation group
		case GroupAdd		// section to display a cell for adding a new presentation group
		case Count			// number of sections
	}


	/* enum of editing states */
	private enum EditMode {
		case None		// no editing
		case Batch		// editing multiple groups (e.g. multiple deletion)
		case Single		// edit a single group (e.g. edit name of a group)
	}
}



/* really contains remote items */
protocol ConcreteRemoteItemContaining {
	/* type of the remote items contained */
	typealias ItemType : RemoteItemStore

	var detailTitle : String { get }

	func remoteItemsByReadyStatus() -> (ready: [ItemType], notReady: [ItemType])
}



// MARK: - Track Detail Controller

/* extension to add remote item containing conformance and support for the detail view controllers */
extension TrackStore : ConcreteRemoteItemContaining {
	/* type of the remote items in this container */
	typealias ItemType = RemoteMediaStore

	var detailTitle : String { return "Track: \(self.title)" }


	/* get the remote items and categorize them as to ready or not */
	func remoteItemsByReadyStatus() -> (ready: [ItemType], notReady: [ItemType]) {
		var readyItems = [ItemType]()
		var notReadyItems = [ItemType]()

		for remoteMedia in self.remoteMedia.array as [RemoteMediaStore] {
			if remoteMedia.isReady {
				readyItems.append(remoteMedia)
			} else {
				notReadyItems.append(remoteMedia)
			}
		}

		return (ready: readyItems, notReady: notReadyItems)
	}
}



/* table controller for displaying detail for a specified track */
class TrackDetailController : UITableViewController, DownloadStatusDelegate, DitourModelContainer {
	/* main model */
	var ditourModel : DitourModel?

	/* track for which to display detail */
	var track : TrackStore!

	/* download status */
	var downloadStatus : DownloadContainerStatus? {
		didSet {
			downloadStatus?.delegate = self
			self.updateScheduled = false
		}
	}

	/* array of pending items */
	var pendingItems = Array<TrackStore.ItemType>()

	/* array of ready items */
	var readyItems = Array<TrackStore.ItemType>()


	/* indicates whether an update has been scheduled to process any pending changes */
	private var updateScheduled = false


	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.updateScheduled = false

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Now Playing", style: .Done, target: self, action: "popToPlaying")

		self.title = self.track.detailTitle
	}


	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		// allow updates to be scheduled immediately
		self.updateScheduled = false
	}


	func popToPlaying() {
		self.navigationController?.popToRootViewControllerAnimated(true)
	}


	/* process a status change */
	func downloadStatusChanged(status: DownloadStatus) {
		// throttle the updates to dramatically lower CPU load and reduce backlog of events
		if !self.updateScheduled { // skip if an update has already been scheduled since the display will be refreshed
			self.updateScheduled = true		// indicate that an update will be scheduled
			let NANO_SECOND_DELAY = Int64(250_000_000)	// refresh at most every 0.25 seconds
			let runTime = dispatch_time(DISPATCH_TIME_NOW, NANO_SECOND_DELAY)
			dispatch_after(runTime, dispatch_get_main_queue()) { () -> Void in
				self.updateScheduled = false	// allow another update to be scheduled since we will begin processing the current one
				self.tableView.reloadData()
			}
		}
	}


	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// determine the ready and pending items for consistency with subsequent table data callbacks
		(self.readyItems, self.pendingItems) = self.track.remoteItemsByReadyStatus()

		return Section.Count.rawValue
	}


	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if self.tableView(tableView, numberOfRowsInSection: section) > 0 {	// only display a section title if there are any rows to display
			switch section {
			case Section.Config.rawValue:
				return "Configuration"
			case Section.Pending.rawValue:
				return "Pending Media"
			case Section.Ready.rawValue:
				return "Ready Media"
			default:
				return nil
			}
		} else {
			return nil
		}
	}


	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case Section.Config.rawValue:
			return self.track.configuration != nil ? 1 : 0
		case Section.Pending.rawValue:
			return self.pendingItems.count
		case Section.Ready.rawValue:
			return self.readyItems.count
		default:
			return 0
		}
	}


	func remoteFileAtIndexPath(indexPath: NSIndexPath) -> RemoteFileStore {
		switch indexPath.section {
		case Section.Config.rawValue:
			return self.track.configuration!
		case Section.Pending.rawValue:
			return self.pendingItems[indexPath.row]
		case Section.Ready.rawValue:
			return self.readyItems[indexPath.row]
		default:
			fatalError("Failed request for remote item at index path: \(indexPath)")
		}
	}


	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		switch indexPath.section {
		case Section.Config.rawValue, Section.Pending.rawValue, Section.Ready.rawValue:
			return self.heightForRemoteItemAtIndexPath(indexPath)
		default:
			return LabelCell.defaultHeight
		}
	}


	private func heightForRemoteItemAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
		let remoteItem = remoteFileAtIndexPath(indexPath)

		if self.isRemoteItemDownloading(remoteItem) {
			return DownloadStatusCell.defaultHeight
		} else {
			return LabelCell.defaultHeight
		}
	}


	private func isRemoteItemDownloading(remoteItem: RemoteItemStore) -> Bool {
		if remoteItem.isReady {
			return false
		} else {
			if let itemDownloadStatus = self.downloadStatus?.childStatusForRemoteItem(remoteItem) {
				return !itemDownloadStatus.completed
			} else {
				return false
			}
		}
	}


	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let remoteItem = self.remoteFileAtIndexPath(indexPath)

		switch indexPath.section {
		case Section.Config.rawValue:
			if self.isRemoteItemDownloading(remoteItem) {
				return self.pendingRemoteFileCell(tableView, indexPath: indexPath)
			} else {
				return self.readyRemoteFileCell(tableView, indexPath: indexPath)
			}
		case Section.Pending.rawValue:
			if self.isRemoteItemDownloading(remoteItem) {
				return self.pendingRemoteFileCell(tableView, indexPath: indexPath)
			} else {
				return self.readyRemoteFileCell(tableView, indexPath: indexPath)
			}
		case Section.Ready.rawValue:
			return self.readyRemoteFileCell(tableView, indexPath: indexPath)
		default:
			fatalError("No match for cell at index path: \(indexPath)")
		}
	}


	private func readyRemoteFileCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let remoteFile = self.remoteFileAtIndexPath(indexPath) as RemoteFileStore
		let cell = tableView.dequeueReusableCellWithIdentifier("ActiveFileCell", forIndexPath: indexPath) as LabelCell
		cell.title = remoteFile.name

		return cell
	}


	private func pendingRemoteFileCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let remoteFile = self.remoteFileAtIndexPath(indexPath) as RemoteFileStore
		let cell = tableView.dequeueReusableCellWithIdentifier("PendingFileCell", forIndexPath: indexPath) as DownloadStatusCell

		cell.title = remoteFile.name

		if let itemDownloadStatus = self.downloadStatus?.childStatusForRemoteItem(remoteFile) {
			cell.setDownloadStatus(itemDownloadStatus)

			if itemDownloadStatus.possibleError != nil {
				cell.subtitle = "Failed"
			} else if itemDownloadStatus.canceled {
				cell.subtitle = "Canceled"
			} else {
				cell.subtitle = ""
			}
		} else {
			cell.subtitle = ""
		}

		return cell
	}


	// MARK - Track Detail Navigation

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch (segue.identifier) {
		case .Some(SEGUE_SHOW_FILE_INFO_ID), .Some(SEGUE_SHOW_PENDING_FILE_INFO_ID):
			let remoteFile = self.remoteFileAtIndexPath(self.tableView.indexPathForSelectedRow()!)
			let fileInfoController = segue.destinationViewController as FileInfoController
			fileInfoController.ditourModel = self.ditourModel
			fileInfoController.remoteFile = remoteFile
			fileInfoController.downloadStatus = self.downloadStatus?.childStatusForRemoteItem(remoteFile)
		default:
			println("Prepare for segue with ID: \(segue.identifier) does not match a known case...")
		}
	}



	/* sections for the table view */
	private enum Section : Int {
		case Config, Pending, Ready
		case Count
	}
}




// MARK: - Presentation Detail Controller

/* extension to add remote item containing conformance and support for the detail view controllers */
extension PresentationStore : ConcreteRemoteItemContaining {
	/* type of the remote items in this container */
	typealias ItemType = TrackStore

	var detailTitle : String { return "Presentation: \(self.name)" }


	/* get the remote items and categorize them as to ready or not */
	func remoteItemsByReadyStatus() -> (ready: [ItemType], notReady: [ItemType]) {
		var readyItems = [ItemType]()
		var notReadyItems = [ItemType]()

		for track in self.tracks.array as [TrackStore] {
			if track.isReady {
				readyItems.append(track)
			} else {
				notReadyItems.append(track)
			}
		}

		return (ready: readyItems, notReady: notReadyItems)
	}
}



/* table controller for displaying detail for a specified presentation */
class PresentationDetailController : UITableViewController, DownloadStatusDelegate, DitourModelContainer {
	/* main model */
	var ditourModel : DitourModel?

	/* presentation for which to display detail */
	var presentation : PresentationStore!

	/* download status */
	var downloadStatus : DownloadContainerStatus? {
		didSet {
			downloadStatus?.delegate = self
			self.updateScheduled = false
		}
	}

	/* switch for making the current presentation the default one */
	@IBOutlet var defaultPresentationSwitch : UISwitch?

	/* array of pending items */
	var pendingItems = Array<PresentationStore.ItemType>()

	/* array of ready items */
	var readyItems = Array<PresentationStore.ItemType>()


	/* indicates whether an update has been scheduled to process any pending changes */
	private var updateScheduled = false


	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.updateScheduled = false

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Now Playing", style: .Done, target: self, action: "popToPlaying")

		self.title = presentation.detailTitle

		self.updateView()
	}


	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		// allow updates to be scheduled immediately
		self.updateScheduled = false
	}


	func popToPlaying() {
		self.navigationController?.popToRootViewControllerAnimated(true)
	}


	@IBAction func changeDefaultPresentation(sender: AnyObject) {
		self.presentation.current = self.defaultPresentationSwitch!.on;
		self.ditourModel?.saveChanges(nil)
		self.ditourModel?.reloadPresentation()
	}


	func updateView() {
		self.updateScheduled = false	// allow another update to be scheduled since we will begin processing the current one

		self.tableView.reloadData()

		self.defaultPresentationSwitch?.on = self.presentation.isCurrent;
		self.defaultPresentationSwitch?.enabled = self.presentation.isReady;
	}


	/* process a status change */
	func downloadStatusChanged(status: DownloadStatus) {
		// throttle the updates to dramatically lower CPU load and reduce backlog of events
		if !self.updateScheduled { // skip if an update has already been scheduled since the display will be refreshed
			self.updateScheduled = true		// indicate that an update will be scheduled
			let NANO_SECOND_DELAY = Int64(250_000_000)	// refresh at most every 0.25 seconds
			let runTime = dispatch_time(DISPATCH_TIME_NOW, NANO_SECOND_DELAY)
			dispatch_after(runTime, dispatch_get_main_queue()) { () -> Void in
				self.updateScheduled = false	// allow another update to be scheduled since we will begin processing the current one
				self.tableView.reloadData()
			}
		}
	}


	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// determine the ready and pending items for consistency with subsequent table data callbacks
		(self.readyItems, self.pendingItems) = self.presentation.remoteItemsByReadyStatus()

		return Section.Count.rawValue
	}


	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if self.tableView(tableView, numberOfRowsInSection: section) > 0 {	// only display a section title if there are any rows to display
			switch section {
			case Section.Config.rawValue:
				return "Configuration"
			case Section.Pending.rawValue:
				return "Pending Tracks"
			case Section.Ready.rawValue:
				return "Ready Tracks"
			default:
				return nil
			}
		} else {
			return nil
		}
	}


	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case Section.Config.rawValue:
			return self.presentation.configuration != nil ? 1 : 0
		case Section.Pending.rawValue:
			return self.pendingItems.count
		case Section.Ready.rawValue:
			return self.readyItems.count
		default:
			return 0
		}
	}


	func remoteItemAtIndexPath(indexPath: NSIndexPath) -> RemoteItemStore {
		switch indexPath.section {
		case Section.Config.rawValue:
			return self.presentation.configuration!
		case Section.Pending.rawValue:
			return self.pendingItems[indexPath.row]
		case Section.Ready.rawValue:
			return self.readyItems[indexPath.row]
		default:
			fatalError("Failed request for remote item at index path: \(indexPath)")
		}
	}


	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		switch indexPath.section {
		case Section.Config.rawValue, Section.Pending.rawValue, Section.Ready.rawValue:
			return self.heightForRemoteItemAtIndexPath(indexPath)
		default:
			return LabelCell.defaultHeight
		}
	}


	private func heightForRemoteItemAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
		let remoteItem = remoteItemAtIndexPath(indexPath)

		if self.isRemoteItemDownloading(remoteItem) {
			return DownloadStatusCell.defaultHeight
		} else {
			return LabelCell.defaultHeight
		}
	}


	private func isRemoteItemDownloading(remoteItem: RemoteItemStore) -> Bool {
		if remoteItem.isReady {
			return false
		} else {
			if let itemDownloadStatus = self.downloadStatus?.childStatusForRemoteItem(remoteItem) {
				return !itemDownloadStatus.completed
			} else {
				return false
			}
		}
	}


	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let remoteItem = self.remoteItemAtIndexPath(indexPath)

		switch indexPath.section {
		case Section.Config.rawValue:
			if self.isRemoteItemDownloading(remoteItem) {
				return self.pendingRemoteFileCell(tableView, indexPath: indexPath)
			} else {
				return self.readyRemoteFileCell(tableView, indexPath: indexPath)
			}
		case Section.Pending.rawValue:
			if self.isRemoteItemDownloading(remoteItem) {
				return self.pendingTrackCell(tableView, indexPath: indexPath)
			} else {
				return self.readyTrackCell(tableView, indexPath: indexPath)
			}
		case Section.Ready.rawValue:
			return self.readyTrackCell(tableView, indexPath: indexPath)
		default:
			fatalError("No match for cell at index path: \(indexPath)")
		}
	}


	private func readyRemoteFileCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let remoteFile = self.remoteItemAtIndexPath(indexPath) as RemoteFileStore
		let cell = tableView.dequeueReusableCellWithIdentifier("ActiveFileCell", forIndexPath: indexPath) as LabelCell
		cell.title = remoteFile.name

		return cell
	}


	private func pendingRemoteFileCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let remoteFile = self.remoteItemAtIndexPath(indexPath) as RemoteFileStore
		let cell = tableView.dequeueReusableCellWithIdentifier("PendingFileCell", forIndexPath: indexPath) as DownloadStatusCell

		cell.title = remoteFile.name

		if let itemDownloadStatus = self.downloadStatus?.childStatusForRemoteItem(remoteFile) {
			cell.setDownloadStatus(itemDownloadStatus)

			if itemDownloadStatus.possibleError != nil {
				cell.subtitle = "Failed"
			} else if itemDownloadStatus.canceled {
				cell.subtitle = "Canceled"
			} else {
				cell.subtitle = ""
			}
		} else {
			cell.subtitle = ""
		}

		return cell
	}


	private func readyTrackCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let track = self.trackAtPath(indexPath)

		let cell = tableView.dequeueReusableCellWithIdentifier("PresentationDetailActiveTrackCell", forIndexPath: indexPath) as LabelCell
		cell.title = track.title

		return cell
	}


	private func pendingTrackCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let track = self.trackAtPath(indexPath)

		let cell = tableView.dequeueReusableCellWithIdentifier("PresentationDetailPendingTrackCell", forIndexPath: indexPath) as DownloadStatusCell

		cell.title = track.title

		if let itemDownloadStatus = self.downloadStatus?.childStatusForRemoteItem(track) {
			cell.setDownloadStatus(itemDownloadStatus)

			if itemDownloadStatus.possibleError != nil {
				cell.subtitle = "Failed"
			} else if itemDownloadStatus.canceled {
				cell.subtitle = "Canceled"
			} else {
				cell.subtitle = ""
			}
		}

		return cell
	}


	private func trackAtPath(indexPath: NSIndexPath) -> TrackStore {
		switch indexPath.section {
		case Section.Pending.rawValue:
			return self.pendingItems[indexPath.row]
		case Section.Ready.rawValue:
			return self.readyItems[indexPath.row]
		default:
			fatalError("No track at index path: \(indexPath)")
		}
	}


	// MARK - Presentation Detail Navigation

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch (segue.identifier) {
		case .Some(SEGUE_SHOW_ACTIVE_TRACK_DETAIL_ID), .Some(SEGUE_SHOW_PENDING_TRACK_DETAIL_ID):
			let indexPath = self.tableView.indexPathForSelectedRow()!
			let track = trackAtPath(indexPath)

			let trackController = segue.destinationViewController as TrackDetailController
			trackController.ditourModel = self.ditourModel
			trackController.track = track

			if segue.identifier! == SEGUE_SHOW_PENDING_TRACK_DETAIL_ID {
				let downloadStatus = self.downloadStatus?.childStatusForRemoteItem(track) as DownloadContainerStatus
				trackController.downloadStatus = downloadStatus
			}

		case .Some(SEGUE_SHOW_FILE_INFO_ID), .Some(SEGUE_SHOW_PENDING_FILE_INFO_ID):
			let remoteFile = self.remoteItemAtIndexPath(self.tableView.indexPathForSelectedRow()!)
			let fileInfoController = segue.destinationViewController as FileInfoController
			fileInfoController.ditourModel = self.ditourModel
			fileInfoController.remoteFile = remoteFile as RemoteFileStore
			fileInfoController.downloadStatus = self.downloadStatus?.childStatusForRemoteItem(remoteFile)
			
		default:
			println("Prepare for segue with ID: \(segue.identifier) does not match a known case...")
		}
	}



	/* sections for the table view */
	private enum Section : Int {
		case Config, Pending, Ready
		case Count
	}
}




// MARK: - Presentation Group Detail Controller

/* extension to add remote item containing conformance and support for the detail view controllers */
extension PresentationGroupStore : ConcreteRemoteItemContaining {
	/* type of the remote items in this container */
	typealias ItemType = PresentationStore

	var detailTitle : String { return "Group: \(self.shortName)" }


	/* get the remote items and categorize them as to ready or not */
	func remoteItemsByReadyStatus() -> (ready: [ItemType], notReady: [ItemType]) {
		var readyItems = [ItemType]()
		var notReadyItems = [ItemType]()

		let sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		let presentations = self.presentations?.sortedArrayUsingDescriptors(sortDescriptors) as [PresentationStore]

		for presentation in presentations {
			if presentation.isReady {
				readyItems.append(presentation)
			} else {
				notReadyItems.append(presentation)
			}
		}

		return (ready: readyItems, notReady: notReadyItems)
	}
}


/* table controller for displaying detail for a specified presentation group */
class PresentationGroupDetailController : UITableViewController, DownloadStatusDelegate, DitourModelContainer {
	/* main model */
	var ditourModel : DitourModel?

	/* indicator of activite download */
	@IBOutlet var downloadIndicator : UIActivityIndicatorView?

	/* presentation group for which to display detail */
	var group : PresentationGroupStore!

	/* download status */
	var downloadStatus : DownloadContainerStatus? {
		didSet {
			downloadStatus?.delegate = self
			self.updateScheduled = false
		}
	}

	/* array of pending items */
	var pendingItems = Array<PresentationGroupStore.ItemType>()

	/* array of ready items */
	var readyItems = Array<PresentationGroupStore.ItemType>()


	/* indicates whether an update has been scheduled to process any pending changes */
	private var updateScheduled = false


	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.updateScheduled = false

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Now Playing", style: .Done, target: self, action: "popToPlaying")

		self.downloadStatus = self.ditourModel?.downloadStatusForGroup(self.group)
		self.downloadStatus?.delegate = self

		self.title = self.group.detailTitle

		self.updateDownloadIndicator()
	}


	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		// allow updates to be scheduled immediately
		self.updateScheduled = false

		// need to force reload to update presentations whose state changed (e.g. currently playing state)
		self.tableView.reloadData()
	}


	func popToPlaying() {
		self.navigationController?.popToRootViewControllerAnimated(true)
	}


	/* download presentations for this group */
	@IBAction func downloadPresentations(sender: AnyObject?) {
		self.tableView.reloadData()

		if self.ditourModel!.downloading {
			let alert = UIAlertView(title: "Can't Download", message: "You attempted to download a group which is already downloading. You need to cancel first.", delegate: nil, cancelButtonTitle: "Dismiss")
			alert.show()
		} else {
			self.downloadStatus = self.ditourModel?.downloadGroup(self.group, delegate: self)

			if let error = self.downloadStatus?.possibleError {
				let alert = UIAlertView(title: "Download Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Dismiss")
				alert.show()
			}

			self.updateDownloadIndicator()
			self.tableView.reloadData()
		}
	}


	/* cancel download */
	@IBAction func cancelGroupDownload(sender: AnyObject?) {
		self.ditourModel?.cancelDownload()
	}


	func updateDownloadIndicator() {
		if self.ditourModel!.downloading && !self.downloadIndicator!.isAnimating() {
			// download in progress but indicator not animating so animate it
			self.downloadIndicator?.startAnimating()
		} else if !self.ditourModel!.downloading && self.downloadIndicator!.isAnimating() {
			// download not in progress but indicator animating so stop animating it
			self.downloadIndicator?.stopAnimating()
		}
	}


	/* process a status change */
	func downloadStatusChanged(status: DownloadStatus) {
		// throttle the updates to dramatically lower CPU load and reduce backlog of events
		if !self.updateScheduled { // skip if an update has already been scheduled since the display will be refreshed
			self.updateScheduled = true		// indicate that an update will be scheduled
			let NANO_SECOND_DELAY = Int64(250_000_000)	// refresh at most every 0.25 seconds
			let runTime = dispatch_time(DISPATCH_TIME_NOW, NANO_SECOND_DELAY)
			dispatch_after(runTime, dispatch_get_main_queue()) { () -> Void in
				self.updateScheduled = false	// allow another update to be scheduled since we will begin processing the current one
				self.updateDownloadIndicator()
				self.tableView.reloadData()
			}
		}
	}


	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// determine the ready and pending items for consistency with subsequent table data callbacks
		(self.readyItems, self.pendingItems) = self.group.remoteItemsByReadyStatus()

		return Section.Count.rawValue
	}


	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if self.tableView(tableView, numberOfRowsInSection: section) > 0 {	// only display a section title if there are any rows to display
			switch section {
			case Section.Config.rawValue:
				return "Configuration"
			case Section.Pending.rawValue:
				return "Pending Presentations"
			case Section.Ready.rawValue:
				return "Ready Presentations"
			default:
				return nil
			}
		} else {
			return nil
		}
	}


	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case Section.Config.rawValue:
			return self.group.configuration != nil ? 1 : 0
		case Section.Pending.rawValue:
			return self.pendingItems.count
		case Section.Ready.rawValue:
			return self.readyItems.count
		default:
			return 0
		}
	}


	func remoteItemAtIndexPath(indexPath: NSIndexPath) -> RemoteItemStore {
		switch indexPath.section {
		case Section.Config.rawValue:
			return self.group.configuration!
		case Section.Pending.rawValue:
			return self.pendingItems[indexPath.row]
		case Section.Ready.rawValue:
			return self.readyItems[indexPath.row]
		default:
			fatalError("Failed request for remote item at index path: \(indexPath)")
		}
	}


	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		switch indexPath.section {
		case Section.Config.rawValue, Section.Pending.rawValue, Section.Ready.rawValue:
			return self.heightForRemoteItemAtIndexPath(indexPath)
		default:
			return LabelCell.defaultHeight
		}
	}


	private func heightForRemoteItemAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
		let remoteItem = remoteItemAtIndexPath(indexPath)

		if self.isRemoteItemDownloading(remoteItem) {
			return DownloadStatusCell.defaultHeight
		} else {
			return LabelCell.defaultHeight
		}
	}


	private func isRemoteItemDownloading(remoteItem: RemoteItemStore) -> Bool {
		if remoteItem.isReady {
			return false
		} else {
			if let itemDownloadStatus = self.downloadStatus?.childStatusForRemoteItem(remoteItem) {
				return !itemDownloadStatus.completed
			} else {
				return false
			}
		}
	}


	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let remoteItem = self.remoteItemAtIndexPath(indexPath)

		switch indexPath.section {
		case Section.Config.rawValue:
			if self.isRemoteItemDownloading(remoteItem) {
				return self.pendingRemoteFileCell(tableView, indexPath: indexPath)
			} else {
				return self.readyRemoteFileCell(tableView, indexPath: indexPath)
			}
		case Section.Pending.rawValue:
			if self.isRemoteItemDownloading(remoteItem) {
				return self.pendingPresentationCell(tableView, indexPath: indexPath)
			} else {
				return self.readyPresentationCell(tableView, indexPath: indexPath)
			}
		case Section.Ready.rawValue:
			return self.readyPresentationCell(tableView, indexPath: indexPath)
		default:
			fatalError("No match for cell at index path: \(indexPath)")
		}
	}


	private func readyRemoteFileCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let remoteFile = self.remoteItemAtIndexPath(indexPath) as RemoteFileStore
		let cell = tableView.dequeueReusableCellWithIdentifier("ActiveFileCell", forIndexPath: indexPath) as LabelCell
		cell.title = remoteFile.name

		return cell
	}


	private func pendingRemoteFileCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let remoteFile = self.remoteItemAtIndexPath(indexPath) as RemoteFileStore
		let cell = tableView.dequeueReusableCellWithIdentifier("PendingFileCell", forIndexPath: indexPath) as DownloadStatusCell

		cell.title = remoteFile.name

		if let itemDownloadStatus = self.downloadStatus?.childStatusForRemoteItem(remoteFile) {
			cell.setDownloadStatus(itemDownloadStatus)

			if itemDownloadStatus.possibleError != nil {
				cell.subtitle = "Failed"
			} else if itemDownloadStatus.canceled {
				cell.subtitle = "Canceled"
			} else {
				cell.subtitle = ""
			}
		} else {
			cell.subtitle = ""
		}


		return cell
	}


	private func readyPresentationCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let presentation = self.presentationAtPath(indexPath)

		let cell = tableView.dequeueReusableCellWithIdentifier("GroupDetailActivePresentationCell", forIndexPath: indexPath) as LabelCell
		cell.setMarked(presentation.isCurrent)
		cell.title = presentation.name
		cell.subtitle = TIMESTAMP_FORMATTER.stringFromDate(presentation.timestamp)

		return cell
	}


	private func pendingPresentationCell(tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell {
		let presentation = self.presentationAtPath(indexPath)

		let cell = tableView.dequeueReusableCellWithIdentifier("GroupDetailPendingPresentationCell", forIndexPath: indexPath) as DownloadStatusCell

		cell.title = presentation.name

		if let itemDownloadStatus = self.downloadStatus?.childStatusForRemoteItem(presentation) {
			cell.setDownloadStatus(itemDownloadStatus)

			if itemDownloadStatus.possibleError != nil {
				cell.subtitle = "Failed"
			} else if itemDownloadStatus.canceled {
				cell.subtitle = "Canceled"
			} else {
				cell.subtitle = ""
			}
		} else {
			cell.subtitle = ""
		}

		return cell
	}


	private func presentationAtPath(indexPath: NSIndexPath) -> PresentationStore {
		switch indexPath.section {
		case Section.Pending.rawValue:
			return self.pendingItems[indexPath.row]
		case Section.Ready.rawValue:
			return self.readyItems[indexPath.row]
		default:
			fatalError("No track at index path: \(indexPath)")
		}
	}


	// MARK - Presentation Group Detail Navigation

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch (segue.identifier) {
		case .Some(SEGUE_SHOW_ACTIVE_PRESENTATION_DETAIL_ID), .Some(SEGUE_SHOW_PENDING_PRESENTATION_DETAIL_ID):
			let indexPath = self.tableView.indexPathForSelectedRow()!
			let presentation = self.presentationAtPath(indexPath)

			let presentationController = segue.destinationViewController as PresentationDetailController
			presentationController.ditourModel = self.ditourModel
			presentationController.presentation = presentation

			if segue.identifier! == SEGUE_SHOW_PENDING_PRESENTATION_DETAIL_ID {
				presentationController.downloadStatus = self.downloadStatus?.childStatusForRemoteItem(presentation) as DownloadContainerStatus?
			}

		case .Some(SEGUE_GROUP_SHOW_FILE_INFO_ID), .Some(SEGUE_GROUP_SHOW_PENDING_FILE_INFO_ID):
			let remoteFile = self.remoteItemAtIndexPath(self.tableView.indexPathForSelectedRow()!) as RemoteFileStore
			let fileInfoController = segue.destinationViewController as FileInfoController
			fileInfoController.ditourModel = self.ditourModel
			fileInfoController.remoteFile = remoteFile
			fileInfoController.downloadStatus = self.downloadStatus?.childStatusForRemoteItem(remoteFile)

		default:
			println("Prepare for segue with ID: \(segue.identifier) does not match a known case...")
		}
	}



	/* sections for the table view */
	private enum Section : Int {
		case Config, Pending, Ready
		case Count
	}
}






