//
//  MeterData.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Meter.h"
#import "CXMLNOde-utils.h"
#import "MeterViewSizing.h"
#import "TedometerData.h"
#import "Flurry.h"

@implementation Meter

@synthesize mtuNumber;
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
@synthesize zeroAngle;

static NSInteger daysInMonths[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };


- (BOOL) isNetMeter {
	return mtuNumber == 0;
}


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
	return [NSString stringWithFormat:@"Since %@", [self timeStringForHour:0 minute:0]];
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
	TedometerData *tedometerData = [TedometerData sharedTedometerData];
	return [NSString stringWithFormat:@"Since %@", [self timeStringForMonth:tedometerData.billingCycleStartMonth day:tedometerData.meterReadDate]];
}

- (NSString*) mtdProjectedLabel {
	return @"Est. Month Total";
}

- (NSString*) infoLabel {
	return @"";
}

- (NSInteger) maxUnitsPerTick {
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSInteger) minUnitsPerTick {
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSInteger) defaultUnitsPerTick {
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSInteger) maxUnitsForOffset {
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSString*) instantaneousUnit {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSString*) cumulativeUnit {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (BOOL) isAverageSupported;
{
	return YES;
}

- (NSInteger) todayAverage {
	TedometerData *tedometerData = [TedometerData sharedTedometerData];
	double hoursSoFar = (tedometerData.gatewayHour + tedometerData.gatewayMinute/60.0);
	return hoursSoFar == 0 ? 0 : (NSInteger) (0.5 + self.today / hoursSoFar);
}

- (NSInteger) monthAverage {
	TedometerData *tedometerData = [TedometerData sharedTedometerData];
	
	NSInteger fullDays;
	if( tedometerData.gatewayDayOfMonth >= tedometerData.meterReadDate ) {
		fullDays = tedometerData.gatewayDayOfMonth - tedometerData.meterReadDate;
	}
	else {
		NSInteger lastMonth = tedometerData.gatewayMonth - 1;
		if( lastMonth < 0 )
			return 0;
		
		if( lastMonth == 0 )
			lastMonth = 12;
		fullDays = tedometerData.gatewayDayOfMonth + (daysInMonths[lastMonth-1] - tedometerData.meterReadDate);
	}
	
	double hoursSoFar = fullDays * 24 + tedometerData.gatewayHour + tedometerData.gatewayMinute / 60.0;
	return hoursSoFar == 0 ? 0 : (NSInteger) (0.5 + self.mtd / hoursSoFar);
}


- (double) currentMaxMeterValue {
	double numTicks = meterSpan / radiansPerTick; 
	return numTicks * unitsPerTick;
}

- (NSString*) meterTitleWithMtuNumber {
	NSString *title;
	if( [self mtuNumber] == 0 ) {
		if( [[TedometerData sharedTedometerData] mtuCount] <= 1 )
			title = self.meterTitle;
		else
			title = [NSString stringWithFormat:@"Net %@", self.meterTitle];
	}
	else {
		title = [NSString stringWithFormat:@"MTU%ld %@", (long)self.mtuNumber, self.meterTitle];
	}

	return title;
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
	return [NSString stringWithFormat:@"%ld:%02ld%@", (long) anHour, (long) aMinute, amPmStr];
}

static NSString *monthStrings[] = {@"January", @"February", @"March", @"April", @"May", @"Jun", @"July", @"August", @"September", @"October", @"November", @"December"};
- (NSString *) timeStringForMonth:(NSInteger)aMonth day:(NSInteger)aDay {
	NSString *timeString = @"N/A";
	if( aMonth >= 1 && aMonth <= 12 ) {
		@try {
			timeString = [NSString stringWithFormat:@"%@ %ld", [monthStrings[aMonth-1] substringToIndex:3], (long) aDay];
		}
		@catch( NSException *exception ) {
			NSString *msg = [NSString stringWithFormat: @"%@ in %s: aMonth=%ld, aDay = %ld", [exception name], __PRETTY_FUNCTION__, (long) aMonth, (long) aDay ];
			[Flurry logError: [exception name] message:msg exception:exception];
			timeString = @"N/A";
		}
	}

	return timeString;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeInteger:mtuNumber forKey:@"mtuNumber"];
	if( mtuNumber == 0 ) {
		[encoder encodeObject:mtuMeters forKey:@"mtuMeters"];
	}
	[encoder encodeDouble:radiansPerTick forKey:@"radiansPerTick"];
	[encoder encodeDouble:unitsPerTick forKey:@"unitsPerTick"];
	[encoder encodeDouble:zeroAngle forKey:@"zeroAngle"];
	[encoder encodeInteger:meterValueType forKey:@"meterValueType"];
}


- (id) init {
	if( self = [super init] ) {
		self.radiansPerTick = 0;
		self.unitsPerTick = 0;
	}
	return self;
}
- (id) initWithMtuNumber:(NSInteger)mtuNum {
	if( self = [super init] ) {
		mtuNumber = mtuNum;
	}
	return self;
}

- (id) initNetMeterWithMtuMeters: (NSArray*)meters {
	if( self = [super init] ) {
		mtuNumber = 0;
		mtuMeters = [meters copy];
	}
	return self;
}


- (id) initWithCoder:(NSCoder*)decoder {
	if (self = [super init]) {
		if( ! [decoder containsValueForKey:@"mtuNumber"] ) 
			mtuNumber = 1;
		else
			mtuNumber = [decoder decodeIntegerForKey:@"mtuNumber"];
		
		if( mtuNumber == 0 ) {
			mtuMeters = [[decoder decodeObjectForKey:@"mtuMeters"] retain];
		}
		self.radiansPerTick = [decoder decodeDoubleForKey:@"radiansPerTick"];
		self.unitsPerTick = [decoder decodeDoubleForKey:@"unitsPerTick"];
		self.zeroAngle = [decoder decodeDoubleForKey:@"zeroAngle"];
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
	return [NSString stringWithFormat:@"%0ld", (long)value];
}

- (NSString *) meterStringForInteger:(NSInteger) value {
	return [NSString stringWithFormat:@"%0ld", (long)value];
}

-(void)dealloc {
	if( mtuNumber == 0 ) {
		[mtuMeters release];
	}
	[super dealloc];
}

@end
