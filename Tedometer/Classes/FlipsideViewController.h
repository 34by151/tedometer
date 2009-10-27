//
//  FlipsideViewController.h
//  Ted5000
//
//  Created by Nathan on 10/4/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "TedometerData.h"

@protocol FlipsideViewControllerDelegate;


@interface FlipsideViewController : UIViewController {
	id <FlipsideViewControllerDelegate> delegate;
	UITextField *gatewayAddress;
	UISlider *refreshRateSlider;
	UILabel *refreshRateLabel;
	TedometerData *tedometerData;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITextField *gatewayAddress;
@property (nonatomic, retain) IBOutlet UISlider *refreshRateSlider;
@property (nonatomic, retain) IBOutlet UILabel *refreshRateLabel;

- (IBAction)done;
- (IBAction)textFieldDoneEditing:(id)sender;
- (IBAction)backgroundClick:(id)sender;
- (IBAction)updateRefreshRateLabel:(id)sender;

@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

