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
import SceneKit
import WebKit


/* conversion for seconds to nanoseconds */
private let nanosPerSecond = Int64(1_000_000_000)



// MARK: - Slide Base Class

/* slide base class for displaying content to a presenter */
class Slide {
	/* set of all supported extensions and the slide classes keyed by extension */
	static let slideClassesByExtension : [String:Slide.Type] = {
		var classesByExtension = [String:Slide.Type]()

		// get the curried function which references the common variable for classes by extension
		let register = Slide.registerSlideClass(classesByExtension: &classesByExtension)

		// register each Slide subclass to append to the supported extensions
		register(slideClass: ImageSlide.self)

		register(slideClass: SceneSlide.self)

		register(slideClass: MovieSlide.self)
		register(slideClass: PDFSlide.self)
		register(slideClass: WebpageSlide.self)

		return classesByExtension
	}()


	/* supported extensions by the Slide subclass */
	class var supportedExtensions : Set<String> { return [] }

	/* duration of the slide's presentation */
	final private(set) var duration : Float

	/* file which contain's this slide's media */
	final private(set) var mediaFile : String

	/* source of transition to this slide */
	final var transitionSource : TransitionSource?


	/* required initializer is used to dynamically initialize instances of any subclass */
	required init(file: String, duration: Float) {
		self.mediaFile = file
		self.duration = duration
	}


	/* determine whether the specified file extensions is supported */
	static func canMakeSlideForExtension(fileExtension : String) -> Bool {
		return slideClassesByExtension[fileExtension.lowercaseString] != nil
	}


	/* make a slide instance based on the file's extension */
	static func makeSlideWithFile(file: String, duration: Float) -> Slide? {
		let fileExtension = file.pathExtension.lowercaseString

		if let SlideType = slideClassesByExtension[fileExtension] {
			return SlideType.init(file: file, duration: duration)
		}
		else {
			return nil;
		}
	}


	/* register a slide class so we can instantiate it by file extension */
	private static func registerSlideClass<T : Slide>(inout classesByExtension classesByExtension : [String:Slide.Type])( slideClass : T.Type ) {
		let fileExtensions = slideClass.supportedExtensions

		for fileExtension in fileExtensions {
			let extensionKey = fileExtension.lowercaseString
			classesByExtension[extensionKey] = slideClass;
		}
	}


	/* determine whether this instance's subclass supports the specified extension */
	final func matchesExtension(fileExtension: String) -> Bool {
		return self.dynamicType.supportedExtensions.contains(fileExtension)
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
	func presentTo(presenter: Presenter, completionHandler: (Slide)->Void) {
		self.performTransition(presenter)
		self.displayTo(presenter, completionHandler: completionHandler)
	}


	/* perform the transition */
	final func performTransition(presenter: Presenter) {
		if let transitionSource = self.transitionSource {
			let transition = transitionSource.generate()
			presenter.beginTransition(transition)
		}
	}


	/* display the image to the presenter */
	func displayTo(presenter: Presenter!, completionHandler: (Slide)->Void) {}


	/* cancel the presentation of this slide */
	func cancelPresentation() {}
}



// MARK: - Private Slide Utility Functions

/* calculate the largest media view frame which fits within the screen frame while preserving the media's aspect ratio */
private func calcMediaFrame(screenFrame screenFrame: CGRect, mediaSize: CGSize) -> CGRect? {
	if mediaSize.height > 0 && screenFrame.height > 0 {
		let screenAspectRatio = screenFrame.width / screenFrame.height
		let mediaAspectRatio = mediaSize.width / mediaSize.height

		// calculate the media's frame to fit in the display as large as possible while preserving the media's aspect ratio
		if mediaAspectRatio > screenAspectRatio {				// width constrained
			let width = screenFrame.width						// fill out the entire width available
			let height = width / mediaAspectRatio				// scale the height preserving aspect ratio
			let offset = (screenFrame.height - height) / 2		// center the media vertically
			return CGRect(x: 0.0, y: offset, width: width, height: height)
		} else {												// height constrained
			let height = screenFrame.height						// fill out the entire height available
			let width = height * mediaAspectRatio				// scale the width preserving aspect ratio
			let offset = (screenFrame.width - width) / 2		// center the media horizontally
			return CGRect(x: offset, y: 0.0, width: width, height: height)
		}
	} else {
		return nil
	}
}


// MARK: - Image Slide

/* slide for displaying an image */
private final class ImageSlide : Slide {
	/* image extensions */
	private static let imageExtensions : Set<String> = ["png", "jpg", "jpeg", "gif"]

