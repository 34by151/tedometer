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
@interface MainViewController : UIViewController <UIScrollViewDelegate> {

	UIScrollView* scrollView;
	UIPageControl* pageControl;
	UIToolbar *toolbar;

	BOOL isApplicationInactive;
	TedometerData *tedometerData;
	
	BOOL shouldAutoRefresh;
	BOOL hasShownFlipsideViewThisSession;
	BOOL hasInitializedSinceFirstSuccessfulConnection;

	MeterViewController* currentMeterViewController;

	NSMutableArray *meterViewControllers;
	
    // To be used when scrolls originate from the UIPageControl
    BOOL pageControlUsed;


}

@property(nonatomic, strong) IBOutlet UIScrollView* scrollView;
@property(nonatomic, strong) IBOutlet UIPageControl* pageControl;
@property(nonatomic, strong) NSMutableArray *meterViewControllers;
@property(nonatomic, strong) IBOutlet UIToolbar *toolbar;

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

- (void)loadScrollViewWithPage:(long)page;
- (void) mtuCountDidChange:(NSNotification*)notification;
- (void) updateMeterVisibility;
- (void) switchToPage:(NSInteger)pageNumber;

@end
