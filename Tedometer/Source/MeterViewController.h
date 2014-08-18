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

@property (nonatomic, strong) MainViewController *mainViewController;
@property (nonatomic, strong, readonly) Meter* curMeter;
@property (nonatomic, strong) Meter* powerMeter;
@property (nonatomic, strong) Meter* costMeter;
@property (nonatomic, strong) Meter* carbonMeter;
@property (nonatomic, strong) Meter* voltageMeter;

@property (nonatomic, strong) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, strong) IBOutlet UISegmentedControl *todayMonthSegmentedControl;
@property (nonatomic, strong) IBOutlet UIView *parentDialView;
@property (nonatomic, strong) IBOutlet UIImageView *dialShadowView;
@property (nonatomic, strong) IBOutlet UIImageView *dialShadowThinView;
@property (nonatomic, strong) IBOutlet UIImageView *dialHaloView;
@property (nonatomic, strong) IBOutlet UIImageView *glareView;
@property (nonatomic, strong) IBOutlet UIImageView *dimmerView;
@property (nonatomic, strong) IBOutlet UILabel *avgValue;
@property (nonatomic, strong) IBOutlet UILabel *avgValueUnit;
@property (nonatomic, strong) IBOutlet UILabel *avgLabel;
@property (nonatomic, strong) IBOutlet UILabel *peakValue;
@property (nonatomic, strong) IBOutlet UILabel *peakValueUnit;
@property (nonatomic, strong) IBOutlet UILabel *peakLabel;
@property (nonatomic, strong) IBOutlet UILabel *lowValue;
@property (nonatomic, strong) IBOutlet UILabel *lowValueUnit;
@property (nonatomic, strong) IBOutlet UILabel *lowLabel;
@property (nonatomic, strong) IBOutlet UILabel *totalValue;
@property (nonatomic, strong) IBOutlet UILabel *totalValueUnit;
@property (nonatomic, strong) IBOutlet UILabel *totalLabel;
@property (nonatomic, strong) IBOutlet UILabel *projValue;
@property (nonatomic, strong) IBOutlet UILabel *projValueUnit;
@property (nonatomic, strong) IBOutlet UILabel *projLabel;
@property (nonatomic, strong) IBOutlet UILabel *meterLabel;
@property (nonatomic, strong) IBOutlet UILabel *metricLabel;
@property (nonatomic, strong) IBOutlet UILabel *meterTitle;
@property (nonatomic, strong) IBOutlet UILabel *infoLabel;
@property (nonatomic, strong) IBOutlet DialView *dialView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIImageView *avgLabelPointerImage;
@property (nonatomic, strong) IBOutlet UIButton *warningIconButton;
@property (nonatomic, strong) IBOutlet UIButton *stopDialEditButton;
@property (nonatomic, strong) IBOutlet UIButton *totalsTypeToggleButton;

- (instancetype) initWithMainViewController:(MainViewController*) aMainViewController powerMeter:(Meter*)aPowerMeter costMeter:(Meter*)aCostMeter carbonMeter:(Meter*)aCarbonMeter voltageMeter:(Meter*)aVoltageMeter NS_DESIGNATED_INITIALIZER;

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
