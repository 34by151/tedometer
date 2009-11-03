//
//  MeterData.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Meter.h"
#import "CXMLNOde-utils.h"
#import "Tedometer.h"
#import "TedometerData.h"

@implementation Meter

@synthesize now;
@synthesize hour;
@synthesize today;
@synthesize mtd;
@synthesize projected;
@synthesize todayPeakValue;
@synthesize todayPeakHour;
@synthesize todayPeakMinute;
@synthesize todayMinValue;
@synthesize todayMinHour;
@synthesize todayMinMinute;
@synthesize mtdPeakValue;
@synthesize mtdPeakMonth;
@synthesize mtdPeakDay;
@synthesize mtdMinValue;
@synthesize mtdMinMonth;
@synthesize mtdMinDay;
@synthesize meterValueType;
@synthesize radiansPerTick;
@synthesize unitsPerTick;

static NSInteger daysInMonths[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

- (NSString*) todayLowLabel {
	return [NSString stringWithFormat:@"Low (%@)", self.todayMinTimeString];
}

- (NSString*) todayAverageLabel {
	return @"Average";
}

- (NSString*) todayPeakLabel {
	return [NSString stringWithFormat:@"Peak (%@)", self.todayPeakTimeString];
}

- (NSString*) todayTotalLabel {
	return @"Total";
}

- (NSString*) todayProjectedLabel {
	return @"";
}

- (NSString*) mtdLowLabel {
	return [NSString stringWithFormat:@"Low (%@)", self.mtdMinTimeString];
}

- (NSString*) mtdAverageLabel {
	return @"Average";
}

- (NSString*) mtdPeakLabel {
	return [NSString stringWithFormat:@"Peak (%@)", self.mtdPeakTimeString];
}

- (NSString*) mtdTotalLabel {
	return @"Total";
}

- (NSString*) mtdProjectedLabel {
	return @"Est. Month Total";
}

- (NSInteger) meterEndMax {
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSInteger) meterEndMin {
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSString*) meterReadingString {
	return [[self meterStringForInteger:self.now] stringByAppendingString:@"/hr"];
}

- (NSInteger) todayAverage {
	TedometerData *tedometerData = [TedometerData sharedTedometerData];
	double hoursSoFar = (tedometerData.gatewayHour + tedometerData.gatewayMinute/60.0);
	return hoursSoFar == 0 ? 0 : self.today / hoursSoFar;
}

- (NSInteger) monthAverage {
	TedometerData *tedometerData = [TedometerData sharedTedometerData];
	
	NSInteger fullDaysThisMonth = daysInMonths[ tedometerData.gatewayMonth - 1 ];
	NSInteger fullDaysSoFar = MAX(0, fullDaysThisMonth - tedometerData.daysLeftInBillingCycle);
	NSInteger hoursSoFar = fullDaysSoFar * 24 + tedometerData.gatewayHour;
	
	return hoursSoFar == 0 ? 0 : self.mtd / hoursSoFar;
}


- (double) currentMaxMeterValue {
	double numTicks = meterSpan / radiansPerTick; 
	return numTicks * unitsPerTick;
}

- (NSString*) meterTitle {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSString *) todayPeakTimeString {
	return [self timeStringForHour:todayPeakHour minute:todayPeakMinute];
}

- (NSString *) todayMinTimeString {
	return [self timeStringForHour:todayMinHour minute:todayMinMinute];
}

- (NSString *) mtdPeakTimeString {
	return [self timeStringForMonth: mtdPeakMonth day: mtdPeakDay];
}

- (NSString *) mtdMinTimeString {
	return [self timeStringForMonth: mtdMinMonth day: mtdMinDay];
}


- (NSString *) timeStringForHour:(NSInteger)anHour minute:(NSInteger)aMinute {
	NSString *amPmStr = anHour > 11 ? @"pm" : @"am";
	if( anHour > 12 )
		anHour -= 12;
	if( anHour == 0 )
		anHour = 12;
	return [NSString stringWithFormat:@"%i:%02i%@", anHour, aMinute, amPmStr];
}

static NSString *monthStrings[] = {@"January", @"February", @"March", @"April", @"May", @"Jun", @"July", @"August", @"September", @"October", @"November", @"December"};
- (NSString *) timeStringForMonth:(NSInteger)aMonth day:(NSInteger)aDay {
	return [NSString stringWithFormat:@"%@ %i", [monthStrings[aMonth-1] substringToIndex:3], aDay];
}

- (void) encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeDouble:radiansPerTick forKey:@"radiansPerTick"];
	[encoder encodeDouble:unitsPerTick forKey:@"unitsPerTick"];
	[encoder encodeInteger:meterValueType forKey:@"meterValueType"];
}

- (id) initWithCoder:(NSCoder*)decoder {
	if (self = [super init]) {
		self.radiansPerTick = [decoder decodeDoubleForKey:@"radiansPerTick"];
		self.unitsPerTick = [decoder decodeDoubleForKey:@"unitsPerTick"];
		self.meterValueType = [decoder decodeIntegerForKey:@"meterValueType"];
	}
	return self;
}


- (NSInteger) valueForMeterValueType:(MeterValueType)unitType {
	switch( meterValueType ) {
		case kMeterValueTypeNow: return now;
		case kMeterValueTypeHour: return hour;
		case kMeterValueTypeToday: return today;
		case kMeterValueTypeMtd: return mtd;
		case kMeterValueTypeProjected: return projected;
		default:
			return now;
	}
}

- (NSString *) tickLabelStringForInteger:(NSInteger) value  {
	return [NSString stringWithFormat:@"%0i", value];
}

- (NSString *) meterStringForInteger:(NSInteger) value {
	return [NSString stringWithFormat:@"%0i", value];
}

- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document {
	
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}


-(void)dealloc {
	[super dealloc];
}

@end
