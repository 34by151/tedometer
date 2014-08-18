//
//  MainViewController.m
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "MeterViewController.h"
#import "MainView.h"
#import "CXMLNode-utils.h"
#import "TouchXML.h"
#import "TedometerData.h"
#import "TedometerAppDelegate.h"
#import "InternetRequiredViewController.h"
#import "MainViewController.h"
#import "MeterViewSizing.h"
#import "log.h"

#define kSegmentedControlToday 0
#define kSegmentedControlMonth 1
#define kValueLabelsToggleView 1000

@implementation MeterViewController

@synthesize powerMeter;
@synthesize costMeter;
@synthesize carbonMeter;
@synthesize voltageMeter;
@synthesize avgLabel;
@synthesize avgValue;
@synthesize avgValueUnit;
@synthesize peakLabel;
@synthesize peakValue;
@synthesize peakValueUnit;
@synthesize lowLabel;
@synthesize lowValue;
@synthesize lowValueUnit;
@synthesize totalLabel;
@synthesize totalValue;
@synthesize totalValueUnit;
@synthesize projLabel;
@synthesize projValue;
@synthesize projValueUnit;
@synthesize metricLabel;
@synthesize meterLabel;
@synthesize meterTitle;
@synthesize dialView;
@synthesize infoLabel;
@synthesize activityIndicator;
@synthesize avgLabelPointerImage;
@synthesize warningIconButton;
@synthesize mainViewController;
@synthesize stopDialEditButton;
@synthesize totalsTypeToggleButton;
@synthesize parentDialView;
@synthesize dialShadowView;
@synthesize dialShadowThinView;
@synthesize dialHaloView;
@synthesize glareView;
@synthesize dimmerView;
@synthesize todayMonthSegmentedControl;
@synthesize navigationBar;


- (instancetype) initWithMainViewController:(MainViewController*) aMainViewController powerMeter:(Meter*)aPowerMeter costMeter:(Meter*)aCostMeter carbonMeter:(Meter*)aCarbonMeter voltageMeter:(Meter*)aVoltageMeter {
	if (self = [super initWithNibName:@"MeterView" bundle:nil]) {
		self.mainViewController = aMainViewController;
		self.powerMeter = aPowerMeter;
		self.costMeter = aCostMeter;
		self.carbonMeter = aCarbonMeter;
		self.voltageMeter = aVoltageMeter;
		self.dialView.curMeter = self.curMeter;

	}
	return self;
}

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    // needed in order to make the nav bar stretch to the top of the status bar
    return UIBarPositionTopAttached;
}


 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {

     self.navigationBar.delegate = (id<UINavigationBarDelegate>) self;        // handle positionForBar: so that nav bar extends to top of status bar


	 // wait to start refresh until we've drawn the initial screen, so that we're not
	 // staring at blackness until the first refresh
	 
	 tedometerData = [TedometerData sharedTedometerData];

	 self.dialView.parentDialView = self.parentDialView;
	 self.dialView.parentDialShadowView = self.dialShadowView;
	 self.dialView.parentDialShadowThinView = self.dialShadowThinView;
	 self.dialView.parentDialHaloView = self.dialHaloView;
	 self.dialView.parentGlareView = self.glareView;
	 self.dialView.parentDimmerView = self.dimmerView;
	 
	 self.dialHaloView.hidden = YES;
	 self.dialHaloView.alpha = 0;
	 self.dialShadowThinView.hidden = YES;
	 self.dimmerView.alpha = 0;

#if DRAW_FOR_ICON_SCREENSHOT
	 meterLabel.center = CGPointMake( meterLabel.center.x + 2, meterLabel.center.y - 8 );
	 meterLabel.text = @"3.036 kW";
#endif

	 /*
	 // Add custom image to Today/Month toggle button
	 UIImage *buttonImageNormal = [UIImage imageNamed:@"panelButtonInset.png"]; 
	 UIImage *stretchableButtonImageNormal = [buttonImageNormal stretchableImageWithLeftCapWidth:16 topCapHeight:0]; 
	 [todayMonthToggleButton setBackgroundImage:stretchableButtonImageNormal forState:UIControlStateNormal];

	 UIImage *buttonImagePressed = [UIImage imageNamed:@"panelButtonInsetSelected.png"]; 
	 UIImage *stretchableButtonImagePressed = [buttonImagePressed stretchableImageWithLeftCapWidth:16 topCapHeight:0]; 
	 [todayMonthToggleButton setBackgroundImage:stretchableButtonImagePressed forState:UIControlStateHighlighted];
	  */
	 
	 todayMonthSegmentedControl.selectedSegmentIndex = tedometerData.isShowingTodayStatistics ? 0 : 1;
	 
#if DRAW_FOR_LAUNCH_IMAGE
	 meterLabel.center = CGPointMake( meterLabel.center.x -3, meterLabel.center.y );
	 meterLabel.text = @"TED-O-Meter"; 
#endif
	 
	 avgValue.text = @"...";
	 avgValueUnit.text = @"";
	 peakValue.text = @"...";
	 peakValueUnit.text = @"";
	 lowValue.text = @"...";
	 lowValueUnit.text = @"";
	 projValue.text = @"...";
	 projValueUnit.text = @"";
	 totalValue.text = @"...";
	 totalValueUnit.text = @"";
	 
	 infoLabel.text = @"";
	 
	 meterTitle.text = @"";
     metricLabel.text = @"";
	 
	 shouldAutoRefresh = YES;

	 [tedometerData addObserver:self forKeyPath:@"curMeterTypeIdx" options:0 context:nil];
	 [tedometerData addObserver:self forKeyPath:@"isShowingTodayStatistics" options:0 context:nil];
	 
	 self.dialView.stopDialEditButton = self.stopDialEditButton;
	 
	 // register for connection notifications
	 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoadWillBegin:) name:kNotificationDocumentReloadWillBegin object:tedometerData];
	 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoadDidFinish:) name:kNotificationDocumentReloadDidFinish object:tedometerData];
	 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoadDidFail:) name:kNotificationConnectionFailure object:tedometerData];

	 //[self refreshData];
	 
     // move dial down a bit if on 4" display
     if( IS_IPHONE_5 ) {
         UIView *dialGroupView = self.parentDialView.superview;
         dialGroupView.frame = CGRectMake( dialGroupView.frame.origin.x, dialGroupView.frame.origin.y+20, dialGroupView.frame.size.width, dialGroupView.frame.size.height);
     }
     
	 [super viewDidLoad];
 }

