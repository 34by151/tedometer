//
//  TedometerData.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

//#define USE_TEST_DATA	0

#import "TedometerData.h"
#import "PowerMeter.h"
#import "CostMeter.h"
#import "CarbonMeter.h"
#import "VoltageMeter.h"
#import "SynthesizeSingleton.h"
#import "CXMLNode-utils.h"
#import "MeterViewSizing.h"
#import "TedometerAppDelegate.h"
#import "ASIHTTPRequest.h"
#import "log.h"
#import "Flurry.h"

#define kPowerMeterIdx		0
#define kCostMeterIdx		1
#define kCarbonMeterIdx 	2
#define kVoltageMeterIdx	3

@interface TedometerData()
- (void) clearIsLoadingXmlFlag;
@end
	
@implementation TedometerData



@synthesize mtusArray;
@synthesize refreshRate;
@synthesize gatewayHost;
@synthesize username;
@synthesize password;
@synthesize useSSL;
@synthesize gatewayHour;
@synthesize gatewayMinute;
@synthesize gatewayMonth;
@synthesize gatewayDayOfMonth;
@synthesize gatewayYear;
@synthesize carbonRate;
@synthesize currentRate;
@synthesize meterReadDate;
@synthesize daysLeftInBillingCycle;
@synthesize isAutolockDisabledWhilePluggedIn;
@synthesize curMtuIdx;
@synthesize hasEstablishedSuccessfulConnectionThisSession;
@synthesize isLoadingXml;
@synthesize connectionErrorMsg;
@synthesize isApplicationInactive;
@synthesize isShowingTodayStatistics;
@synthesize hasDisplayedDialEditHelpMessage;
@synthesize isDialBeingEdited;
@synthesize isPatchingAggregationDataSelected;

// ----------------------------------------------------------------------
// From http://www.cocoadev.com/index.pl?SingletonDesignPattern

static TedometerData *sharedTedometerData = nil;

+ (TedometerData*)sharedTedometerData
{
    Class myClass = [self class];
    @synchronized(myClass) {
        if (sharedTedometerData == nil) {
            [[self alloc] init];
        }
    }
    return sharedTedometerData;
}

+ (id)allocWithZone:(NSZone *)zone
{
    Class myClass = [self class];
    @synchronized(myClass) {
        if (sharedTedometerData == nil) {
            return [super allocWithZone:zone];
        }
    }
    return sharedTedometerData;
}

