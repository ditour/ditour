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



class Presenter : NSObject, ILobbyPresentationDelegate {
	/* unique identifier of the current run */
	var currentRunID : AnyObject?

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
struct TransitionSource {
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