- (void)showAlertMessage:(NSString*) message withTitle:(NSString*)title {
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}



- (void) viewWillAppear:(BOOL)animated {
				
	[super viewWillAppear:animated];
}


- (void) viewDidAppear:(BOOL)animated {
	/*
	if( tedometerData.refreshRate != -1.0 ) {
		[self refreshData];
	}
	 */
	[super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	

	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

-(void)documentLoadWillBegin:(NSNotification*)notification;
{
    DLog( @"Received documentLoadWillBegin notification -- will begin animating activity indicator..." );
    dispatch_async(dispatch_get_main_queue(), ^{
        //some UI methods ej
        self.warningIconButton.hidden = YES;
        [activityIndicator startAnimating];
    });
}

-(void)documentLoadDidFinish:(NSNotification*)notification;
{
    DLog( @"Received documentLoadDidFinish notification -- will stop animating activity indicator..." );
    dispatch_async(dispatch_get_main_queue(), ^{
        [activityIndicator stopAnimating];
        self.dialView.curMeter = self.curMeter;
        [self refreshView];
    });
}

-(void)documentLoadDidFail:(NSNotification*)notification;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.warningIconButton.hidden = NO;
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	//DLog(@"Observing change to key %@", keyPath );
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dialView.curMeter = self.curMeter;
        [self performSelectorOnMainThread:@selector(refreshView) withObject:nil waitUntilDone:FALSE];
    });
}

-(Meter*) curMeter {
	//DLog("tedometerData.curMeterTypeIdx = %d", tedometerData.curMeterTypeIdx);
	switch( tedometerData.curMeterTypeIdx ) {
		case kMeterTypeCost: return self.costMeter;
		case kMeterTypePower: return self.powerMeter;
		case kMeterTypeCarbon: return self.carbonMeter;
		case kMeterTypeVoltage: return self.voltageMeter;
	}
	return nil;
}