- (id)init
{
    Class myClass = [self class];
    @synchronized(myClass) {
        if (sharedTedometerData == nil) {
            if (self = [super init]) {
				
                // custom initialization here
				
				TedometerData *tedometerData = [TedometerData unarchiveFromDocumentsFolder];
				DLog( "tedometerData.curMeterTypeIdx = %d", tedometerData.curMeterTypeIdx );
				
				if( tedometerData ) {
					[self release];
					self = [tedometerData retain];
				}
				
				// mtusArray is an NSArray of NUM_MTUS elements of type NSArray, 
				// each of which is an array consisting of NUM_METER_TYPES elements of type Meter.
				//
				// [ [PowerNet,  CostNet,  CarbonNet,  VoltageNet],			// MTU0 (net)
				//   [PowerMtu1, CostMtu1, CarbonMtu1, VoltageMtu1],		// MTU1
				//	 [PowerMtu2, CostMtu2, CarbonMtu2, VoltageMtu2],		// MTU2
				//	 [PowerMtu3, CostMtu3, CarbonMtu3, VoltageMtu3],		// MTU3
				//	 [PowerMtu4, CostMtu4, CarbonMtu4, VoltageMtu4] ]		// MTU4
				

				// The first mtu's elements are net meters of each type
				
				if( mtusArray == nil || [mtusArray count] < NUM_MTUS) {
					NSMutableArray* newMtusArray = [[NSMutableArray alloc] initWithCapacity:NUM_MTUS];
					for( int i=0; i < NUM_MTUS; ++i ) 
						[newMtusArray addObject: [NSMutableArray arrayWithCapacity:NUM_METER_TYPES]];

					NSMutableArray *typeMeters;
					for( NSInteger mtuNum = 1; mtuNum < NUM_MTUS; ++mtuNum ) {	// skip the net meter; we'll add it later
						typeMeters = (NSMutableArray*) [newMtusArray objectAtIndex:mtuNum];
						// NOTE: Ordering here is signficant (power, cost, carbon, voltage)
						[typeMeters addObject: [[PowerMeter alloc] initWithMtuNumber:mtuNum]];
						[typeMeters addObject: [[CostMeter alloc] initWithMtuNumber:mtuNum]];
						[typeMeters addObject: [[CarbonMeter alloc] initWithMtuNumber:mtuNum]];
						[typeMeters addObject: [[VoltageMeter alloc] initWithMtuNumber:mtuNum]];
					}					
					
					// initialize net meters
					NSMutableArray *netMtuTypeMeters = [newMtusArray objectAtIndex:kMtuNet];
					for( NSInteger meterType = 0; meterType < NUM_METER_TYPES; ++meterType ) {
						NSMutableArray *typeMetersForNetMtu = [NSMutableArray arrayWithCapacity:NUM_METER_TYPES];
						for( NSInteger mtuNum = 1; mtuNum < NUM_MTUS; ++mtuNum ) {
							[typeMetersForNetMtu addObject:[[newMtusArray objectAtIndex:mtuNum] objectAtIndex:meterType]];
						}
						
						Meter *aTypeNetMeter;
						switch( meterType ) {
							case kMeterTypePower:	aTypeNetMeter = [PowerMeter alloc]; break;
							case kMeterTypeCost:	aTypeNetMeter = [CostMeter alloc]; break;
							case kMeterTypeCarbon:	aTypeNetMeter = [CarbonMeter alloc]; break;
							case kMeterTypeVoltage:	aTypeNetMeter = [VoltageMeter alloc]; break;
						}
						
						[aTypeNetMeter initNetMeterWithMtuMeters: typeMetersForNetMtu];
						[netMtuTypeMeters addObject:aTypeNetMeter];
					}

					
					self.mtusArray = newMtusArray;
					[newMtusArray release];
					
				}
				
				if( self.refreshRate == 0 )
					self.refreshRate = 10;
				
				self.isLoadingXml = NO;
				self.connectionErrorMsg = nil;
				self.hasEstablishedSuccessfulConnectionThisSession = NO;

				sharedTedometerData = self;
            }
        }
    }
    return sharedTedometerData;
}

- (id)copyWithZone:(NSZone *)zone { return self; }

- (id)retain { return self; }

- (unsigned)retainCount { return UINT_MAX; }

- (oneway void)release {}

- (id)autorelease { return self; }
// ----------------------------------------------------------------------


- (NSInteger) curMeterTypeIdx {
	return curMeterTypeIdx;
}


- (void) setCurMeterTypeIdx:(NSInteger) value {
	curMeterTypeIdx = value;
}

	
NSString* _archiveLocation;

+ (NSString*)archiveLocation
{
	if (_archiveLocation == nil) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		_archiveLocation = [[documentsDirectory stringByAppendingPathComponent:@"TedometerData.plist" ] retain];       
	}
	return _archiveLocation;
}
							
+ (TedometerData *) unarchiveFromDocumentsFolder {
	TedometerData *tedometerData = [NSKeyedUnarchiver unarchiveObjectWithFile:[TedometerData archiveLocation]];
	return tedometerData;

}	

+ (BOOL) archiveToDocumentsFolder {
	BOOL result = NO;
	if( sharedTedometerData )
		result = [NSKeyedArchiver archiveRootObject:sharedTedometerData toFile:[TedometerData archiveLocation]];
	return result;
}

- (NSInteger) mtuCount;
{
	return mtuCount;
}

- (NSInteger) meterCount;
{
	return mtuCount == 1 ? 1 : mtuCount + 1;
}

- (void) setMtuCount:(NSInteger)value;
{
	BOOL sendNotification = NO;
	if( value != mtuCount )
		sendNotification = YES;
	mtuCount = value;
	
	if( sendNotification ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationMtuCountDidChange object:self];
	}
}

