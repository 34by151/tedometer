//
//  MeterView.m
//  Ted5000
//
//  Created by Nathan on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <math.h>
#import "DialView.h"
#import "MeterViewSizing.h"
#import "geometry_utils.h"
#import "UITouch+TouchSorting.h"
#import "log.h"

#define kMinimumPinchDelta 10

#define kMeterBottomAngle (M_PI*3.0/2.0)
//#define DRAW_FOR_PEAK_POINTER_SCREENSHOT
//#define DRAW_FOR_AVG_POINTER_SCREENSHOT
//#define DRAW_FOR_LOW_POINTER_SCREENSHOT


// struct used to pass parameters needed for drawing
typedef struct __DialDrawingContext {
	CGContextRef context;
	double meterRadius;
	double edgeWidth;
	double tickLength;
	int numWholeTicks;
} DialDrawingContext;


// Hidden methods
@interface DialView ()
-(void) drawDangerArc:(DialDrawingContext*) dialContext;
-(void) drawTicks:(DialDrawingContext*) dialContext;
-(void) drawTickNumber:(NSInteger)tickNumber dialContext:(DialDrawingContext*) dialContext;
-(void) drawLabelForTickNumber:(NSInteger)tickNumber withFont:(UIFont*)font dialContext:(DialDrawingContext*) dialContext;
-(void) drawPeakAvgLowPointers:(DialDrawingContext*) dialContext;
-(void) drawPointerInContext:(CGContextRef) context atAngle:(double)angle radius:(double)radius width:(double)width length:(double)length;
-(void) drawArrow:(DialDrawingContext*) dialContext;
-(void) drawLimitReachedGlow: (DialDrawingContext*) dialContext;
-(void) drawEditModeGlow:(DialDrawingContext*) dialContext;
-(double) meterRadius;
-(CGPoint) polarCoordFromViewPoint:(CGPoint)point;
-(double) radiansFromMeterStartAngleToViewPoint:(CGPoint)point;
-(double) radiansFromMeterBottomAngleToViewPoint:(CGPoint)point;
-(void) playLimitReachedSound; 
-(void) didReachStretchLimit:(NSNotification*) notification;
-(void) loadSystemSound:(NSString*)soundFilename soundId:(SystemSoundID*)soundId;
-(void) changeStateToTouched;
-(void) changeStateToEditMode;
-(void) changeStateToDefault;

@end


@implementation DialView

static UIColor *labelColor;
static UIFont *labelFont;

@synthesize stopDialEditButton;
@synthesize parentDialView;
@synthesize parentDialShadowView;
@synthesize parentDialShadowThinView;
@synthesize parentDialHaloView;
@synthesize parentGlareView;
@synthesize parentDimmerView;

#pragma mark -
#pragma mark Public methods

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		/*
		meterValue = 25;
		unitsPerTick = 10;
		radiansPerTick = meterSpan / 10;
		*/
    }
    return self;
}

- (void)awakeFromNib {

	if( ! labelColor )
		labelColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4] retain];
	
	if( ! labelFont )
		labelFont = [[UIFont fontWithName:@"Helvetica" size:10.0] retain];

#if DRAW_FOR_ICON_SCREENSHOT
	drawForIconScreenshot = YES;
#else
	drawForIconScreenshot = NO;
#endif
	
	tedometerData = [TedometerData sharedTedometerData];
	dial = [[Dial alloc] initWithMeter:self.curMeter];
	
	isBeingTouchedBeforeEditMode = NO;
	isBeingPinched = NO;
	
	[self setMultipleTouchEnabled: YES];

	// Loads sounds
	[self loadSystemSound:@"metallic_blip.caf" soundId:&limitReachedSoundId];
	[self loadSystemSound:@"push_in.caf" soundId:&pushInSoundId];
	//[self loadSystemSound:@"push_out.caf" soundId:&pushOutSoundId];
	//[self loadSystemSound:@"click.caf" soundId:&clickSoundId];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReachStretchLimit:) name:kNotificationDidReachStretchLimit object:dial];
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//}

- (void) loadSystemSound:(NSString*)soundFilename soundId:(SystemSoundID*)soundId;
{
	NSString *path = [NSString stringWithFormat:@"%@/%@",
					  [[NSBundle mainBundle] resourcePath],
					  soundFilename];
	NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
	AudioServicesCreateSystemSoundID((CFURLRef)filePath, soundId);
}

