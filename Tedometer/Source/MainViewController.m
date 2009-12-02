//
//  MainViewController.m
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "MainViewController.h"
#import "MainView.h"
#import "CXMLNode-utils.h"
#import "TouchXML.h"
#import "TedometerData.h"
#import "TedometerAppDelegate.h"
#import "InternetRequiredViewController.h"
#import "ASIHTTPRequest.h"

@implementation MainViewController

@synthesize avgLabel;
@synthesize avgValue;
@synthesize peakLabel;
@synthesize peakValue;
@synthesize lowLabel;
@synthesize lowValue;
@synthesize totalLabel;
@synthesize totalValue;
@synthesize projLabel;
@synthesize projValue;
@synthesize meterLabel;
@synthesize meterTitle;
@synthesize meterView;
@synthesize infoLabel;
@synthesize activityIndicator;
@synthesize toolbar;
@synthesize todayMonthToggleButton;
@synthesize avgLabelPointerImage;
@synthesize warningIconButton;
@synthesize connectionErrorMsg;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		document = nil;
    }
    return self;
}


 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {

	 // wait to start refresh until we've drawn the initial screen, so that we're not
	 // staring at blackness until the first refresh
	 
	 // Add Info Icon to toolbar
	 UIButton * infoDarkButtonType = [[UIButton buttonWithType:UIButtonTypeInfoLight] retain];
	 infoDarkButtonType.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	 infoDarkButtonType.backgroundColor = [UIColor clearColor];
	 [infoDarkButtonType addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
	 UIBarButtonItem *infoButton = [[UIBarButtonItem alloc] initWithCustomView:infoDarkButtonType];
	 
	 NSMutableArray *toolbarItems = [[NSMutableArray alloc] initWithArray:toolbar.items];
	 [toolbarItems addObject:infoButton];
	 toolbar.items = toolbarItems;
	 [toolbarItems release];
	 [infoDarkButtonType release];
	 [infoButton release];
	 
	 // Add custom image to Today/Month toggle button
	 UIImage *buttonImageNormal = [UIImage imageNamed:@"translucentButton.png"]; 
	 UIImage *stretchableButtonImageNormal = [buttonImageNormal stretchableImageWithLeftCapWidth:12 topCapHeight:0]; 
	 [todayMonthToggleButton setBackgroundImage:stretchableButtonImageNormal forState:UIControlStateNormal];

	 UIImage *buttonImagePressed = [UIImage imageNamed:@"whiteButton.png"]; 
	 UIImage *stretchableButtonImagePressed = [buttonImagePressed stretchableImageWithLeftCapWidth:12 topCapHeight:0]; 
	 [todayMonthToggleButton setBackgroundImage:stretchableButtonImagePressed forState:UIControlStateHighlighted];
	 
	 isShowingTodayStatistics = YES;			// stores toggle state for Today/Month button
	 
	 avgValue.text = @"...";
	 peakValue.text = @"...";
	 lowValue.text = @"...";
	 projValue.text = @"";
	 projLabel.text = @"";
	 
	 infoLabel.text = @"";
	 
	 meterTitle.text = @"";
	 connectionErrorMsg = nil;
	 
	 shouldAutoRefresh = YES;
	 [self performSelector:@selector(repeatRefresh) withObject:nil afterDelay: 2.0];

	 tedometerData = [TedometerData sharedTedometerData];
	 hasShownFlipsideThisSession = NO;
	 isApplicationInactive = NO;
	 
	 
	 [[NSNotificationCenter defaultCenter] addObserver:self
											  selector:@selector(applicationWillResignActive:)
												  name:UIApplicationWillResignActiveNotification object:nil];

	 // Enable battery monitoring so we received the above notification
	 [UIDevice currentDevice].batteryMonitoringEnabled = YES;
	 [self updateIdleTimerState];
	 
	 [[NSNotificationCenter defaultCenter] addObserver:self
											  selector:@selector(applicationDidBecomeActive:)
												  name:UIApplicationDidBecomeActiveNotification object:nil];
	 
	 
	 [[NSNotificationCenter defaultCenter] addObserver:self
											  selector:@selector(batteryStateDidChange:)
												  name:UIDeviceBatteryStateDidChangeNotification object:nil];
	 
	 [self refreshData];
	 
	 [super viewDidLoad];
 }

- (void)showAlertMessage:(NSString*) message withTitle:(NSString*)title {
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void) updateIdleTimerState {
	
	UIDevice *device = [UIDevice currentDevice];
	if( device.batteryState == UIDeviceBatteryStateCharging || device.batteryState == UIDeviceBatteryStateFull ) {
		
		// The device is plugged in
		[UIApplication sharedApplication].idleTimerDisabled = tedometerData.isAutolockDisabledWhilePluggedIn;
	}
	else {
		// The device is unplugged
		[UIApplication sharedApplication].idleTimerDisabled = NO;	
	}
}

- (void)batteryStateDidChange:(NSNotification *) notification {
	[self updateIdleTimerState];
}

- (void) applicationWillResignActive: (NSNotification*)notification {
	isApplicationInactive = YES;
}

- (void) applicationDidBecomeActive: (NSNotification*)notification {
	isApplicationInactive = NO;
}

- (void) viewWillAppear:(BOOL)animated {
				
	[super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
	[self refreshView];
	
	if( tedometerData.refreshRate != -1.0 ) {
		[self refreshData];
	}
	[super viewDidAppear:animated];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */


- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {

	BOOL needsInitialRefresh = ! hasShownFlipsideThisSession;
	hasShownFlipsideThisSession = YES;
	hasShownConnectionErrorSinceFlip = NO;

	[TedometerData archiveToDocumentsFolder];
	
	[self updateIdleTimerState];
	
	[self dismissModalViewControllerAnimated:YES];

	if( needsInitialRefresh || tedometerData.refreshRate != -1.0 )
		[self refreshData];
	
	shouldAutoRefresh = YES;
	
	
	// refresh will get called in viewDidAppear:
}


- (IBAction)showInfo {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	controller.connectionErrorMsg = self.connectionErrorMsg;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];	
	[controller release];
	shouldAutoRefresh = NO;

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
	
	[UIDevice currentDevice].batteryMonitoringEnabled = NO;

	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

-(void) repeatRefresh {
	if( shouldAutoRefresh && tedometerData.refreshRate != -1.0 )
		[self refreshData];
	[self performSelector:@selector(repeatRefresh) withObject:nil afterDelay: tedometerData.refreshRate];
}

-(IBAction) showConnectionErrorMsg {
	[self showInfo];
	/*
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:connectionErrorMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
	 */
}

-(void) reloadXmlDocument {

	NSString *urlString;
	BOOL usingDemoAccount = NO;
	if( [@"theenergydetective.com" isEqualToString: [tedometerData.gatewayHost lowercaseString]]
	   || [@"www.theenergydetective.com" isEqualToString: [tedometerData.gatewayHost lowercaseString]] ) 
	{
		usingDemoAccount = YES;
	}
	
	if( usingDemoAccount )
		urlString = @"http://www.theenergydetective.com/media/5000LiveData.xml";
	else 
		urlString = [NSString stringWithFormat:@"%@://%@/api/LiveData.xml", tedometerData.useSSL ? @"https" : @"http", tedometerData.gatewayHost];
	
    NSURL *url = [NSURL URLWithString: urlString];
	
	NSLog(@"Attempting connection with URL %@", url);
	BOOL success = NO;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setUseSessionPersistance:NO];
	if( ! usingDemoAccount ) {
		if( tedometerData.useSSL ) 
			[request setValidatesSecureCertificate:NO];
		[request setUsername:tedometerData.username];
		[request setPassword:tedometerData.password];
	}
	
	[request start];
	NSError *error = [request error];
	if (!error) {
		NSString *response = [request responseString];
		
		CXMLDocument *newDocument = [[[CXMLDocument alloc] initWithXMLString:response options:0 error:&error] retain];
		if( newDocument ) {
			success = YES;
			self.connectionErrorMsg = nil;
			@synchronized( self ) {
				if( document )
					[document release];
				document = newDocument;
			}
			[self performSelectorOnMainThread:@selector(stopActivityIndicator) withObject:self waitUntilDone:NO];
			[self performSelectorOnMainThread:@selector(hideWarningIcon) withObject:self waitUntilDone:NO];
			[self performSelectorOnMainThread:@selector(refreshView) withObject:self waitUntilDone:NO];
		}
	}
	
	if( ! success ) {
		if( [[error domain] isEqualToString:@"CXMLErrorDomain"] ) {
			self.connectionErrorMsg = [NSString stringWithFormat:@"Unable to parse data from %@", url];
		}
		else {
			self.connectionErrorMsg = [error localizedDescription];
		}
		NSLog( @"%@", self.connectionErrorMsg);
		[self performSelectorOnMainThread:@selector(stopActivityIndicator) withObject:self waitUntilDone:YES];
		[self performSelectorOnMainThread:@selector(showWarningIcon) withObject:self waitUntilDone:YES];
		// nh 11/28/09: Gateway seems to have connection issues periodically. Rather than wait for user to
		// acknowledge an error message, we simply display a warning icon.
		//[self performSelectorOnMainThread:@selector(showConnectionErrorMsg) withObject:self waitUntilDone:NO];
	}
}

-(void) showWarningIcon {
	self.warningIconButton.hidden = NO;
}

-(void) hideWarningIcon {
	self.warningIconButton.hidden = YES;
}

-(void) stopActivityIndicator {
	[activityIndicator stopAnimating];
}

-(IBAction) manualRefresh {
	hasShownConnectionErrorSinceFlip = NO;	// show error message if we fail during a manual refresh attempt
	[self refreshData];
}

-(IBAction) refreshData {

	if( isApplicationInactive || tedometerData.gatewayHost == nil || [tedometerData.gatewayHost isEqualToString:@""] ) {
		// don't show the error message if the gateway host is empty and we haven't yet shown the flip side this session,
		// since we'll be showing them the flip side automatically to let them enter the host.
		if( hasShownFlipsideThisSession )
			[self showWarningIcon];
		return;
	}
	
	//NSLog(@"Refreshing MainView data..." );
	[self hideWarningIcon];
	[activityIndicator startAnimating];
	NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(reloadXmlDocument) object:nil];
	[[(TedometerAppDelegate *)[[UIApplication sharedApplication] delegate] sharedOperationQueue] addOperation:op];
	[op release];
}

-(void) refreshView {
		
	BOOL isSuccessful = NO;

#ifndef DRAW_FOR_ICON_SCREENSHOT
	
	if( ! hasShownFlipsideThisSession && (tedometerData.gatewayHost == nil || [tedometerData.gatewayHost isEqualToString:@""]) ) {
		[self showInfo];
	}
	
	@synchronized( self ) {
		if( document ) 
			isSuccessful = [tedometerData refreshDataFromXmlDocument:document];
	}
	if( isSuccessful ) {

		meterTitle.text = [tedometerData.curMeter.meterTitle uppercaseString];
		meterLabel.text =  tedometerData.curMeter.meterReadingString;
		meterView.meterValue = tedometerData.curMeter.now;

		NSArray* detailLabels = [NSArray arrayWithObjects:lowLabel, avgLabel, peakLabel, totalLabel, projLabel, nil];
		NSArray* detailValueLabels = [NSArray arrayWithObjects: lowValue, avgValue, peakValue, totalValue, projValue, nil];
		NSArray* meterValueProperties;
		NSArray* meterLabelProperties;
		
		if( isShowingTodayStatistics ) {
			meterLabelProperties = [NSArray arrayWithObjects:@"todayLowLabel", @"todayAverageLabel", @"todayPeakLabel", @"todayTotalLabel", @"todayProjectedLabel", nil];
			meterValueProperties = [NSArray arrayWithObjects:@"todayMinValue", @"todayAverage", @"todayPeakValue", @"today", @"", nil];
		}
		else {
			meterLabelProperties = [NSArray arrayWithObjects:@"mtdLowLabel", @"mtdAverageLabel", @"mtdPeakLabel", @"mtdTotalLabel", @"mtdProjectedLabel", nil];
			meterValueProperties = [NSArray arrayWithObjects:@"mtdMinValue", @"monthAverage", @"mtdPeakValue", @"mtd", @"projected", nil];
		}
		
		for( NSInteger i = 0; i < [detailLabels count]; ++i ) {
			NSString* aMeterLabelProperty = [meterLabelProperties objectAtIndex:i];
			NSString* aMeterLabelString = [tedometerData.curMeter valueForKey:aMeterLabelProperty];
			
			UILabel* aLabel = [detailLabels objectAtIndex:i];
			UILabel* aValueLabel = [detailValueLabels objectAtIndex:i];
			
			if( ! [aMeterLabelString isEqualToString:@""] ) {
				aLabel.text = aMeterLabelString;
				NSString* aMeterValueProperty = [meterValueProperties objectAtIndex:i];
				if( ! [aMeterValueProperty isEqualToString:@""] ) {
					NSNumber* aValue = [tedometerData.curMeter valueForKey:aMeterValueProperty];
					if( aValue == nil )
						aValueLabel.text = @"";
					else
						aValueLabel.text = [tedometerData.curMeter meterStringForInteger: [aValue integerValue]];
				}
				else {
					aValueLabel.text = @"";
				}
			}
			else {
				aLabel.text = @"";
				aValueLabel.text = @"";
			}
		}
		
		infoLabel.text = tedometerData.curMeter.infoLabel;
		
						   
	}
	else {
		// render the meter with the dial on 0
		meterView.meterValue = 0;
	}

	// Hide the average pointer image if we don't support averages
	[avgLabelPointerImage setHidden:[avgLabel.text isEqualToString:@""]];

#endif
	[meterView setNeedsDisplay];
	
}

int buttonCount = 0;
- (IBAction) toggleTodayMonthStatistics {
	isShowingTodayStatistics = ! isShowingTodayStatistics;
	NSString* buttonLabel = isShowingTodayStatistics ? @"Today" : @"This Month";
	self.meterView.isShowingTodayStatistics = isShowingTodayStatistics;
	[self.todayMonthToggleButton setTitle:buttonLabel forState:UIControlStateNormal];
	[self refreshView];
}


- (IBAction) activateCostMeter {
	[tedometerData activateCostMeter];
	[self refreshView];
}

- (IBAction) activatePowerMeter {
	[tedometerData activatePowerMeter];
	[self refreshView];
}

- (IBAction) activateCarbonMeter {
	[tedometerData activateCarbonMeter];
	[self refreshView];
}

- (IBAction) activateVoltageMeter {
	[tedometerData activateVoltageMeter];
	[self refreshView];
}

- (IBAction)nextMeter {
	[tedometerData nextMeter];
	[self refreshView];
}
	 
	 
- (void)dealloc {
	if( document )
		[document release];
	
	[avgValue release];
	[avgLabel release];
	[peakValue release];
	[peakLabel release];
	[lowValue release];
	[lowLabel release];
	[totalValue release];
	[totalLabel release];
	[projValue release];
	[projLabel release];
	[meterLabel release];
	[meterTitle release];
	[toolbar release];
	[todayMonthToggleButton release];
	[meterView release];
	[activityIndicator release];
	[avgLabelPointerImage release];
	[warningIconButton release];
	[connectionErrorMsg release];
	
    [super dealloc];
	
}

@end
