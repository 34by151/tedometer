//
//  TedometerData.h
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Meter.h"

@interface TedometerData : NSObject <NSCoding> {

	NSArray* meters;
	NSInteger refreshRate;
	NSString* gatewayHost;
	NSInteger curMeterIdx;
	NSInteger gatewayHour;
	NSInteger gatewayMinute;
	NSInteger gatewayMonth;
	NSInteger gatewayDayOfMonth;
	NSInteger gatewayYear;
	NSInteger carbonRate;
	NSInteger currentRate;
	NSInteger meterReadDate;
	NSInteger daysLeftInBillingCycle;
	BOOL isAutolockDisabledWhilePluggedIn;
	
}

@property(readwrite, nonatomic, retain) NSArray* meters;
@property(readwrite, assign) NSInteger refreshRate;
@property(readwrite, copy) NSString* gatewayHost;
@property(readwrite, assign) NSInteger gatewayHour;
@property(readwrite, assign) NSInteger gatewayMinute;
@property(readwrite, assign) NSInteger gatewayMonth;
@property(readwrite, assign) NSInteger gatewayDayOfMonth;
@property(readwrite, assign) NSInteger gatewayYear;
@property(readwrite, assign) NSInteger carbonRate;
@property(readwrite, assign) NSInteger currentRate;
@property(readwrite, assign) NSInteger meterReadDate;
@property(readwrite, assign) NSInteger daysLeftInBillingCycle;
@property(readwrite, assign) BOOL isAutolockDisabledWhilePluggedIn;


//@property(readwrite, assign) NSInteger curMeterIdx;
@property(readonly) Meter* curMeter;

+ (TedometerData *) sharedTedometerData;

- (Meter*) nextMeter;
- (Meter*) prevMeter;
- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document;

- (void) activatePowerMeter;
- (void) activateCostMeter;
- (void) activateCarbonMeter;
- (void) activateVoltageMeter;

- (void) encodeWithCoder:(NSCoder*)encoder;
- (id) initWithCoder:(NSCoder*)decoder;

+ (NSString*)archiveLocation;
+ (TedometerData *) unarchiveFromDocumentsFolder;
+ (BOOL) archiveToDocumentsFolder;
+ (BOOL)loadIntegerValuesFromXmlDocument:(CXMLDocument *)document intoObject:(NSObject*) object 
		withParentNodePath:(NSString*)parentNodePath andNodesKeyedByProperty:(NSDictionary*)propertiesKeyedByNodeDict;

@end
