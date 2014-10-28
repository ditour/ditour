//
//  Slides.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 10/28/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import AVFoundation
import QuartzCore


/* conversion for seconds to nanoseconds */
private let NANOS_PER_SECOND = Int64(1_000_000_000)



/* slide for displaying an image */
private class ImageSlide : ILobbySlide {
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
	override func icon() -> UIImage? {
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



/* slide for displaying a movie to the external screen */
private class MovieSlide : ILobbySlide {
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


	private func clearNotifications() {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}


	private func handlePlayerCompletion(notification: NSNotification) {
		self.clearNotifications()

		if let handler = self.completionHandler {
			handler(self)
		}
	}
}



/* slide for displaying pages from a PDF document as frames */
private class PDFSlide : ILobbySlide {
	/* container of static constants */
	struct Statics {
		static let PDF_EXTENSIONS = NSSet(object: "pdf")
		static var IMAGE_VIEW : UIImageView? = nil
	}

	/* run ID identifying the current Run (if any) */
	var currentRunID : NSObject? = nil


	/* register this slide class upon loading this class */
	override class func load() {
		self.registerSlideClass()
	}


	/* get the supported extensions */
	override class func supportedExtensions() -> NSSet {
		return Statics.PDF_EXTENSIONS
	}


	private func newDocument() -> CGPDFDocumentRef {
		let mediaURL = NSURL(fileURLWithPath: self.mediaFile)
		return CGPDFDocumentCreateWithURL(mediaURL)
	}


	override func cancelPresentation() {
		self.currentRunID = nil
	}


	/* icon is the image itself */
	override func icon() -> UIImage? {
		let documentRef = self.newDocument()
		let pageCount = CGPDFDocumentGetNumberOfPages(documentRef)

		if ( pageCount > 0 ) {
			let pageRef = CGPDFDocumentGetPage(documentRef, 1)
			let image = self.imageFromPageRef(pageRef)
			return image
		} else {
			return nil
		}
	}


	/* generate an image from the specified page */
	private func imageFromPageRef( pageRef: CGPDFPageRef ) -> UIImage {
		let bounds = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox)
		let width = UInt( CGRectGetWidth(bounds) )
		let height = UInt( CGRectGetHeight(bounds) )
		let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
		let options = CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue
		let context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpaceRef, CGBitmapInfo(options))
		CGContextDrawPDFPage(context, pageRef)

		let imageRef = CGBitmapContextCreateImage(context)
		let image = UIImage(CGImage: imageRef)

		return image!
	}


	/* determine whether slide displays just a single frame */
	override func isSingleFrame() -> Bool {
		let document = self.newDocument()
		let pageCount = CGPDFDocumentGetNumberOfPages(document)
		return pageCount == 1
	}


	/* display the image to the presenter */
	override func displayTo(presenter: PresentationDelegate!, completionHandler: ILobbySlideCompletionHandler!) {
		let runID = NSDate()
		self.currentRunID = runID

		let documentRef = self.newDocument()
		let pageCount = CGPDFDocumentGetNumberOfPages(documentRef)

		if ( pageCount > 0 ) {
			// pages begin with 1
			self.displayPage(1, to: presenter, completionHandler: completionHandler, runID: runID)
		} else {	// no pages to display
			completionHandler(self)
		}
	}


	private func displayPage(pageNumber: size_t, to presenter: PresentationDelegate, completionHandler: (ILobbySlide)->Void, runID: NSObject) {
		let documentRef = self.newDocument()
		let pageCount = CGPDFDocumentGetNumberOfPages(documentRef)

		let pageRef = CGPDFDocumentGetPage(documentRef, pageNumber)
		let image = self.imageFromPageRef(pageRef)

		if Statics.IMAGE_VIEW == nil || Statics.IMAGE_VIEW?.bounds != presenter.externalBounds {
			Statics.IMAGE_VIEW = UIImageView(frame: presenter.externalBounds)
		}
		Statics.IMAGE_VIEW?.image = image

		presenter.displayMediaView(Statics.IMAGE_VIEW!)

		let nextPageNumber = pageNumber + 1
		let delayInSeconds = Int64(self.duration)
		let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NANOS_PER_SECOND )
		dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
			if ( runID == self.currentRunID ) { // make sure the user hasn't switched to another track
				// if the page number is valid display the image for the page otherwise we are done
				if ( nextPageNumber <= pageCount ) {
					self.performTransition(presenter);
					self.displayPage(nextPageNumber, to: presenter, completionHandler: completionHandler, runID: runID)
				} else {	// no more pages to present
					completionHandler( self );
				}
			}
		}
	}
}





