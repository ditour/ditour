//
//  Presentation.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 10/22/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore



/* view controller for displaying content on the external screen */
private class ExternalViewController : UIViewController {
	/* external view should always be displayed in portait mode */
	override func supportedInterfaceOrientations() -> Int {
		let x : UInt = 3
		let y : Int = Int( x )
		return Int( UIInterfaceOrientationMask.Portrait.rawValue )
	}


	/* prevent the external view from rotating when the device is in landscape orientation */
	override func shouldAutorotate() -> Bool {
		return false
	}
}



/* delegate implemented by presenters of media */
@objc protocol PresentationDelegate {
	/* unique identifier of the current run */
	var currentRunID : NSObject? { get set }

	/* window for displaying content on the external screen */
	var externalWindow : UIWindow? { get }

	/* bounds of the external window */
	var externalBounds : CGRect { get }

	/* begin the animated transition to the new content */
	func beginTransition(transition: CATransition!)

	/* display the specified mediaView in the content view of the external window */
	func displayMediaView(mediaView: UIView!)
}



/* presents the media to an external screen */
class ExternalPresenter : NSObject, PresentationDelegate {
	/* unique identifier of the current run */
	var currentRunID : NSObject?

	/* window for displaying content on the external screen */
	private(set) var externalWindow : UIWindow?

	/* bounds of the external window */
	var externalBounds : CGRect { return self.externalWindow?.bounds ?? CGRect() }

	/* container view within the external window that contains the media to display */
	private var contentView : UIView?


	override init() {
		super.init()

		// respond to external screen connection changes
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleScreensChange:", name: UIScreenDidConnectNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleScreensChange:", name: UIScreenDidDisconnectNotification, object: nil)
	}


	/* begin the animated transition to the new content */
	func beginTransition(transition: CATransition!) {
		if ( transition != nil && self.externalWindow != nil ) {
			self.contentView?.layer.addAnimation(transition, forKey: nil)
		}
	}


	/* display the specified mediaView in the content view of the external window */
	func displayMediaView(mediaView: UIView!) {
		// remove all subviews from the content view (should just be the last media view but just in case remove all subviews)
		if let contentView = self.contentView {
			for subView in contentView.subviews {
				(subView as UIView).removeFromSuperview()
			}

			contentView.addSubview( mediaView )
		}
	}


	/* handle a screen change notification */
	func handleScreensChange(notification : NSNotification) {
		self.updateConfiguration()
	}


	/* update the configuration */
	func updateConfiguration() {
		self.configureExternalDisplay()
	}


	/* configure the external display */
	func configureExternalDisplay() {
		let screens = UIScreen.screens() as [UIScreen]

		// test whether there is an external screen in addition to the device's screen
		if screens.count > 1 {
			let externalScreen = screens[1]		// first screen beyond the device's screen
			externalScreen.currentMode = externalScreen.preferredMode

			// create the external window
			self.externalWindow = UIWindow(frame: externalScreen.bounds)
			self.externalWindow?.screen = externalScreen
			self.externalWindow?.backgroundColor = UIColor.blackColor()

			// create the content view for the external window
			let contentView = UIView(frame: externalScreen.bounds)
			contentView.layer.borderWidth = 0
			self.contentView = contentView

			// create the view controller for the content in the external window
			let contentViewController = ExternalViewController(nibName: nil, bundle: nil)
			contentViewController.view = contentView
			self.externalWindow?.rootViewController = contentViewController

			// show the window
			self.externalWindow?.hidden = false
		}
		else {
			println( "No external screen..." )
			self.externalWindow = nil
		}
	}
}



/* Generater of a transition */
class TransitionSource : NSObject {
	var duration : CFTimeInterval = 0.0
	var type : String?
	var subType : String?


	init( config : [String:NSObject] ) {
		if let duration = config["duration"] as? Double {
			self.duration = duration
		}

		self.type = config["type"] as? String
		self.subType = config["subtype"] as? String
	}


	func generate() -> CATransition {
		let transition = CATransition()
		transition.type = self.type
		transition.subtype = self.subType
		transition.duration = self.duration
		return transition;
	}
}



// private constants for use by Track
private let DEFAULT_SLIDE_DURATION = Float(5.0)
private let DEFAULT_SINGLE_IMAGE_SLIDE_DURATION = Float(600.0)

/* Track of sequential slides to present */
class Track : NSObject {
	/* this track's icon */
	let icon : UIImage

	/* this track's label */
	let label : String

	/* array of slides to display */
	let slides : [Slide]

	/* default duration for a slide */
	let defaultSlideDuration : Float

