//
//  Dial.h
//  Ted-O-Meter
//
//  Created by Nathan on 2/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MeterViewSizing.h"
#import "Meter.h"

@interface Dial : NSObject {

	double baseRadiansPerTick;
	double unitsPerTick;
	double baseZeroAngle;
	double deltaRadiansPerTick;
	double deltaZeroAngle;
	double pivotValueForPinching;
	double normalizedRadiansPerTick;
	double normalizedUnitsPerTick;

	BOOL isNormalizationNeeded;
	BOOL isAnimating;
	BOOL isBeingTouched;
	BOOL isAtStretchLimit;
	BOOL isAtOffsetLimit;
	
	Meter *curMeter;
}

@property (nonatomic, strong) Meter* curMeter; 
@property (nonatomic, assign) double baseRadiansPerTick;
@property (nonatomic, assign) double baseZeroAngle;
@property (nonatomic, readonly) double unitsPerTick;
@property (nonatomic, readonly) double normalizedRadiansPerTick;
@property (nonatomic, readonly) double normalizedUnitsPerTick;
@property (nonatomic, readonly) double currentValue;
@property (nonatomic, assign) double deltaRadiansPerTick;
@property (nonatomic, assign) double deltaZeroAngle;
@property (nonatomic, assign) double pivotValueForPinching;
@property (nonatomic, readonly) BOOL isAnimating;
@property (nonatomic, readonly) double firstTickAngle;
@property (nonatomic, readonly) NSInteger numTicks;
@property (nonatomic, readonly) double radiansPerTick;
@property (nonatomic, readonly) double zeroAngle;
@property (nonatomic, assign) BOOL isBeingTouched;
@property (nonatomic, readonly) BOOL isAtStretchLimit;
@property (nonatomic, readonly) BOOL isAtOffsetLimit;


-(instancetype) initWithMeter:(Meter*)aMeter NS_DESIGNATED_INITIALIZER;
-(void) updateBaseValues;
-(void) animateToRestPosition;
-(void) nextAnimationFrame;
-(double) angleForValue:(double)value;
@property (NS_NONATOMIC_IOSONLY, readonly) double dialAngle;
-(BOOL) isValueVisible:(double) value;




@end
