//
//  CarbonMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CarbonMeter.h"
#import "TouchXML.h"
#import "CXMLNode-utils.h"
#import "TedometerData.h"

@implementation CarbonMeter

@synthesize carbonRate;


- (NSString*) meterTitle {
	return @"CO2";
}

-(NSInteger) meterMaxValue {
	return 1000000;
}

static NSNumberFormatter *meterStringNumberFormatter;
- (NSNumberFormatter *)meterStringNumberFormatter {
	if( ! meterStringNumberFormatter ) {
		meterStringNumberFormatter = [[NSNumberFormatter alloc] init];
		[meterStringNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
		[meterStringNumberFormatter setMaximumFractionDigits:2];
		[meterStringNumberFormatter setMinimumFractionDigits:2];
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
	NSString *valueStr = [[self tickLabelStringNumberFormatter] stringFromNumber: [NSNumber numberWithDouble:carbonRate*value/100000.0]];
	//NSLog(@"CarbonMeter.tickLabelStringForInteger:%i = %f (carbonRate = %i)", value, carbonRate * value / 100000.0, carbonRate );
	return valueStr;
}

- (NSString *) meterStringForInteger:(NSInteger) value {
	NSString *valueStr = [[self meterStringNumberFormatter] stringFromNumber: [NSNumber numberWithDouble:carbonRate*value/100000.0]];
	return [valueStr stringByAppendingString:@" lbs"];
}


- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document {
	
	BOOL isSuccessful = [super refreshDataFromXmlDocument:document]; 
	if( isSuccessful ) {
		isSuccessful = [TedometerData loadIntegerValuesFromXmlDocument:document intoObject:self withParentNodePath:@"Utility" 
											  andNodesKeyedByProperty:[NSDictionary dictionaryWithObject:@"CarbonRate" forKey:@"carbonRate"]];
	}
	
	return isSuccessful;
}

- (id) init {
	if( self = [super init] ) {
		self.carbonRate = 524;	// initial default taken from http://www.pge.com/myhome/environment/calculator/assumptions.shtml
		self.radiansPerTick = meterSpan / 10.0;
		self.unitsPerTick = 100.0;
	}
	return self;
}

@end
