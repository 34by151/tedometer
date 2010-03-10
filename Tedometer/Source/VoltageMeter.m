//
//  VoltageMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VoltageMeter.h"
#import "TedometerData.h"
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
	NSString *valueStr = [[self tickLabelStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/10.0]];
	return valueStr;
}

- (NSString *) meterStringForInteger:(NSInteger) value {
	NSString *valueStr = [[self meterStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:value/10.0]];
	return valueStr;
}

- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document {
	
	BOOL isSuccessful = NO; 
	
	/*
	 <Voltage>
	 <Total>
	 <VoltageNow>1221</VoltageNow>
	 <LowVoltageHour>1221</LowVoltageHour>
	 <LowVoltageToday>1213</LowVoltageToday>
	 <LowVoltageTodayTimeHour>0</LowVoltageTodayTimeHour>
	 <LowVoltageTodayTimeMin>8</LowVoltageTodayTimeMin>
	 <HighVoltageHour>1223</HighVoltageHour>
	 <HighVoltageToday>1223</HighVoltageToday>
	 <HighVoltageTodayTimeHour>2</HighVoltageTodayTimeHour>
	 <HighVoltageTodayTimeMin>16</HighVoltageTodayTimeMin>
	 <LowVoltageMTD>1076</LowVoltageMTD>
	 <LowVoltageMTDDateMonth>10</LowVoltageMTDDateMonth>
	 <LowVoltageMTDDateDay>15</LowVoltageMTDDateDay>
	 <HighVoltageMTD>1230</HighVoltageMTD>
	 <HighVoltageMTDDateMonth>10</HighVoltageMTDDateMonth>
	 <HighVoltageMTDDateDay>22</HighVoltageMTDDateDay>
	 </Total>
	 ...
	 </Power>
	 */
	
	NSDictionary* nodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys: 
										  @"VoltageNow",					@"now",
										  @"HighVoltageToday",				@"todayPeakValue",
										  @"HighVoltageTodayTimeHour",		@"todayPeakHour",
										  @"HighVoltageTodayTimeMin", 		@"todayPeakMinute",
										  @"LowVoltageToday",				@"todayMinValue",
										  @"LowVoltageTodayTimeHour",		@"todayMinHour",
										  @"LowVoltageTodayTimeMin",		@"todayMinMinute",
										  @"HighVoltageMTD",				@"mtdPeakValue",
										  @"HighVoltageMTDDateMonth",		@"mtdPeakMonth",
										  @"HighVoltageMTDDateDay",			@"mtdPeakDay",
										  @"LowVoltageMTD",					@"mtdMinValue",
										  @"LowVoltageMTDDateMonth",		@"mtdMinMonth",
										  @"LowVoltageMTDDateDay",			@"mtdMinDay",
										  nil];
	NSString *parentNodePath;
	if( mtuNumber == 0 ) 
		parentNodePath = @"Voltage.Total";
	else 
		parentNodePath = [NSString stringWithFormat: @"Voltage.MTU%d", mtuNumber];
	
	isSuccessful = [TedometerData loadIntegerValuesFromXmlDocument:document intoObject:self withParentNodePath:parentNodePath 
										   andNodesKeyedByProperty:nodesKeyedByProperty];
	
	[nodesKeyedByProperty release];
	
	if( self.isNetMeter ) {
		
		// Fix peak/min for net meter
		NSDictionary *netMeterFixNodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
														 @"HighVoltageToday",		@"todayPeakValue",
														 @"PeakVoltageMTD",			@"mtdPeakValue",
														 nil];
		
		isSuccessful = [TedometerData fixNetMeterValuesFromXmlDocument:document 
															intoObject:self 
												   withParentMeterNode:@"Voltage" 
											   andNodesKeyedByProperty:netMeterFixNodesKeyedByProperty 
													usingAggregationOp:kAggregationOpMax];
		
		[netMeterFixNodesKeyedByProperty release];

		netMeterFixNodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
														 @"LowVoltageToday",		@"todayMinValue",
														 @"PeaVoltageMTD",			@"mtdMinValue",
														 nil];
		
		isSuccessful = [TedometerData fixNetMeterValuesFromXmlDocument:document 
															intoObject:self 
												   withParentMeterNode:@"Voltage" 
											   andNodesKeyedByProperty:netMeterFixNodesKeyedByProperty 
													usingAggregationOp:kAggregationOpMin];
		
	}
	
	
	return isSuccessful;
}

- (id) init {
	if( self = [super init] ) {
	}
	return self;
}


@end