- (Meter*) curMeter {
	Meter *meter = [[mtusArray objectAtIndex: curMeterTypeIdx] objectAtIndex:curMtuIdx];
	NSLog(@"curMeter = %@ MTU%d", [meter meterTitle], [meter mtuNumber] );
	return meter;
}

- (void) activatePowerMeter {
	self.curMeterTypeIdx = kPowerMeterIdx;
}

- (void) activateCostMeter {
	self.curMeterTypeIdx = kCostMeterIdx;
}

- (void) activateCarbonMeter {
	self.curMeterTypeIdx = kCarbonMeterIdx;
}

- (void) activateVoltageMeter {
	self.curMeterTypeIdx = kVoltageMeterIdx;
}

- (NSInteger) billingCycleStartMonth {
	
	// LiveData.xml provides the gateway day and month and billing cycle end day, but not the
	// current billing cycle start month. To derive it, we check whether the current day
	// is before the billing cycle end day, and if so, rewind one month.
	
	int month = self.gatewayMonth;
	
	int curDay = self.gatewayDayOfMonth;
	if( month != 0 && curDay != 0 && curDay < self.meterReadDate ) {
		month -= 1;
		if( month == 0 )
			month = 12;
	}
	
	return month;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:mtusArray forKey:@"mtusArray"];
	[encoder encodeInteger:refreshRate forKey:@"refreshRate"];
	[encoder encodeObject:gatewayHost forKey:@"gatewayHost"];
	[encoder encodeObject:username forKey:@"username"];
	[encoder encodeObject:password forKey:@"password"];
	[encoder encodeBool:useSSL forKey:@"useSSL"];
	[encoder encodeInteger:curMeterTypeIdx forKey:@"curMeterTypeIdx"];
	[encoder encodeInteger:curMtuIdx forKey:@"curMtuIdx"];
	[encoder encodeBool:isShowingTodayStatistics forKey:@"isShowingTodayStatistics"];
	[encoder encodeBool:isAutolockDisabledWhilePluggedIn forKey:@"isAutolockDisabledWhilePluggedIn"];
	[encoder encodeInteger:hasDisplayedDialEditHelpMessage forKey:@"hasDisplayedDialEditHelpMessage"];
	[encoder encodeBool:isPatchingAggregationDataSelected forKey:@"isPatchingAggregationDataSelected"];
}

- (id) initWithCoder:(NSCoder*)decoder {
	if (self = [super init]) {
		self.mtusArray = [decoder decodeObjectForKey:@"mtusArray"];
		self.refreshRate = [decoder decodeIntegerForKey:@"refreshRate"];
		self.gatewayHost = [decoder decodeObjectForKey:@"gatewayHost"];
		self.username = [decoder decodeObjectForKey:@"username"];
		self.password = [decoder decodeObjectForKey:@"password"];
		self.useSSL = [decoder decodeBoolForKey:@"useSSL"];
		curMeterTypeIdx = [decoder decodeIntegerForKey:@"curMeterTypeIdx"];
		curMtuIdx = [decoder decodeIntegerForKey:@"curMtuIdx"];
		self.isShowingTodayStatistics = [decoder decodeBoolForKey:@"isShowingTodayStatistics"];
		self.isAutolockDisabledWhilePluggedIn = [decoder decodeBoolForKey:@"isAutolockDisabledWhilePluggedIn"];
		self.hasDisplayedDialEditHelpMessage = [decoder decodeIntegerForKey:@"hasDisplayedDialEditHelpMessage"];
		self.isPatchingAggregationDataSelected = [decoder decodeBoolForKey:@"isPatchingAggregationDataSelected"];
	}
	return self;
}

- (Meter*) nextMtu {
	NSInteger newIdx = curMtuIdx + 1;
	if( newIdx >= NUM_MTUS )
		newIdx = 0;
	
	self.curMtuIdx = newIdx;
	return [[mtusArray objectAtIndex: curMeterTypeIdx] objectAtIndex:curMtuIdx];
}

