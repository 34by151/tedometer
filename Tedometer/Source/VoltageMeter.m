//
//  VoltageMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VoltageMeter.h"
#import "TED5000DataLoader.h"
#import "MeterViewSizing.h"

@implementation VoltageMeter


- (NSString*) meterTitle {
	return @"Voltage";
}

- (NSString*) instantaneousUnit {
	return @"V";
}

- (NSString*) cumulativeUnit {
	return @"";
}

- (NSString*) todayTotalLabel {
	return @"";
}

- (NSString*) todayAverageLabel {
	return @"";
}

- (NSString*) mtdTotalLabel {
	return @"";
}

- (NSString*) mtdAverageLabel {
	return @"";
}

- (NSString*) mtdProjectedLabel {
	return @"";
}

- (NSInteger) maxUnitsPerTick {
	return 1000000;
}

- (NSInteger) minUnitsPerTick {
	return 1;
}

- (NSInteger) defaultUnitsPerTick {
	return 1;
}

- (NSInteger) maxUnitsForOffset {
	return 10 * self.maxUnitsPerTick;
}

static NSNumberFormatter *meterStringNumberFormatter;
- (NSNumberFormatter *)meterStringNumberFormatter {
	if( ! meterStringNumberFormatter ) {
		meterStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[meterStringNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[meterStringNumberFormatter setMaximumFractionDigits:1];
		[meterStringNumberFormatter setMinimumFractionDigits:1];
	}
	return meterStringNumberFormatter;
}

static NSNumberFormatter *tickLabelStringNumberFormatter;
- (NSNumberFormatter *)tickLabelStringNumberFormatter {
	if( ! tickLabelStringNumberFormatter ) {
		tickLabelStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[tickLabelStringNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[tickLabelStringNumberFormatter setMaximumFractionDigits:1];
	}
	return tickLabelStringNumberFormatter;
}

- (NSString *) tickLabelStringForInteger:(NSInteger) value  {
	NSString *valueStr = [[self tickLabelStringNumberFormatter] stringFromNumber: @(value/10.0)];
	return valueStr;
}

- (NSString *) meterStringForInteger:(NSInteger) value {
	NSString *valueStr = [[self meterStringNumberFormatter] stringFromNumber: @(value/10.0)];
	return valueStr;
}


- (instancetype) init {
	if( self = [super init] ) {
	}
	return self;
}


@end
