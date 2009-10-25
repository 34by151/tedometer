//
//  PowerMeter.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PowerMeter.h"


@implementation PowerMeter


- (NSString*) xmlDocumentNodeName {
	return @"Power";
}

- (NSDictionary*) xmlDocumentNodeNameToVariableNameConversionsDict {
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
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"PowerNow",	@"now",
			@"PowerHour",	@"hour",
			@"PowerTDY",	@"today",
			@"PowerMTD",	@"mtd",
			@"PowerProj",	@"proj",
			nil];
}

- (void) encodeWithCoder:(NSCoder*)encoder {
	[super encodeWithCoder:encoder];
}

- (id) initWithCoder:(NSCoder*)decoder {
	if( self = [super initWithCoder: decoder] ) {
	}
	return self;
}

@end
