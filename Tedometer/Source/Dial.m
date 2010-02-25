//
//  Dial.m
//  Ted-O-Meter
//
//  Created by Nathan on 2/7/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Dial.h"
#import "VoltageMeter.h"
#import "MeterViewSizing.h"
#import "log.h"

// Hidden methods
@interface Dial ()
-(void) normalizeRadiansAndUnitsPerTick;
@end

@implementation Dial


@synthesize baseRadiansPerTick;
@synthesize baseZeroAngle;
@synthesize deltaZeroAngle;
@synthesize pivotValueForPinching;
@synthesize isBeingTouched;

-(id) initWithMeter:(Meter*)aMeter {
	if( self = [super init] ) {
		curMeter = nil;
		self.curMeter = aMeter;
	}
	
	return self;
}

-(void) setCurMeter:(Meter*)aMeter {
	if( curMeter != aMeter ) {
		Meter *oldMeter = curMeter;
		
		curMeter = [aMeter retain];
		
		NSLog(@"Dial.setCurMeter: aMeter.radiansPerTick = %f, aMeter.unitsPerTick = %f", aMeter.radiansPerTick, aMeter.unitsPerTick );
		
		// voltage meter doesn't share the same scale
		if( oldMeter && ! [oldMeter isMemberOfClass:[VoltageMeter class]] && ! [aMeter isMemberOfClass:[VoltageMeter class]] ) {
			
			if( oldMeter.now > 0 ) {
				// using current radiansPerTick and meter position, calculate new unitsPerTick
				aMeter.radiansPerTick = oldMeter.radiansPerTick;
				aMeter.unitsPerTick = oldMeter.now == 0 ? 0 : aMeter.now * (oldMeter.currentMaxMeterValue / (double) oldMeter.now) * (aMeter.radiansPerTick / (double) meterSpan);
				aMeter.zeroAngle = oldMeter.zeroAngle;
			} 
		}
		
		baseRadiansPerTick = aMeter.radiansPerTick;
		unitsPerTick = aMeter.unitsPerTick;
		baseZeroAngle = aMeter.zeroAngle;
		pivotValueForPinching = 0;
		deltaRadiansPerTick = 0;
		deltaZeroAngle = 0;
		isAnimating = NO;
		isBeingTouched = NO;
		isNormalizationNeeded = YES;
		isAtStretchLimit = NO;
		isAtOffsetLimit = NO;

		int defNumTicks = 10;
		if( baseRadiansPerTick == 0 )
			baseRadiansPerTick = meterSpan / defNumTicks;
		
		if( unitsPerTick == 0 || isnan( unitsPerTick ) ) {
			if( aMeter.now > 0 )
				unitsPerTick = (aMeter.now * 3.0) / defNumTicks;
			else
				unitsPerTick = aMeter.defaultUnitsPerTick;
		}
		
		[oldMeter release];
		
	}
}

-(Meter*) curMeter {
	return curMeter;
}

-(BOOL) isAnimating {
	return isAnimating;
}

-(double) currentValue {
	return [curMeter now];
}

-(double) firstTickAngle {
	return meterSpan - (self.radiansPerTick * self.numTicks);
}

-(double) deltaRadiansPerTick {
	return deltaRadiansPerTick;
}

-(void) setDeltaRadiansPerTick:(double)value {
	deltaRadiansPerTick = value;
	isNormalizationNeeded = YES;
}

-(double) normalizedRadiansPerTick {
	if( isNormalizationNeeded )
		[self normalizeRadiansAndUnitsPerTick];
	
	return normalizedRadiansPerTick;
}

-(double) normalizedUnitsPerTick {
	if( isNormalizationNeeded )
		[self normalizeRadiansAndUnitsPerTick];

	return normalizedUnitsPerTick;
}

