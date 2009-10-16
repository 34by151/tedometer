//
//  MainViewController.h
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FlipsideViewController.h"
#import "MeterView.h"
#import "Ted5000.h"
#import "TouchXML.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate> {
	UILabel *gatewayAddressLabel;
	NSString *gatewayAddress;
	UILabel *costNowLabel;
	UILabel *costHourLabel;
	UILabel *costMonthLabel;
	UILabel *costProjLabel;
	UILabel *powerNowLabel;
	UILabel *powerHourLabel;
	UILabel *powerMonthLabel;
	UILabel *powerProjLabel;
	UILabel *carbonNowLabel;
	UILabel *carbonHourLabel;
	UILabel *carbonMonthLabel;
	UILabel *carbonProjLabel;
	
	MeterView *meterView;
	
	UILabel *meterLabel;
		
	BOOL shouldAutoRefresh;
	float autoRefreshInterval;
	
	int meterDataType;
	float maxMeterValue;
	
	CXMLDocument *document;
}

@property (nonatomic, retain) IBOutlet UILabel *gatewayAddressLabel;
@property (nonatomic, retain) IBOutlet UILabel *costNowLabel;
@property (nonatomic, retain) IBOutlet UILabel *costHourLabel;
@property (nonatomic, retain) IBOutlet UILabel *costMonthLabel;
@property (nonatomic, retain) IBOutlet UILabel *costProjLabel;
@property (nonatomic, retain) IBOutlet UILabel *powerNowLabel;
@property (nonatomic, retain) IBOutlet UILabel *powerHourLabel;
@property (nonatomic, retain) IBOutlet UILabel *powerMonthLabel;
@property (nonatomic, retain) IBOutlet UILabel *powerProjLabel;
@property (nonatomic, retain) IBOutlet UILabel *carbonNowLabel;
@property (nonatomic, retain) IBOutlet UILabel *carbonHourLabel;
@property (nonatomic, retain) IBOutlet UILabel *carbonMonthLabel;
@property (nonatomic, retain) IBOutlet UILabel *carbonProjLabel;
@property (nonatomic, retain) IBOutlet UILabel *meterLabel;
@property (nonatomic, retain) IBOutlet MeterView *meterView;

- (UIImage *)GCA;
- (IBAction)showInfo;
- (IBAction)refresh;
- (void) repeatRefresh;
-(void) refreshData;


@end
