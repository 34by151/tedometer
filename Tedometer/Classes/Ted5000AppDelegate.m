//
//  Ted5000AppDelegate.m
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "Ted5000AppDelegate.h"
#import "MainViewController.h"
#import "TedometerData.h"

@implementation Ted5000AppDelegate


@synthesize window;
@synthesize mainViewController;
@synthesize sharedOperationQueue;

- (void)applicationDidFinishLaunching:(UIApplication *)application {

	NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
	self.sharedOperationQueue = opQueue;
	[opQueue release];
	
	MainViewController *aController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
	self.mainViewController = aController;
	[aController release];
	
    mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
	[window addSubview:[mainViewController view]];
    [window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[TedometerData archiveToDocumentsFolder];
}


- (void)dealloc {
	[mainViewController release];
    [window release];
    [super dealloc];
}

@end
