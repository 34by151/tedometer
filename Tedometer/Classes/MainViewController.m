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

@implementation MainViewController

@synthesize gatewayAddressLabel;
@synthesize costNowLabel;
@synthesize costHourLabel;
@synthesize costMonthLabel;
@synthesize costProjLabel;
@synthesize powerNowLabel;
@synthesize powerHourLabel;
@synthesize powerMonthLabel;
@synthesize powerProjLabel;
@synthesize carbonNowLabel;
@synthesize carbonHourLabel;
@synthesize carbonMonthLabel;
@synthesize carbonProjLabel;
@synthesize meterLabel;
@synthesize meterView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}


 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
	 /*
	 UIImageView *imageView = [[UIImageView alloc] initWithImage:[self GCA]];
	 [self.view addSubview:imageView];
	 */
	 // wait to start refresh until we've drawn the initial screen, so that we're not
	 // staring at blackness until the first refresh
	 shouldAutoRefresh = YES;
	 [self performSelector:@selector(repeatRefresh) withObject:nil afterDelay: 2.0];

	 [super viewDidLoad];
 }


- (void) viewWillAppear:(BOOL)animated {
	gatewayAddress = [[NSUserDefaults standardUserDefaults] stringForKey:@"gatewayAddress"];
	gatewayAddressLabel.text = gatewayAddress;
	
	
	autoRefreshInterval = [[NSUserDefaults standardUserDefaults] integerForKey:@"refreshRate"];
	if( autoRefreshInterval == 0 )
		autoRefreshInterval = 2.0;

	meterDataType = [[NSUserDefaults standardUserDefaults] integerForKey:@"meterType"];
	maxMeterValue = [[NSUserDefaults standardUserDefaults] floatForKey:@"maxMeterValue"];
	
	meterView.meterMax = maxMeterValue;
	
	[super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
	//[self refresh];
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

    /*
	gatewayAddress = [[NSUserDefaults standardUserDefaults] stringForKey:@"gatewayAddress"];
	gatewayAddressLabel.text = gatewayAddress;
	 */
	[self dismissModalViewControllerAnimated:YES];
	shouldAutoRefresh = YES;
	[self refresh];
}


- (IBAction)showInfo {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

-(void) repeatRefresh {
	if( shouldAutoRefresh && autoRefreshInterval != 11.0 )
		[self refreshData];
	[self performSelector:@selector(repeatRefresh) withObject:nil afterDelay: autoRefreshInterval];
}

-(void) refreshData {
	
	NSString *urlString = [NSString stringWithFormat:@"http://%@/api/LiveData.xml", gatewayAddress];
    NSURL *url = [NSURL URLWithString: urlString];
	
	NSError* error;
	if( document )
		[document release];
    document = [[[CXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error] retain];
	if( document )
		[self refresh];
	else 
		NSLog( @"%@", [error localizedDescription]);

	
}

-(IBAction) refresh {
		
	
	//NSString *urlString = [NSString stringWithFormat:@"http://%@/api/LiveData.xml", gatewayAddress];
    //NSURL *url = [NSURL URLWithString: urlString];
	
    //CXMLDocument *document = [[[CXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error] autorelease];
	if( document ) {
		NSNumberFormatter *currencyFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
		
		CXMLNode *costNode = [[document rootElement] childNamed:@"Cost"];
		CXMLNode *totalCostNode = [costNode childNamed:@"Total"];
		
		NSInteger costNow = [[[totalCostNode childNamed:@"CostNow"] stringValue] intValue];
		costNowLabel.text = [NSString stringWithFormat:@"%@/hr",[currencyFormatter stringFromNumber:[NSNumber numberWithFloat: costNow/100.0]]];
		costHourLabel.text = [currencyFormatter stringFromNumber:[NSNumber numberWithFloat: ([[[totalCostNode childNamed:@"CostHour"] stringValue] intValue])/100.0]];
		costMonthLabel.text = [currencyFormatter stringFromNumber:[NSNumber numberWithFloat: ([[[totalCostNode childNamed:@"CostMTD"] stringValue] intValue])/100.0]];
		costProjLabel.text = [currencyFormatter stringFromNumber:[NSNumber numberWithFloat: ([[[totalCostNode childNamed:@"CostProj"] stringValue] intValue])/100.0]];
		
		
		CXMLNode *powerNode = [[document rootElement] childNamed:@"Power"];
		CXMLNode *totalPowerNode = [powerNode childNamed:@"Total"];
		NSInteger powerNow = [[[totalPowerNode childNamed:@"PowerNow"] stringValue] intValue];
		NSInteger powerHour = [[[totalPowerNode childNamed:@"PowerHour"] stringValue] intValue];
		NSInteger powerMonth = [[[totalPowerNode childNamed:@"PowerMTD"] stringValue] intValue];
		NSInteger powerProj = [[[totalPowerNode childNamed:@"PowerProj"] stringValue] intValue];
		
		powerNowLabel.text = [NSString stringWithFormat:@"%01.2f kW/hr", powerNow/1000.0];
		powerHourLabel.text = [NSString stringWithFormat:@"%01.2f kW", powerHour/1000.0];
		powerMonthLabel.text = [NSString stringWithFormat:@"%01.2f kW", powerMonth/1000.0];
		powerProjLabel.text = [NSString stringWithFormat:@"%01.2f kW", powerProj/1000.0];
		
		CXMLNode *utilityNode = [[document rootElement] childNamed:@"Utility"];
		NSInteger carbonRate = [[[utilityNode childNamed:@"CarbonRate"] stringValue] intValue];
		carbonNowLabel.text = [NSString stringWithFormat:@"%01.2f lbs/hr", powerNow * carbonRate/100000.0];
		carbonHourLabel.text = [NSString stringWithFormat:@"%01.2f lbs", powerHour * carbonRate/100000.0];
		carbonMonthLabel.text = [NSString stringWithFormat:@"%01.2f lbs", powerMonth * carbonRate/100000.0];
		carbonProjLabel.text = [NSString stringWithFormat:@"%01.2f lbs", powerProj * carbonRate/100000.0];
		
		// update meter
		
		meterView.meterMax = maxMeterValue;

		switch( meterDataType ) {
			case MeterDataTypeCost: {
				meterLabel.text = costNowLabel.text;
				meterView.meterValue = costNow;
				break;
			}
				
			case MeterDataTypePower: {
				meterLabel.text = powerNowLabel.text;
				meterView.meterValue = powerNow/1000;
				break;
			}
				
			case MeterDataTypeCarbon: {
				meterLabel.text = carbonNowLabel.text;
				meterView.meterValue = powerNow * carbonRate/100000.0;
				break;
			}
		}
		
	}
	else {
		// render the meter with the dial on 0
		meterView.meterMax = 100;
		meterView.meterValue = 0;
	}

	[meterView setNeedsDisplay];
	
}

- (void)dealloc {
	if( document )
		[document release];
    [super dealloc];
	
}

- (UIImage *)GCA
{
	NSString *requestString = @"http://chart.apis.google.com/chart?";
	NSString *param = @"cht=gom&chd=t:60&chs=250x100&chl=Power&chf=bg,s,000000";
	requestString = [requestString stringByAppendingString:param];
	requestString = [requestString stringByAddingPercentEscapesUsingEncoding:
					 NSUTF8StringEncoding];
	
	NSURL *requestURL = [NSURL URLWithString:requestString];
	NSData *chartData = [NSData dataWithContentsOfURL:requestURL];
	
	UIImage *chartImage = [UIImage imageWithData:chartData];
	
	return chartImage;
}

@end