	/* supported extensions by this Slide subclass */
	override class var supportedExtensions : Set<String> { return imageExtensions }


	/* icon is the image itself */
	override func icon() -> UIImage? {
		return UIImage(contentsOfFile: self.mediaFile)
	}


	/* slide displays just a single frame */
	override func isSingleFrame() -> Bool {
		return true
	}


	/* display the image to the presenter */
	override func displayTo(presenter: Presenter!, completionHandler: (Slide)->Void) {
		if let image = UIImage(contentsOfFile: self.mediaFile), imageFrame = calcMediaFrame(screenFrame: presenter.externalBounds, mediaSize: image.size) {
			let imageView = UIImageView(frame: imageFrame)
			imageView.image = UIImage(contentsOfFile: self.mediaFile)

			presenter.displayMediaView(imageView)

			let delayInSeconds = Int64(self.duration)
			let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * nanosPerSecond )
			dispatch_after(popTime, dispatch_get_main_queue()) {
				completionHandler(self)
			}
		} else {
			completionHandler(self)
		}
	}
}


// MARK: - Slide for Displaying a 3D Scene

/* Slide for displaying an COLLADA 3D model using SceneKit. */
@available(iOS 8.0, *)
private final class SceneSlide : Slide {
	// The dae file must be compressed and contain materials (if any referenced) internally.
	private static let sceneExtensions : Set<String> = ["dae"]


	/* supported extensions by this Slide subclass */
	override class var supportedExtensions : Set<String> {
		// register if SceneKit is supported (available starting in iOS 8)
		return NSClassFromString("SCNScene") != nil ? sceneExtensions : []
	}


	/* icon is the image itself */
	override func icon() -> UIImage? {
		return nil
	}


	/* slide displays just a single frame */
	override func isSingleFrame() -> Bool {
		return true
	}


	/* display the image to the presenter */
	override func displayTo(presenter: Presenter!, completionHandler: (Slide)->Void) {
		do {
			let location = NSURL(fileURLWithPath: self.mediaFile)
			let scene = try SCNScene(URL: location, options: nil)
			// get the bounding box
			var minBox = SCNVector3(x: 0, y: 0, z: 0)
			var maxBox = SCNVector3(x: 0, y: 0, z: 0)
			scene.rootNode.getBoundingBoxMin(&minBox, max: &maxBox)
			let nativeSceneWidth =  CGFloat(maxBox.x - minBox.x)
			let nativeSceneHeight = CGFloat(maxBox.y - minBox.y)
			let nativeSceneSize = CGSize(width: nativeSceneWidth, height: nativeSceneHeight)

			if let sceneFrame = calcMediaFrame(screenFrame: presenter.externalBounds, mediaSize: nativeSceneSize) {
				let view = SCNView(frame: sceneFrame)
				view.scene = scene
				view.backgroundColor = UIColor.blackColor()

				presenter.displayMediaView(view)

				let delayInSeconds = Int64(self.duration)
				let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * nanosPerSecond )
				dispatch_after(popTime, dispatch_get_main_queue()) {
					completionHandler(self)
				}
			} else {
				completionHandler(self)
			}
		} catch _ {
			completionHandler(self)
		}
	}
}


// MARK: - Movie Slide

/* slide for displaying a movie to the external screen */
private final class MovieSlide : Slide {
	/* container of static constants */
	private static let movieExtensions : Set<String> = ["m4v", "mp4", "mov"]

	/* supported extensions by this Slide subclass */
	override class var supportedExtensions : Set<String> { return movieExtensions }

	/* handler to call upon completion of the movie */
	var completionHandler : ((Slide)->Void)? = nil


	/* display the image to the presenter */
	override func displayTo(presenter: Presenter!, completionHandler: (Slide)->Void) {
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


	func handlePlayerCompletion(notification: NSNotification) {
		self.clearNotifications()

		if let handler = self.completionHandler {
			handler(self)
		}
	}
}


// MARK: - PDF Slide

/* slide for displaying pages from a PDF document as frames */
private final class PDFSlide : Slide {
	/* container of static constants */
	private static let pdfExtensions : Set<String> = ["pdf"]

	/* supported extensions by this Slide subclass */
	override class var supportedExtensions : Set<String> { return pdfExtensions }

	/* run ID identifying the current Run (if any) */
	var currentRunID : NSObject? = nil


	private func newDocument() -> CGPDFDocumentRef {
		let mediaURL = NSURL(fileURLWithPath: self.mediaFile)
		return CGPDFDocumentCreateWithURL(mediaURL)!
	}


	override func cancelPresentation() {
		self.currentRunID = nil
	}