-(void) normalizeRadiansAndUnitsPerTick {

	double savedNormalizedRadiansPerTick = normalizedRadiansPerTick;
	double savedNormalizedUnitsPerTick = normalizedUnitsPerTick;
	
	normalizedRadiansPerTick = baseRadiansPerTick + deltaRadiansPerTick;
	normalizedUnitsPerTick = unitsPerTick;
	
	if( savedNormalizedUnitsPerTick != normalizedUnitsPerTick || savedNormalizedRadiansPerTick != normalizedRadiansPerTick)
		isAtStretchLimit = NO;
	
	while( normalizedRadiansPerTick > maxRadiansPerTick ) {
		DLog( @"radiansPerTick %f exceeds MAX of %f...", normalizedRadiansPerTick, maxRadiansPerTick );
		normalizedRadiansPerTick /= 2.0;
		normalizedUnitsPerTick /= 2.0;
		
		double savedValue = normalizedRadiansPerTick;
		normalizedRadiansPerTick = MIN(maxRadiansPerTick, MAX( normalizedRadiansPerTick, minRadiansPerTick ));
		if( savedValue != normalizedRadiansPerTick )
			DLog( @"Bumped into max/min limits." );
	}
	
	while( normalizedRadiansPerTick < minRadiansPerTick ) {
		DLog( @"radiansPerTick %f exceeds MIN of %f...", normalizedRadiansPerTick, minRadiansPerTick );
		normalizedRadiansPerTick *= 2.0;
		normalizedUnitsPerTick *= 2.0;
		
		double savedValue = normalizedRadiansPerTick;
		normalizedRadiansPerTick = MAX(minRadiansPerTick, MIN( normalizedRadiansPerTick, maxRadiansPerTick ));
		if( savedValue != normalizedRadiansPerTick )
			DLog( @"Bumped into max/min limits." );
	}
	
	if( normalizedUnitsPerTick > self.curMeter.maxUnitsPerTick ) {
		DLog( @"unitsPerTick %f exceeds MAX of %d...", normalizedUnitsPerTick, self.curMeter.maxUnitsPerTick );
		normalizedUnitsPerTick = self.curMeter.maxUnitsPerTick;
		//normalizedUnitsPerTick = savedNormalizedUnitsPerTick;
		normalizedRadiansPerTick = savedNormalizedRadiansPerTick;
		isAtStretchLimit = YES;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidReachStretchLimit object:self];
	}
	
	else if( normalizedUnitsPerTick < self.curMeter.minUnitsPerTick ) {
		DLog( @"unitsPerTick %f exceeds MIN of %d...", normalizedUnitsPerTick, self.curMeter.minUnitsPerTick );
		normalizedUnitsPerTick = self.curMeter.minUnitsPerTick;
		//normalizedUnitsPerTick = savedNormalizedUnitsPerTick;
		normalizedRadiansPerTick = savedNormalizedRadiansPerTick;
		isAtStretchLimit = YES;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidReachStretchLimit object:self];

	}

	isNormalizationNeeded = NO;
	
}

-(BOOL) isAtStretchLimit;
{
	return isAtStretchLimit;
}

-(BOOL) isAtOffsetLimit;
{
	return isAtOffsetLimit;
}

-(double) radiansPerTick {
	return baseRadiansPerTick + deltaRadiansPerTick;
}

-(double) unitsPerTick {
	return unitsPerTick;
}

-(double) zeroAngle {
	double curZeroAngle = baseZeroAngle + deltaZeroAngle;
	//double maxAngle = 2*M_PI * 1.0;	// allow 2 full rotations each direction
	/*
	if( zeroAngle > maxAngle ) {
		baseZeroAngle = zeroAngle = maxAngle;
		deltaZeroAngle = 0;
	}
	else if( zeroAngle < - maxAngle ) {
		baseZeroAngle = zeroAngle = -maxAngle;
		deltaZeroAngle = 0;
	}
	*/
	return curZeroAngle;
		
	
/*		
	double zeroValue = zeroAngle * self.unitsPerTick / self.radiansPerTick;
	double maxValue = 
	if( zeroValue > M_PI * 2 * 2 ) {
		zeroAngle = curMeter.maxUnitsForOffset * self.radiansPerTick / self.unitsPerTick;
		baseZeroAngle = zeroAngle;
		deltaZeroAngle = 0;
	}
	else if( zeroValue < - curMeter.maxUnitsForOffset ) {
		zeroAngle = - curMeter.maxUnitsForOffset * self.radiansPerTick / self.unitsPerTick;
		baseZeroAngle = zeroAngle;
		deltaZeroAngle = 0;
	}
	
	return zeroAngle;
 */
}

-(NSInteger) numTicks {
	NSInteger numTicks = (NSInteger) (meterSpan / self.normalizedRadiansPerTick);
	return numTicks;
}


-(void) updateBaseValues {
	
	if( isNormalizationNeeded )
		[self normalizeRadiansAndUnitsPerTick];
	
	baseRadiansPerTick = normalizedRadiansPerTick;
	unitsPerTick = normalizedUnitsPerTick;
	
	baseZeroAngle = baseZeroAngle + deltaZeroAngle;
	
	deltaRadiansPerTick = 0;
	deltaZeroAngle = 0;
	
	self.curMeter.radiansPerTick = baseRadiansPerTick;
	self.curMeter.unitsPerTick = unitsPerTick;
	self.curMeter.zeroAngle = baseZeroAngle;
}

-(void) animateToRestPosition {
}

-(void) nextAnimationFrame {
}

-(void) dealloc {
	[curMeter release];
	[super dealloc];
}

- (double) angleForValue:(double)value {
	double angleFromStart = (value == 0 ? self.zeroAngle : self.zeroAngle + value * self.normalizedRadiansPerTick / self.normalizedUnitsPerTick);
	angleFromStart = MAX( 0, MIN( angleFromStart, meterSpan ) );

	return radOffset - angleFromStart;
}

- (double) dialAngle {
	return [self angleForValue:self.currentValue];
}

- (BOOL) isValueVisible:(double) value {
	double angle = self.zeroAngle + value * self.normalizedRadiansPerTick / self.normalizedUnitsPerTick;
	return angle >= 0.0 && angle <= meterSpan;
	//return (self.zeroAngle + (value / self.unitsPerTick * self.radiansPerTick) <= meterSpan);
}


@end
