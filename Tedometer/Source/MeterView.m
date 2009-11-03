//
//  MeterView.m
//  Ted5000
//
//  Created by Nathan on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <math.h>
#import "MeterView.h"
#import "MeterViewSizing.h"

@implementation MeterView

@synthesize meterValue;
@synthesize meterUpperBound;
@synthesize isShowingTodayStatistics;

//#define DRAW_FOR_PEAK_POINTER_SCREENSHOT
//#define DRAW_FOR_AVG_POINTER_SCREENSHOT
//#define DRAW_FOR_LOW_POINTER_SCREENSHOT

double magnitude( CGPoint p );
double distanceFromCenterToEdgeOfRectAtAngle( CGSize size, double angle );
CGPoint cartesianToPolar( CGPoint p );
CGPoint polarToCartesian( CGPoint p );
double distanceBetweenPoints( CGPoint p1, CGPoint p2 );
double angleBetweenPoints( CGPoint origin, CGPoint p1, CGPoint p2 );

double magnitude( CGPoint p ) {
	return distanceBetweenPoints( p, CGPointMake( 0, 0 ) );
}


/** 
 * Converts (x,y) to (magnitude, angle);
 */
CGPoint cartesianToPolar( CGPoint p ) {
	double angle = atan2( p.y, p.x );
	return CGPointMake( magnitude( p ), angle );
}

/**
 * Converts (magnitude, angle) to (x,y)
 */
CGPoint polarToCartesian( CGPoint p ) {
	return CGPointMake( p.x * cos( p.y ), p.x * sin( p.y ) );
}

double distanceFromCenterToEdgeOfRectAtAngle( CGSize size, double angle ) {
	
	// from http://stackoverflow.com/questions/1343346/calculate-a-vector-from-the-center-of-a-square-to-edge-based-on-radius/1343531#1343531

	double magnitude;

	double abs_cos_angle= fabs(cos(angle));
	double abs_sin_angle= fabs(sin(angle));
	if( size.width/2.0 * abs_sin_angle <= size.height/2.0 * abs_cos_angle)
		magnitude = size.width/2.0/abs_cos_angle;
	else
		magnitude = size.height/2.0/abs_sin_angle;
	
	return magnitude;
}

double distanceBetweenPoints( CGPoint p1, CGPoint p2 ) {
	double distance = sqrt( (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y) );
	return distance;
}

double angleBetweenPoints( CGPoint origin, CGPoint p1, CGPoint p2 ) {

	double angle;
	CGPoint v1 = CGPointMake( p1.x - origin.x, p1.y - origin.y );
	CGPoint v2 = CGPointMake( p2.x - origin.x, p2.y - origin.y );
	double dotProd = v1.x * v2.x + v1.y * v2.y;
	angle = acos( dotProd / (magnitude( v1 ) * magnitude( v2 )) ); 
	
	return angle;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		meterValue = 25;
		unitsPerTick = 10;
		radiansPerTick = meterSpan / 10;
    }
    return self;
}

