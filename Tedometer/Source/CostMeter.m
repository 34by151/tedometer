//
//  CostMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CostMeter.h"
#import "MeterViewSizing.h"
#import "TED5000DataLoader.h"


@implementation CostMeter

- (NSString*) meterTitle {
	return @"Cost";
}

- (NSString*) instantaneousUnit {
	return @"/h";
}

- (NSString*) cumulativeUnit {
	return @"";
}

// units are cents
- (NSInteger) maxUnitsPerTick {
	return 1000000;
}

- (NSInteger) minUnitsPerTick {
	return 1;
}

- (NSInteger) maxUnitsForOffset {
	return 100 * self.maxUnitsPerTick;
}

- (NSInteger) defaultUnitsPerTick {
	return 10;
}


static NSNumberFormatter *meterStringNumberFormatter;
- (NSNumberFormatter *)meterStringNumberFormatter {
	if( ! meterStringNumberFormatter ) {
		meterStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[meterStringNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	}
	return meterStringNumberFormatter;
}

static NSNumberFormatter *tickLabelStringNumberFormatter;
- (NSNumberFormatter *)tickLabelStringNumberFormatter {
	if( ! tickLabelStringNumberFormatter ) {
		tickLabelStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[tickLabelStringNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
		[tickLabelStringNumberFormatter setMaximumFractionDigits:2];
	}
	return tickLabelStringNumberFormatter;
}

- (NSString *) tickLabelStringForInteger:(NSInteger) value  {
	NSString *valueStr = [[self tickLabelStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/100.0]];
	return valueStr;
}

- (NSString *) meterStringForInteger:(NSInteger) value {
	NSString *valueStr = [[self meterStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/100.0]];
	return valueStr;
}


- (id) init {
	if( self = [super init] ) {
	}
	return self;
}


@end
