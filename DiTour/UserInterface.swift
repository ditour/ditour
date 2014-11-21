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
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TrackCell", forIndexPath: indexPath) as ILobbyTrackViewCell

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




