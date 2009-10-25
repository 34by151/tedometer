//
//  MeterData.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Meter.h"
#import "CXMLNOde-utils.h"


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
@synthesize valueFormatter;
@synthesize tickLabelFormatter;

-(NSInteger) meterMaxValue {
	return 100;
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
		/*
		tickLabelFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		valueFormatter = tickLabelFormatter;
		 */
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

- (NSString*) xmlDocumentNodeName {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


- (NSDictionary*) xmlDocumentNodeNameToVariableNameConversionsDict {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (NSDictionary*) defaultXmlDocumentNodeNameToVariableNameConversionsDict {
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"PeakTdy",			@"todayPeakValue",
			@"PeakTdyHour",		@"todayPeakHour",
			@"PeakTdyMin",		@"todayPeakMinute",
			@"MinTdy",			@"todayMinValue",
			@"MinTdyHour",		@"todayMinHour",
			@"MinTdyMin",		@"todayMinMinute",
			@"PeakMTD",			@"mtdPeakValue",
			@"PeakMTDMonth",	@"mtdPeakMonth",
			@"PeakMTDDay",		@"mtdPeakDay",
			@"MinMTD",			@"mtdMinValue",
			@"MinMTDMonth",		@"mtdMinMonth",
			@"MinMTDDay",		@"mtdMinDay",
			nil];
}

- (void)refreshDataFromXmlDocument:(CXMLDocument *)document {
	
	
	
	NSDictionary* nodeDict = self.xmlDocumentNodeNameToVariableNameConversionsDict;
	NSDictionary* defaultNodeDict = self.defaultXmlDocumentNodeNameToVariableNameConversionsDict;
	
	CXMLNode *meterNode = [[document rootElement] childNamed:self.xmlDocumentNodeName];
	CXMLNode *totalNode = [meterNode childNamed:@"Total"];
	
	for( NSString *aKey in [nodeDict allKeys] ) {
		NSString *nodeName = [nodeDict valueForKey:aKey];
		if( nodeName == nil ) {
			nodeName = [defaultNodeDict valueForKey:aKey];
		}
		if( nodeName ) {
			NSInteger value = [[[totalNode childNamed:nodeName] stringValue]  integerValue];
			[self setValue: [NSNumber numberWithInteger:value] forKey:aKey];
		}
	}
}

@end
