//
//  MeterView.m
//  Ted-O-Meter
//
//  Created by Nathan on 1/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MeterView.h"


@implementation MeterView


-(void) drawRect:(CGRect)rect {
	
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGGradientRef gradient;
    CGColorSpaceRef rgbColorspace;
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.00 };
    CGFloat components[8] = { 
        0.8, 1.0, 0.80, 0.40,  	// Start color
        0.8, 1.0, 0.80, 0.15 	// End color
    }; 
    rgbColorspace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents(rgbColorspace, components, locations, num_locations);

    CGRect currentBounds = self.bounds;
    //CGPoint topCenter = CGPointMake(CGRectGetMidX(currentBounds), 0.0f);
    //CGPoint bottomCenter = CGPointMake(CGRectGetMidX(currentBounds), CGRectGetMaxY(currentBounds));
    //CGContextDrawLinearGradient(currentContext, gradient, topCenter, bottomCenter, 0);
    
    CGPoint startCenter = CGPointMake( CGRectGetMidX( currentBounds ), 0.25 * CGRectGetHeight( currentBounds ) );
    CGFloat startRadius = 0; //CGRectGetHeight( currentBounds ) / 6.0;
    CGPoint endCenter = startCenter; //CGPointMake( CGRectGetMidX( currentBounds ), CGRectGetMidY( currentBounds ) );
    CGFloat endRadius = CGRectGetHeight( currentBounds ) - endCenter.y;
    
    CGContextDrawRadialGradient( context,gradient, startCenter, startRadius, endCenter, endRadius, kCGGradientDrawsAfterEndLocation );
    
    CGGradientRelease( gradient );
    CGColorSpaceRelease(rgbColorspace); 
    
    // Draw panel dividers
    CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.3);
    CGContextSetLineWidth(context, 1.0);
    //CGContextMoveToPoint( context, CGRectGetWidth( currentBounds ), 0 );
    //CGContextAddLineToPoint( context, 0, 0 );
    CGContextMoveToPoint( context, 0, 0 );
    CGContextAddLineToPoint( context, 0, CGRectGetHeight( currentBounds ) );
    CGContextStrokePath( context );
    

    CGContextSetRGBStrokeColor(context, 0, 0, 0, 0.5);
    CGContextSetLineWidth(context, 2.0);
    CGContextMoveToPoint( context, CGRectGetWidth( currentBounds ), 0 );
    CGContextAddLineToPoint( context, CGRectGetWidth( currentBounds ), CGRectGetHeight( currentBounds ) );
    CGContextStrokePath( context );
	
}
@end
