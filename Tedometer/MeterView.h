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
	BOOL isShowingTodayStatistics;

	TedometerData *tedometerData;
	
	NSInteger numTouchRevolutionsWhileDragging;
}

@property (nonatomic, assign) double meterValue;
@property (nonatomic, assign) double meterUpperBound;
@property (nonatomic, assign) BOOL isShowingTodayStatistics;

- (double) meterRadius;
- (double) dialLength;
- (double) angleForValue:(double)value;
- (double) dialAngle;
- (CGPoint) polarCoordFromViewPoint:(CGPoint)point;
- (double) radiansFromMeterZeroForViewPoint:(CGPoint)point;
- (void) updateTedometerData;
- (void) drawPointerInContext:(CGContextRef) context atAngle:(double)angle radius:(double)radius width:(double)width length:(double)length;
- (BOOL) isMeterAbleToDisplayValue:(double) value withUnitsPerTick:(double) unitsPerTickValue andRadiansPerTick:(double) radiansPerTickValue;



@end