	/* icon is the image itself */
	override func icon() -> UIImage? {
		let documentRef = self.newDocument()
		let pageCount = CGPDFDocumentGetNumberOfPages(documentRef)

		if ( pageCount > 0 ) {
			let pageRef = CGPDFDocumentGetPage(documentRef, 1)!
			let image = self.imageFromPageRef(pageRef)
			return image
		} else {
			return nil
		}
	}


	/* generate an image from the specified page */
	private func imageFromPageRef( pageRef: CGPDFPageRef ) -> UIImage? {
		let bounds = CGPDFPageGetBoxRect(pageRef, .CropBox)
		let width = Int( CGRectGetWidth(bounds) )
		let height = Int( CGRectGetHeight(bounds) )
		let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
		let options = CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedFirst.rawValue
		let context = CGBitmapContextCreate(nil, width, height, 8, 0, colorSpaceRef, options)
		CGContextDrawPDFPage(context, pageRef)

		guard let imageRef = CGBitmapContextCreateImage(context) else { return nil }
		return UIImage(CGImage: imageRef)
	}


	/* determine whether slide displays just a single frame */
	override func isSingleFrame() -> Bool {
		let document = self.newDocument()
		let pageCount = CGPDFDocumentGetNumberOfPages(document)
		return pageCount == 1
	}