- (void) setCurMeter:(Meter*)aMeter {
	
	// This method is invoked by MeterViewController when the meter type
	// changes
	
	if( curMeter != aMeter ) {
		[curMeter release];
		curMeter = [aMeter retain];
		
		dial.curMeter = curMeter;
	}
	curMeter = aMeter;
}

-(Meter*) curMeter {
	return curMeter;
}


- (double) meterRadius {
	return MIN(self.bounds.size.height, self.bounds.size.width)/2.0;
}


- (void)drawRect:(CGRect)rect {
	
	//NSAutoreleasePool *autoReleasePool = [[NSAutoreleasePool alloc] init];
	
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGRect drect = self.bounds;
	
	// put origin at center with y increasing upwards
	CGContextTranslateCTM( context, drect.size.width/2, drect.size.height/2);
	CGContextScaleCTM( context, 1.0, -1.0 );


	DialDrawingContext dialContext;
	dialContext.context = context;
	dialContext.meterRadius = [self meterRadius];
	dialContext.edgeWidth = 28;
	dialContext.tickLength = 15;

	
	[self drawDangerArc:&dialContext];

#if ! DRAW_FOR_LAUNCH_IMAGE
	[self drawTicks:&dialContext];
#endif

	if( ! drawForIconScreenshot ) {
		[self drawPeakAvgLowPointers:&dialContext];
	}

	[self drawArrow:&dialContext];
	
	//if( isEditMode || isBeingTouchedBeforeEditMode )
	//	[self drawEditModeGlow:&dialContext];
	
	
	if( isEditMode && dial.isAtStretchLimit )
		[self drawLimitReachedGlow:&dialContext];

	//[autoReleasePool drain];
}



