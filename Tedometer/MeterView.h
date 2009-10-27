//
//  MeterView.h
//  Ted5000
//
//  Created by Nathan on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "TedometerData.h"


@interface MeterView : UIView {

	double meterValue;
	
	double radiansPerTick;
	double unitsPerTick;
	
	double meterUpperBound;
	double meterLowerBound;
	
	BOOL isDialBeingDragged;
	BOOL isResizeAnimationInProgress;
	double radiansPerTickWhenTouchesBegan;
	double meterOffsetFromZeroWhenTouchesBegan;
	double animationRadianIncrement;
	double resizeGapBeforeAnimation;
	
	//float meterValueWhenTouchesBegan;
	//float meterMaxWhenTouchesBegan;
	
	NSNumberFormatter *currencyFormatter;
	TedometerData *tedometerData;
	
}

@property (nonatomic, assign) double meterValue;
@property (nonatomic, assign) double meterUpperBound;

- (double) meterRadius;
- (double) dialLength;
- (double) dialAngle;
- (CGPoint) polarCoordFromViewPoint:(CGPoint)point;
- (double) radiansFromMeterZeroForViewPoint:(CGPoint)point;
- (void) updateTedometerData;

@end
