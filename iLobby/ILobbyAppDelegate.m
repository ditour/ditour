//
//  ILobbyAppDelegate.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/19/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyAppDelegate.h"
#import "ILobbyModelContainer.h"
#import "ILobbyViewController.h"
#import "ILobbyPresenter.h"


@interface ILobbyAppDelegate ()
@property (nonatomic, strong, readwrite) ILobbyModel *lobbyModel;
@property (nonatomic, strong, readwrite) ILobbyPresenter *presenter;
@end


@implementation ILobbyAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
	[UIApplication sharedApplication].idleTimerDisabled = YES;
	
	self.lobbyModel = [ILobbyModel new];
	self.presenter = [ILobbyPresenter new];
	self.lobbyModel.presentationDelegate = self.presenter;

	// set the model on any view controller that will take it starting at the root
	[self propagateLobbyModel:self.window.rootViewController];
	
    return YES;
}


// propagate the probe model to the view controller and any of its subcontrollers
- (void)propagateLobbyModel:(id)viewController {
	if ( [viewController conformsToProtocol:@protocol(ILobbyModelContainer)] ) {
		[viewController setLobbyModel:self.lobbyModel];
	}

	for ( id subController in [viewController childViewControllers] ) {
		[self propagateLobbyModel:subController];
	}
}


// process background URL session callback
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
	[self.lobbyModel handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	[self.lobbyModel performShutdown];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	[self.presenter updateConfiguration];
	[self.lobbyModel play];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	[self.lobbyModel performShutdown];
}


@end
