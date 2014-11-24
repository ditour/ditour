//
//  Views.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 11/20/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation


// segue IDs
private let SEGUE_SHOW_CONFIGURATION_ID = "MainToGroups"


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



/* table cell displaying the download status */
class DownloadStatusCell : LabelCell {
	/* static constants */
	private struct Constants {
		/* format for displaying the numerical progress */
		static let PROGRESS_FORMAT : NSNumberFormatter = {
			let format = NSNumberFormatter()
			format.numberStyle = .PercentStyle
			format.minimumFractionDigits = 2
			format.maximumFractionDigits = 2
			return format
		}()
	}


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
		self.progressLabel.text = Constants.PROGRESS_FORMAT.stringFromNumber(progress)
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





