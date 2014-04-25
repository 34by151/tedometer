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
	
	NSDictionary* nodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys: 
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
	
	NSString *parentNodePath;
	if( mtuNumber == 0 ) 
		parentNodePath = @"Cost.Total";
	else 
		parentNodePath = [NSString stringWithFormat: @"Cost.MTU%ld", (long)mtuNumber];
	
	isSuccessful = [TedometerData loadIntegerValuesFromXmlDocument:document intoObject:self withParentNodePath:parentNodePath 
										   andNodesKeyedByProperty:nodesKeyedByProperty];
	
	[nodesKeyedByProperty release];
	
	if( self.isNetMeter ) {
		
		// Fix peak/min for net meter
		NSDictionary *netMeterFixNodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
														 @"PeakTdy",		@"todayPeakValue",
														 @"MinTdy",			@"todayMinValue",
														 @"PeakMTD",		@"mtdPeakValue",
														 @"MinMTD",			@"mtdMinValue",
														 nil];
		
		isSuccessful = [TedometerData fixNetMeterValuesFromXmlDocument:document 
															intoObject:self 
												   withParentMeterNode:@"Cost" 
											   andNodesKeyedByProperty:netMeterFixNodesKeyedByProperty usingAggregationOp:kAggregationOpSum];
		
		[netMeterFixNodesKeyedByProperty release];
	}
	
	return isSuccessful;
}

- (id) init {
	if( self = [super init] ) {
	}
	return self;
}


@end
