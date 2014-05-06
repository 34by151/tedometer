//
//  TedometerData.h
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Meter.h"
#import "UICKeyChainStore.h"
@import Security;

#define NUM_METER_TYPES		4
#define NUM_MTUS			5	// 4 MTUs plus a net

typedef enum {
	kMeterTypePower = 0,
	kMeterTypeCost,
	kMeterTypeCarbon,
	kMeterTypeVoltage
} MeterType;

typedef enum {
	kMtuNet = 0,
	kMtu1,
	kMtu2,
	kMtu3,
	kMtu4
} MtuType;

typedef enum {
	kAggregationOpSum = 0,
	kAggregationOpMin,
	kAggregationOpMax
} AggregationOp;

@interface TedometerData : NSObject <NSCoding> {

//    KeychainItemWrapper *keychain;
    
	NSInteger refreshRate;
	NSString* gatewayHost;
	NSString* username;
	NSString* password;
	BOOL useSSL;
	BOOL isAutolockDisabledWhilePluggedIn;
	BOOL hasEstablishedSuccessfulConnectionThisSession;
	BOOL isApplicationInactive;
	BOOL isShowingTodayStatistics;
	BOOL isDialBeingEdited;				// don't reload data while dial is being edited; seems to crash the app
    NSInteger detectedHardwareType;
	
	BOOL hasDisplayedDialEditHelpMessage;
	
	BOOL isPatchingAggregationDataSelected;
	
	BOOL isLoadingXml;
	NSString *connectionErrorMsg;
	
	NSInteger curMeterTypeIdx;
	NSInteger curMtuIdx;
	NSInteger gatewayHour;
	NSInteger gatewayMinute;
	NSInteger gatewayMonth;
	NSInteger gatewayDayOfMonth;
	NSInteger gatewayYear;
	NSInteger carbonRate;
	NSInteger currentRate;
	NSInteger meterReadDate;
	NSInteger daysLeftInBillingCycle;
	NSInteger mtuCount;
	NSMutableArray* mtusArray;			// array of arrays containing mtus
}

@property(readwrite, assign) BOOL isPatchingAggregationDataSelected;
@property(readwrite, assign) BOOL isDialBeingEdited;
@property(readwrite, nonatomic, retain) NSMutableArray* mtusArray;
@property(readwrite, assign) NSInteger refreshRate;
@property(readwrite, copy) NSString* gatewayHost;
@property(readwrite, copy) NSString* username;
@property(readwrite, copy) NSString* password;
@property(readwrite, assign) NSInteger gatewayHour;
@property(readwrite, assign) NSInteger gatewayMinute;
@property(readwrite, assign) NSInteger gatewayMonth;
@property(readwrite, assign) NSInteger gatewayDayOfMonth;
@property(readwrite, assign) NSInteger gatewayYear;
@property(readwrite, assign) NSInteger carbonRate;
@property(readwrite, assign) NSInteger currentRate;
@property(readwrite, assign) NSInteger meterReadDate;
@property(readwrite, assign) NSInteger daysLeftInBillingCycle;
@property(readonly) NSInteger billingCycleStartMonth;
@property(readwrite, assign) NSInteger mtuCount;
@property(readonly) NSInteger meterCount;
@property(readwrite, assign) BOOL isAutolockDisabledWhilePluggedIn;
@property(readwrite, assign) BOOL useSSL;
@property(readwrite, assign) BOOL hasEstablishedSuccessfulConnectionThisSession;
@property(readwrite, assign) BOOL isApplicationInactive;
@property(readwrite, assign) BOOL isShowingTodayStatistics;
@property(readwrite, assign) NSInteger detectedHardwareType;
@property(readwrite, assign) BOOL isLoadingXml;
@property(readwrite, copy) NSString *connectionErrorMsg;
@property(readwrite, assign) BOOL hasDisplayedDialEditHelpMessage;

@property(readwrite, assign) NSInteger curMeterTypeIdx;
@property(readwrite, assign) NSInteger curMtuIdx;
@property(readonly) Meter* curMeter;


+ (TedometerData *) sharedTedometerData;

- (Meter*) nextMtu;
- (Meter*) prevMtu;
- (Meter*) nextMeterType;
- (Meter*) prevMeterType;

- (void) reloadXmlDocumentInBackground;
- (void) reloadXmlDocument;

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
+ (BOOL) fixNetMeterValuesFromXmlDocument:(CXMLDocument*) document 
							   intoObject:(Meter*) meterObject 
					  withParentMeterNode:(NSString*)parentNode 
				  andNodesKeyedByProperty:(NSDictionary*)netMeterFixNodesKeyedByProperty 
							 usingAggregationOp:(AggregationOp)aggregationOp;

+ (CXMLNode *) nodeInXmlDocument:(CXMLDocument *)document atPath:(NSString*)nodePath;

@end
