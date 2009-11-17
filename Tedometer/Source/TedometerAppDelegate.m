//
//  TedometerAppDelegate.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "TedometerAppDelegate.h"
#import "MainViewController.h"
#import "InternetRequiredViewController.h"

@implementation TedometerAppDelegate


@synthesize window;
@synthesize mainViewController;
@synthesize internetRequiredViewController;
@synthesize sharedOperationQueue;

- (void)applicationDidFinishLaunching:(UIApplication *)application {

	NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
	self.sharedOperationQueue = opQueue;
	[opQueue release];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[internetReach startNotifer];
	
	UIViewController *aController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
	self.mainViewController = (MainViewController*) aController;
	[aController release];

	aController = [[InternetRequiredViewController alloc] initWithNibName:@"InternetRequiredView" bundle:nil];	
	self.internetRequiredViewController = (InternetRequiredViewController *) aController;

    mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
    internetRequiredViewController.view.frame = [UIScreen mainScreen].applicationFrame;
	
	[window addSubview:[internetRequiredViewController view]];
	[window addSubview:[mainViewController view]];
	
	[self updateInterfaceWithReachability: internetReach];

    [window makeKeyAndVisible];

}


- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
	if( curReach == internetReach ) {
		NetworkStatus netStatus = [curReach currentReachabilityStatus];
		BOOL connectionRequired = [curReach connectionRequired];
		if( netStatus == NotReachable ) {
			[window bringSubviewToFront:internetRequiredViewController.view];
		}
		else {
			[window bringSubviewToFront:mainViewController.view];
		}
	}
}

- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	[TedometerData archiveToDocumentsFolder];
}
-(void) applicationWillResignActive:(UIApplication *) application {
	//NSLog( @"applicationWillResignActive" );
}

-(void) applicationDidBecomeActive:(UIApplication *)application {
	//NSLog( @"applicationDidBecomeActive"  );
}

- (void)dealloc {
	[mainViewController release];
	[internetRequiredViewController release];
	[internetReach release];
    [window release];
    [super dealloc];
}

@end
