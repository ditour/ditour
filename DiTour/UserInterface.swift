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
private let SEGUE_SHOW_PRESENTATOIN_MASTERS_ID = "GroupToPresentationMasters"



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
	@IBAction func reloadPresentation(sender: NSObject) {
		self.ditourModel?.reloadPresentation()
	}


	/* handle changes to the model's tracks or current track to update the display accordingly */
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
		// test against the source object and the keyPath
		switch (object, keyPath) {

		// event due to model tracks change
		case (_ as DitourModel, "tracks"):
			// since the model's tracks have changed, relaod the collection view to display the new tracks
			dispatch_async(dispatch_get_main_queue()) { () -> Void in
				self.collectionView.reloadData()
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
				dispatch_async(dispatch_get_main_queue()) { () -> Void in
					self.collectionView.reloadItemsAtIndexPaths(cellPaths)
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
		self.collectionView.deselectItemAtIndexPath(indexPath, animated: true)

		self.ditourModel?.playTrackAtIndex(UInt(indexPath.item))
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		self.collectionView.allowsSelection = true
		self.collectionView.allowsMultipleSelection = false

		self.navigationController?.navigationBar.barStyle = .BlackTranslucent
	}


	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		switch ( segue.identifier, segue.destinationViewController ) {

		case ( .Some(SEGUE_SHOW_CONFIGURATION_ID), let configController as ILobbyPresentationGroupsTableController ):
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
			dispatch_after(runTime, dispatch_get_main_queue()) { () -> Void in
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


	@IBAction func displayPreview(sender: NSObject) {
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
		group.managedObjectContext?.performBlockAndWait{ () -> Void in
			groupID = group.objectID
		}

		var editingGroup : PresentationGroupStore!
		self.editContext?.performBlockAndWait{ () -> Void in
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
	private func cancelGroupEditing() {
		self.editingCell?.locationField.resignFirstResponder()

		self.exitEditMode()

		self.updateControls()
		self.tableView.reloadData()
	}


	/* configure the editing state */
	private func setupEditing() {
		// create a new edit context
		self.editContext = self.ditourModel!.createEditContextOnMain()

		// get the current root ID
		var storeRootID : NSManagedObjectID! = nil
		self.mainRootStore!.managedObjectContext!.performBlockAndWait{ () -> Void in
			storeRootID = self.mainRootStore?.objectID
		}

		// create a new root store corresponding to the same current root
		self.editContext?.performBlockAndWait{ () -> Void in
			self.editingRootStore = self.editContext!.objectWithID(storeRootID) as? RootStore
		}

		self.currentRootStore = self.editingRootStore
	}


	/* enter the batch editing mode */
	private func editTable() {
		self.editing = true
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





