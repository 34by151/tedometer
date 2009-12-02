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
	UISwitch *disableAutolockWhilePluggedIn;
	UILabel *connectionErrorMsgLabel;
	UIView *settingsView;
	UIView *warningView;
	UIScrollView *scrollView;
	UITextField *username;
	UITextField *password;
	UISwitch *useSSL;
	NSString *connectionErrorMsg;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UITextField *gatewayAddress;
@property (nonatomic, retain) IBOutlet UISlider *refreshRateSlider;
@property (nonatomic, retain) IBOutlet UILabel *refreshRateLabel;
@property (nonatomic, retain) IBOutlet UISwitch *disableAutolockWhilePluggedIn;
@property (nonatomic, retain) IBOutlet UILabel *connectionErrorMsgLabel;
@property (nonatomic, retain) IBOutlet UIView *settingsView;
@property (nonatomic, retain) IBOutlet UIView *warningView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UISwitch *useSSL;
@property (nonatomic, retain) IBOutlet UITextField *username;
@property (nonatomic, retain) IBOutlet UITextField *password;
@property (nonatomic, copy) NSString *connectionErrorMsg;



- (IBAction)done;
- (IBAction)textFieldDoneEditing:(id)sender;
- (IBAction)backgroundClick:(id)sender;
- (IBAction)updateRefreshRateLabel:(id)sender;
- (IBAction)clearConnectionErrorMsg:(id)sender;
@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