- (void)awakeFromNib {

#ifdef DRAW_FOR_ICON_SCREENSHOT
	drawForIconScreenshot = YES;
#else
	drawForIconScreenshot = NO;
#endif
	
	tedometerData = [TedometerData sharedTedometerData];

	meterValue = 0;
	
	meterUpperBound = tedometerData.curMeter.meterEndMax;
	meterLowerBound = tedometerData.curMeter.meterEndMin;
	unitsPerTick = tedometerData.curMeter.unitsPerTick;
	radiansPerTick = tedometerData.curMeter.radiansPerTick;
	isDialBeingDragged = NO;
	isResizeAnimationInProgress = NO;
	isShowingTodayStatistics = YES;
	
	if( radiansPerTick == 0 )
		radiansPerTick = M_PI / 10.0;
	if( unitsPerTick == 0 )
		unitsPerTick = 10;

	[tedometerData addObserver:self forKeyPath:@"curMeterIdx" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	meterUpperBound = tedometerData.curMeter.meterEndMax;
	meterLowerBound = tedometerData.curMeter.meterEndMin;
	unitsPerTick = tedometerData.curMeter.unitsPerTick;
	radiansPerTick = tedometerData.curMeter.radiansPerTick;
	
	if( radiansPerTick == 0 )
		radiansPerTick = M_PI / 10.0;
	if( unitsPerTick == 0 )
		unitsPerTick = 10;
	
}
- (double) dialLength {
	return [self meterRadius] - 45;
}

- (double) meterRadius {
	return self.bounds.size.width/2.0;
}


- (void)drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGRect drect = self.bounds;
	
	// put origin at center with y increasing upwards
	CGContextTranslateCTM( context, drect.size.width/2, drect.size.height/2);
	CGContextScaleCTM( context, 1.0, -1.0 );

	double meterRadius = [self meterRadius];
	double dialLength = [self dialLength];
	double edgeWidth = 18;
	double tickLength = 15;

	int numWholeTicks = (int) (meterSpan / radiansPerTick);

	if( isResizeAnimationInProgress ) {
		double newRadiansPerTick = radiansPerTick + animationRadianIncrement;
		if( newRadiansPerTick * numWholeTicks > meterSpan ) { 
			isResizeAnimationInProgress = NO;
			[self updateTedometerData];
		}
		else 
			radiansPerTick = newRadiansPerTick;
	}
	

	if( ! isDialBeingDragged ) {
		radiansPerTickWhenTouchesBegan = radiansPerTick;
	}
	
	
	double drawRadiansPerTick = radiansPerTick;
	double drawUnitsPerTick = unitsPerTick;
	
	if( drawRadiansPerTick == 0 )
		drawRadiansPerTick = 0.01;
	
	while( drawRadiansPerTick < minRadiansPerTick ) {
		drawRadiansPerTick *= 2.0;
		drawUnitsPerTick *= 2.0;
		//NSLog(@"drawRect: Doubled drawRadiansPerTick (%f), halved drawUnitsPerTick (%f)", drawRadiansPerTick, drawUnitsPerTick );
	}
	
	while( drawRadiansPerTick > maxRadiansPerTick ) {
		drawRadiansPerTick /= 2.0;
		drawUnitsPerTick /= 2.0;
		//NSLog(@"drawRect: Halved drawRadiansPerTick (%f), halved drawUnitsPerTick (%f)", drawRadiansPerTick, drawUnitsPerTick );
	}
	
	int numArcTicks = meterSpan / drawRadiansPerTick;

	
	// danger arc
	double arcRadians = meterSpan * 6/7.0;
	double arcStartRadian = radOffset - meterSpan + arcRadians;
	double arcEndRadian = radOffset - meterSpan;
	double arcStartThickness = 1;
	double arcEndThickness = tickLength * 5 / 5.0;
	double arcAlphaStartVal = 0.0;
	double arcAlphaEndVal = 0.9;

	double numArcPieces = 100; //arcRadians * (meterRadius - edgeWidth);

	double alphaMultiplier = 1.0;
	double alphaMultiplierDuringDrag = 0.3;
	if( isDialBeingDragged )
		alphaMultiplier = alphaMultiplierDuringDrag;
	
	if( isResizeAnimationInProgress ) {
		double gapRadians = meterSpan - (drawRadiansPerTick * numWholeTicks);
		alphaMultiplier = 1.0 - (1.0 - alphaMultiplierDuringDrag) * gapRadians / resizeGapBeforeAnimation;
		//NSLog(@"animationAlphaFactor = %f, gapRadians = %f", alphaMultiplier, gapRadians);
	}
	
	for( int arcPiece = 0; arcPiece < numArcPieces; ++arcPiece ) {
		double arcPieceStartRadian = arcStartRadian + arcPiece * (arcEndRadian - arcStartRadian) / numArcPieces;
		double arcPieceEndRadian = arcStartRadian + (arcPiece+1) * (arcEndRadian - arcStartRadian) / numArcPieces; 
		double alphaVal = arcAlphaStartVal + arcPiece * (arcAlphaEndVal - arcAlphaStartVal) / numArcPieces;
		alphaVal *= alphaMultiplier;
		
		double lineWidth = arcStartThickness + arcPiece * (arcEndThickness - arcStartThickness ) / numArcPieces;
		CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, alphaVal);
		CGContextSetLineWidth(context, lineWidth);
		CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - lineWidth / 2, arcPieceStartRadian, arcPieceEndRadian, 1 ); 
		CGContextStrokePath( context );
	}

	
	// draw ticks
	CGContextSetRGBStrokeColor(context, 0.35, 0.35, 0.35, 1.0);
	CGContextSetLineWidth(context, 1.0);
	
	for( int curTick = 0; curTick <= numArcTicks; ++curTick ) {
		
		double curRad = curTick * drawRadiansPerTick;
		double angle = radOffset - curRad;
		double x1 = (meterRadius - edgeWidth) * cos( angle );
		double y1 = (meterRadius - edgeWidth) * sin( angle );
		double x2 = (meterRadius - edgeWidth - tickLength) * cos( angle );
		double y2 = (meterRadius - edgeWidth - tickLength) * sin( angle );
		CGContextMoveToPoint( context, x1, y1 );
		CGContextAddLineToPoint( context, x2, y2 );
	}
	CGContextStrokePath(context);
	


	if( ! drawForIconScreenshot ) {
	
		// draw tick labels
		if( meterValue > 0.0 ) {

			if( unitsPerTick > 0 && radiansPerTick > 0 ) {
				CGContextSaveGState(context);
				CGContextScaleCTM(context, 1.0, -1.0);
				
				
				double labelGap = 8;
				UIFont *font = [UIFont fontWithName:@"Helvetica" size:10.0];
				UIColor *textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];

				[textColor set];
				
				for( int curTick = 0; curTick <= numArcTicks; ++curTick ) {
					
					double curRad = curTick * drawRadiansPerTick;
					double labelValue = curTick * drawUnitsPerTick;
					NSString *label = [[tedometerData curMeter]tickLabelStringForInteger: labelValue];
					CGSize labelSize = [label sizeWithFont: font];
					double angle = radOffset - curRad;
					double labelCenterRadius = (meterRadius - edgeWidth - tickLength - labelGap);
					labelCenterRadius -= distanceFromCenterToEdgeOfRectAtAngle( labelSize, angle );
					double x1 = labelCenterRadius * cos( angle ) - labelSize.width / 2.0;
					double y1 = labelCenterRadius * sin( angle ) + labelSize.height / 2.0;
					[label drawAtPoint:CGPointMake(x1,-y1) withFont:font];
				}
				CGContextStrokePath(context);
				CGContextRestoreGState(context);
			}
		}
	

		double pointerWidth = 10.0;
		double pointerProtrusionLength = tickLength * 0.2;
		double pointerProtrusionBeyondTicks = 4;
		double pointerLength = tickLength + pointerProtrusionLength + pointerProtrusionBeyondTicks;
		double pointerRadius = meterRadius - edgeWidth + pointerProtrusionBeyondTicks;
		
		double peakValue = isShowingTodayStatistics ? tedometerData.curMeter.todayPeakValue : tedometerData.curMeter.mtdPeakValue;
		double avgValue = isShowingTodayStatistics ? tedometerData.curMeter.todayAverage : tedometerData.curMeter.monthAverage;
		double lowValue = isShowingTodayStatistics ? tedometerData.curMeter.todayMinValue : tedometerData.curMeter.mtdMinValue;
		double peakAngle = 0;
		double avgAngle = 0;
		double lowAngle = 0;
		double overlapOffset = (0.5 * M_PI / 180.0);	// if values overlap, displace them by half a degree 
		
		if( peakValue > 0 && [self isMeterAbleToDisplayValue:peakValue withUnitsPerTick:drawUnitsPerTick andRadiansPerTick:drawRadiansPerTick] ) {
			peakAngle = [self angleForValue:peakValue];
			CGContextSetRGBFillColor( context, 0.98, 0.62, 0.23, 1.0 );	// yellow
#ifdef DRAW_FOR_PEAK_POINTER_SCREENSHOT
			double radius = pointerRadius + pointerLength + edgeWidth + 1;
			[self drawPointerInContext:context atAngle: - M_PI /4 radius:radius width:pointerWidth length:pointerLength];
#else
			[self drawPointerInContext:context atAngle:peakAngle radius:pointerRadius width:pointerWidth length:pointerLength];
#endif
		}

		if( peakValue > 0 && [self isMeterAbleToDisplayValue:lowValue withUnitsPerTick:drawUnitsPerTick andRadiansPerTick:drawRadiansPerTick] ) {
			lowAngle = [self angleForValue:lowValue];
			if( peakValue > 0 && ABS(peakAngle - lowAngle) < 2.0 * overlapOffset )
				lowAngle += 2.0 * overlapOffset;
			CGContextSetRGBFillColor(context, 0.3, 0.3, 1.0, 1.0);	// blue
#ifdef DRAW_FOR_LOW_POINTER_SCREENSHOT
			double radius = pointerRadius + pointerLength + edgeWidth + 1;
			[self drawPointerInContext:context atAngle: - M_PI /4 radius:radius width:pointerWidth length:pointerLength];
#else
			[self drawPointerInContext:context atAngle: lowAngle radius:pointerRadius width:pointerWidth length:pointerLength];
#endif
			
		}
		
		if( avgValue > 0 && [self isMeterAbleToDisplayValue:avgValue withUnitsPerTick:drawUnitsPerTick andRadiansPerTick:drawRadiansPerTick] ) {
			avgAngle = [self angleForValue:avgValue];
			if( peakValue > 0 && ABS(peakAngle - avgAngle) < overlapOffset )
				avgAngle = peakAngle + overlapOffset;
			if( lowValue > 0 && ABS(avgAngle - lowAngle) < overlapOffset )
				avgAngle = lowAngle - overlapOffset;
			
			CGContextSetRGBFillColor( context, 0.60, 0.77, 0.19, 1.0 );	// green
#ifdef DRAW_FOR_AVG_POINTER_SCREENSHOT
			double radius = pointerRadius + pointerLength + edgeWidth + 1;
			[self drawPointerInContext:context atAngle: - M_PI /4 radius:radius width:pointerWidth length:pointerLength];
#else
			[self drawPointerInContext:context atAngle:avgAngle radius:pointerRadius width:pointerWidth length:pointerLength];
#endif
		}
		
	}


	// draw dial
	
	
	
	float dialAngle;
	if( drawForIconScreenshot )
		dialAngle = M_PI - M_PI/3.0;
	else
		dialAngle = [self dialAngle];
	
	CGContextSaveGState(context);
	CGContextRotateCTM(context, dialAngle);
	
	CGContextSetRGBStrokeColor(context, 1.0, 0.2, 0.2, 1.0);
	if( false && isDialBeingDragged ) 
		CGContextSetShadowWithColor( context, CGSizeMake( 0, 0 ), 20.0, [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0].CGColor );
	else 
		CGContextSetShadow( context, CGSizeMake( 0, -2.5 ), 4 );
	
	// TODO: Convert this to a filled polygon?
	float centerOffset = -3.0;
	float largeEndWidth = 6.0;
	CGContextSetLineCap( context, kCGLineCapRound );
	CGContextSetLineWidth(context, 10.0);
	CGContextMoveToPoint( context, centerOffset, largeEndWidth / 2.0 );
	CGContextAddLineToPoint( context, dialLength, 0 );
	CGContextMoveToPoint( context, centerOffset, -largeEndWidth / 2.0 );
	CGContextAddLineToPoint( context, dialLength, 0 );
	CGContextMoveToPoint( context, centerOffset, largeEndWidth / 2.0 );
	CGContextAddLineToPoint( context, centerOffset, -largeEndWidth / 2.0 );
	CGContextStrokePath(context);
	
	CGContextRestoreGState(context);
}

