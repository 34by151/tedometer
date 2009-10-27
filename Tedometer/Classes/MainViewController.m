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
#import "Ted5000AppDelegate.h"

@implementation MainViewController

@synthesize nowValue;
@synthesize hourValue;
@synthesize todayValue;
@synthesize monthValue;
@synthesize projValue;
@synthesize meterLabel;
@synthesize meterView;
@synthesize activityIndicator;
@synthesize toolbar;

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
	 
	 nowValue.text = @"...";
	 hourValue.text = @"...";
	 todayValue.text = @"...";
	 monthValue.text = @"...";
	 projValue.text = @"...";
	 
	 shouldAutoRefresh = YES;
	 [self performSelector:@selector(repeatRefresh) withObject:nil afterDelay: 2.0];

	 tedometerData = [TedometerData sharedTedometerData];
	 [super viewDidLoad];
 }


- (void) viewWillAppear:(BOOL)animated {
				
	[super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
	[self refreshView];
	
	if( tedometerData.refreshRate == -1.0 ) {
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

	[TedometerData archiveToDocumentsFolder];
	
	[self dismissModalViewControllerAnimated:YES];
	shouldAutoRefresh = YES;
	// refresh will get called in viewDidAppear:
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
	if( shouldAutoRefresh && tedometerData.refreshRate != -1.0 )
		[self refreshData];
	[self performSelector:@selector(repeatRefresh) withObject:nil afterDelay: tedometerData.refreshRate];
}

-(void) reloadXmlDocument {

	NSString *urlString = [NSString stringWithFormat:@"http://%@/api/LiveData.xml", tedometerData.gatewayHost];
    NSURL *url = [NSURL URLWithString: urlString];
	
	NSError* error;
	CXMLDocument *newDocument = [[[CXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error] retain];
	if( ! newDocument ) {
		NSLog( @"%@", [error localizedDescription]);
	}
	else {
		@synchronized( self ) {
			if( document )
				[document release];
			document = newDocument;
		}
		[self performSelectorOnMainThread:@selector(stopActivityIndicator) withObject:self waitUntilDone:NO];
		[self performSelectorOnMainThread:@selector(refreshView) withObject:self waitUntilDone:NO];
	}
}

-(void) stopActivityIndicator {
	[activityIndicator stopAnimating];
}

-(IBAction) refreshData {
	
	[activityIndicator startAnimating];
	NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(reloadXmlDocument) object:nil];
	[[(Ted5000AppDelegate *)[[UIApplication sharedApplication] delegate] sharedOperationQueue] addOperation:op];
	[op release];
}

-(void) refreshView {
		
	BOOL isSuccessful = NO;
	
	@synchronized( self ) {
		if( document ) 
			isSuccessful = [tedometerData refreshDataFromXmlDocument:document];
	}
	if( isSuccessful ) {
		nowValue.text = [tedometerData.curMeter meterStringForInteger:tedometerData.curMeter.now];
		hourValue.text = [tedometerData.curMeter meterStringForInteger:tedometerData.curMeter.hour];
		todayValue.text = [tedometerData.curMeter meterStringForInteger:tedometerData.curMeter.today];
		monthValue.text = [tedometerData.curMeter meterStringForInteger:tedometerData.curMeter.mtd];
		projValue.text = [tedometerData.curMeter meterStringForInteger:tedometerData.curMeter.projected];
		
		meterLabel.text = [nowValue.text stringByAppendingString:@"/hr"];
		meterView.meterValue = tedometerData.curMeter.now;
	}
	else {
		// render the meter with the dial on 0
		meterView.meterValue = 0;
	}

	meterView.meterUpperBound = tedometerData.curMeter.meterMaxValue;
	[meterView setNeedsDisplay];
	
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

- (void)dealloc {
	if( document )
		[document release];
	
	[nowValue release];
	[hourValue release];
	[todayValue release];
	[monthValue release];
	[projValue release];
	[meterLabel release];
	[meterView release];
	[activityIndicator release];
    [super dealloc];
	
}

@end
