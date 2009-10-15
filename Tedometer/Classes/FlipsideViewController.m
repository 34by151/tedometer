//
//  FlipsideViewController.m
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FlipsideViewController.h"
#import "Ted5000.h"

@implementation FlipsideViewController

@synthesize delegate;
@synthesize gatewayAddress;
@synthesize refreshRateSlider;
@synthesize refreshRateLabel;
@synthesize meterDataSegmentedControl;
@synthesize maxMeterValueSlider;
@synthesize maxMeterValueLabel;

- (void)setMaxMeterValueSliderDefaultsForMeterType:(NSInteger)meterType {
	[self updateMaxMeterValueSliderLimitsForMeterType:meterType];
	
	switch( meterType ) {
		case MeterDataTypeCost:
			maxMeterValueSlider.value = 100;
			break;
		case MeterDataTypePower:
			maxMeterValueSlider.value = 10;
			break;
		case MeterDataTypeCarbon:
			maxMeterValueSlider.value = 15;
			break;
	}
	
}

- (void)updateMaxMeterValueSliderLimitsForMeterType:(NSInteger)meterType {
	switch( meterType ) {
		case MeterDataTypeCost:
			maxMeterValueSlider.maximumValue = 500;
			maxMeterValueSlider.minimumValue = 10;
			break;
		case MeterDataTypePower:
			maxMeterValueSlider.maximumValue = 30;
			maxMeterValueSlider.minimumValue = 1;
			break;
		case MeterDataTypeCarbon:
			maxMeterValueSlider.maximumValue = 40;
			maxMeterValueSlider.minimumValue = 1;
			break;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor]; 

	gatewayAddress.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"gatewayAddress"];
	refreshRateSlider.value = [[NSUserDefaults standardUserDefaults] integerForKey:@"refreshRate"];
	meterDataSegmentedControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"meterType"];
	
	[self updateMaxMeterValueSliderLimitsForMeterType:meterDataSegmentedControl.selectedSegmentIndex];
	
	NSInteger maxMeterValue = [[NSUserDefaults standardUserDefaults] integerForKey:@"maxMeterValue"];
	if( maxMeterValue == 0 )
		maxMeterValue = 100;		// initial default is 1 dollar
	maxMeterValueSlider.value = maxMeterValue;
	
	if( refreshRateSlider.value == 0 )
		refreshRateSlider.value = 2;
	
	
	[self updateRefreshRateLabel: refreshRateSlider];
	[self updateMeterValueLabel: maxMeterValueSlider];
}


- (IBAction)done {
	[[NSUserDefaults standardUserDefaults] setObject:gatewayAddress.text forKey:@"gatewayAddress"];
	[[NSUserDefaults standardUserDefaults] setInteger:refreshRateSlider.value forKey:@"refreshRate"];
	[[NSUserDefaults standardUserDefaults] setInteger:meterDataSegmentedControl.selectedSegmentIndex forKey:@"meterType"];
	[[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)maxMeterValueSlider.value forKey:@"maxMeterValue"];
	
	
	[self.delegate flipsideViewControllerDidFinish:self];	
}

- (IBAction)textFieldDoneEditing:(id)sender {
	[sender resignFirstResponder];
}

- (IBAction)backgroundClick:(id)sender {
	[gatewayAddress resignFirstResponder];
}

- (IBAction)updateRefreshRateLabel:(id)sender {	
	float refreshRate = [refreshRateSlider value];
	NSString *label;
	if( refreshRate == 11.0) 
		label = @"Never";
	else
		label = [NSString stringWithFormat:@"%i %@", (int) refreshRate, (refreshRate == 1.0 ? @"second" : @"seconds"), nil];
	refreshRateLabel.text = label;
}

- (IBAction)meterDataSelectionChanged:(id)sender {
	[self setMaxMeterValueSliderDefaultsForMeterType: meterDataSegmentedControl.selectedSegmentIndex];
	[self updateMeterValueLabel:meterDataSegmentedControl];
}

- (IBAction)updateMeterValueLabel:(id)sender {
	
	[self updateMaxMeterValueSliderLimitsForMeterType: meterDataSegmentedControl.selectedSegmentIndex];
	
	switch( meterDataSegmentedControl.selectedSegmentIndex ) {
		case MeterDataTypeCost: {
			
			NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
			[currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
			NSInteger sliderValue = ((NSInteger)(maxMeterValueSlider.value / 10))*10;	
			if( sliderValue < maxMeterValueSlider.minimumValue )
				sliderValue = maxMeterValueSlider.minimumValue;
			maxMeterValueSlider.value = sliderValue;	// round to nearest tenth

			maxMeterValueLabel.text = [NSString stringWithFormat:@"%@/hr", [currencyFormatter stringFromNumber:[NSNumber numberWithFloat:sliderValue / 100.0]]];
			[currencyFormatter release];
			break;
		}
		
		case MeterDataTypePower: {
			maxMeterValueLabel.text = [NSString stringWithFormat:@"%i kW/hr", (NSInteger)maxMeterValueSlider.value];
			break;
		}
		
		case MeterDataTypeCarbon: {
			maxMeterValueLabel.text = [NSString stringWithFormat:@"%i lbs/hr", (NSInteger)maxMeterValueSlider.value];
			break;
		}
	};
	

}


/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
