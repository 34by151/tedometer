//
//  MeterView.m
//  Ted5000
//
//  Created by Nathan on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MeterView.h"
#import <math.h>

@implementation MeterView

@synthesize meterValue;
@synthesize meterMax;

#define meterGap (M_PI * 2/3)
#define radOffset (M_PI + (M_PI - meterGap)/2.0)
#define meterSpan (2*M_PI - meterGap)
#define touchThresholdAngle (M_PI / 10)
#define touchThresholdRadius 10

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
	
	double test;
	double testDegrees;
	test = atan( 1 );
	testDegrees = test / M_PI * 180;
	test = atan( 1/2.0 );
	testDegrees = test / M_PI * 180;
	test = atan( 2.0 );
	testDegrees = test / M_PI * 180;
	
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
		meterMin = 0;
		meterMax = 100;
    }
    return self;
}

- (void)awakeFromNib {
	meterValue = 0;
	meterMin = 0;
	meterMax = 100;
	isDialBeingDragged = NO;
}

- (float) dialLength {
	return self.bounds.size.width/2.0 - 35;
}

- (void)drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGRect drect = self.bounds;
	
	// put origin at center with y increasing upwards
	CGContextTranslateCTM( context, drect.size.width/2, drect.size.height/2);
	CGContextScaleCTM( context, 1.0, -1.0 );

	float meterRadius = drect.size.width/2.0;
	float dialLength = [self dialLength];
	float edgeWidth = 18;
	float tickLength = 15;
	
	int numTicks = 10;
	float radPerTick = meterSpan / numTicks;
	
	// draw danger arc
	float arcWidth = tickLength * 2 / 3.0;
	CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, 0.8);
	CGContextSetLineWidth(context, arcWidth);
	float dangerEndAngle = radOffset - numTicks * radPerTick;
	float dangerStartAngle = dangerEndAngle + floor(numTicks / 3.0)* radPerTick;
	CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - arcWidth / 2, dangerStartAngle, dangerEndAngle, 1 ); 
	CGContextStrokePath( context );
	
	// draw warning arc
	arcWidth /= 2.0;
	CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, 0.6);
	CGContextSetLineWidth(context, arcWidth);
	float warningEndAngle = dangerStartAngle;
	float warningStartAngle = warningEndAngle + floor(numTicks / 5.0) * radPerTick;
	CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - arcWidth / 2, warningStartAngle, warningEndAngle, 1 ); 
	CGContextStrokePath( context );

	// draw caution arc
	arcWidth /= 2.0;
	CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, 0.3);
	CGContextSetLineWidth(context, arcWidth);
	float cautionEndAngle = warningStartAngle;
	float cautionStartAngle = cautionEndAngle + ceil(numTicks / 5.0) * radPerTick;
	CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - arcWidth / 2, cautionStartAngle, cautionEndAngle, 1 ); 
	CGContextStrokePath( context );
	
	// draw dial ticks
	CGContextSetRGBStrokeColor(context, 0.4, 0.4, 0.4, 1.0);
	CGContextSetLineWidth(context, 1.0);

	for( int curTick = 0; curTick < numTicks + 1; ++curTick ) {
		float angle = radOffset - curTick * radPerTick;
		float x1 = (meterRadius - edgeWidth) * cos( angle );
		float y1 = (meterRadius - edgeWidth) * sin( angle );
		float x2 = (meterRadius - edgeWidth - tickLength) * cos( angle );
		float y2 = (meterRadius - edgeWidth - tickLength) * sin( angle );
		CGContextMoveToPoint( context, x1, y1 );
		CGContextAddLineToPoint( context, x2, y2 );
	}
	CGContextStrokePath(context);
	
	// draw tick labels
	CGContextSaveGState(context);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	float labelGap = 8;
	UIFont *font = [UIFont fontWithName:@"Helvetica" size:10.0];
	UIColor *textColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
	[textColor set];
	
	for( int curTick = 0; curTick < numTicks + 1; ++curTick ) {
		float labelValue = meterMin + (curTick * (meterMax - meterMin) / (float) numTicks);
		NSString *label = [NSString stringWithFormat:@"%0i", (int)labelValue];
		CGSize labelSize = [label sizeWithFont: font];
		float angle = radOffset - curTick * radPerTick;
		float labelCenterRadius = (meterRadius - edgeWidth - tickLength - labelGap);
		labelCenterRadius -= distanceFromCenterToEdgeOfRectAtAngle( labelSize, angle );
		float x1 = labelCenterRadius * cos( angle ) - labelSize.width / 2.0;
		float y1 = labelCenterRadius * sin( angle ) + labelSize.height / 2.0;
		[label drawAtPoint:CGPointMake(x1,-y1) withFont:font];
	}
	CGContextRestoreGState(context);
	
	// draw dial
	float value = meterValue;
	if( value > meterMax )
		value = meterMax;
	
	float dialAngle = radOffset - (value / (float) (meterMax - meterMin)) * meterSpan;
	float x1 = 5 * cos( dialAngle + M_PI );	// make the short end of the dial extend a bit beyond the center
	float y1 = 5 * sin( dialAngle + M_PI );
	float x2 = dialLength * cos( dialAngle );
	float y2 = dialLength * sin( dialAngle );

	CGContextSetRGBStrokeColor(context, 1.0, 0.2, 0.2, 1.0);
	if( isDialBeingDragged ) {
		float glowWidth = 20.0;
		float colorValues[] = { 1.0, 0.2, 0.2, 1.0 };
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGColorRef glowColor = CGColorCreate( colorSpace, colorValues );
		CGContextSetShadowWithColor( context, CGSizeMake( 0, 0 ), glowWidth, glowColor );
	}
	else
		CGContextSetShadow( context, CGSizeMake( 0, -2 ), 2 );
	CGContextSetLineCap( context, kCGLineCapRound );
	CGContextSetLineWidth(context, 10.0);
	CGContextMoveToPoint( context, x1, y1 );
	CGContextAddLineToPoint( context, x2, y2 );
	CGContextStrokePath(context);
	
}


