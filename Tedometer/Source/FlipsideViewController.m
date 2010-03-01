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
@synthesize disableAutolockWhilePluggedIn;
@synthesize connectionErrorMsgLabel;
@synthesize connectionErrorMsg;
@synthesize warningView;
@synthesize settingsView;
@synthesize scrollView;
@synthesize useSSL;
@synthesize username;
@synthesize password;

// slider range must be 0 to num elts -1 (0-10)
static NSInteger sliderToSeconds[] = {2,3,4,5,10,30,60,120,300,600,-1};

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

	gatewayAddress.text = tedometerData.gatewayHost;
	username.text = tedometerData.username;
	password.text = tedometerData.password;
	useSSL.on = tedometerData.useSSL;
	refreshRateSlider.value = secondsToSliderValue( tedometerData.refreshRate );
	disableAutolockWhilePluggedIn.on = tedometerData.isAutolockDisabledWhilePluggedIn;
	

	
	[self updateRefreshRateLabel: refreshRateSlider];

	settingsView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
;
	[scrollView addSubview:settingsView];
	scrollView.contentSize = settingsView.frame.size;
	
	
	[self.view addSubview:warningView];
	warningView.frame = CGRectMake( 0, self.view.frame.size.height, self.view.frame.size.width, warningView.frame.size.height );

	if( connectionErrorMsg ) {
		// Seems we don't get the animation unless we delay a moment
		[NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector( showConnectionErrorMsg:) userInfo:nil repeats:NO];
	}
		
	
	[scrollView flashScrollIndicators];
	
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

- (IBAction)showConnectionErrorMsg:(id)sender {

	connectionErrorMsgLabel.text = connectionErrorMsg;

	[UIView beginAnimations:@"OpenWarningView" context:NULL];

	warningView.frame = CGRectMake( 0, self.view.frame.size.height - warningView.frame.size.height, self.view.frame.size.width, warningView.frame.size.height );
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:3.0];
		
	[UIView commitAnimations];
}

- (IBAction)clearConnectionErrorMsg:(id)sender {
	self.connectionErrorMsg = nil;
	
	[UIView beginAnimations:@"CloseWarningView" context:NULL];
	
	warningView.frame = CGRectMake( 0, self.view.frame.size.height, self.view.frame.size.width, warningView.frame.size.height );
	[UIView setAnimationDuration:3.0];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];

	[UIView commitAnimations];

}

- (IBAction)done {
	tedometerData.gatewayHost = gatewayAddress.text;
	tedometerData.refreshRate = sliderValueToSeconds( refreshRateSlider.value );
	tedometerData.isAutolockDisabledWhilePluggedIn = disableAutolockWhilePluggedIn.on;
	tedometerData.useSSL = useSSL.on;
	tedometerData.username = username.text;
	tedometerData.password = password.text;
	
	[self.delegate flipsideViewControllerDidFinish:self];	
}


- (IBAction)textFieldDoneEditing:(id)sender {
	[sender resignFirstResponder];
}

- (IBAction)backgroundClick:(id)sender {
	//DLog(@"Background click");
	
	[gatewayAddress resignFirstResponder];
	[username resignFirstResponder];
	[password resignFirstResponder];
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
	
	[warningView removeFromSuperview];

}


- (void)dealloc {
	[gatewayAddress release];
	[refreshRateSlider release];
	[refreshRateLabel release];	
	[useSSL release];
	[username release];
	[password release];
	[settingsView release];
	[scrollView release];
	[connectionErrorMsgLabel release];
	[connectionErrorMsg release];
	[super dealloc];
}


@end
