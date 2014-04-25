//
//  PartiallyTouchSensitiveScrollView.m
//  Ted-O-Meter
//
//  Created by Nathan on 1/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PartiallyTouchSensitiveScrollView.h"
#import "DialView.h"

@implementation PartiallyTouchSensitiveScrollView


- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
	// Don't scroll if touches are on DialView, to avoid
	// confusion with touch gestures for adjusting scale and
	// offset

	// Apparently, returning YES means don't ignore the touches.
	// (I.e., cancel the subview touch handlers? -- and yet the Today/Month button still works... I don't get it...)
	
	BOOL shouldCancel = ([view class] != [DialView class]);
	//NSLog( @"PartiallyTouchSensitiveScrollView: shouldCancelInContentView cancel = %d view = %@", shouldCancel, [[view class] description] );
	
	return shouldCancel;
}


@end
