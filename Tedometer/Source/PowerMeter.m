//
//  PowerMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PowerMeter.h"
#import "TedometerData.h"
#import "MeterViewSizing.h"

@implementation PowerMeter

@synthesize kva;

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
	NSString *kvaStr = [[self meterStringNumberFormatter] stringFromNumber: [NSNumber numberWithDouble:kva/1000.0]];
	NSString *powerFactorStr = [[self powerFactorFormatter] stringFromNumber: [NSNumber numberWithDouble:(now / (double)kva)]];
	NSString *label = [NSString stringWithFormat:@"%@ kVA\nPF: %@", kvaStr, powerFactorStr ];
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
	NSString *valueStr = [[self tickLabelStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/1000.0]];
	return valueStr;
}


- (NSString *) meterStringForInteger:(NSInteger) value {
	NSString *valueStr = [[self meterStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/1000.0]];
	return valueStr;
}

- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document {
	
	BOOL isSuccessful = NO; 
	
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
	
	NSDictionary* nodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys: 
													  @"PowerNow",		@"now",
													  @"PowerHour",		@"hour",
													  @"PowerTDY",		@"today",
													  @"PowerMTD",		@"mtd",
													  @"KVA",			@"kva",
													  @"PowerProj",		@"projected",
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
	if( self.isNetMeter ) 
		parentNodePath = @"Power.Total";
	else 
		parentNodePath = [NSString stringWithFormat: @"Power.MTU%d", mtuNumber];
	
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
												   withParentMeterNode:@"Power" 
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