- (Meter*) prevMtu {
	NSInteger newIdx = curMtuIdx - 1;
	if( newIdx < 0 )
		newIdx = NUM_MTUS -1;
	
	self.curMtuIdx = newIdx;
	
	return [[mtusArray objectAtIndex: curMeterTypeIdx] objectAtIndex:curMtuIdx];
}

-(Meter*) nextMeterType {
	NSInteger newIdx = curMeterTypeIdx + 1;
	if( newIdx >= NUM_METER_TYPES )
		newIdx = 0;
	
	self.curMeterTypeIdx = newIdx;
	return [[mtusArray objectAtIndex: curMeterTypeIdx] objectAtIndex:curMtuIdx];
}

-(Meter*) prevMeterType {
	NSInteger newIdx = curMeterTypeIdx - 1;
	if( newIdx < 0 )
		newIdx = NUM_METER_TYPES -1;
	
	self.curMeterTypeIdx = newIdx;
	
	return [[mtusArray objectAtIndex: curMeterTypeIdx] objectAtIndex:curMtuIdx];
}

-(void) reloadXmlDocumentInBackground {
	
	self.connectionErrorMsg = nil;
	
	if( self.isDialBeingEdited ) {
		// aggressively reloading (e.g., every 2 seconds) while the dial is being edited seems to crash the app
		return;
	}
	else if( self.isApplicationInactive ) {
		return;
	}
	else if( self.gatewayHost == nil || [self.gatewayHost isEqualToString:@""] ) {
		// Don't display the error message if we haven't shown the flipside this session;
		// we'll show the flipside automatically for them to provide it.
		
		self.connectionErrorMsg = @"No gateway address provided";
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationConnectionFailure object:self];
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDocumentReloadWillBegin object:self];

	self.isLoadingXml = YES;
	self.connectionErrorMsg = nil;
	
	NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(reloadXmlDocument) object:nil];
	[[(TedometerAppDelegate *)[[UIApplication sharedApplication] delegate] sharedOperationQueue] addOperation:op];
	[op release];
}


-(void) reloadXmlDocument {
	
	DLog(@"Reloading XML Document..." );

	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init]; 

	NSString *urlString;
	BOOL usingDemoAccount = NO;
	if( [@"theenergydetective.com" isEqualToString: [self.gatewayHost lowercaseString]]
	   || [@"www.theenergydetective.com" isEqualToString: [self.gatewayHost lowercaseString]] ) 
	{
		usingDemoAccount = YES;
	}
	
	if( usingDemoAccount ) {
		urlString = @"http://www.theenergydetective.com/media/5000LiveData.xml";
    }
	else {
		urlString = [NSString stringWithFormat:@"%@://%@/api/LiveData.xml", self.useSSL ? @"https" : @"http", self.gatewayHost];
    }

    BOOL success = NO;
    NSError *error = nil;
    NSString *responseContent = nil;
	
    if( [self.gatewayHost hasPrefix:@"Data/"] ) {
        // Use test data
        urlString = [self.gatewayHost stringByAppendingString: @".xml"];    // used for error reporting (below)
        NSString *path = [[NSBundle mainBundle] pathForResource:self.gatewayHost ofType:@"xml"];
        responseContent = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &error];
    }
    else {
	
        NSURL *url = [NSURL URLWithString: urlString];
        
        ALog(@"Attempting connection with URL %@", url);
        
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setUseSessionPersistence:NO];
        if( ! usingDemoAccount ) {
            if( self.useSSL ) 
                [request setValidatesSecureCertificate:NO];
            [request setUsername:self.username];
            [request setPassword:self.password];
        }
        
        [request start];
        error = [request error];
        if (!error) {
            responseContent = [request responseString];
        }
    }
    
    if( !error ) {
		
		CXMLDocument *newDocument = [[[CXMLDocument alloc] initWithXMLString:responseContent options:0 error:&error] retain];
		if( newDocument ) {
			success = YES;
			self.connectionErrorMsg = nil;
			[self refreshDataFromXmlDocument: newDocument];
			
			self.hasEstablishedSuccessfulConnectionThisSession = YES;
			
		}
	}
	
	if( ! success ) {
		if( [[error domain] isEqualToString:@"CXMLErrorDomain"] ) {
			self.connectionErrorMsg = [NSString stringWithFormat:@"Unable to parse data from %@", urlString];
		}
		else {
			self.connectionErrorMsg = [error localizedDescription];
		}
		ALog( @"%@", self.connectionErrorMsg);
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationConnectionFailure object:self];

	}
	[self clearIsLoadingXmlFlag];
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDocumentReloadDidFinish object:self];
	
	[autoreleasePool drain];

}

