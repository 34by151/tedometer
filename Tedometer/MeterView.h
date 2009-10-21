//
//  MeterView.h
//  Ted5000
//
//  Created by Nathan on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@interface MeterView : UIView {

	double meterValue;
	double meterMax;
	double meterMin;
	
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
}

@property (nonatomic) double meterValue;

- (double) meterRadius;
- (double) dialLength;
- (double) dialAngle;
- (CGPoint) polarCoordFromViewPoint:(CGPoint)point;
- (double) radiansFromMeterZeroForViewPoint:(CGPoint)point;


@end
