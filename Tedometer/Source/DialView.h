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
	
	double lastOffsetDragClickAngle;
}

@property (nonatomic, retain) Meter *curMeter;
@property (nonatomic, retain) UIButton *stopDialEditButton;

-(void) startDialEdit;
-(void) stopDialEdit;



@end
