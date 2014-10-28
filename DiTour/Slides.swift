//
//  Slides.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 10/28/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import AVFoundation


/* conversion for seconds to nanoseconds */
private let NANOS_PER_SECOND = Int64(1_000_000_000)



/* slide for displaying an image */
class ImageSlide : ILobbySlide {
	/* container of static constants */
	struct Statics {
		static let IMAGE_EXTENSIONS = NSSet(array: ["png", "jpg", "jpeg", "gif"])
	}


	/* register this slide class upon loading this class */
	override class func load() {
		self.registerSlideClass()
	}


	/* get the supported extensions */
	override class func supportedExtensions() -> NSSet {
		return Statics.IMAGE_EXTENSIONS
	}


	/* icon is the image itself */
	override func icon() -> UIImage! {
		return UIImage(contentsOfFile: self.mediaFile)
	}


	/* slide displays just a single frame */
	override func isSingleFrame() -> Bool {
		return true
	}


	/* display the image to the presenter */
	override func displayTo(presenter: PresentationDelegate!, completionHandler handler: ILobbySlideCompletionHandler!) {
		let imageView = UIImageView(frame: presenter.externalBounds)
		imageView.image = UIImage(contentsOfFile: self.mediaFile)

		presenter.displayMediaView(imageView)

		let delayInSeconds = Int64(self.duration)
		let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NANOS_PER_SECOND )
		dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
			handler(self)
		}
	}
}



/* slide for displaying an image */
class MovieSlide : ILobbySlide {
	/* container of static constants */
	struct Statics {
		static let MOVIE_EXTENSIONS = NSSet(array: ["m4v", "mp4", "mov"])
	}

	var completionHandler : ((ILobbySlide)->Void)? = nil


	/* register this slide class upon loading this class */
	override class func load() {
		self.registerSlideClass()
	}


	/* get the supported extensions */
	override class func supportedExtensions() -> NSSet {
		return Statics.MOVIE_EXTENSIONS
	}


	/* display the image to the presenter */
	override func displayTo(presenter: PresentationDelegate!, completionHandler handler: ILobbySlideCompletionHandler!) {
		self.completionHandler = handler

		let mediaURL = NSURL(fileURLWithPath: self.mediaFile)
		let asset = AVURLAsset(URL: mediaURL, options: nil)
		let videoItem = AVPlayerItem(asset: asset)
		let player = AVPlayer(playerItem: videoItem)

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlePlayerCompletion:", name: AVPlayerItemDidPlayToEndTimeNotification, object: videoItem)

		let videoView = UIView(frame: presenter.externalBounds)
		let videoLayer = AVPlayerLayer(player: player)
		videoLayer.contentsGravity = kCAGravityResizeAspect;
		videoLayer.frame = videoView.frame;
		videoLayer.backgroundColor = UIColor.blackColor().CGColor
		videoView.layer.addSublayer(videoLayer)

		presenter.displayMediaView(videoView)

		player.play()
	}


	override func cancelPresentation() {
		self.clearNotifications()
	}


	func clearNotifications() {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}


	func handlePlayerCompletion(notification: NSNotification) {
		self.clearNotifications()

		if let handler = self.completionHandler {
			handler(self)
		}
	}
}





