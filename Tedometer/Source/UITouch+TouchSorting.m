//
//  UITouch+TouchSorting.m
//  Ted-O-Meter
//
//  Created by Nathan on 2/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UITouch+TouchSorting.h"



@implementation UITouch (TouchSorting)
- (NSComparisonResult)compareAddress:(id)obj {
	if ((void *)self < (void *)obj) return NSOrderedAscending;
    else if ((void *)self == (void *)obj) return NSOrderedSame;
    else return NSOrderedDescending;
}
@end