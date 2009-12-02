//
//  TedometerAppDelegate.h
//  Ted-O-Meter
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "TedometerData.h"
#import "Reachability2.h"

@class MainViewController;
@class InternetRequiredViewController;

@interface TedometerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController *mainViewController;
    InternetRequiredViewController *internetRequiredViewController;
	NSOperationQueue *sharedOperationQueue;
	
    Reachability2* internetReach;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) MainViewController *mainViewController;
@property (nonatomic, retain) InternetRequiredViewController *internetRequiredViewController;
@property (retain) NSOperationQueue *sharedOperationQueue;

- (void) updateInterfaceWithReachability: (Reachability2*) curReach;
- (void) reachabilityChanged: (NSNotification* )note;

@end

