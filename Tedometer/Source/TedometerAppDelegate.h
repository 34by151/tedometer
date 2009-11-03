//
//  TedometerAppDelegate.h
//  Ted-O-Meter
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "TedometerData.h"

@class MainViewController;

@interface TedometerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController *mainViewController;
	NSOperationQueue *sharedOperationQueue;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) MainViewController *mainViewController;
@property (retain) NSOperationQueue *sharedOperationQueue;
- (void)batteryStateDidChange:(NSNotification *) notification;

@end

