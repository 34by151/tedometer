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

@implementation CarbonMeter

@synthesize carbonRate;

-(NSInteger) meterMaxValue {
	return 10000;
}

- (NSString *) tickLabelStringForInteger:(NSInteger) value  {
	NSString *valueStr = [[PowerMeter tickLabelStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:carbonRate*value/100000.0]];
	return valueStr;
}

- (NSString *) meterStringForInteger:(NSInteger) value {
	NSString *valueStr = [[PowerMeter meterStringNumberFormatter] stringFromNumber: [NSNumber numberWithFloat:carbonRate*value/100000.0]];
	return [valueStr stringByAppendingString:@" lbs"];
}


- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document {
	
	BOOL isSuccessful = NO; 
	
	if( [super refreshDataFromXmlDocument:document] ) {

		CXMLElement *rootElement = [document rootElement];
		if( rootElement != nil ) {
			CXMLNode *meterNode = [rootElement childNamed:@"Utility"];
			if( meterNode != nil ) {
				CXMLNode *attributeNode = [meterNode childNamed:@"CarbonRate"];
				if( attributeNode != nil ) {
					isSuccessful = YES;
					NSInteger value = [[attributeNode stringValue] integerValue];
					self.carbonRate = value;
				}
			}
		}
	}
	
	return isSuccessful;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
	[super encodeWithCoder:encoder];
}

- (id) initWithCoder:(NSCoder*)decoder {
	if( self = [super initWithCoder: decoder] ) {
		if( radiansPerTick == 0 )
			radiansPerTick = M_PI / 10.0;
		if( unitsPerTick == 0 )
			unitsPerTick = 100.0;
	}
	return self;
}

@end
