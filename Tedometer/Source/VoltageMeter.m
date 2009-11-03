//
//  VoltageMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VoltageMeter.h"
#import "TedometerData.h"

@implementation VoltageMeter


- (NSString*) meterTitle {
	return @"Voltage";
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


- (NSInteger) meterEndMax {
	return 1000 * 10;
}

- (NSInteger) meterEndMin {
	return 10 * 10;	
}

- (NSString*) meterReadingString {
	return [self meterStringForInteger:self.now];
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
	return [valueStr stringByAppendingString:@" V"];
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
	
	NSDictionary* nodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys: 
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
	
	isSuccessful = [TedometerData loadIntegerValuesFromXmlDocument:document intoObject:self withParentNodePath:@"Voltage.Total" 
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
