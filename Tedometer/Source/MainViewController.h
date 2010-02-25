//
//  MeterViewController.h
//  Ted-O-Meter
//
//  Created by Nathan on 12/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlipsideViewController.h"
#import "MeterViewController.h"

#define kNumberOfPages 5
@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, UIScrollViewDelegate> {

	UIScrollView* scrollView;
	UIPageControl* pageControl;
	UIToolbar *toolbar;

	BOOL isApplicationInactive;
	TedometerData *tedometerData;
	
	BOOL shouldAutoRefresh;
	
	MeterViewController* currentMeterViewController;

	NSMutableArray *meterViewControllers;
	
    // To be used when scrolls originate from the UIPageControl
    BOOL pageControlUsed;

	NSString *connectionErrorMsg;

}

@property(nonatomic, retain) IBOutlet UIScrollView* scrollView;
@property(nonatomic, retain) IBOutlet UIPageControl* pageControl;
@property(nonatomic, retain) NSMutableArray *meterViewControllers;
@property(nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) NSString *connectionErrorMsg;

- (IBAction) showInfo;
- (IBAction) refreshData;
- (IBAction) activateCostMeter;
- (IBAction) activatePowerMeter;
- (IBAction) activateCarbonMeter;
- (IBAction) activateVoltageMeter;

- (void) applicationWillResignActive: (NSNotification*)notification;
- (void) applicationDidBecomeActive: (NSNotification*)notification;
- (void) flipsideViewControllerDidFinish:(FlipsideViewController *)controller;

- (IBAction)changePage:(id)sender;

- (void)loadScrollViewWithPage:(int)page;
- (void) mtuCountDidChange:(NSNotification*)notification;
- (void) updateMeterVisibility;

@end
