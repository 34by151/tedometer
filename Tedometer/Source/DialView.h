//
//  MeterView.h
//  Ted5000
//
//  Created by Nathan on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import "TedometerData.h"
#import "Meter.h"
#import "Dial.h"


@interface DialView : UIView {

	
	double touchAngleWhenTouchesBegan;		// 0 = meter start angle
	double animationRadianIncrement;
	double resizeGapBeforeAnimation;

	TedometerData *tedometerData;
	
	NSInteger numTouchRevolutionsWhileDragging;
	double initialDistanceBetweenTouches;
	
	BOOL drawForIconScreenshot;
	
	BOOL isEditMode;
	BOOL isBeingTouchedBeforeEditMode;
	BOOL isBeingPinched;
	
	NSDate *touchesBeganDate;
	
	UIButton *stopDialEditButton;
	
	Meter *curMeter;
	Dial *dial;
	
	SystemSoundID limitReachedSoundId;
	SystemSoundID clickSoundId;
	SystemSoundID pushInSoundId;
	SystemSoundID pushOutSoundId;
	
	double lastOffsetDragClickAngle;
	
	UIView *parentDialView;
	UIImageView *parentDialShadowView;
	UIImageView *parentDialShadowThinView;
	UIImageView *parentDialHaloView;
	UIImageView *parentGlareView;
	UIImageView *parentDimmerView;
	
}

@property (nonatomic, strong) UIImageView *parentDialShadowView;
@property (nonatomic, strong) UIImageView *parentDialShadowThinView;
@property (nonatomic, strong) UIImageView *parentDialHaloView;
@property (nonatomic, strong) UIImageView *parentGlareView;
@property (nonatomic, strong) UIImageView *parentDimmerView;
@property (nonatomic, strong) UIView *parentDialView;
@property (nonatomic, strong) Meter *curMeter;
@property (nonatomic, strong) UIButton *stopDialEditButton;

-(void) stopDialEdit;
-(void) startDialEdit;
-(void) stopDialEditAndSaveSettings;



@end
