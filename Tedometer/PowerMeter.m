//
//  PowerMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PowerMeter.h"


@implementation PowerMeter

-(NSInteger) meterMaxValue {
	return 10000;
}

static NSNumberFormatter *meterStringNumberFormatter;
+ (NSNumberFormatter *)meterStringNumberFormatter {
	if( ! meterStringNumberFormatter ) {
		meterStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[meterStringNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[meterStringNumberFormatter setMaximumFractionDigits:2];
		[meterStringNumberFormatter setMinimumFractionDigits:2];
	}
	return meterStringNumberFormatter;
}

static NSNumberFormatter *tickLabelStringNumberFormatter;
+ (NSNumberFormatter *)tickLabelStringNumberFormatter {
	if( ! tickLabelStringNumberFormatter ) {
		tickLabelStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[tickLabelStringNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[tickLabelStringNumberFormatter setMaximumFractionDigits:1];
	}
	return tickLabelStringNumberFormatter;
}

- (NSString *) tickLabelStringForInteger:(NSInteger) value  {
	NSString *valueStr = [[PowerMeter tickLabelStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/1000.0]];
	return valueStr;
}

- (NSString *) meterStringForInteger:(NSInteger) value {
	NSString *valueStr = [[PowerMeter meterStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/1000.0]];
	return [valueStr stringByAppendingString:@" kW"];
}

- (NSString*) xmlDocumentNodeName {
	return @"Power";
}

- (NSDictionary*) xmlDocumentNodeNameToVariableNameConversionsDict {
	/*
	 <Power>
	 <Total>
	 <PowerNow>1570</PowerNow>
	 <PowerHour>1682</PowerHour>
	 <PowerTDY>32581</PowerTDY>
	 <PowerMTD>824305</PowerMTD>
	 <PowerProj>1681897</PowerProj>
	 <KVA>1863</KVA>
	 <PeakTdy>12265</PeakTdy>
	 <PeakMTD>12265</PeakMTD>
	 <PeakTdyHour>9</PeakTdyHour>
	 <PeakTdyMin>40</PeakTdyMin>
	 <PeakMTDMonth>10</PeakMTDMonth>
	 <PeakMTDDay>24</PeakMTDDay>
	 <MinTdy>1005</MinTdy>
	 <MinMTD>0</MinMTD>
	 <MinTdyHour>1</MinTdyHour>
	 <MinTdyMin>42</MinTdyMin>
	 <MinMTDMonth>10</MinMTDMonth>
	 <MinMTDDay>14</MinMTDDay>
	 </Total>
	 ...
	 </Power>
	 */
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"PowerNow",	@"now",
			@"PowerHour",	@"hour",
			@"PowerTDY",	@"today",
			@"PowerMTD",	@"mtd",
			@"PowerProj",	@"projected",
			nil];
}

- (void) encodeWithCoder:(NSCoder*)encoder {
	[super encodeWithCoder:encoder];
}

- (id) initWithCoder:(NSCoder*)decoder {
	if( self = [super initWithCoder: decoder] ) {
		if( radiansPerTick == 0 )
			radiansPerTick = M_PI / 10.0;
		if( unitsPerTick == 0 )
			unitsPerTick = 100.0;
	}
	return self;
}

@end