-(void) refreshView {
		
#if DRAW_FOR_ICON_SCREENSHOT || DRAW_FOR_LAUNCH_IMAGE
#else
	if( true || ! tedometerData.connectionErrorMsg ) {

        metricLabel.text = [self.curMeter.meterTitle uppercaseString];
        metricLabel.hidden = NO;
        
        if( ! tedometerData.hasEstablishedSuccessfulConnectionThisSession ) {
            meterTitle.hidden = YES;
            totalsTypeToggleButton.hidden = YES;
        }
        else {
            if( self.curMeter.isNetMeter ) {
                meterTitle.hidden = YES;
                if( tedometerData.mtuCount <= 1 ) {
                    // If there is only one MTU, the totals meter is automatically the NET meter,
                    // so don't display the toggle button
                    totalsTypeToggleButton.hidden = YES;
                }
                else {
                    
                    // For the totals-type toggle button, we show the current state of the setting
                    // rather than the current state of the meter, so that there is immediate UI
                    // feedback even if it takes some time to reload. However, if the current meter
                    // doesn't support totals-type toggling (e.g., TED 5000), then we want to display
                    // the NET tag regardless of what is in the settings.
                    NSArray *totalsTypeImageNames = @[ @"totals_net.png", @"totals_load.png", @"totals_gen.png"];
                    NSInteger totalsMeterType = tedometerData.totalsMeterType;
                    NSString *totalsImage = totalsTypeImageNames[totalsMeterType];
                    [totalsTypeToggleButton setImage:[UIImage imageNamed:totalsImage] forState:UIControlStateNormal];
                    totalsTypeToggleButton.hidden = NO;
                }
            }
            else {
                // we're an MTU meter (not a totals meter)
                totalsTypeToggleButton.hidden = YES;
                meterTitle.hidden = NO;
                meterTitle.text = [self.curMeter.meterTitleWithMtuNumber uppercaseString];
            }
        }
		meterLabel.text =  [NSString stringWithFormat:@"%@%@", [self.curMeter meterStringForInteger: self.curMeter.now], self.curMeter.instantaneousUnit];

		NSArray* detailLabels = @[lowLabel, avgLabel, peakLabel, totalLabel, projLabel];
		NSArray* detailValueLabels = @[lowValue, avgValue, peakValue, totalValue, projValue];
		NSArray* detailUnitLabels = @[lowValueUnit, avgValueUnit, peakValueUnit, totalValueUnit, projValueUnit];
		NSArray* meterValueProperties;
		NSArray* meterLabelProperties;
		NSArray* meterUnitProperties;
		
		if( tedometerData.isShowingTodayStatistics ) {
			meterLabelProperties = @[@"todayLowLabel", @"todayAverageLabel", @"todayPeakLabel", @"todayTotalLabel", @"todayProjectedLabel"];
			meterValueProperties = @[@"todayMinValue", @"todayAverage", @"todayPeakValue", @"today", @"projected"];
		}
		else {
			meterLabelProperties = @[@"mtdLowLabel", @"mtdAverageLabel", @"mtdPeakLabel", @"mtdTotalLabel", @"mtdProjectedLabel"];
			meterValueProperties = @[@"mtdMinValue", @"monthAverage", @"mtdPeakValue", @"mtd", @"projected"];
		}
		
		meterUnitProperties = @[@"instantaneousUnit", @"instantaneousUnit", @"instantaneousUnit", @"cumulativeUnit", @"cumulativeUnit"];
		
		for( NSInteger i = 0; i < [detailLabels count]; ++i ) {
			NSString* aMeterLabelProperty = meterLabelProperties[i];
			NSString* aMeterLabelString = [self.curMeter valueForKey:aMeterLabelProperty];
			NSString* aMeterUnitProperty = meterUnitProperties[i];
			
			UILabel* aLabel = detailLabels[i];
			UILabel* aValueLabel = detailValueLabels[i];
			UILabel* aUnitLabel = detailUnitLabels[i];
			
			if( ! [aMeterLabelString isEqualToString:@""] ) {
				aLabel.text = aMeterLabelString;
				NSString* aMeterValueProperty = meterValueProperties[i];
				if( ! [aMeterValueProperty isEqualToString:@""] ) {
					NSNumber* aValue = [self.curMeter valueForKey:aMeterValueProperty];
					if( aValue == nil )
						aValueLabel.text = @"";
					else {
						aValueLabel.text = [self.curMeter meterStringForInteger: [aValue integerValue]];
						aUnitLabel.text = [self.curMeter valueForKey:aMeterUnitProperty];
					}
					
				}
				else {
					aValueLabel.text = @"";
					aUnitLabel.text = @"";
				}
			}
			else {
				aLabel.text = @"";
				aValueLabel.text = @"";
				aUnitLabel.text = @"";
			}
		}
		
        //modelLabel.text = tedometerData.tedModel;     // on second thought, this is ugly
		infoLabel.text = self.curMeter.infoLabel;
		
						   
	}
	else {
		// render the meter with the dial on 0
	}

	// Hide the average pointer image if we don't support averages
	[avgLabelPointerImage setHidden:[avgLabel.text isEqualToString:@""]];

#endif
	[dialView setNeedsDisplay];
	
}

- (IBAction) toggleTotalsMeterType {
	if( self.curMeter.isTotalsMeterTypeSelectionSupported ) {
        ++tedometerData.totalsMeterType;
        if( tedometerData.totalsMeterType > kTotalsMeterTypeGen )
            tedometerData.totalsMeterType = kTotalsMeterTypeNet;
    }
    else {
        tedometerData.totalsMeterType = kTotalsMeterTypeNet;
    }
	[self refreshView];
    [self.mainViewController refreshData];
}


int buttonCount = 0;
- (IBAction) toggleTodayMonthStatistics {
	
//    if( [[sender tag] == kValueLabelsToggleView] ) {
        tedometerData.isShowingTodayStatistics = ! tedometerData.isShowingTodayStatistics;
//    }
//    else {
//        tedometerData.isShowingTodayStatistics = (todayMonthSegmentedControl.selectedSegmentIndex == kSegmentedControlToday);
//    }
    
    [todayMonthSegmentedControl setSelectedSegmentIndex: tedometerData.isShowingTodayStatistics ? 0 : 1 ];
	[self refreshView];
}

- (IBAction) nextMeterType {
	[tedometerData nextMeterType];
}
 
- (IBAction) showConnectionErrorMsg {
	[mainViewController showInfo];
}

- (IBAction) stopDialEditAndSaveSettings {
    [dialView stopDialEditAndSaveSettings];
}

- (IBAction) stopDialEdit {
	[dialView stopDialEdit];
}

	 
- (void)dealloc {
	
    [tedometerData removeObserver:self forKeyPath:@"curMeterTypeIdx"];
    [tedometerData removeObserver:self forKeyPath:@"isShowingTodayStatistics"];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
	
}

@end
