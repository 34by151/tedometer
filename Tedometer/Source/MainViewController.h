//
//  MainViewController.h
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FlipsideViewController.h"
#import "MeterView.h"
#import "TouchXML.h"
#import "TedometerData.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate> {
	
	UILabel *avgValue;
	UILabel *peakValue;
	UILabel *lowValue;
	UILabel *totalLabel;
	UILabel *projValue;
	UILabel *avgLabel;
	UILabel *peakLabel;
	UILabel *lowLabel;
	UILabel *totalValue;
	UILabel *projLabel;
	
	UIToolbar *toolbar;
	
	MeterView *meterView;
	
	UILabel *meterLabel;
	UILabel *meterTitle;
	UIActivityIndicatorView *activityIndicator;
	
	UIImageView *avgLabelPointerImage;
	
	UIButton *todayMonthToggleButton;
	
	BOOL shouldAutoRefresh;
		
	CXMLDocument *document;
	
	TedometerData *tedometerData;
	
	BOOL isShowingTodayStatistics;
	
	BOOL hasShownFlipsideThisSession;
	BOOL hasShownConnectionErrorSinceFlip;
	
	BOOL isApplicationInactive;
}

@property (nonatomic, retain) IBOutlet UILabel *avgValue;
@property (nonatomic, retain) IBOutlet UILabel *avgLabel;
@property (nonatomic, retain) IBOutlet UILabel *peakValue;
@property (nonatomic, retain) IBOutlet UILabel *peakLabel;
@property (nonatomic, retain) IBOutlet UILabel *lowValue;
@property (nonatomic, retain) IBOutlet UILabel *lowLabel;
@property (nonatomic, retain) IBOutlet UILabel *totalValue;
@property (nonatomic, retain) IBOutlet UILabel *totalLabel;
@property (nonatomic, retain) IBOutlet UILabel *projValue;
@property (nonatomic, retain) IBOutlet UILabel *projLabel;
@property (nonatomic, retain) IBOutlet UILabel *meterLabel;
@property (nonatomic, retain) IBOutlet UILabel *meterTitle;
@property (nonatomic, retain) IBOutlet MeterView *meterView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIButton *todayMonthToggleButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UIImageView *avgLabelPointerImage;

- (IBAction)showInfo;
- (IBAction)refreshData;
- (IBAction)manualRefresh;

- (void)refreshView;
- (void) repeatRefresh;
- (IBAction) activateCostMeter;
- (IBAction) activatePowerMeter;
- (IBAction) activateCarbonMeter;
- (IBAction) activateVoltageMeter;
- (IBAction) nextMeter;
- (IBAction) toggleTodayMonthStatistics;
- (void) updateIdleTimerState;

- (void) applicationWillResignActive: (NSNotification*)notification;
- (void) applicationDidBecomeActive: (NSNotification*)notification;
- (void)batteryStateDidChange:(NSNotification *) notification;


@end