- (void) showHelpMessage {
	NSString *helpMsg = @"Drag the dial to adjust the origin. Pinch and stretch to adjust the scale.";
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:helpMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

-(void) startDialEdit {
	[self changeStateToEditMode];
}

-(void) stopDialEdit {
	[self changeStateToDefault];
}

- (void)dealloc {
	[curMeter release];
	[dial release];
    [super dealloc];
}

#pragma mark -
#pragma mark Touch handling


-(double)radiansBetweenTouch:(UITouch*)first andTouch:(UITouch*)second {
	double radiansToFirst = [self radiansFromMeterStartAngleToViewPoint:[first locationInView:self]];
	double radiansToSecond = [self radiansFromMeterStartAngleToViewPoint:[second locationInView:self]];
	return ABS(radiansToSecond - radiansToFirst);
}

-(double)radiansToCenterBetweenTouch:(UITouch*)first andTouch:(UITouch*)second {
	double radiansToFirst = [self radiansFromMeterStartAngleToViewPoint:[first locationInView:self]];
	double radiansToSecond = [self radiansFromMeterStartAngleToViewPoint:[second locationInView:self]];
	
	return (radiansToFirst + radiansToSecond / 2.0);
}


- (BOOL) isMultipleTouchEnabled {
	return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	//DLog(@"touches count = %d", [touches count]);

	// if not yet in edit mode, make sure touches are inside meter
	// (we don't require them to be in the meter if we're in edit mode
	// so that there is more surface area for pinching/stretching)
	BOOL isTouchInsideMeter = NO;
	
	if( ! isEditMode ) {
		for( UITouch *aTouch in touches ) {
			CGPoint polarLocation = [self polarCoordFromViewPoint:[aTouch locationInView:self]];
			if( polarLocation.x <= [self meterRadius] ) {
				isTouchInsideMeter = YES;
				break;
			}
		}
	}
	
	if( isEditMode || isTouchInsideMeter ) {
		
		touchesBeganDate = [[NSDate date] retain];

		initialDistanceBetweenTouches = 0;
		lastOffsetDragClickAngle = 0;

		if( ! isEditMode ) {
			[self changeStateToTouched];
			[self performSelector:@selector(startDialEdit) withObject:nil afterDelay:0.65];
		}
		else {
			dial.isBeingTouched = YES;
		}
	}
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

	//DLog(@"touches count = %d", [touches count]);

	if( isEditMode ) {
		if( [touches count] > 1 ) {
			
			isBeingPinched = YES;
			
			NSArray *sortedTouches = [[touches allObjects] sortedArrayUsingSelector:@selector(compareAddress:)];
			UITouch *first = [sortedTouches objectAtIndex:0];
			UITouch *second = [sortedTouches objectAtIndex:1];

			double distanceBetweenTouches = distanceBetweenPoints( [first locationInView:self], [second locationInView:self] );

			if( initialDistanceBetweenTouches == 0 )
				initialDistanceBetweenTouches = distanceBetweenTouches;
			
			double numTicks = meterSpan / dial.baseRadiansPerTick;
			
			double deltaDistance = distanceBetweenTouches - initialDistanceBetweenTouches;
			double deltaRadiansPerTickForFullStretch = M_PI / numTicks;		// full stretch increases total of all tick angle increases to half circle
			
			double deltaRadians = deltaDistance / (1.0 * [self meterRadius]) * deltaRadiansPerTickForFullStretch;
			dial.deltaRadiansPerTick = deltaRadians;
			
			
			// Move zeroAngle so that stretching pivots about top of dial
			
			//DLog(@"UnitsPerTick: %f", dial.unitsPerTick );
			double radiansFromTopToZeroAtTouchesBegan = meterSpan / 2.0 - dial.baseZeroAngle;
			double unitsPerRadianAtTouchesBegan = dial.unitsPerTick / dial.baseRadiansPerTick;
			
			double unitsFromTopToZeroAtTouchesBegan = radiansFromTopToZeroAtTouchesBegan * unitsPerRadianAtTouchesBegan;
			//DLog(@"unitsFromTopToZeroAtTouchesBegan = %f", unitsFromTopToZeroAtTouchesBegan);
			double radiansPerUnitNow = (dial.baseRadiansPerTick + dial.deltaRadiansPerTick) / dial.unitsPerTick;
			double radiansFromTopToZeroNow = unitsFromTopToZeroAtTouchesBegan * radiansPerUnitNow;
			
			//DLog(@"delta radiansFromTopToZero = %f", radiansFromTopToZeroAtTouchesBegan - radiansFromTopToZeroNow);
			double newZeroOffset = radiansFromTopToZeroAtTouchesBegan - radiansFromTopToZeroNow;
			dial.deltaZeroAngle = newZeroOffset;
			
			[self setNeedsDisplay];
			
		}
		else {
			
			if( ! isBeingPinched ) {
				
				// Once we begin pinching, don't allow rotation
				// again until touches have ended. Otherwise,
				// the dial bounces around too much while you're trying to pinch/stretch.
					
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
				
				dial.deltaZeroAngle += radianDelta;
				
				if( ABS( dial.deltaZeroAngle - lastOffsetDragClickAngle) > 10/180.0 * M_PI ) {
					// When played on iPhone, timing of sound is uneven; disabled for now
					//AudioServicesPlaySystemSound(clickSoundId);
					lastOffsetDragClickAngle = dial.deltaZeroAngle;
				}
				
				
				[self setNeedsDisplay];
			}
		}
	}
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	//DLog(@"touches count = %d", [touches count]);

	[touchesBeganDate release];
	touchesBeganDate = nil;
	isBeingPinched = NO;

	initialDistanceBetweenTouches = 0;

	isBeingTouchedBeforeEditMode = NO;
	
	if( ! isEditMode ) {
		
		[self changeStateToDefault];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startDialEdit) object:nil];
	}

	
	dial.isBeingTouched = NO;
	

	//NSLog( @"touchesEnded" );
	
	[dial updateBaseValues];
	[self setNeedsDisplay];

}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

# pragma mark -
# pragma mark Hidden methods


# pragma mark -
# pragma mark State change methods
-(void) changeStateToTouched {
	parentDialShadowView.hidden = YES;
	parentDialShadowThinView.hidden = NO;
	//parentGlareView.transform = CGAffineTransformMakeScale(0.99, 0.99);
	parentGlareView.alpha = 0.3;

	parentDialHaloView.hidden = NO;
	parentDialHaloView.alpha = 0;
	
	isBeingTouchedBeforeEditMode = YES;
	parentDialView.transform = CGAffineTransformMakeScale(0.99, 0.99);

	[self setNeedsDisplay];
}

