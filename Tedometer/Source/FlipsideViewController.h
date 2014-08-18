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
	id <FlipsideViewControllerDelegate> __weak delegate;
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
	UISwitch *patchAggregationData;
    UINavigationBar *navigationBar;
    UISegmentedControl *totalsMeterTypeSegmentedControl;
}

@property (nonatomic, weak) id <FlipsideViewControllerDelegate> delegate;
@property (nonatomic, strong) IBOutlet UITextField *gatewayAddress;
@property (nonatomic, strong) IBOutlet UISlider *refreshRateSlider;
@property (nonatomic, strong) IBOutlet UILabel *refreshRateLabel;
@property (nonatomic, strong) IBOutlet UISwitch *disableAutolockWhilePluggedIn;
@property (nonatomic, strong) IBOutlet UILabel *connectionErrorMsgLabel;
@property (nonatomic, strong) IBOutlet UIView *settingsView;
@property (nonatomic, strong) IBOutlet UIView *warningView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UISwitch *useSSL;
@property (nonatomic, strong) IBOutlet UITextField *username;
@property (nonatomic, strong) IBOutlet UITextField *password;
@property (nonatomic, strong) IBOutlet UISwitch *patchAggregationData;
@property (nonatomic, strong) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, copy) NSString *connectionErrorMsg;
@property (nonatomic, strong) IBOutlet UISegmentedControl *totalsMeterTypeSegmentedControl;



- (IBAction)done;
- (IBAction)textFieldDoneEditing:(id)sender;
- (IBAction)backgroundClick:(id)sender;
- (IBAction)updateRefreshRateLabel:(id)sender;
- (IBAction)showConnectionErrorMsg:(id)sender;
- (IBAction)clearConnectionErrorMsg:(id)sender;
@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

