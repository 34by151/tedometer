//
//  TedometerAppDelegate.h
//  Ted-O-Meter
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "TedometerData.h"
#import "Reachability.h"

@class MainViewController;
@class InternetRequiredViewController;

@interface TedometerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController *mainViewController;
    InternetRequiredViewController *internetRequiredViewController;
	NSOperationQueue *sharedOperationQueue;
	
    Reachability* internetReach;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) MainViewController *mainViewController;
@property (nonatomic, retain) InternetRequiredViewController *internetRequiredViewController;
@property (retain) NSOperationQueue *sharedOperationQueue;

- (void) batteryStateDidChange:(NSNotification *) notification;
- (void) updateInterfaceWithReachability: (Reachability*) curReach;
- (void) reachabilityChanged: (NSNotification* )note;
- (void) updateIdleTimerState;

@end