	/* display the image to the presenter */
	override func displayTo(presenter: Presenter!, completionHandler: (Slide)->Void) {
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


	private func displayPage(pageNumber: size_t, to presenter: Presenter, completionHandler: (Slide)->Void, runID: NSObject) {
		let documentRef = self.newDocument()
		let pageCount = CGPDFDocumentGetNumberOfPages(documentRef)

		guard let pageRef = CGPDFDocumentGetPage(documentRef, pageNumber) else { completionHandler(self); return }
		guard let image = self.imageFromPageRef(pageRef) else { completionHandler(self); return }
		guard let imageFrame = calcMediaFrame(screenFrame: presenter.externalBounds, mediaSize: image.size) else { completionHandler(self); return }

		let imageView = UIImageView(frame: imageFrame)
		imageView.image = image

		presenter.displayMediaView(imageView)

		let nextPageNumber = pageNumber + 1
		let delayInSeconds = Int64(self.duration)
		let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * nanosPerSecond )
		dispatch_after(popTime, dispatch_get_main_queue()) {
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


// MARK: - Webpage Slide

/* slide for displaying a rendering of a web page to the presenter */
private final class WebpageSlide : Slide {
	/* container of static constants */
	private static let webExtensions : Set<String> = ["urlspec"]

	/* supported extensions by this Slide subclass */
	override class var supportedExtensions : Set<String> { return webExtensions }


	/* options for zooming the web view to fit the external display bounds */
	enum ZoomMode : String {
		case None = "none"
		case Width = "width"
		case Height = "height"
		case Both = "both"
	}


	/* web view in which to render the page corresponding to a URL */
	var webView : WKWebView? = nil

	/* indicates whether the run was canceled */
	var canceled : Bool = false

	/* mode for zooming the web view to fit the external display bounds */
	var zoomMode : ZoomMode = .Both

	/* handler of webview */
	private var webViewHandler : WebViewHandler!


	/* required initializer is used to dynamically initialize instances of any subclass */
	required init(file: String, duration: Float) {
		super.init(file: file, duration: duration)

		self.webViewHandler = WebViewHandler(slide: self)
	}


	deinit {
		self.cleanup()
	}


	/* cleanup the resources */
	func cleanup() {
		if let webView = self.webView {
			webView.navigationDelegate = nil
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
	override func displayTo(presenter: Presenter!, completionHandler: (Slide)->Void) {
		self.canceled = false;

		// store a local copy to compare during post processing
		let currentRunID = presenter.currentRunID;

		do {
			let slideWebSpec = try NSString(contentsOfFile: self.mediaFile, encoding: NSUTF8StringEncoding)
			if let slideURL = NSURL(string: slideWebSpec as String) {
				print("")
				//print("Loading Slide URL: \(slideURL)")
				let queryDictionary = WebpageSlide.dictionaryForQuery(slideURL.query)
				//print("query dictionary: \(queryDictionary)")
				if let zoomModeID = queryDictionary["ditour-zoom"]?.lowercaseString {
					self.zoomMode = ZoomMode(rawValue: zoomModeID) ?? .None
				} else {
					self.zoomMode = .Both
				}

				let webView = WKWebView(frame: presenter.externalBounds)
				//webView.scalesPageToFit = true
				webView.navigationDelegate = self.webViewHandler
				webView.backgroundColor = UIColor.blackColor()
				self.webView = webView

				// inject webslide.js into the web page to support a callback to resize the slide
				webView.configuration.userContentController.addScriptMessageHandler(self.webViewHandler, name: "resize")
				let webscriptURL = NSBundle.mainBundle().URLForResource("webslide", withExtension: "js")
				let webscript = try! NSString(contentsOfURL: webscriptURL!, usedEncoding: nil) as String
				let resizeScript = WKUserScript(source: webscript, injectionTime: .AtDocumentEnd, forMainFrameOnly: true)
				webView.configuration.userContentController.addUserScript(resizeScript)

				presenter.displayMediaView(webView)
				webView.loadRequest(NSURLRequest(URL: slideURL))

				let delayInSeconds = Int64(self.duration)
				let popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * nanosPerSecond )
				dispatch_after(popTime, dispatch_get_main_queue()) {
					// since the web slides share a common web view we should not perform and cleanup upon cancelation as this may interrupt another web slide
					if !self.canceled && currentRunID == presenter.currentRunID {
						completionHandler(self)
					}
				}
			} else {
				completionHandler(self)
			}
		} catch _ {
			completionHandler(self)
		}
	}


	/* extract the key value pairs for the raw URL query and return then in a dictionary */
	static func dictionaryForQuery(possibleQuery: String?) -> [String:String] {
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


	/* handles web view callbacks */
	private final class WebViewHandler : NSObject, WKNavigationDelegate, WKScriptMessageHandler {
		/* slide for which the web view is managed */
		unowned let slide : WebpageSlide


		// initializer
		init(slide: WebpageSlide) {
			self.slide = slide
			super.init()
		}

		// process callbacks from the web page
		@objc func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
			switch message.name {
			case "resize":
				guard let webView = message.webView, sizeDictionary = message.body as? NSDictionary as? Dictionary<String,AnyObject> else { break }
				guard let width = sizeDictionary["width"] as? Double else { break }
				guard let height = sizeDictionary["height"] as? Double else { break }
				let size = CGSize(width: width, height: height)
				resizeSlideView(webView, clientSize: size)
			default:
				break
			}
		}

		private func resizeSlideView(webView: WKWebView, clientSize: CGSize) {
			// scale the web view's scroll zoom to match the content width so we can see the whole width
			if !self.slide.canceled && self.slide.webView == webView {
				let contentSize = webView.scrollView.contentSize

				guard let parentView = webView.superview else { return }

				var xOffset = 0 as CGFloat
				var yOffset = 0 as CGFloat
				if contentSize.width > 0 && contentSize.height > 0 {
					let widthZoom = parentView.bounds.size.width / contentSize.width
					let heightZoom = parentView.bounds.size.height / contentSize.height

					// verify that th zoom is not anomalous and if it is just return
					if heightZoom == 0 || widthZoom == 0 {
						return
					}

					switch ( self.slide.zoomMode ) {
					case .Width:
						let scale = widthZoom / heightZoom
						webView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)
						webView.frame.size.width = parentView.bounds.size.width / scale
						yOffset = (parentView.bounds.size.height - scale * webView.bounds.size.height)/2

					case .Height:
						let scale = heightZoom / widthZoom
						webView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)
						webView.bounds.size.height = parentView.bounds.size.height / scale
						xOffset = (parentView.bounds.size.width - scale * webView.bounds.size.width)/2

					case .Both:
						if ( heightZoom < widthZoom ) {		// height is the constraining dimension
							let scale = heightZoom / widthZoom
							webView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)
							webView.bounds.size.height = parentView.bounds.size.height / scale
							xOffset = (parentView.bounds.size.width - scale * webView.bounds.size.width)/2
						} else {		// width is the constraining dimension
							let scale = widthZoom / heightZoom
							webView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)
							webView.frame.size.width = parentView.bounds.size.width / scale
							yOffset = (parentView.bounds.size.height - scale * webView.bounds.size.height)/2
						}

					default:
						break
					}

					// center the web view horizontally
					if xOffset >= 0 {
						webView.frame.origin.x = xOffset
					}

					// center the web view vertically
					if yOffset >= 0 {
						webView.frame.origin.y = yOffset
					}
				}
			}
		}


		/* Handle the web page load completion. Must mark the optional WKNavigationDelegate protocol method @objc so it will be considered as implemented. */
		@objc func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
			// trigger the resizing of the slide
			webView.evaluateJavaScript("resizeDiTourSlide()") { (result, error) -> Void in }
		}
	}
}





