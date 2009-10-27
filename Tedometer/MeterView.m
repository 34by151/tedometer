//
//  MeterView.m
//  Ted5000
//
//  Created by Nathan on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MeterView.h"
#import "Tedometer.h"
#import <math.h>

@implementation MeterView

@synthesize meterValue;
@synthesize meterUpperBound;


#define USE_SMOOTH_CAUTION_ARC

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

	tedometerData = [TedometerData sharedTedometerData];

	meterValue = 0;
	
	meterUpperBound = [[tedometerData curMeter] meterMaxValue];
	meterLowerBound = 10;
	unitsPerTick = [[tedometerData curMeter] unitsPerTick];
	radiansPerTick = [[tedometerData curMeter] radiansPerTick];
	isDialBeingDragged = NO;
	isResizeAnimationInProgress = NO;
	
	if( radiansPerTick == 0 )
		radiansPerTick = M_PI / 10.0;
	if( unitsPerTick == 0 )
		unitsPerTick = 10;

	[tedometerData addObserver:self forKeyPath:@"curMeterIdx" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	unitsPerTick = [[tedometerData curMeter] unitsPerTick];
	radiansPerTick = [[tedometerData curMeter] radiansPerTick];
	
	if( radiansPerTick == 0 )
		radiansPerTick = M_PI / 10.0;
	if( unitsPerTick == 0 )
		unitsPerTick = 10;
	
}
- (double) dialLength {
	return [self meterRadius] - 35;
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

#ifndef USE_SMOOTH_CAUTION_ARC
	
	if( ! isDialBeingDragged ) {
		
		int numArcTicksWhenTouchesBegan = meterSpan / radiansPerTickWhenTouchesBegan;

		// draw danger arc
		
		double arcWidth = tickLength * 2 / 3.0;
		CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, isDialBeingDragged ? 0.4 : 0.8);
		CGContextSetLineWidth(context, arcWidth);
		double dangerEndAngle = radOffset - numArcTicksWhenTouchesBegan * radiansPerTickWhenTouchesBegan;
		double dangerStartAngle = dangerEndAngle + floor(numArcTicksWhenTouchesBegan / 3.0)* radiansPerTickWhenTouchesBegan;
		CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - arcWidth / 2, dangerStartAngle, dangerEndAngle, 1 ); 
		CGContextStrokePath( context );
		
		// draw warning arc
		arcWidth /= 2.0;
		CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, isDialBeingDragged ? 0.3 : 0.6);
		CGContextSetLineWidth(context, arcWidth);
		double warningEndAngle = dangerStartAngle;
		double warningStartAngle = warningEndAngle + floor(numArcTicksWhenTouchesBegan / 5.0) * radiansPerTickWhenTouchesBegan;
		CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - arcWidth / 2, warningStartAngle, warningEndAngle, 1 ); 
		CGContextStrokePath( context );
		
		// draw caution arc
		arcWidth /= 2.0;
		CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, isDialBeingDragged ? 0.2 : 0.3);
		CGContextSetLineWidth(context, arcWidth);
		double cautionEndAngle = warningStartAngle;
		double cautionStartAngle = cautionEndAngle + ceil(numArcTicksWhenTouchesBegan / 5.0) * radiansPerTickWhenTouchesBegan;
		CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - arcWidth / 2, cautionStartAngle, cautionEndAngle, 1 ); 
		CGContextStrokePath( context );
		
	}
	
#else
	
	// alternate danger arc style -- smooth curve instead of steps
	
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

#endif

	
	// draw max/min ranges
	double outerArcWidth = 2.0; 
	double innerArcWidth = 3.0;
	
	double startRadius = meterRadius - edgeWidth;
	
	double rangeMax;
	double rangeMin;
	double startAngle;
	double endAngle;
	
	// inner range (today)
	rangeMax = tedometerData.curMeter.todayPeakValue;
	rangeMin = tedometerData.curMeter.todayMinValue;
	CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.6, isDialBeingDragged ? 0.2 : 0.6);
	CGContextSetLineWidth(context, (innerArcWidth + outerArcWidth));		// we double the arc width so that there's no gap between lines
	startAngle = [self angleForValue:rangeMin];
	endAngle = [self angleForValue:rangeMax];
	CGContextAddArc( context, 0, 0, startRadius - (outerArcWidth + innerArcWidth / 2), startAngle, endAngle, 1 ); 
	CGContextStrokePath( context );
	
	// outer range (month)
	rangeMax = tedometerData.curMeter.mtdPeakValue;
	rangeMin = tedometerData.curMeter.mtdMinValue;
	CGContextSetRGBStrokeColor(context, 0.3, 0.3, 0.6, isDialBeingDragged ? 0.2 : 1.0);
	CGContextSetLineWidth(context, outerArcWidth);
	startAngle = [self angleForValue:rangeMin];
	endAngle = [self angleForValue:rangeMax];
	CGContextAddArc( context, 0, 0, startRadius - outerArcWidth / 2, startAngle, endAngle, 1 ); 
	CGContextStrokePath( context );
	
	
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

#ifndef DRAW_FOR_ICON_SCREENSHOT
	
	// draw tick labels
	
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
#endif
	

	

	// draw dial
	float dialAngle;
#ifdef DRAW_FOR_ICON_SCREENSHOT
	dialAngle = M_PI - M_PI/3.0;
#else
	dialAngle = [self dialAngle];
#endif
	
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

- (double) angleForValue:(double)value {
	double angleFromOffset = MAX( 0, MIN( value / unitsPerTick * radiansPerTick, meterSpan ) );
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
		[self setNeedsDisplay];
	}
	
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	if( isDialBeingDragged ) {
		
		UITouch *touch = [touches anyObject];
		
		CGPoint location = [touch locationInView:self];

		double touchAngle = [self radiansFromMeterZeroForViewPoint:location];
		double ticksToTouchAngleWhenTouchesBegan = meterOffsetFromZeroWhenTouchesBegan / radiansPerTickWhenTouchesBegan;
		double newRadiansPerTick = touchAngle / ticksToTouchAngleWhenTouchesBegan;
		
		double numTicks = meterSpan / newRadiansPerTick;
		BOOL exceedsUpperBound = numTicks * unitsPerTick > meterUpperBound;
		BOOL exceedsLowerBound = numTicks * unitsPerTick < meterLowerBound;
		if( ! exceedsUpperBound && ! exceedsLowerBound ) {
			radiansPerTick = newRadiansPerTick;
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
