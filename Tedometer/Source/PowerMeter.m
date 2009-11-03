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

- (NSString*) meterTitle {
	return @"Power";
}

- (NSInteger) meterEndMax {
	return 100 * 1000;	// 100 
}

- (NSInteger) meterEndMin {
	return (NSInteger) 1000;	// 1
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
	return [valueStr stringByAppendingString:@" kW"];
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
	
	NSDictionary* nodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys: 
													  @"PowerNow",		@"now",
													  @"PowerHour",		@"hour",
													  @"PowerTDY",		@"today",
													  @"PowerMTD",		@"mtd",
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
	
	isSuccessful = [TedometerData loadIntegerValuesFromXmlDocument:document intoObject:self withParentNodePath:@"Power.Total" 
									  andNodesKeyedByProperty:nodesKeyedByProperty];
	
	return isSuccessful;
}

- (id) init {
	if( self = [super init] ) {
		self.radiansPerTick = meterSpan / 10.0;
		self.unitsPerTick = 500.0;
	}
	return self;
}


@end
