//
//  MainViewController.h
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FlipsideViewController.h"
#import "DialView.h"
#import "TouchXML.h"
#import "TedometerData.h"


@class MainViewController;

@interface MeterViewController : UIViewController {
	
	Meter *powerMeter;
	Meter *costMeter;
	Meter *carbonMeter;
	Meter *voltageMeter;
	
	UILabel *avgValue;
	UILabel *avgValueUnit;
	UILabel *peakValue;
	UILabel *peakValueUnit;
	UILabel *lowValue;
	UILabel *lowValueUnit;
	UILabel *projValue;
	UILabel *projValueUnit;
	UILabel *totalValue;
	UILabel *totalValueUnit;
	UILabel *totalLabel;
	UILabel *avgLabel;
	UILabel *avgLabelUnit;
	UILabel *peakLabel;
	UILabel *lowLabel;
	UILabel *projLabel;
	
	
	DialView *dialView;
	
	UILabel *meterLabel;
	UILabel *meterTitle;
	UILabel *infoLabel;
    UILabel *metricLabel;
    
	UIActivityIndicatorView *activityIndicator;
	
	UIImageView *avgLabelPointerImage;
	
	UIButton *warningIconButton;
	UIButton *stopDialEditButton;
    UIButton *totalsTypeToggleButton;

	UIView *parentDialView;
	UIImageView *dialShadowView;
	UIImageView *dialShadowThinView;
	UIImageView *dialHaloView;
	UIImageView *glareView;
	UIImageView *dimmerView;
    

    UINavigationBar *navigationBar;
	UISegmentedControl *todayMonthSegmentedControl;

	BOOL shouldAutoRefresh;
	
	TedometerData *tedometerData;
	MainViewController *mainViewController;
}

@property (nonatomic, retain) MainViewController *mainViewController;
@property (nonatomic, retain, readonly) Meter* curMeter;
@property (nonatomic, retain) Meter* powerMeter;
@property (nonatomic, retain) Meter* costMeter;
@property (nonatomic, retain) Meter* carbonMeter;
@property (nonatomic, retain) Meter* voltageMeter;

@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UISegmentedControl *todayMonthSegmentedControl;
@property (nonatomic, retain) IBOutlet UIView *parentDialView;
@property (nonatomic, retain) IBOutlet UIImageView *dialShadowView;
@property (nonatomic, retain) IBOutlet UIImageView *dialShadowThinView;
@property (nonatomic, retain) IBOutlet UIImageView *dialHaloView;
@property (nonatomic, retain) IBOutlet UIImageView *glareView;
@property (nonatomic, retain) IBOutlet UIImageView *dimmerView;
@property (nonatomic, retain) IBOutlet UILabel *avgValue;
@property (nonatomic, retain) IBOutlet UILabel *avgValueUnit;
@property (nonatomic, retain) IBOutlet UILabel *avgLabel;
@property (nonatomic, retain) IBOutlet UILabel *peakValue;
@property (nonatomic, retain) IBOutlet UILabel *peakValueUnit;
@property (nonatomic, retain) IBOutlet UILabel *peakLabel;
@property (nonatomic, retain) IBOutlet UILabel *lowValue;
@property (nonatomic, retain) IBOutlet UILabel *lowValueUnit;
@property (nonatomic, retain) IBOutlet UILabel *lowLabel;
@property (nonatomic, retain) IBOutlet UILabel *totalValue;
@property (nonatomic, retain) IBOutlet UILabel *totalValueUnit;
@property (nonatomic, retain) IBOutlet UILabel *totalLabel;
@property (nonatomic, retain) IBOutlet UILabel *projValue;
@property (nonatomic, retain) IBOutlet UILabel *projValueUnit;
@property (nonatomic, retain) IBOutlet UILabel *projLabel;
@property (nonatomic, retain) IBOutlet UILabel *meterLabel;
@property (nonatomic, retain) IBOutlet UILabel *metricLabel;
@property (nonatomic, retain) IBOutlet UILabel *meterTitle;
@property (nonatomic, retain) IBOutlet UILabel *infoLabel;
@property (nonatomic, retain) IBOutlet DialView *dialView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) IBOutlet UIImageView *avgLabelPointerImage;
@property (nonatomic, retain) IBOutlet UIButton *warningIconButton;
@property (nonatomic, retain) IBOutlet UIButton *stopDialEditButton;
@property (nonatomic, retain) IBOutlet UIButton *totalsTypeToggleButton;

- (id) initWithMainViewController:(MainViewController*) aMainViewController powerMeter:(Meter*)aPowerMeter costMeter:(Meter*)aCostMeter carbonMeter:(Meter*)aCarbonMeter voltageMeter:(Meter*)aVoltageMeter;

- (IBAction) toggleTodayMonthStatistics;
- (IBAction) nextMeterType;
- (IBAction) showConnectionErrorMsg;
- (IBAction) stopDialEdit;
- (IBAction) stopDialEditAndSaveSettings;

- (void) refreshView;

-(void)documentLoadWillBegin:(NSNotification*)notification;
-(void)documentLoadDidFinish:(NSNotification*)notification;
-(void)documentLoadDidFail:(NSNotification*)notification;

	
@end