- (void) drawPointerInContext:(CGContextRef) context atAngle:(double)angle radius:(double)radius width:(double)width length:(double)length {

	CGContextSaveGState(context);
	
	CGContextRotateCTM(context, angle);
	
	CGContextSetShadow( context, CGSizeMake( 0, -1 ), 1 );
	CGContextSetLineWidth( context, 0 );
	CGContextMoveToPoint( context, radius, width / 2.0 );
	CGContextAddLineToPoint( context, radius - width / 2.0, 0 );
	CGContextAddLineToPoint( context, radius, - width / 2.0 );
	
	CGContextAddLineToPoint( context, radius - length, 0 );
	CGContextClosePath( context );
	CGContextFillPath( context );
	
	CGContextRestoreGState( context );
}

/**
 * Returns clockwise radians from meter zero to point
 */

- (double) radiansFromMeterZeroForViewPoint:(CGPoint)point {
	CGPoint p = [self polarCoordFromViewPoint: point];
	
	double radians;
	if( p.y <= radOffset )
		radians = radOffset - p.y;
	else 
		radians = radOffset + (2*M_PI - p.y);

	return radians;
	
}

- (CGPoint) polarCoordFromViewPoint:(CGPoint)point {
	CGAffineTransform t = CGAffineTransformMakeTranslation( - self.bounds.size.width/2, self.bounds.size.height/2); 
	t = CGAffineTransformScale( t, 1, -1 );
	
	CGPoint pCart = CGPointApplyAffineTransform( point, t );
	CGPoint pPolar = cartesianToPolar( pCart );
	
	
	if( pPolar.y < 0 )
		pPolar.y += 2 * M_PI;
	
	return pPolar;
}

