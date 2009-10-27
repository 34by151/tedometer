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

-(NSInteger) meterMaxValue {
	return 1000;
}

- (NSString*) meterTitle {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
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

- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document {
	
	BOOL isSuccessful = NO; 
	
	
	NSDictionary* nodeDict = self.xmlDocumentNodeNameToVariableNameConversionsDict;
	NSDictionary* defaultNodeDict = self.defaultXmlDocumentNodeNameToVariableNameConversionsDict;
	NSMutableArray* attributesToLoad = [NSMutableArray arrayWithArray: [defaultNodeDict allKeys]];
	[attributesToLoad addObjectsFromArray:[nodeDict allKeys]];
	
	
	CXMLElement *rootElement = [document rootElement];
	if( rootElement != nil ) {
		CXMLNode *meterNode = [rootElement childNamed:self.xmlDocumentNodeName];
		if( meterNode != nil ) {
			CXMLNode *totalNode = [meterNode childNamed:@"Total"];
			if( totalNode != nil ) {
				for( NSString *aKey in attributesToLoad ) {
					NSString *nodeName = [nodeDict valueForKey:aKey];
					if( nodeName == nil ) {
						nodeName = [defaultNodeDict valueForKey:aKey];
					}
					if( nodeName ) {
						CXMLNode *attributeNode = [totalNode childNamed:nodeName];
						if( attributeNode != nil ) {
							isSuccessful = YES;
							NSInteger value = [[attributeNode stringValue] integerValue];
							NSNumber *numberObject = [[NSNumber alloc ]initWithInteger:value];
							[self setValue: numberObject forKey:aKey];
							[numberObject release];
						}
					}
				}
			}
		}
	}
		
	return isSuccessful;
}

-(void)dealloc {
	[super dealloc];
}

@end
