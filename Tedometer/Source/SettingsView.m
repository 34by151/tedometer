//
//  SettingsView.m
//  Ted-O-Meter
//
//  Created by Nathan on 1/29/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "SettingsView.h"


@implementation SettingsView
-(void) drawRect:(CGRect)rect {
	
	self.backgroundColor = [UIColor blackColor];
    
	CGContextRef currentContext = UIGraphicsGetCurrentContext();
	
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
	
	CGContextDrawRadialGradient( currentContext,gradient, startCenter, startRadius, endCenter, endRadius, kCGGradientDrawsAfterEndLocation );
	
	CGGradientRelease( gradient );
	CGColorSpaceRelease(rgbColorspace);
}

@end
