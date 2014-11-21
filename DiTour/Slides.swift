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
import JavaScriptCore
import UIKit


/* conversion for seconds to nanoseconds */
private let NANOS_PER_SECOND = Int64(1_000_000_000)



/* slide base class for displaying content to a presenter */
class Slide : NSObject {
	/* container of static constants */
	struct Statics {
		static var ALL_SUPPORTED_EXTENSIONS = NSSet()
		static var SLIDE_CLASSES_BY_EXTENSION = [String:Slide.Type]()
	}


	/* duration of the slide's presentation */
	private(set) var duration : Float

	/* file which contain's this slide's media */
	private(set) var mediaFile : String

	/* source of transition to this slide */
	var transitionSource : TransitionSource?


	/* required initializer is used to dynamically initialize instances of any subclass */
	required init(file: String, duration: Float) {
		self.mediaFile = file
		self.duration = duration
	}


	/* make a slide instance based on the file's extension */
	class func makeSlideWithFile(file: String, duration: Float) -> Slide? {
		let fileExtension = file.pathExtension.lowercaseString

		if let SlideType = Statics.SLIDE_CLASSES_BY_EXTENSION[fileExtension] {
			return SlideType(file: file, duration: duration)
		}
		else {
			return nil;
		}
	}


	/* register a slide class so we can instantiate it by file extension */
	private class func registerSlideClass() {
		// store the class names keyed by lower case extension for later use when instantiating slides
		let className = NSStringFromClass( self )
		var slideClassesByExtension = Statics.SLIDE_CLASSES_BY_EXTENSION
		let fileExtensions = self.supportedExtensions()
		for fileExtension in fileExtensions {
			let extensionKey = fileExtension.lowercaseString
			slideClassesByExtension[extensionKey] = self;
		}
		Statics.SLIDE_CLASSES_BY_EXTENSION = slideClassesByExtension

		self.appendSupportedExtensions(fileExtensions)
	}


	// append the supported extensions to ALL_SUPPORTED_EXTENSIONS
	private class func appendSupportedExtensions(fileExtensions: NSSet) {
		let allExtensions = Statics.ALL_SUPPORTED_EXTENSIONS.mutableCopy() as NSMutableSet
		allExtensions.unionSet(fileExtensions)
		Statics.ALL_SUPPORTED_EXTENSIONS = allExtensions.copy()	as NSSet
	}


	/* get the supported extensions */
	class func supportedExtensions() -> NSSet {
		return NSSet()
	}


	class func allSupportedExtensions() -> NSSet {
		return Statics.ALL_SUPPORTED_EXTENSIONS
	}


	/* determine whether this instance's subclass supports the specified extension */
	func matchesExtension(fileExtension: String) -> Bool {
		return self.dynamicType.supportedExtensions().containsObject(fileExtension)
	}


	/* icon is the image itself */
	func icon() -> UIImage? {
		return nil
	}


	/* indicates whether the slide displays just a single frame */
	func isSingleFrame() -> Bool {
		return false
	}


	/* present this slide to the presenter */
	func presentTo(presenter: PresentationDelegate, completionHandler: (Slide)->Void) {
		self.performTransition(presenter)
		self.displayTo(presenter, completionHandler: completionHandler)
	}


	/* perform the transition */
	func performTransition(presenter: PresentationDelegate) {
		if let transitionSource = self.transitionSource {
			let transition = transitionSource.generate()
			presenter.beginTransition(transition)
		}
	}


	/* display the image to the presenter */
	func displayTo(presenter: PresentationDelegate!, completionHandler: (Slide)->Void) {}


	/* cancel the presentation of this slide */
	func cancelPresentation() {}
}



/* slide for displaying an image */
class ImageSlide : Slide {
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
	override func displayTo(presenter: PresentationDelegate!, completionHandler: (Slide)->Void) {
		let imageView = UIImageView(frame: presenter.externalBounds)
		imageView.image = UIImage(contentsOfFile: self.mediaFile)

		presenter.displayMediaView(imageView)

		let delayInSeconds = Int64(self.duration)
		let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NANOS_PER_SECOND )
		dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
			completionHandler(self)
		}
	}
}



/* slide for displaying a movie to the external screen */
class MovieSlide : Slide {
	/* container of static constants */
	struct Statics {
		static let MOVIE_EXTENSIONS = NSSet(array: ["m4v", "mp4", "mov"])
	}

	var completionHandler : ((Slide)->Void)? = nil


	/* register this slide class upon loading this class */
	override class func load() {
		self.registerSlideClass()
	}


	/* get the supported extensions */
	override class func supportedExtensions() -> NSSet {
		return Statics.MOVIE_EXTENSIONS
	}


