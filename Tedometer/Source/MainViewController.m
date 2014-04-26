//
//  MeterViewController.m
//  Ted-O-Meter
//
//  Created by Nathan on 12/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "TedometerAppDelegate.h"
#import "MeterViewSizing.h"
#import "log.h"


@interface MainViewController ()
-(void)documentReloadDidFinish:(NSNotification*)notification;
-(void) connectionDidFail:(NSNotification*)notification;
-(void) mtuCountDidChange:(NSNotification*)notification;

@end

@implementation MainViewController

@synthesize pageControl;
@synthesize scrollView;
@synthesize meterViewControllers;
@synthesize toolbar;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	tedometerData = [TedometerData sharedTedometerData];
	
	isApplicationInactive = NO;
	hasShownFlipsideViewThisSession = NO;
	hasInitializedSinceFirstSuccessfulConnection = NO;


	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationDidBecomeActive:)
												 name:UIApplicationDidBecomeActiveNotification object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillResignActive:)
												 name:UIApplicationWillResignActiveNotification object:nil];

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
	
	
	// view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (unsigned i = 0; i < kNumberOfPages; i++) {
        [controllers addObject:[NSNull null]];
    }
    self.meterViewControllers = controllers;
    [controllers release];
	
    // a page is the width of the scroll view
	
    scrollView.pagingEnabled = YES;
    scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * tedometerData.meterCount, scrollView.frame.size.height);
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.scrollsToTop = NO;
    scrollView.delegate = self;
	
    pageControl.numberOfPages = tedometerData.meterCount;
    pageControl.currentPage = 0;

#if DRAW_FOR_ICON_SCREENSHOT || DRAW_FOR_LAUNCH_IMAGE
	pageControl.hidden = YES;
#endif
	
	// pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    [self loadScrollViewWithPage:0];
    [self loadScrollViewWithPage:1];
		
	// register for mtuCount changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mtuCountDidChange:) name:kNotificationMtuCountDidChange object:tedometerData];
	
	// register for connection failures
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionDidFail:) name:kNotificationConnectionFailure object:tedometerData];

	// register for document reloads, so that on startup we can return to the MTU we were on in our last session
	// nh 3/8/10: Not working for some reason
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentReloadDidFinish:) name:kNotificationDocumentReloadDidFinish object:tedometerData];

	if( tedometerData.refreshRate == -1.0 )
		[self performSelector:@selector(refreshData) withObject:nil afterDelay: 0.1];
	else
		[self performSelector:@selector(repeatRefresh) withObject:nil afterDelay: 0.1];

    [super viewDidLoad];
}


- (void) viewDidAppear:(BOOL)animated {
	
	[super viewDidAppear:animated];
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
	
	[UIDevice currentDevice].batteryMonitoringEnabled = NO;

}



- (void)dealloc {
	[pageControl release];
	[scrollView release];
	[meterViewControllers release];
	[toolbar release];

    [super dealloc];
}

-(void) repeatRefresh {
	[self refreshData];
	[self performSelector:@selector(repeatRefresh) withObject:nil afterDelay: tedometerData.refreshRate];
}


-(IBAction) refreshData {
	[tedometerData reloadXmlDocumentInBackground];
}

#pragma mark -
#pragma mark IB Actions

- (IBAction)showInfo {    

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repeatRefresh) object:nil];

	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	controller.connectionErrorMsg = tedometerData.connectionErrorMsg;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:controller animated:YES completion:nil];
    hasShownFlipsideViewThisSession = YES;
    
    // Note: flipsideViewControllerDidFinish: selector in this class
    // is called from FlipsideViewController when the Done button is selected.
    
	[controller release];
}

- (IBAction) activateCostMeter {
	[tedometerData activateCostMeter];
}

- (IBAction) activatePowerMeter {
	[tedometerData activatePowerMeter];
}

- (IBAction) activateCarbonMeter {
	[tedometerData activateCarbonMeter];
}

- (IBAction) activateVoltageMeter {
	[tedometerData activateVoltageMeter];
}


#pragma mark -
#pragma mark Flipside View
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {

	BOOL needsInitialRefresh = ! tedometerData.hasEstablishedSuccessfulConnectionThisSession;
	
	tedometerData.hasEstablishedSuccessfulConnectionThisSession = YES;
	
	[TedometerData archiveToDocumentsFolder];
	
	[(TedometerAppDelegate *)[[UIApplication sharedApplication] delegate] updateIdleTimerState];
	
//	[self dismissModalViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
	
//	if( needsInitialRefresh || tedometerData.refreshRate != -1.0 )
//		[self refreshData];
	
	//shouldAutoRefresh = YES;
	
	if( tedometerData.refreshRate == -1.0 ) {
        // nh 4/26/14: Can't remember why we're only refreshing after leaving the info panel
        // if we haven't yet had a successful connection? If we changed the host, SSL, etc.,
        // wouldn't we want to refresh that automatically?
        // Perhaps so that we don't refresh if all they did was view the settings, but
        // didn't change anything? Thinking this must be the reason.
		if( needsInitialRefresh )
			[self refreshData];
	}
	else
		[self repeatRefresh];
	
	
	// refresh will get called in viewDidAppear:
}

#pragma mark -
#pragma mark Inactivity Monitoring

- (void) applicationWillResignActive: (NSNotification*)notification {
	isApplicationInactive = YES;
}

- (void) applicationDidBecomeActive: (NSNotification*)notification {
	isApplicationInactive = NO;
}

#pragma mark -
#pragma mark UIScrollViewDelegate

