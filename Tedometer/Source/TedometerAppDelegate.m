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
#import "FlurryAPI.h"
#import "TedometerData.h"
#import "L0SolicitReviewController.h"

@implementation TedometerAppDelegate


@synthesize window;
@synthesize mainViewController;
@synthesize internetRequiredViewController;
@synthesize sharedOperationQueue;

void uncaughtExceptionHandler(NSException *exception);

- (void)applicationDidFinishLaunching:(UIApplication *)application {

    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	NSLog(@"Starting Flurry session...");
	[FlurryAPI startSession:@"A6AVHF5HAWY7768ADRVZ"];
	NSLog(@"Finished Flurry session initiation.");

	NSOperationQueue *opQueue = [[NSOperationQueue alloc] init];
	self.sharedOperationQueue = opQueue;
	[opQueue release];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    internetReach = [[Reachability2 reachabilityForInternetConnection] retain];
	[internetReach startNotifer];
	
	
	// Enable battery monitoring so we received power chnage notifications
	[UIDevice currentDevice].batteryMonitoringEnabled = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(batteryStateDidChange:)
												 name:UIDeviceBatteryStateDidChangeNotification object:nil];
	
	// initialize with current settings
	[self updateIdleTimerState];
	
	
	UIViewController *aController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
	self.mainViewController = (MainViewController*) aController;
	[aController release];

	aController = [[InternetRequiredViewController alloc] initWithNibName:@"InternetRequiredView" bundle:nil];	
	self.internetRequiredViewController = (InternetRequiredViewController *) aController;
	[aController release];

    mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
    internetRequiredViewController.view.frame = [UIScreen mainScreen].applicationFrame;
	
	[window addSubview:[mainViewController view]];
	[window addSubview:[internetRequiredViewController view]];
	
	[self updateInterfaceWithReachability: internetReach];

    [window makeKeyAndVisible];
	
	[L0SolicitReviewController solicit];		// Invitation to the review the app

}

- (void)applicationWillTerminate:(UIApplication *)application {
	[TedometerData archiveToDocumentsFolder];
}

- (void)dealloc {
	[mainViewController release];
	[internetRequiredViewController release];
	[internetReach release];
    [window release];
	self.sharedOperationQueue = nil;
	
    [super dealloc];
}

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAPI logError:@"Uncaught" message:@"Crash!" exception:exception];
}

#pragma mark -
#pragma mark Internet Reachability
- (void) updateInterfaceWithReachability: (Reachability2*) curReach
{
	if( curReach == internetReach ) {
		NetworkStatus netStatus = [curReach currentReachabilityStatus];
		//BOOL connectionRequired = [curReach connectionRequired];
		if( netStatus == NotReachable ) {
			internetRequiredViewController.view.hidden = NO;
		}
		else {
			internetRequiredViewController.view.hidden = YES;
		}
	}
}

- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability2* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability2 class]]);
	[self updateInterfaceWithReachability: curReach];
}



#pragma mark -
#pragma mark Battery State
- (void) updateIdleTimerState {
	
	UIDevice *device = [UIDevice currentDevice];
	if( device.batteryState == UIDeviceBatteryStateCharging || device.batteryState == UIDeviceBatteryStateFull ) {
		
		// The device is plugged in
		[UIApplication sharedApplication].idleTimerDisabled = [TedometerData sharedTedometerData].isAutolockDisabledWhilePluggedIn;
	}
	else {
		// The device is unplugged
		[UIApplication sharedApplication].idleTimerDisabled = NO;	
	}
}

- (void)batteryStateDidChange:(NSNotification *) notification {
	[self updateIdleTimerState];
}



@end
