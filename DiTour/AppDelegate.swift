//
//  AppDelegate.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 9/18/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, UIGuidedAccessRestrictionDelegate {
	// window
	var window: UIWindow? = MainWindow()

	// model
	var ditourModel = DitourModel()

	// main window as MainWindow
	private var mainWindow : MainWindow {
		return self.window! as! MainWindow
	}


	override init() {
		super.init()
	}


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.

		UIApplication.sharedApplication().idleTimerDisabled = true;

		self.propagateLobbyModel( self.window?.rootViewController )

		return true
	}


	func propagateLobbyModel( optViewController:UIViewController? ) {
		if let viewController = optViewController {
			if let modelContainer = viewController as? DitourModelContainer {
				modelContainer.ditourModel = self.ditourModel
			}

			for subController in viewController.childViewControllers {
				self.propagateLobbyModel( subController )
			}
		}
	}


	func application( application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void ) {
		self.ditourModel.handleEventsForBackgroundURLSession( identifier, completionHandler: completionHandler );
	}


	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
		// restore brightness
		self.mainWindow.restoreActive()
	}


	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		self.mainWindow.restoreActive()
		self.ditourModel.performShutdown()
	}


	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
		self.mainWindow.restoreActive()
	}


	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		self.mainWindow.restoreActive()
		self.ditourModel.presenter?.updateConfiguration()
		self.ditourModel.play()
	}


	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		self.mainWindow.restoreActive()
		self.ditourModel.performShutdown()
	}


	// MARK: Guided Access Restriction Delegate

	// Guided Access identifier
	enum GuidedAccessID : String {
		case Configuration		// just allow presentation as by a Tour Guide (no editing)

		var label : String {
			return self.rawValue
		}

		var detailedDescription : String {
			switch self {
			case .Configuration:
				return "Allow configuration and content editing."
			}
		}
	}


	// update the view controllers to handle Guided Access changes
	func propagateGuidedAccess( viewController: UIViewController ) {
		if let guidedAccessHandler = viewController as? GuidedAccessHandling {
			guidedAccessHandler.guidedAccessChanged()
		}

		for subController in viewController.childViewControllers {
			self.propagateGuidedAccess( subController )
		}
	}


	// get the identifiers for guided access
	func guidedAccessRestrictionIdentifiers() -> [String]? {
		return [GuidedAccessID.Configuration.rawValue]
	}


	// get the short text for the guided access restriction
	func textForGuidedAccessRestrictionWithIdentifier(restrictionIdentifier: String) -> String? {
		let guidedAccessID = GuidedAccessID(rawValue: restrictionIdentifier)
		return guidedAccessID?.label
	}


	// get the detailed description for the guided access restriction
	func detailTextForGuidedAccessRestrictionWithIdentifier(restrictionIdentifier: String) -> String? {
		let guidedAccessID = GuidedAccessID(rawValue: restrictionIdentifier)
		return guidedAccessID?.detailedDescription
	}


	// handle the guided access state change for the specified restriction
	func guidedAccessRestrictionWithIdentifier(restrictionIdentifier: String, didChangeState newRestrictionState: UIGuidedAccessRestrictionState) {
		guard let guidedAccessID = GuidedAccessID(rawValue: restrictionIdentifier) else { return }

		switch (guidedAccessID, newRestrictionState) {
		case (.Configuration, .Allow):
			ditourModel.allowsConfiguration = true
		case (.Configuration, .Deny):
			ditourModel.allowsConfiguration = false
		}

		// propagate the changes to the view controllers
		if let rootViewController = self.mainWindow.rootViewController {
			propagateGuidedAccess(rootViewController)
		}
	}
}



// custom window to capture touch events to awaken the model if necessary
final private class MainWindow : UIWindow {
	// represents the mode the user selected for determining whether and when to dim the screen
	enum ScreenSleepOption : String {
		case Never, OnBattery, InactiveOffHours, Inactive

		// get the user default mode
		static var userDefault : ScreenSleepOption {
			if let rawMode = NSUserDefaults.standardUserDefaults().stringForKey("auto_screen_sleep") {
				return ScreenSleepOption(rawValue: rawMode) ?? .OnBattery
			} else {
				return .OnBattery
			}
		}
	}


	// record the timestamp of the latest touch
	var latestTouchTime : NSDate = NSDate()

	// latest value of actual active brightness
	private var rawActiveBrightness : CGFloat = UIScreen.mainScreen().brightness