	/* default transition source for each slide */
	let defaultTransitionSource : TransitionSource? = nil

	/* extra delay over and above the slide duration (used when there is just a single image slide) */
	let extraTrackDuration : Float

	/* indicates whether this track is playing */
	private var playing : Bool = false

	/* the current slide that is playing (if any) */
	private var currentSlide : Slide? = nil

	/* initialize the track from the core data track store */
	init( trackStore: TrackStore ) {
		self.label = trackStore.title

		let possibleConfig = trackStore.effectiveConfiguration
		let defaultSlideDuration = possibleConfig?["slideDuration"] as? Float ?? DEFAULT_SLIDE_DURATION
		self.defaultSlideDuration = defaultSlideDuration

		if let slideTransitionConfig = possibleConfig?["slideTransition"] as? [String: NSObject] {
			self.defaultTransitionSource = TransitionSource( config: slideTransitionConfig )
		}

		// add the track icon and the slides
		var trackIcon : UIImage?
		var slides = [Slide]()
		for media in trackStore.remoteMedia.array {
			let mediaPath = media.absolutePath()

			// if the filename is Icon.* then it is the icon and all others are slides
			if media.name.stringByDeletingPathExtension.lowercaseString == "icon" {
				trackIcon = UIImage(contentsOfFile: mediaPath)
			} else {
				if let slide = Slide.makeSlideWithFile(mediaPath, duration: self.defaultSlideDuration) {
					if let slideTransitionSource = self.defaultTransitionSource {
						slide.transitionSource = slideTransitionSource
					}
					slides.append(slide)
				}
			}
		}

		// if there was no explicit icon file provided then use first image if any
		if trackIcon == nil {
			for slide in slides {
				if let slideIcon = slide.icon() {
					trackIcon = slideIcon
					break
				}
			}
		}

		// if there is still no icon provide a default one from this application's main bundle
		self.icon = trackIcon ?? UIImage(named: "DefaultSlideIcon")!

		// if there is only one slide and it is an image slide then the slide duration may be extended if the config file specifies it
		var extraTrackDuration = Float(0.0)
		if slides.count == 1 {
			let firstSlide = slides[0]
			if firstSlide.isSingleFrame() {		// it's an image
				let trackDuration = possibleConfig?["singleImageSlideTrackDuration"] as? Float ?? DEFAULT_SINGLE_IMAGE_SLIDE_DURATION
				extraTrackDuration = ( trackDuration > defaultSlideDuration ) ? trackDuration - defaultSlideDuration : 0.0
			}
		}
		self.extraTrackDuration = extraTrackDuration

		// copy the slides to the instance variable
		self.slides = slides
	}


	/* present this track to the presenter and call the completion handler upon completion of this track */
	func presentTo( presenter: PresentationDelegate, completionHandler: (Track)->Void ) {
		self.playing = true

		let slides = self.slides
		let runID = NSDate()
		if slides.count > 0 {
			presenter.currentRunID = runID
			self.presentSlide( atIndex: 0, to: presenter, forRun: runID, completionHandler: completionHandler )
		} else {
			completionHandler(self)
		}
	}


	/* present the slide at the specified index to the presenter and call the completion handler upon completion */
	private func presentSlide( atIndex slideIndex: UInt, to presenter: PresentationDelegate, forRun runID: NSObject, completionHandler: (Track)->Void ) {
		let slides = self.slides
		let slide = slides[Int(slideIndex)]
		self.currentSlide = slide

		// present the specified slide and upon completion present the next slide if any or complete the track
		slide.presentTo(presenter){ theSlide -> Void in
			if self.playing {
				let nextSlideIndex = slideIndex + 1
				if let currentRunID = presenter.currentRunID {	// verify the current run is the one we are on
					if runID == currentRunID {
						if nextSlideIndex < UInt(slides.count) {
							self.presentSlide(atIndex: nextSlideIndex, to: presenter, forRun: runID, completionHandler: completionHandler)
						} else {
							let trackDelay = self.extraTrackDuration

							// if there is an extra track delay then we will delay calling the completion handler
							if trackDelay > 0.0 {
								let delayInSeconds = Int64(trackDelay)
								let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * Int64(1_000_000_000) )
								dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
									completionHandler(self)		// call this track's completion handler
								}
							} else {
								completionHandler(self)	// call this track's completion handler
							}
						}
					}
				}
			}
		}
	}


	/* cancel the presentation of this track */
	func cancelPresentation() {
		self.playing = false

		// cancel the current slide (if any) presentation
		self.currentSlide?.cancelPresentation()

		// clear the current slide to avoid unnecessary slide cancelation
		self.currentSlide = nil
	}
}




