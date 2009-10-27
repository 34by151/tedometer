//
//  FlipsideViewController.m
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FlipsideViewController.h"
#import "TedometerData.h"

@implementation FlipsideViewController

@synthesize delegate;
@synthesize gatewayAddress;
@synthesize refreshRateSlider;
@synthesize refreshRateLabel;


// slider range must be 0 to num elts -1 (0-10)
NSInteger sliderToSeconds[] = {2,3,4,5,10,30,60,120,300,600,-1};

NSInteger secondsToSliderValue( NSInteger seconds ) {
	NSInteger numItems = sizeof( sliderToSeconds ) / sizeof( NSInteger );
	
	NSInteger sliderValue = numItems - 1;	// if invalid value, default to last item
	for( NSInteger i=0; i < numItems; ++i ) {
		if( sliderToSeconds[i] == seconds ) {
			sliderValue = i;
			break;
		}
	}
	return sliderValue;
}

NSInteger sliderValueToSeconds( NSInteger sliderValue ) {
	NSInteger numItems = sizeof( sliderToSeconds ) / sizeof( NSInteger );
	
	NSInteger seconds;
	if( sliderValue < 0 || sliderValue >= numItems ) {
		seconds = sliderToSeconds[numItems-1];	// if invalid value, default to last item
	}
	else {
		seconds = sliderToSeconds[sliderValue];
	}

	return seconds; 
}
	
- (void)viewDidLoad {
    [super viewDidLoad];
	tedometerData = [TedometerData sharedTedometerData];
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor]; 

	gatewayAddress.text = tedometerData.gatewayHost;
	refreshRateSlider.value = secondsToSliderValue( tedometerData.refreshRate );

	[self updateRefreshRateLabel: refreshRateSlider];
}

- (IBAction)updateRefreshRateLabel:(id)sender {	
	float refreshRate = [refreshRateSlider value];
	
	NSInteger labelValue = sliderValueToSeconds((NSInteger)refreshRate);

	NSString *unit;
	if( labelValue < 60 ) {
		unit = (labelValue == 1) ? @"second" : @"seconds";
	}
	else {
		labelValue /= 60;
		unit = (labelValue == 1) ? @"minute": @"minutes";
	}
	
	NSString *label;
	if( labelValue == -1 ) {
		label = @"Manual";
		refreshRateLabel.text = label;
	}
	else {
		NSString* label = [[NSString alloc] initWithFormat:@"%i %@", labelValue, unit, nil];
		refreshRateLabel.text = label;
		[label release];
	}

}


- (IBAction)done {
	tedometerData.gatewayHost = gatewayAddress.text;
	tedometerData.refreshRate = sliderValueToSeconds( refreshRateSlider.value );
	
	[self.delegate flipsideViewControllerDidFinish:self];	
}

- (IBAction)textFieldDoneEditing:(id)sender {
	[sender resignFirstResponder];
}

- (IBAction)backgroundClick:(id)sender {
	[gatewayAddress resignFirstResponder];
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
	[gatewayAddress release];
	[refreshRateSlider release];
	[refreshRateLabel release];	
	[super dealloc];
}


@end