	// last brightness when active restricted to be at least 0.5
	var activeBrightness : CGFloat {
		get {
			return self.rawActiveBrightness >= 0.5 ? self.rawActiveBrightness : 0.75
		}

		set {
			self.rawActiveBrightness = newValue
		}
	}

	// indicates whether the app is dormant
	var dormant : Bool = false


	convenience init() {
		self.init(frame: UIScreen.mainScreen().bounds)
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.userInteractionEnabled = true		// allows this window to capture and handle touch events
		UIDevice.currentDevice().batteryMonitoringEnabled = true	// otherwise battery state will be unknown
		self.periodicallyUpdateDisplayState()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("unsupported initialization of the MainWindow from a coder...")
	}

	deinit {
		// restore brightness
		self.restoreActive()
	}


	// restore the screen to active
	func restoreActive() {
		self.dormant = false
		UIScreen.mainScreen().brightness = self.activeBrightness
	}

	// if dormant then intercept touch events through this window
	override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
		self.latestTouchTime = NSDate()

		// if we have any touch event and we are dormant then accept the event in this window
		if let event = event, case .Touches = event.type where self.dormant {
			return self
		} else {
			// process the event normally
			return super.hitTest(point, withEvent: event)
		}
	}

	// handle touch ended events intercepted by this window
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if self.dormant {
			self.restoreActive()
		}
	}

	// update the display state (brightness) depending on whether the device is active or not and time of day
	private func periodicallyUpdateDisplayState() {
		struct Constants {
			// period of dormancy (inactivity) in seconds before switching to the dormant state when on external power
			static let EXTERNAL_POWER_DORMANT_TIMEOUT = 30.0 * 60.0	// 30 minutes on external power

			// period of dormancy (inactivity) in seconds before switching to the dormant state when on battery power
			static let BATTERY_DORMANT_TIMEOUT = 5.0 * 60.0		// 5 minutes on battery

			// period in seconds before next check
			static let CHECKING_PERIOD : Int64 = 60		// 1 minute

			// conversion from seconds to nanoseconds
			static let SECONDS_TO_NANOSECONDS : Int64 = 1_000_000_000
		}

		// always scheduled the next check before returning from this method
		defer {
			// schedule next check for the prescribed period
			let nextRunTime = dispatch_time(DISPATCH_TIME_NOW, Constants.CHECKING_PERIOD * Constants.SECONDS_TO_NANOSECONDS)
			dispatch_after(nextRunTime, dispatch_get_main_queue()) { [weak self] () -> Void in
				self?.periodicallyUpdateDisplayState()
			}
		}

		// determine if powered by battery and the corresponding conditional timeout
		let isOnBattery : Bool
		let conditionalTimeout : Double		// timeout to use assuming the other sleep conditions are met
		switch UIDevice.currentDevice().batteryState {
		case .Unplugged:
			isOnBattery = true
			conditionalTimeout = Constants.BATTERY_DORMANT_TIMEOUT
		default:
			isOnBattery = false
			conditionalTimeout = Constants.EXTERNAL_POWER_DORMANT_TIMEOUT
		}

		// determine the real timeout depending on the sleep option
		let timeout : Double
		let sleepOption = ScreenSleepOption.userDefault
		switch sleepOption {
		case .Never:					// never sleep the display
			timeout = Double.infinity
		case _ where isOnBattery:		// for any case where (other than Never) when we are on battery
			timeout = conditionalTimeout
		case .Inactive:					// anytime it is inactive regardless of time of day
			timeout = conditionalTimeout
		case .InactiveOffHours:			// only sleep the display if off hours
			let dayStart = NSUserDefaults.standardUserDefaults().integerForKey("day_start")
			let dayEnd = NSUserDefaults.standardUserDefaults().integerForKey("day_end")
			let now = NSCalendar.currentCalendar().components([.Hour, .Minute], fromDate: NSDate())
			timeout = (now.hour >= dayStart && now.hour < dayEnd) ? Double.infinity : conditionalTimeout
		default:
			timeout = Double.infinity	// don't sleep the display
		}

		// if not already dormant and the elapsed dormant time exceeds the threshold then enter the dormant state
		let elapsedTime = -self.latestTouchTime.timeIntervalSinceNow
		if self.dormant && elapsedTime < timeout {		// if we are sleeping but conditions have changed (e.g. it is now daytime) see if we need to awaken the display
			self.restoreActive()
		} else if !self.dormant && elapsedTime > timeout {
			// record the current active brightness
			self.activeBrightness = UIScreen.mainScreen().brightness
			UIScreen.mainScreen().brightness = 0.0
			self.dormant = true
		}
	}
}


