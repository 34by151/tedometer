//
//  UITouch+TouchSorting.h
//  Ted-O-Meter
//
//  Created by Nathan on 2/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


// UITouch category to facilitate sorting
@interface UITouch (TouchSorting)
- (NSComparisonResult)compareAddress:(id)obj;
@end