-(void) changeStateToEditMode {
	parentDialShadowView.hidden = YES;
	parentDialShadowThinView.hidden = YES;
	stopDialEditButton.hidden = NO;
	stopDialEditButton.alpha = 0;
	
	parentDialHaloView.transform = CGAffineTransformMakeScale(0.99,0.99);
	parentDialHaloView.alpha = 1.0;
	parentDimmerView.alpha = 0.25;
	parentDimmerView.transform = CGAffineTransformMakeScale(1.01, 1.01);

	float scale;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.15];
	scale = 0.94;
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	parentDialView.transform = CGAffineTransformMakeScale(scale, scale);
	//parentGlareView.transform = CGAffineTransformMakeScale(scale, scale);
	parentGlareView.alpha = 0.2;
	stopDialEditButton.alpha = 1.0;
	[UIView commitAnimations];

	// do a little pop back out animation, to give the effect of locking in
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.15];
	scale = 0.945;
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	parentDialView.transform = CGAffineTransformMakeScale(scale, scale);
	//parentGlareView.transform = CGAffineTransformMakeScale(scale, scale);
	[UIView commitAnimations];
	
	AudioServicesPlaySystemSound(pushInSoundId);

	tedometerData.isDialBeingEdited = YES;
	isEditMode = YES;
	
	initialDistanceBetweenTouches = 0;
	isBeingTouchedBeforeEditMode = NO;
	
	//parentDialView.transform = CGAffineTransformMakeScale(0.99, 0.99);
	
	if( ! tedometerData.hasDisplayedDialEditHelpMessage ) {
		tedometerData.hasDisplayedDialEditHelpMessage = YES;
		[self performSelector:@selector(showHelpMessage) withObject:self afterDelay:0.1];
	}
	
	[self setNeedsDisplay];
}

-(void) changeStateToDefault {
	parentDialShadowView.hidden = NO;
	parentDialShadowThinView.hidden = YES;
	stopDialEditButton.hidden = YES;
	parentDimmerView.alpha = 0;


	float scale;
	// pop out then back in
	if( ! isEditMode ) {
		scale = 1.0;
		parentDialHaloView.alpha = 0;
		parentGlareView.alpha = 0.39;
		//parentGlareView.transform = CGAffineTransformMakeScale(scale,scale);
		parentDialView.transform = CGAffineTransformMakeScale(scale,scale);
		
	}
	else {
		AudioServicesPlaySystemSound(pushInSoundId);
		scale = 0.92;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration: 0.35];
		[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
		//parentGlareView.transform = CGAffineTransformMakeScale(scale,scale);
		parentDialView.transform = CGAffineTransformMakeScale(scale,scale);
		parentDialHaloView.alpha = 0;
		[UIView commitAnimations];
		
		scale = 1.035;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration: 0.35];
		[UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
		//parentGlareView.transform = CGAffineTransformMakeScale(scale,scale);
		parentDialView.transform = CGAffineTransformMakeScale(scale,scale);
		[UIView commitAnimations];
		
		scale = 1.0;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration: 0.2];
		[UIView setAnimationCurve: UIViewAnimationCurveEaseOut];
		//parentGlareView.transform = CGAffineTransformMakeScale(scale,scale);
		parentDialView.transform = CGAffineTransformMakeScale(scale,scale);
		parentGlareView.alpha = 0.39;
		[UIView commitAnimations];
	}
	
	isEditMode = NO;
	tedometerData.isDialBeingEdited = NO;
	
	[self setNeedsDisplay];
}

# pragma mark -
# pragma mark Dial drawing methods

/**
 * Returns clockwise radians from bottom of meter
 */

- (double) radiansFromMeterBottomAngleToViewPoint:(CGPoint)point {
	CGPoint p = [self polarCoordFromViewPoint: point];
	
	double radians;
	if( p.y <= kMeterBottomAngle )
		radians = kMeterBottomAngle - p.y;
	else 
		radians = kMeterBottomAngle + (2*M_PI - p.y);
	
	return radians;
	
}

/**
 * Returns clockwise radians from meter zero to point
 */

