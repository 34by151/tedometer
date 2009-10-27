//
//  Ted5000AppDelegate.h
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "TedometerData.h"

@class MainViewController;

@interface Ted5000AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController *mainViewController;
	NSOperationQueue *sharedOperationQueue;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) MainViewController *mainViewController;
@property (retain) NSOperationQueue *sharedOperationQueue;

@end

