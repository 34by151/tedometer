//
//  CostMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CostMeter.h"
#import "TedometerData.h"
#import "MeterViewSizing.h"


@implementation CostMeter

- (NSString*) meterTitle {
	return @"Cost";
}

- (NSInteger) meterEndMax {
	return 100 * 100;	// $100 
}

- (NSInteger) meterEndMin {
	return (NSInteger) (0.10 * 100);	// $0.10
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

- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document {
	
	BOOL isSuccessful = NO; 
	
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
	
	NSDictionary* nodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys: 
													  @"CostNow",		@"now",
													  @"CostHour",		@"hour",
													  @"CostTDY",		@"today",
													  @"CostMTD",		@"mtd",
													  @"CostProj",		@"projected",
													  @"PeakTdy",		@"todayPeakValue",
													  @"PeakTdyHour",	@"todayPeakHour",
													  @"PeakTdyMin",	@"todayPeakMinute",
													  @"MinTdy",		@"todayMinValue",
													  @"MinTdyHour",	@"todayMinHour",
													  @"MinTdyMin",		@"todayMinMinute",
													  @"PeakMTD",		@"mtdPeakValue",
													  @"PeakMTDMonth",	@"mtdPeakMonth",
													  @"PeakMTDDay",	@"mtdPeakDay",
													  @"MinMTD",		@"mtdMinValue",
													  @"MinMTDMonth",	@"mtdMinMonth",
													  @"MinMTDDay",		@"mtdMinDay",
													  nil];
	
	isSuccessful = [TedometerData loadIntegerValuesFromXmlDocument:document intoObject:self withParentNodePath:@"Cost.Total" 
										  andNodesKeyedByProperty:nodesKeyedByProperty];
	
	return isSuccessful;
}

- (id) init {
	if( self = [super init] ) {
		self.radiansPerTick = meterSpan / 10.0;
		self.unitsPerTick = 10.0;
	}
	return self;
}


@end
