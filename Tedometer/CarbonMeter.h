//
//  CarbonMeter.h
//  Ted-O-Meter
//
//  Created by Nathan on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Meter.h"
#import "PowerMeter.h"

@interface CarbonMeter : PowerMeter <NSCoding> {
	
	NSInteger carbonRate;
}

@property(nonatomic, assign) NSInteger carbonRate;
@end
