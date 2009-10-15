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
}

- (void)drawRect:(CGRect)rect {
	
	CGContextRef context = UIGraphicsGetCurrentContext();

	CGRect drect = self.bounds;
	//CGRect drect = rect;
	
	// put origin at center with y increasing upwards
	CGContextTranslateCTM( context, drect.size.width/2, drect.size.height/2);
	CGContextScaleCTM( context, 1.0, -1.0 );

	float meterRadius = drect.size.width/2.0;
	float dialLength = meterRadius - 35;
	float edgeWidth = 18;
	float ticLength = 20;
	
	float meterGap = M_PI * 2/3;
	float numTics = 10;
	float radPerTic = (2 * M_PI - meterGap) / numTics;
	float radOffset = M_PI + (M_PI - meterGap)/2.0;
	
	// draw danger arc
	float arcWidth = ticLength / 2;
	CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, 0.8);
	CGContextSetLineWidth(context, arcWidth);
	float dangerEndAngle = radOffset - numTics * radPerTic;
	float dangerStartAngle = dangerEndAngle + floor(numTics / 3)* radPerTic;
	CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - arcWidth / 2, dangerStartAngle, dangerEndAngle, 1 ); 
	CGContextStrokePath( context );
	
	// draw warning arc
	arcWidth = ticLength / 4;
	CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, 0.6);
	CGContextSetLineWidth(context, arcWidth);
	float warningEndAngle = dangerStartAngle;
	float warningStartAngle = warningEndAngle + floor(numTics / 5) * radPerTic;
	CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - arcWidth / 2, warningStartAngle, warningEndAngle, 1 ); 
	CGContextStrokePath( context );

	// draw caution arc
	arcWidth = ticLength / 8;
	CGContextSetRGBStrokeColor(context, 0.9, 0.1, 0.1, 0.3);
	CGContextSetLineWidth(context, arcWidth);
	float cautionEndAngle = warningStartAngle;
	float cautionStartAngle = cautionEndAngle + ceil(numTics / 5) * radPerTic;
	CGContextAddArc( context, 0, 0, meterRadius - edgeWidth - arcWidth / 2, cautionStartAngle, cautionEndAngle, 1 ); 
	CGContextStrokePath( context );
	
	// draw dial tics
	CGContextSetRGBStrokeColor(context, 0.4, 0.4, 0.4, 1.0);
	CGContextSetLineWidth(context, 1.0);

	for( int curTic = 0; curTic < numTics + 1; ++curTic ) {
		float angle = radOffset - curTic * radPerTic;
		float x1 = (meterRadius - edgeWidth) * cos( angle );
		float y1 = (meterRadius - edgeWidth) * sin( angle );
		float x2 = (meterRadius - edgeWidth - ticLength) * cos( angle );
		float y2 = (meterRadius - edgeWidth - ticLength) * sin( angle );
		CGContextMoveToPoint( context, x1, y1 );
		CGContextAddLineToPoint( context, x2, y2 );
	}
	
	// draw dial

	float value = meterValue;
	if( value > meterMax )
		value = meterMax;
	
	float dialAngle = radOffset - (value / (float) (meterMax - meterMin)) * (M_PI * 2 - meterGap);
	float x1 = 5 * cos( dialAngle + M_PI );	// make the short end of the dial extend a bit beyond the center
	float y1 = 5 * sin( dialAngle + M_PI );
	float x2 = dialLength * cos( dialAngle );
	float y2 = dialLength * sin( dialAngle );

	CGContextStrokePath(context);

	CGContextSetRGBStrokeColor(context, 1.0, 0.2, 0.2, 1.0);
	CGContextSetShadow( context, CGSizeMake( 0, -2 ), 2 );
	CGContextSetLineCap( context, kCGLineCapRound );
	CGContextSetLineWidth(context, 10.0);
	CGContextMoveToPoint( context, x1, y1 );
	CGContextAddLineToPoint( context, x2, y2 );
	
	CGContextStrokePath(context);
}


- (void)dealloc {
    [super dealloc];
}




@end