- (void) clearIsLoadingXmlFlag {
	
	// In 2.0, when we were observing isLoadingXml in the MeterViewController, self.isLoadingXml = NO 
	// seemed to cause exceptions at times. This method is an attempt to catch and ignore (but note) those
	// exceptions, since they aren't really fatal.
	//
	// Now that we use notifications instead, this property isn't used. Keeping it in case it becomes useful.
	@try {
		self.isLoadingXml = NO;
	}
	@catch( NSException *exception ) {
		NSString *msg = [NSString stringWithFormat: @"%@ in %s", [exception name], __PRETTY_FUNCTION__ ];
		[Flurry logError: [exception name] message:msg exception:exception];
	}
}

- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document {

	BOOL isSuccessful = NO;

	NSDictionary* gatewayTimeNodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys: 
										   @"Hour", @"gatewayHour", 
										   @"Minute", @"gatewayMinute", 
										   @"Month", @"gatewayMonth", 
										   @"Day", @"gatewayDayOfMonth", 
										   @"Year", @"gatewayYear", 
										   nil];
	isSuccessful = [TedometerData loadIntegerValuesFromXmlDocument:document intoObject:self withParentNodePath:@"GatewayTime" 
										  andNodesKeyedByProperty:gatewayTimeNodesKeyedByProperty];

	if( isSuccessful ) {
		NSDictionary* utilityNodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys: 
														 @"CarbonRate", @"carbonRate", 
														 @"CurrentRate", @"currentRate", 
														 @"MeterReadDate", @"meterReadDate", 
														 @"DaysLeftInBillingCycle", @"daysLeftInBillingCycle", 
														 nil];
		isSuccessful = [TedometerData loadIntegerValuesFromXmlDocument:document intoObject:self withParentNodePath:@"Utility" 
										   andNodesKeyedByProperty:utilityNodesKeyedByProperty];
	}
	
	if( isSuccessful ) {
		NSDictionary* systemNodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys: 
													 @"NumberMTU", @"mtuCount", 
													 nil];
		isSuccessful = [TedometerData loadIntegerValuesFromXmlDocument:document intoObject:self withParentNodePath:@"System" 
											   andNodesKeyedByProperty:systemNodesKeyedByProperty];
	}
	
	if( isSuccessful ) {
		
		for( NSArray *mtuArray in mtusArray ) {
			for( Meter *aMeter in mtuArray ) {
				DLog(@"Refreshing data for meter %@ MTU%d...", [aMeter meterTitle], [aMeter mtuNumber]);
				isSuccessful = [aMeter refreshDataFromXmlDocument:document];
				if( ! isSuccessful )
					break;
			}
			if( ! isSuccessful )
				break;
		}
	}
	return isSuccessful;
}

- (void) dealloc {
	self.mtusArray = nil;
	if( gatewayHost )
		[gatewayHost release];
	
	[super dealloc];
}

+ (CXMLNode *) nodeInXmlDocument:(CXMLDocument *)document atPath:(NSString*)nodePath {

	CXMLNode *node = [document rootElement];
	for( NSString* pathElement in [nodePath componentsSeparatedByString:@"."] ) {
		node = [node childNamed:pathElement];
		if( node == nil ) {
			DLog( @"Could not find node named '%@' at path '%@'.", pathElement, nodePath );
			break;
		}
	}
	return node;
}

