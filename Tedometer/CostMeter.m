//
//  CostMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CostMeter.h"


@implementation CostMeter

-(NSInteger) meterMaxValue {
	return 1000;
}

static NSNumberFormatter *meterStringNumberFormatter;
+ (NSNumberFormatter *)meterStringNumberFormatter {
	if( ! meterStringNumberFormatter ) {
		meterStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[meterStringNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	}
	return meterStringNumberFormatter;
}

static NSNumberFormatter *tickLabelStringNumberFormatter;
+ (NSNumberFormatter *)tickLabelStringNumberFormatter {
	if( ! tickLabelStringNumberFormatter ) {
		tickLabelStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[tickLabelStringNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
		[tickLabelStringNumberFormatter setMaximumFractionDigits:2];
	}
	return tickLabelStringNumberFormatter;
}

- (NSString *) tickLabelStringForInteger:(NSInteger) value  {
	NSString *valueStr = [[CostMeter tickLabelStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/100.0]];
	return valueStr;
}

- (NSString *) meterStringForInteger:(NSInteger) value {
	NSString *valueStr = [[CostMeter meterStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/100.0]];
	return valueStr;
}

- (NSString*) xmlDocumentNodeName {
	return @"Cost";
}

- (NSDictionary*) xmlDocumentNodeNameToVariableNameConversionsDict {
	/*
	 <Cost>
	 <Total>
	 <CostNow>13</CostNow>
	 <CostHour>13</CostHour>
	 <CostTDY>250</CostTDY>
	 <CostMTD>6632</CostMTD>
	 <CostProj>13219</CostProj>
	 <PeakTdy>95</PeakTdy>
	 <PeakMTD>95</PeakMTD>
	 <PeakTdyHour>0</PeakTdyHour>
	 <PeakTdyMin>27</PeakTdyMin>
	 <PeakMTDMonth>10</PeakMTDMonth>
	 <PeakMTDDay>24</PeakMTDDay>
	 
	 <MinTdy>8</MinTdy>
	 <MinMTD>8</MinMTD>
	 <MinTdyHour>1</MinTdyHour>
	 <MinTdyMin>31</MinTdyMin>
	 <MinMTDMonth>10</MinMTDMonth>
	 <MinMTDDay>14</MinMTDDay>
	 </Total>
	 ...
	 </Power>
	 */
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"CostNow",	@"now",
			@"CostHour",	@"hour",
			@"CostTDY",	@"today",
			@"CostMTD",	@"mtd",
			@"CostProj",	@"projected",
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
			unitsPerTick = 10.0;
	}
	return self;
}

@end