- (BOOL) isMeterAbleToDisplayValue:(double) value withUnitsPerTick:(double) unitsPerTickValue andRadiansPerTick:(double) radiansPerTickValue {
	return (value >= 0) && ((value / unitsPerTickValue * radiansPerTickValue) <= meterSpan);
}

- (double) angleForValue:(double)value {
	double angleFromOffset = MAX( 0, MIN( value * radiansPerTick / unitsPerTick, meterSpan ) );
	return radOffset - angleFromOffset;
}

- (double) dialAngle {
	return [self angleForValue:meterValue];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	CGPoint location = [touch locationInView:self];
	CGPoint locationPolar = [self polarCoordFromViewPoint:location];
	
	double meterRadiansFromZeroForLocation = [self radiansFromMeterZeroForViewPoint: location];
	BOOL isWithinMeterSpan = ( meterRadiansFromZeroForLocation < meterSpan);
	BOOL isWithinMeterRadius = locationPolar.x < [self meterRadius] + 20;
	if(  isWithinMeterSpan && isWithinMeterRadius ) {
		isDialBeingDragged = YES;
		radiansPerTickWhenTouchesBegan = radiansPerTick;
		meterOffsetFromZeroWhenTouchesBegan = meterRadiansFromZeroForLocation;
		numTouchRevolutionsWhileDragging = 0;
		radiansDragged = 0;
		radiansDraggedWhenHitUpperBound = 0;
		radiansDraggedwhenHitLowerBound = 0;
		[self setNeedsDisplay];
	}
	
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if( isDialBeingDragged ) {
		
		// TODO: If new touch point and old touch point span the bottom of the meter:
		//  - If the old touch point is left of the new touch point, we're winding counter-clockwise; subtract from our cyclesSoFar
		//  - If the new touch poitn is right of the old touch point, we're winding clockwise; add to our cyclesSoFar
		
		UITouch *touch = [touches anyObject];
		
		CGPoint location = [touch locationInView:self];
		CGPoint prevLocation = [touch previousLocationInView:self];

		CGPoint locationPolar = [self polarCoordFromViewPoint:location];
		CGPoint prevLocationPolar = [self polarCoordFromViewPoint:prevLocation];

		double radianDelta = prevLocationPolar.y - locationPolar.y;
		if( radianDelta < - M_PI ) {
			// we jumped more than halfway around; assume we crossed 0 going clockwise
			radianDelta += 2 * M_PI;
		}
		else if( radianDelta > M_PI ) {
			// we jumped more than halfway around; assume we crossed 0 going counter-clockwise
			radianDelta -= 2*M_PI;
		}
		
		radiansDragged += radianDelta;

		double ticksToTouchAngleWhenTouchesBegan = meterOffsetFromZeroWhenTouchesBegan / radiansPerTickWhenTouchesBegan;
		double newRadiansPerTick = (meterOffsetFromZeroWhenTouchesBegan + radiansDragged) / ticksToTouchAngleWhenTouchesBegan;
	
		double numTicks = meterSpan / newRadiansPerTick;
		//double numTicks = (meterOffsetFromZeroWhenTouchesBegan + radiansDragged) / radiansPerTick;
		BOOL exceedsUpperBound = numTicks * unitsPerTick > meterUpperBound;
		BOOL exceedsLowerBound = numTicks * unitsPerTick < meterLowerBound;
		
		
		// TODO: Fix so that if dragginb beyond boundaries, we only count one revolution around 
		// (so you don't have to unwind several times before the mete starts dragging again the other direction)
		// nh 10/29/09: I'm having a hard time getting my head around the math here...
		
		//NSLog( @"Num ticks: %f, num units: %f, meterUpperBound: %f", numTicks, numTicks * unitsPerTick, meterUpperBound );
		if( ! exceedsUpperBound && ! exceedsLowerBound ) {
			radiansPerTick = newRadiansPerTick;
			if( radiansDraggedWhenHitUpperBound != 0 || radiansDraggedwhenHitLowerBound != 0 ) {
				//NSLog(@"No longer outside boundaries.");
				radiansDraggedWhenHitUpperBound = 0.0;		// if we previously exceeded the upper bound, we don't anymore
				radiansDraggedwhenHitLowerBound = 0.0;
			}
		}
		else {
			//NSLog(@"Dragging outside boundaries. Exceeds upper? %i Exceeds lower? %i", exceedsUpperBound, exceedsLowerBound );
			if( exceedsUpperBound ) {
				if( radiansDraggedWhenHitUpperBound == 0.0 ) {
					//NSLog( @"Meter upper bound reached!" );
					radiansDraggedWhenHitUpperBound = radiansDragged;
				}
				
			}
			else if( exceedsLowerBound ) {
				if( radiansDraggedwhenHitLowerBound == 0.0 ) {
					//NSLog( @"Meter lower bound reached!" );
					radiansDraggedwhenHitLowerBound = numTicks * radiansPerTick;
				}
			}
		}

				
		[self setNeedsDisplay];
	}
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	//NSLog( @"touchesEnded" );
	if( isDialBeingDragged ) {
		
		while( radiansPerTick < minRadiansPerTick ) {
			radiansPerTick *= 2.0;
			unitsPerTick *= 2.0;
		}
		
		while( radiansPerTick > maxRadiansPerTick ) {
			radiansPerTick /= 2.0;
			unitsPerTick /= 2.0;
		}
		
		//[[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)meterMax forKey:@"maxMeterValue"];
		
		isDialBeingDragged = NO;
		
		int numAnimationFrames = 10;
		int numWholeTicks = (int) (meterSpan / radiansPerTick);
		double curSpan = numWholeTicks * radiansPerTick;
		resizeGapBeforeAnimation = meterSpan - curSpan;
		
		if( resizeGapBeforeAnimation == 0 ) {
			[self updateTedometerData];
		}
		else {
			isResizeAnimationInProgress = YES;
			animationRadianIncrement = (meterSpan - curSpan) / (double) numWholeTicks / (double) numAnimationFrames;
			
			for( int i=0; i < numAnimationFrames; ++i ) {
				NSTimeInterval scheduledTime = i * 0.3/numAnimationFrames;	// animation within half a second
				[NSTimer scheduledTimerWithTimeInterval:scheduledTime target:self selector:@selector(setNeedsDisplay) userInfo:nil repeats:NO];
			}
			

		}
		
	}
	[self setNeedsDisplay];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)dealloc {
    [super dealloc];
}

- (void) updateTedometerData {
	[[tedometerData curMeter] setRadiansPerTick:radiansPerTick];
	[[tedometerData curMeter] setUnitsPerTick:unitsPerTick];
}



@end