+ (BOOL)loadIntegerValuesFromXmlDocument:(CXMLDocument *)document intoObject:(NSObject*) object withParentNodePath:(NSString*)parentNodePath andNodesKeyedByProperty:(NSDictionary*)nodesKeyedByPropertyDict {
	
	BOOL isSuccessful = NO; 

	CXMLNode *parentNode = [TedometerData nodeInXmlDocument:document atPath:parentNodePath];

	if( parentNode ) {
		isSuccessful = YES;
		for( NSString *aPropertyName in [nodesKeyedByPropertyDict allKeys] ) {
			NSString *aNodeName = [nodesKeyedByPropertyDict objectForKey:aPropertyName];
			CXMLNode *aNode = [parentNode childNamed:aNodeName];
			NSInteger aValue;
			if( aNode == nil ) {
				DLog(@"Could not find node named '%@' at path '%@'. Defaulting to 0.", aNodeName, parentNodePath);
				aValue = 0;
			}
			else {
				aValue = [[aNode stringValue] integerValue];
			}
			
			NSNumber *aNumberObject = [[NSNumber alloc] initWithInteger:aValue];
			[object setValue:aNumberObject forKey:aPropertyName];
			[aNumberObject release];
		}
	}
	
	return isSuccessful;
}


+ (BOOL) fixNetMeterValuesFromXmlDocument:(CXMLDocument*) document 
							   intoObject:(Meter*) meterObject 
					  withParentMeterNode:(NSString*)parentNode 
				  andNodesKeyedByProperty:(NSDictionary*)netMeterFixNodesKeyedByProperty 
							 usingAggregationOp:(AggregationOp)aggregationOp
{
	BOOL isSuccessful = YES;
	
	
	int mtuCount = [TedometerData sharedTedometerData].mtuCount;
	if( [TedometerData sharedTedometerData].isPatchingAggregationDataSelected && mtuCount > 1 ) {
		
		NSMutableDictionary *mtuTotalsKeyedByProperty = [[NSMutableDictionary alloc] initWithCapacity: [netMeterFixNodesKeyedByProperty allKeys].count];
		
		for( NSInteger i=0; i < mtuCount; ++i ) {
			NSString *mtuNodePath = [NSString stringWithFormat:@"%@.MTU%d", parentNode, i+1];
			CXMLNode *mtuNode = [TedometerData nodeInXmlDocument:document atPath:mtuNodePath];
			if( ! mtuNode ) {
				isSuccessful = NO;
				continue;
			}
			
			for( NSString *aPropertyName in [netMeterFixNodesKeyedByProperty allKeys] ) {
				NSString *aNodeName = [netMeterFixNodesKeyedByProperty objectForKey:aPropertyName];
				CXMLNode *aNode = [mtuNode childNamed:aNodeName];
				NSInteger aValue;
				if( aNode == nil ) {
					DLog(@"No node found at %@.%@", mtuNodePath, aNodeName );
				}
				if( aNode != nil ) {
					aValue = [[aNode stringValue] integerValue];

					NSNumber *prevValueObject = [mtuTotalsKeyedByProperty objectForKey:aPropertyName];
					if( prevValueObject ) {
						NSInteger prevValue = [prevValueObject integerValue];
						switch( aggregationOp ) {
							case kAggregationOpSum: aValue += prevValue; break;
							case kAggregationOpMax: aValue = MAX( aValue, prevValue ); break;
							case kAggregationOpMin: aValue = MIN( aValue, prevValue ); break;
							default: {
								NSException *e = [NSException exceptionWithName:@"UnrecognizedArgumentException" reason:[NSString stringWithFormat:@"Unrecognized AggregationOp: %d", aggregationOp] userInfo:nil];
								[e raise];
							}
						}
					}
					
					prevValueObject = [[NSNumber alloc] initWithInteger:aValue];
					[mtuTotalsKeyedByProperty setValue:prevValueObject forKey:aPropertyName];
					[prevValueObject release];
				}
				
			}
		}
	
		for( NSString *aPropertyName in [netMeterFixNodesKeyedByProperty allKeys] ) {
			NSNumber *prevValueObject = [mtuTotalsKeyedByProperty objectForKey:aPropertyName];
			if( prevValueObject ) {
				[meterObject setValue:prevValueObject forKey:aPropertyName];
			}
		}
		
		[mtuTotalsKeyedByProperty release];
	}

	return isSuccessful;
}

@end