- (void)loadScrollViewWithPage:(long)page {
    if (page < 0) return;
    if (page >= kNumberOfPages) return;
	
    // replace the placeholder if necessary
    MeterViewController *controller = [meterViewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null]) {
		
		NSInteger mtuNumber = page;

		NSMutableArray *mtuMeters = [tedometerData.mtusArray objectAtIndex:mtuNumber];
		
        controller = [[MeterViewController alloc] initWithMainViewController:self
																  powerMeter:[mtuMeters objectAtIndex:kMeterTypePower] 
																   costMeter:[mtuMeters objectAtIndex:kMeterTypeCost] 
																 carbonMeter:[mtuMeters objectAtIndex:kMeterTypeCarbon]
																voltageMeter:[mtuMeters objectAtIndex:kMeterTypeVoltage]];
		
		if( page == 0 ) //page % 2 == 0 )
			controller.view.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
		else
			controller.view.backgroundColor = [UIColor colorWithWhite:0.23 alpha:1.0];

			
        [meterViewControllers replaceObjectAtIndex:page withObject:controller];
        [controller release];
    }
	
    // add the controller's view to the scroll view
    if (nil == controller.view.superview) {
        CGRect frame = scrollView.frame;
        frame.origin.x = frame.size.width * page;
        //frame.origin.y = 0;
        controller.view.frame = frame;
        [scrollView addSubview:controller.view];
		[self updateMeterVisibility];
    }
	
	[controller stopDialEdit];
	[controller refreshView];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
	
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (! pageControlUsed) {
		// Switch the indicator when more than 50% of the previous/next page is visible
		CGFloat pageWidth = scrollView.frame.size.width;
		int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
		pageControl.currentPage = page;
		
		// load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
		[self loadScrollViewWithPage:page - 1];
		[self loadScrollViewWithPage:page];
		[self loadScrollViewWithPage:page + 1];
		// A possible optimization would be to unload the views+controllers which are no longer visible
	}
	
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)aScrollView {
    pageControlUsed = NO;
}

- (IBAction)changePage:(id)sender {
    long page = pageControl.currentPage;
	
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
	
    // update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
	DLog(@"Switching frame to origin at %f", frame.origin.x);
    [scrollView scrollRectToVisible:frame animated:YES];
	
	// nh 3/8/10: The following seems to work as well as the scrollRecToVisible method.
	// Was trying to figure out a way to solve hte problem of this method not scrolling
	// the view when invoked from the 
	//CGPoint offsetPoint = CGPointMake( frame.size.width*page, 0 );
	//[scrollView setContentOffset: offsetPoint animated: YES];
	
    // Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = NO;
	//[scrollView setNeedsDisplay];
	//[scrollView setNeedsLayout];
	//[self.view setNeedsLayout];
	//[self.view setNeedsDisplay];
}

- (void) updateMeterVisibility;
{
	for( int i=0; i < kNumberOfPages; ++i ) {
		MeterViewController* controller = [meterViewControllers objectAtIndex:i];
		if( (NSNull *)controller != [NSNull null] ) {
			BOOL isHidden = (i >= tedometerData.meterCount);
			controller.view.hidden = isHidden;
		}
	}
}

- (void) switchToPage:(NSInteger)pageNumber {
	DLog(@"pageNumber = %ld mtuCount = %ld", (long)pageNumber, (long)tedometerData.meterCount);
	if( pageNumber < 0 || pageNumber >= tedometerData.meterCount ) {
		pageNumber = 0;
	}
	pageControl.currentPage = 1; //pageNumber;
	//[self performSelector:@selector(changePage:) withObject:self afterDelay:1.5];
	[self changePage:self];
	pageControlUsed = NO;
}

#pragma mark -
#pragma mark Notification handlers

- (void) mtuCountDidChange:(NSNotification*)notification;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger newMtuCount = tedometerData.mtuCount;

        // if there's only one mtu, we only show the net meter
        if( newMtuCount <= 1 ) {
            if( pageControl.currentPage > 0 ) {
                pageControl.currentPage = 0;
                [self changePage:self];
            }
            pageControl.numberOfPages = 1;
        }
        else {
            if( pageControl.currentPage + 1 > tedometerData.meterCount ) {
                pageControl.currentPage = 0;
            }
            pageControl.numberOfPages = tedometerData.meterCount;
            
            [self changePage:self];
            pageControlUsed = NO;
        }
        
        scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * tedometerData.meterCount, scrollView.frame.size.height);
        
        [self updateMeterVisibility];
    });

}

-(void)documentReloadDidFinish:(NSNotification*)notification;
{
    dispatch_async(dispatch_get_main_queue(), ^{

        if( tedometerData.hasEstablishedSuccessfulConnectionThisSession ) {
            if( ! hasInitializedSinceFirstSuccessfulConnection ) {
                hasInitializedSinceFirstSuccessfulConnection = YES;
                [self switchToPage:tedometerData.curMtuIdx];
            }
        }
            
        [self switchToPage:tedometerData.curMtuIdx];	// This isn't working, for some reason
    });

}

- (void) connectionDidFail:(NSNotification*)notification;
{
    dispatch_async(dispatch_get_main_queue(), ^{

        if( ! tedometerData.hasEstablishedSuccessfulConnectionThisSession && ! hasShownFlipsideViewThisSession ) {
            
            // if the gateway host is empty and we haven't shown the flipside this session,
            // don't show an error message; just let them provide the settings
            if( tedometerData.gatewayHost == nil || [tedometerData.gatewayHost isEqualToString:@""] )
                tedometerData.connectionErrorMsg = nil;
            
            [self showInfo];
        }
    });
	
}
@end
