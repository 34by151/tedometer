//
//  PowerMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PowerMeter.h"
#import "TED5000DataLoader.h"
#import "MeterViewSizing.h"

@implementation PowerMeter

@synthesize kva;
@synthesize phase;

- (void) reset;
{
    [super reset];
    self.kva = 0;
    self.phase = 0;
}
- (NSString*) meterTitle {
	return @"Power";
}

- (NSString*) instantaneousUnit {
	return @" kW";
}

- (NSString*) cumulativeUnit {
	return @" kWh";
}

- (NSString*) infoLabel {
    NSString *label;
    if( kva != 0 && now != 0 ) {
        NSString *kvaStr = [[self meterStringNumberFormatter] stringFromNumber: @(kva/1000.0)];
        NSString *powerFactorStr = [[self powerFactorFormatter] stringFromNumber: @(now / (double)kva)];
        label = [NSString stringWithFormat:@"%@ kVA\nPF: %@", kvaStr, powerFactorStr ];
        if( phase != 0 ) {
            label = [label stringByAppendingFormat:@"\nPhs: %ld", (long) phase];
        }
    }
    else {
        label = @"";
    }
	//return @"KVA:\nPF:";
	return label;
}


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
	return 100;
}

static NSNumberFormatter *powerFactorFormatter;
- (NSNumberFormatter *)powerFactorFormatter {
	if( ! powerFactorFormatter ) {
		powerFactorFormatter = [[NSNumberFormatter alloc] init];
		[powerFactorFormatter setNumberStyle:NSNumberFormatterPercentStyle];
		[powerFactorFormatter setMaximumFractionDigits:2];
		[powerFactorFormatter setMinimumFractionDigits:2];
	}
	return powerFactorFormatter;
}

static NSNumberFormatter *meterStringNumberFormatter;
- (NSNumberFormatter *)meterStringNumberFormatter {
	if( ! meterStringNumberFormatter ) {
		meterStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[meterStringNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[meterStringNumberFormatter setMaximumFractionDigits:3];
		[meterStringNumberFormatter setMinimumFractionDigits:3];
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
	NSString *valueStr = [[self tickLabelStringNumberFormatter] stringFromNumber: @(value/1000.0)];
	return valueStr;
}


- (NSString *) meterStringForInteger:(NSInteger) value {
	NSString *valueStr = [[self meterStringNumberFormatter] stringFromNumber: @(value/1000.0)];
	return valueStr;
}

- (instancetype) init {
	if( self = [super init] ) {
	}
	return self;
}


@end