- (CGPoint) polarCoordFromViewPoint:(CGPoint)point {
	CGAffineTransform t = CGAffineTransformMakeTranslation( - self.bounds.size.width/2, self.bounds.size.height/2); 
	t = CGAffineTransformScale( t, 1, -1 );
	
	CGPoint pCart = CGPointApplyAffineTransform( point, t );
	return cartesianToPolar( pCart );
}

- (double) dialAngle {
	double dialAngle = radOffset - (meterValue / (float) (meterMax - meterMin)) * meterSpan;
	return dialAngle;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	CGPoint locationPolar = [self polarCoordFromViewPoint:[touch locationInView:self]];
	/*
	float angleToDial = ABS( [self dialAngle] - locationPolar.y );
	
	BOOL isWithinRadiusThreshold = false;
	float dialLength = [self dialLength];
	if( locationPolar.x < dialLength + touchThresholdRadius && locationPolar.x > 20 )
		isWithinRadiusThreshold = true;
	if( angleToDial <= touchThresholdAngle && locationPolar.x > 20 && isWithinRadiusThreshold ) {	// is within threshold of dial and at least 20 pixels away from  
		isDialBeingDragged = YES;
		[self setNeedsDisplay];
	}
	*/
	
	if( ABS( [self  - locationPolar.x
	
	NSLog( @"touchesBegan isDialBeingDragged = %i", isDialBeingDragged );
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	NSLog( @"touchesMoved isDialBeingDragged = %i", isDialBeingDragged );

	if( isDialBeingDragged ) {
		UITouch *touch = [touches anyObject];
		
		CGPoint prevLocationPolar = [self polarCoordFromViewPoint: [touch previousLocationInView:self]];
		CGPoint locationPolar = [self polarCoordFromViewPoint: [touch locationInView:self]];
		
		double maxValueAngle = meterSpan;
		
		float newMaxValue = meterValue / (radOffset - locationPolar.y) * maxValueAngle;
		meterMax = newMaxValue;
		[self setNeedsDisplay];
		/*
		double angleDelta = (prevLocationPolar.y - locationPolar.y);
		
			
			//double angle = angleBetweenPoints( origin, prevLocation, location );
			double angleInDegrees = 180 * angle / M_PI;
			
			float newMaxValue = meterValue / 
			float newMaxValue = meterMax - (angle / meterSpan * (meterMax - meterMin));
			meterMax = newMaxValue;
			NSLog( @"angleInDegrees = %f, meterMax = %f", angleInDegrees, meterMax );
			[self setNeedsDisplay];
		}
		*/
	}
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog( @"touchesEnded" );
	if( isDialBeingDragged ) {
		[[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)meterMax forKey:@"maxMeterValue"];
	}
	isDialBeingDragged = NO;
	[self setNeedsDisplay];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)dealloc {
    [super dealloc];
}




@end