- (double) radiansFromMeterStartAngleToViewPoint:(CGPoint)point {
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



-(void) drawArrow:(DialDrawingContext*) dialContext {
	float dialAngle;
	if( drawForIconScreenshot ) {
		dialAngle = radOffset; //M_PI / 2;
		
//#if	DRAW_FOR_LAUNCH_IMAGE
//		dialAngle = radOffset;
//#endif
		
	}
	else
		dialAngle = [dial dialAngle];
	
	
	CGContextSaveGState(dialContext->context);
	CGContextRotateCTM(dialContext->context, dialAngle);
	
	CGContextSetRGBStrokeColor(dialContext->context, 1.0, 0.2, 0.2, 1.0);
    
    CGContextSetShadowWithColor( dialContext->context, CGSizeMake( 0, 2.5 ), 3, [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3].CGColor );
//	CGContextSetShadow( dialContext->context, CGSizeMake( 0, 3.5 ), 2 );
	
	float centerOffset = -27.0;
	float largeEndWidth = 2;
	
	double arrowLength = 0.79 * dialContext->meterRadius;
	
	CGContextSetLineCap( dialContext->context, kCGLineCapRound );
	CGContextSetLineWidth(dialContext->context, 3.0);
	CGContextMoveToPoint( dialContext->context, centerOffset, largeEndWidth / 2.0 );
	CGContextAddLineToPoint( dialContext->context, arrowLength, 0 );
	CGContextMoveToPoint( dialContext->context, centerOffset, -largeEndWidth / 2.0 );
	CGContextAddLineToPoint( dialContext->context, arrowLength, 0 );
	CGContextMoveToPoint( dialContext->context, centerOffset, largeEndWidth / 2.0 );
	CGContextAddLineToPoint( dialContext->context, centerOffset, -largeEndWidth / 2.0 );
	CGContextStrokePath(dialContext->context);
	
	CGContextRestoreGState(dialContext->context);
}

-(void) drawPeakAvgLowPointers:(DialDrawingContext*) dialContext {
	
	double pointerWidth = 10.0;
	double pointerProtrusionLength = dialContext->tickLength * 0.2;
	double pointerProtrusionBeyondTicks = 4;
	double pointerLength = dialContext->tickLength + pointerProtrusionLength + pointerProtrusionBeyondTicks;
	double pointerRadius = dialContext->meterRadius - dialContext->edgeWidth + pointerProtrusionBeyondTicks;
	
	double peakValue = tedometerData.isShowingTodayStatistics ? self.curMeter.todayPeakValue : self.curMeter.mtdPeakValue;
	double avgValue = tedometerData.isShowingTodayStatistics ? self.curMeter.todayAverage : self.curMeter.monthAverage;
	double lowValue = tedometerData.isShowingTodayStatistics ? self.curMeter.todayMinValue : self.curMeter.mtdMinValue;
	double peakAngle = 0;
	double avgAngle = 0;
	double lowAngle = 0;
	double overlapOffset = (0.5 * M_PI / 180.0);	// if values overlap, displace them by half a degree 
	
	if( [dial isValueVisible:peakValue] ) {
		peakAngle = [dial angleForValue:peakValue];
		CGContextSetRGBFillColor( dialContext->context, 0.98, 0.62, 0.23, 1.0 );	// orange
#ifdef DRAW_FOR_PEAK_POINTER_SCREENSHOT
		double radius = pointerRadius + pointerLength + dialContext->edgeWidth + 1;
		[self drawPointerInContext:dialContext->context atAngle: - M_PI /4 radius:radius width:pointerWidth length:pointerLength];
#else
		[self drawPointerInContext:dialContext->context atAngle:peakAngle radius:pointerRadius width:pointerWidth length:pointerLength];
#endif
	}
	
	if( [dial isValueVisible:lowValue] ) {
		lowAngle = [dial angleForValue:lowValue];
		if( peakValue > 0 && ABS(peakAngle - lowAngle) < 2.0 * overlapOffset )
			lowAngle += 2.0 * overlapOffset;
		CGContextSetRGBFillColor( dialContext->context, 0.5, 0.65, 0.996, 1.0 );	// blue
		//CGContextSetRGBFillColor(context, 0.3, 0.3, 1.0, 1.0);	// blue
#ifdef DRAW_FOR_LOW_POINTER_SCREENSHOT
		double radius = pointerRadius + pointerLength + dialContext->edgeWidth + 1;
		[self drawPointerInContext:dialContext->context atAngle: - M_PI /4 radius:radius width:pointerWidth length:pointerLength];
#else
		[self drawPointerInContext:dialContext->context atAngle: lowAngle radius:pointerRadius width:pointerWidth length:pointerLength];
#endif
		
	}
	
	if( [self.curMeter isAverageSupported] && [dial isValueVisible:avgValue] ) {
		avgAngle = [dial angleForValue:avgValue];
		if( peakValue > 0 && ABS(peakAngle - avgAngle) < overlapOffset )
			avgAngle = peakAngle + overlapOffset;
		if( lowValue > 0 && ABS(avgAngle - lowAngle) < overlapOffset )
			avgAngle = lowAngle - overlapOffset;
		
		CGContextSetRGBFillColor( dialContext->context, 0.60, 0.77, 0.19, 1.0 );	// green
		//CGContextSetRGBFillColor( context, 0.635, 0.824, 0.204, 1.0 );	// green (matches text, but seems too light against the dial background)
		
#ifdef DRAW_FOR_AVG_POINTER_SCREENSHOT
		double radius = pointerRadius + pointerLength + edgeWidth + 1;
		[self drawPointerInContext:dialContext->context atAngle: - M_PI /4 radius:radius width:pointerWidth length:pointerLength];
#else
		[self drawPointerInContext:dialContext->context atAngle:avgAngle radius:pointerRadius width:pointerWidth length:pointerLength];
#endif
	}
}


- (void) drawPointerInContext:(CGContextRef) context atAngle:(double)angle radius:(double)radius width:(double)width length:(double)length {
	
	CGContextSaveGState(context);
	
	CGContextRotateCTM(context, angle);
	
	CGContextSetShadow( context, CGSizeMake( 0, 1 ), 1 );
	CGContextSetLineWidth( context, 0 );
	CGContextMoveToPoint( context, radius, width / 2.0 );
	CGContextAddLineToPoint( context, radius - width / 2.0, 0 );
	CGContextAddLineToPoint( context, radius, - width / 2.0 );
	
	CGContextAddLineToPoint( context, radius - length, 0 );
	CGContextClosePath( context );
	CGContextFillPath( context );
	
	CGContextRestoreGState( context );
}


-(void) drawLabelForTickNumber:(NSInteger)tickNumber withFont:(UIFont*)font dialContext:(DialDrawingContext*) dialContext {
	
	if( dial.radiansPerTick == 0 )
		return;
	
	
	CGContextSaveGState(dialContext->context);
	CGContextScaleCTM(dialContext->context, 1.0, -1.0);
	
	double labelGap = 8;

	double curRad = dial.zeroAngle + tickNumber * dial.normalizedRadiansPerTick;
	double labelValue = tickNumber * dial.normalizedUnitsPerTick;
	NSString *label = [self.curMeter tickLabelStringForInteger: labelValue];
    CGSize labelSize = [label sizeWithAttributes: @{NSFontAttributeName:font}];
	double angle = radOffset - curRad;
	double labelCenterRadius = (dialContext->meterRadius - dialContext->edgeWidth - dialContext->tickLength - labelGap);
	labelCenterRadius -= distanceFromCenterToEdgeOfRectAtAngle( labelSize, angle );
	double x1 = labelCenterRadius * cos( angle ) - labelSize.width / 2.0;
	double y1 = labelCenterRadius * sin( angle ) + labelSize.height / 2.0;
	[label drawAtPoint:CGPointMake(x1,-y1) withAttributes:@{
                                                            NSFontAttributeName:font,
                                                            NSStrokeColorAttributeName: labelColor,
                                                            NSForegroundColorAttributeName: labelColor
                                                            }];
	
	//NSLog(@"DialView.drawTickLabels: drawing label %@ for tick %d", label, tickNumber);
	
	CGContextStrokePath(dialContext->context);
	CGContextRestoreGState(dialContext->context);
	
}

-(void) drawTicks:(DialDrawingContext*) dialContext {
	
	if( dial.normalizedRadiansPerTick == 0 )
		return;
	
	UIFont *font = labelFont; //[UIFont fontWithName:@"Helvetica" size:10.0];
	UIColor *textColor = labelColor; //[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
	[textColor set];

	CGContextSetRGBStrokeColor(dialContext->context, 0.35, 0.35, 0.35, 1.0);
	CGContextSetLineWidth(dialContext->context, 1.0);
	
	
	// start at 0; draw ticks both directions until we get to end points
	
	NSInteger curTick = 0;
	double curRad = dial.zeroAngle;
	while( curRad >= 0 ) {
		if( curRad < meterSpan ) {
			[self drawTickNumber:curTick dialContext:dialContext];
			[self drawLabelForTickNumber:curTick withFont:font dialContext:dialContext];
		}
		
		--curTick;
		curRad -= dial.normalizedRadiansPerTick;
	}
	//CGContextStrokePath(dialContext->context);
	//CGContextSetRGBStrokeColor(dialContext->context, 1.0, 0.35, 0.35, 1.0);
	curRad = dial.zeroAngle + dial.normalizedRadiansPerTick;
	curTick = 1;
	while( curRad <= meterSpan ) {
		if( curRad > 0 ) {
			[self drawTickNumber:curTick dialContext:dialContext];
			[self drawLabelForTickNumber:curTick withFont:font dialContext:dialContext];
		}
		curRad += dial.normalizedRadiansPerTick;
		++curTick;
	}
	CGContextStrokePath(dialContext->context);
	
	if( NO && isBeingPinched ) {
		// Draw zero offset
		CGPoint edgePoint = polarToCartesian( CGPointMake( [self meterRadius], radOffset - dial.zeroAngle ) );
		
		CGContextSetRGBStrokeColor(dialContext->context, 0.9, 0.1, 0.1, 1.0 );
		CGContextSetLineWidth(dialContext->context, 2.0);
		CGContextMoveToPoint( dialContext->context, 0, 0 );
		CGContextAddLineToPoint( dialContext->context, edgePoint.x, edgePoint.y );
		CGContextStrokePath( dialContext->context );
		
		// Draw zero offset base
		edgePoint = polarToCartesian( CGPointMake( [self meterRadius], radOffset - dial.baseZeroAngle ) );
		
		CGContextSetRGBStrokeColor(dialContext->context, 0.1, 0.9, 0.1, 1.0 );
		CGContextSetLineWidth(dialContext->context, 2.0);
		CGContextMoveToPoint( dialContext->context, 0, 0 );
		CGContextAddLineToPoint( dialContext->context, edgePoint.x, edgePoint.y );
		CGContextStrokePath( dialContext->context );
/*
		// Draw zero offset base + delta
		edgePoint = polarToCartesian( CGPointMake( [self meterRadius], radOffset - (dial.baseZeroAngle + dial.deltaZeroAngle) ) );
		
		CGContextSetRGBStrokeColor(dialContext->context, 0.1, 0.1, 0.9, 1.0 );
		CGContextSetLineWidth(dialContext->context, 2.0);
		CGContextMoveToPoint( dialContext->context, 0, 0 );
		CGContextAddLineToPoint( dialContext->context, edgePoint.x, edgePoint.y );
		CGContextStrokePath( dialContext->context );
*/		
	}
	
	
}

-(void) drawTickNumber:(NSInteger)tickNumber dialContext:(DialDrawingContext*) dialContext {
	
	double angleFromStart = dial.zeroAngle + (tickNumber * dial.normalizedRadiansPerTick);
	//NSLog( @"Drawing tick at angle %f", radiansToDegrees( angleFromStart ) );
		   
	double meterRadius = dialContext->meterRadius;
	double edgeWidth = dialContext->edgeWidth;
	double tickLength = dialContext->tickLength;
	
	double angle = radOffset - angleFromStart;
	double x1 = (meterRadius - edgeWidth) * cos( angle );
	double y1 = (meterRadius - edgeWidth) * sin( angle );
	double x2 = (meterRadius - edgeWidth - tickLength) * cos( angle );
	double y2 = (meterRadius - edgeWidth - tickLength) * sin( angle );
	CGContextMoveToPoint( dialContext->context, x1, y1 );
	CGContextAddLineToPoint( dialContext->context, x2, y2 );
}

-(void) drawDangerArc:(DialDrawingContext*) dialContext {
	// danger arc
	double arcRadians = meterSpan * 6/7.0;
	double arcStartRadian = radOffset - meterSpan + arcRadians;
	double arcEndRadian = radOffset - meterSpan;
	double arcStartThickness = 1;
	double arcEndThickness = dialContext->tickLength;
	double arcAlphaStartVal = 0.0;
	double arcAlphaEndVal = 0.9;
	
	double numArcPieces = 100; //arcRadians * (meterRadius - edgeWidth);
	
	double alphaMultiplier = 1.0;
	double alphaMultiplierDuringDrag = 0.3;
	if( isEditMode )
		alphaMultiplier = alphaMultiplierDuringDrag;
	
	if( dial.isAnimating ) {
		double gapRadians = meterSpan - (dial.normalizedRadiansPerTick * dial.numTicks);
		alphaMultiplier = 1.0 - (1.0 - alphaMultiplierDuringDrag) * gapRadians / resizeGapBeforeAnimation;
		//NSLog(@"animationAlphaFactor = %f, gapRadians = %f", alphaMultiplier, gapRadians);
	}
	
	for( int arcPiece = 0; arcPiece < numArcPieces; ++arcPiece ) {
		double arcPieceStartRadian = arcStartRadian + arcPiece * (arcEndRadian - arcStartRadian) / numArcPieces;
		double arcPieceEndRadian = arcStartRadian + (arcPiece+1) * (arcEndRadian - arcStartRadian) / numArcPieces; 
		double alphaVal = arcAlphaStartVal + arcPiece * (arcAlphaEndVal - arcAlphaStartVal) / numArcPieces;
		alphaVal *= alphaMultiplier;
		
		double lineWidth = arcStartThickness + arcPiece * (arcEndThickness - arcStartThickness ) / numArcPieces;
		CGContextSetRGBStrokeColor(dialContext->context, 0.9, 0.1, 0.1, alphaVal);
		CGContextSetLineWidth(dialContext->context, lineWidth);
		CGContextAddArc( dialContext->context, 0, 0, dialContext->meterRadius - dialContext->edgeWidth - lineWidth / 2, arcPieceStartRadian, arcPieceEndRadian, 1 ); 
		CGContextStrokePath( dialContext->context );
	}
	
}

-(void) drawLimitReachedGlow: (DialDrawingContext*) dialContext;
{
	
	CGContextSetRGBStrokeColor(dialContext->context, 0.9, 0.1, 0.1, 1.0);
	CGContextSetLineWidth(dialContext->context, 1.0);
	CGContextSetShadowWithColor( dialContext->context, CGSizeMake( 0, 0 ), 10.0, [UIColor colorWithRed:0.9 green:0.1 blue:0.1 alpha:1.0].CGColor );
	//CGContextAddArc( dialContext->context, 0, 0, dialContext->meterRadius - 10, 0.0, 2*M_PI, 0 ); 
	CGFloat glowRadius = dialContext->meterRadius - 9.0;
	
	CGContextAddEllipseInRect( dialContext->context, CGRectMake( -glowRadius, -glowRadius, glowRadius * 2, glowRadius*2 ) );
	
	CGContextStrokePath( dialContext->context );
}

-(void) drawEditModeGlow:(DialDrawingContext*) dialContext {
	
	CGContextSetRGBStrokeColor(dialContext->context, 1.0, 1.0, 1.0, isBeingTouchedBeforeEditMode ? 0.0 : 1.0);
	CGContextSetLineWidth(dialContext->context, isBeingTouchedBeforeEditMode ? 1.5 : 2.0);
	CGContextSetShadowWithColor( dialContext->context, CGSizeMake( 0, 0 ), 10.0, [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0].CGColor );
	//CGContextAddArc( dialContext->context, 0, 0, dialContext->meterRadius - 10, 0.0, 2*M_PI, 0 ); 
	CGFloat glowRadius = dialContext->meterRadius - 9.0;
	
	CGContextAddEllipseInRect( dialContext->context, CGRectMake( -glowRadius, -glowRadius, glowRadius * 2, glowRadius*2 ) );

	CGContextStrokePath( dialContext->context );
}

#pragma mark -
#pragma mark Sounds

-(void) playLimitReachedSound; 
{
	AudioServicesPlaySystemSound(limitReachedSoundId);
	
}

-(void) didReachStretchLimit:(NSNotification*) notification;
{
	[self playLimitReachedSound];
}

@end
