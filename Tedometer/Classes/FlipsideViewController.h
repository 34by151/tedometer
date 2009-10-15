//
//  FlipsideViewController.h
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

@protocol FlipsideViewControllerDelegate;


@interface FlipsideViewController : UIViewController {
	id <FlipsideViewControllerDelegate> delegate;
	UITextField *gatewayAddress;
	UISlider *refreshRateSlider;
	UILabel *refreshRateLabel;
	UISegmentedControl *meterDataSegmentedControl;
	UISlider *maxMeterValueSlider;
	UILabel *maxMeterValueLabel;
	

}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;
@property (nonatomic, assign) IBOutlet UITextField *gatewayAddress;
@property (nonatomic, retain) IBOutlet UISlider *refreshRateSlider;
@property (nonatomic, retain) IBOutlet UILabel *refreshRateLabel;
@property (nonatomic, retain) IBOutlet UISegmentedControl *meterDataSegmentedControl;
@property (nonatomic, retain) IBOutlet UISlider *maxMeterValueSlider;
@property (nonatomic, retain) IBOutlet UILabel *maxMeterValueLabel;

- (IBAction)done;
- (IBAction)textFieldDoneEditing:(id)sender;
- (IBAction)backgroundClick:(id)sender;
- (IBAction)updateRefreshRateLabel:(id)sender;
- (IBAction)meterDataSelectionChanged:(id)sender;
- (IBAction)updateMeterValueLabel:(id)sender;
- (void)updateMaxMeterValueSliderLimitsForMeterType:(NSInteger)meterType;
- (void)setMaxMeterValueSliderDefaultsForMeterType:(NSInteger)meterType;

@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