	/* display the image to the presenter */
	override func displayTo(presenter: PresentationDelegate!, completionHandler: (Slide)->Void) {
		self.completionHandler = completionHandler

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
class PDFSlide : Slide {
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
	override func displayTo(presenter: PresentationDelegate!, completionHandler: (Slide)->Void) {
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


	private func displayPage(pageNumber: size_t, to presenter: PresentationDelegate, completionHandler: (Slide)->Void, runID: NSObject) {
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



/* slide for displaying a rendering of a web page to the presenter */
class WebSlide : Slide, UIWebViewDelegate {
	/* container of static constants */
	struct Statics {
		static let WEB_EXTENSIONS = NSSet(array: ["urlspec"])
	}


	/* options for zooming the web view to fit the external display bounds */
	enum ZoomMode : String {
		case None = "none"
		case Width = "width"
		case Height = "height"
		case Both = "both"
	}


	/* web view in which to render the page corresponding to a URL */
	var webView : UIWebView? = nil

	/* indicates whether the run was canceled */
	var canceled : Bool = false

	/* mode for zooming the web view to fit the external display bounds */
	var zoomMode : ZoomMode = .Both


	/* register this slide class upon loading this class */
	override class func load() {
		self.registerSlideClass()
	}


	/* get the supported extensions */
	override class func supportedExtensions() -> NSSet {
		return Statics.WEB_EXTENSIONS
	}


	deinit {
		self.cleanup()
	}


	/* cleanup the resources */
	func cleanup() {
		if let webView = self.webView {
			webView.delegate = nil
			webView.stopLoading()
			self.webView = nil
		}
	}


	/* cancel the current run */
	override func cancelPresentation() {
		if !self.canceled {	// prevent unnecessary cleanup
			self.canceled = true
			self.cleanup()
		}
	}


	/* slide displays just a single frame */
	override func isSingleFrame() -> Bool {
		return true
	}


	/* display the image to the presenter */
	override func displayTo(presenter: PresentationDelegate!, completionHandler: (Slide)->Void) {
		self.canceled = false;

		// store a local copy to compare during post processing
		let currentRunID = presenter.currentRunID;

		if let slideWebSpec = NSString(contentsOfFile: self.mediaFile, encoding: NSUTF8StringEncoding, error: nil) {
			if let slideURL = NSURL(string: slideWebSpec) {
				let queryDictionary = WebSlide.dictionaryForQuery(slideURL.query)
				if let zoomModeID = queryDictionary["ditour-zoom"]?.lowercaseString {
					self.zoomMode = ZoomMode(rawValue: zoomModeID) ?? .None
				} else {
					self.zoomMode = .Both
				}

				let webView = UIWebView(frame: presenter.externalBounds)
				webView.scalesPageToFit = true
				webView.delegate = self
				webView.backgroundColor = UIColor.blackColor()
				self.webView = webView

				presenter.displayMediaView(webView)
				webView.loadRequest(NSURLRequest(URL: slideURL))

				let delayInSeconds = Int64(self.duration)
				let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NANOS_PER_SECOND )
				dispatch_after(popTime, dispatch_get_main_queue()) { () -> Void in
					// since the web slides share a common web view we should not perform and cleanup upon cancelation as this may interrupt another web slide
					if !self.canceled && currentRunID == presenter.currentRunID {
						completionHandler(self)
					}
				}
			} else {
				completionHandler(self)
			}
		} else {
			completionHandler(self)
		}
	}


	/* handle the web page load completion */
	func webViewDidFinishLoad(webView: UIWebView) {
		// scale the web view's scroll zoom to match the content width so we can see the whole width
		if !self.canceled && self.webView == webView {
			let contentSize = webView.scrollView.contentSize

			if contentSize.width > 0 && contentSize.height > 0 {
				let widthZoom = CGRectGetWidth( webView.bounds ) / contentSize.width
				let heightZoom = CGRectGetHeight( webView.bounds ) / contentSize.height
				var zoomScale = CGFloat(1.0)

				// initialize the content center variables with the default content view center
				let contentView = webView.scrollView.subviews[0] as UIView
				var xContentCenter = CGRectGetMidX( contentView.frame )
				var yContentCenter = CGRectGetMidY( contentView.frame )

				switch ( self.zoomMode ) {
				case .Width:
					zoomScale = widthZoom
					xContentCenter = 0.5 * CGRectGetWidth( webView.scrollView.bounds )	// center the content horizontally in the scroll view

				case .Height:
					zoomScale = heightZoom;
					yContentCenter = 0.5 * CGRectGetHeight( webView.scrollView.bounds )	// center the content vertically in the scroll view

				case .Both:
					// use the minimum zoom to fit both the content width and height on the page
					zoomScale = widthZoom < heightZoom ? widthZoom : heightZoom

					// center the content both horizontally and vertically in the scroll view
					xContentCenter = 0.5 * CGRectGetWidth( webView.scrollView.bounds )
					yContentCenter = 0.5 * CGRectGetHeight( webView.scrollView.bounds )

				default:
					zoomScale = 1.0
				}

				// set the scroll view zoom scale
				if ( zoomScale != 1.0 ) {
					webView.scrollView.minimumZoomScale = zoomScale
					webView.scrollView.maximumZoomScale = zoomScale
					webView.scrollView.zoomScale = zoomScale
				}

				// recenter the content view relative to the scroll view since the scaling is relative to the upper left corner
				contentView.center = CGPointMake( xContentCenter, yContentCenter )
			}
		}
	}


	/* extract the key value pairs for the raw URL query and return then in a dictionary */
	class func dictionaryForQuery(possibleQuery: String?) -> [String:String] {
		// dictionary of key/value string pairs corresponding to the input query
		var dictionary = [String:String]()

		if let query = possibleQuery {
			let scriptContext = JSContext()
			let records = query.componentsSeparatedByString("&")
			for record in records {
				let fields = record.componentsSeparatedByString("=")
				if fields.count == 2 {
					let key = fields[0]
					let scriptCommand = "decodeURIComponent( \"\(fields[1])\" )"
					let scriptResult = scriptContext.evaluateScript(scriptCommand)
					dictionary[key] = scriptResult.toString()
				}
			}
		}

		return dictionary
	}
}





