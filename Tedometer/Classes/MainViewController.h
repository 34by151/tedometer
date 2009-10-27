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
	
	UILabel *nowValue;
	UILabel *hourValue;
	UILabel *todayValue;
	UILabel *monthValue;
	UILabel *projValue;
	
	UIToolbar *toolbar;
	
	MeterView *meterView;
	
	UILabel *meterLabel;
	UILabel *meterTitle;
	UIActivityIndicatorView *activityIndicator;
		
	BOOL shouldAutoRefresh;
		
	CXMLDocument *document;
	
	TedometerData *tedometerData;
}

@property (nonatomic, retain) IBOutlet UILabel *nowValue;
@property (nonatomic, retain) IBOutlet UILabel *hourValue;
@property (nonatomic, retain) IBOutlet UILabel *todayValue;
@property (nonatomic, retain) IBOutlet UILabel *monthValue;
@property (nonatomic, retain) IBOutlet UILabel *projValue;
@property (nonatomic, retain) IBOutlet UILabel *meterLabel;
@property (nonatomic, retain) IBOutlet UILabel *meterTitle;
@property (nonatomic, retain) IBOutlet MeterView *meterView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)showInfo;
- (IBAction)refreshData;
- (void)refreshView;
- (void) repeatRefresh;
- (IBAction) activateCostMeter;
- (IBAction) activatePowerMeter;
- (IBAction) activateCarbonMeter;
- (IBAction) nextMeter;


@end
