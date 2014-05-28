//
//  TedometerData.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

//#define USE_TEST_DATA	0

#import "TedometerData.h"
#import "DataLoader.h"
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
#import "TED5000DataLoader.h"
#import "TED6000DataLoader.h"
#import "CXMLNode-utils.h"


#define kPowerMeterIdx		0
#define kCostMeterIdx		1
#define kCarbonMeterIdx 	2
#define kVoltageMeterIdx	3

#define kUnusedArchiveEntryValue @"<unused>"

@interface TedometerData()
@end
	
@implementation TedometerData

@synthesize mtusArray;
@synthesize refreshRate;
@synthesize gatewayHost;
@synthesize username;
@synthesize password;
@synthesize useSSL;
@synthesize tedModel;
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
@synthesize connectionErrorMsg;
@synthesize isApplicationInactive;
@synthesize isShowingTodayStatistics;
@synthesize detectedHardwareType;
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

+ (id)alloc
{
    Class myClass = [self class];
    @synchronized(myClass) {
        if (sharedTedometerData == nil) {
            return [super alloc];
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
				DLog( @"tedometerData.curMeterTypeIdx = %ld", (long)tedometerData.curMeterTypeIdx );
				
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

- (NSUInteger)retainCount { return UINT_MAX; }

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

    if( tedometerData.username && ! [tedometerData.username isEqualToString:kUnusedArchiveEntryValue] ) {
        // upgrading from version that didn't store username/password in keychain
        [UICKeyChainStore setString:tedometerData.username forKey:@"username"];
        [UICKeyChainStore setString:tedometerData.password forKey:@"password"];
    }
    tedometerData.username = [UICKeyChainStore stringForKey:@"username"];
    tedometerData.password = [UICKeyChainStore stringForKey:@"password"];
	return tedometerData;

}	

+ (BOOL) archiveToDocumentsFolder {
	BOOL result = NO;
	if( sharedTedometerData ) {

        [UICKeyChainStore setString:sharedTedometerData.username forKey:@"username"];
        [UICKeyChainStore setString:sharedTedometerData.password forKey:@"password"];
		result = [NSKeyedArchiver archiveRootObject:sharedTedometerData toFile:[TedometerData archiveLocation]];
    }
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
	NSLog(@"curMeter = %@ MTU%ld", [meter meterTitle], (long)[meter mtuNumber] );
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
	
	long month = self.gatewayMonth;
	
	long curDay = self.gatewayDayOfMonth;
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
    // we used to encode username and password here, so blank them out just in case
	[encoder encodeObject:kUnusedArchiveEntryValue forKey:@"username"];
	[encoder encodeObject:kUnusedArchiveEntryValue forKey:@"password"];
	[encoder encodeBool:useSSL forKey:@"useSSL"];
	[encoder encodeInteger:curMeterTypeIdx forKey:@"curMeterTypeIdx"];
	[encoder encodeInteger:curMtuIdx forKey:@"curMtuIdx"];
	[encoder encodeBool:isShowingTodayStatistics forKey:@"isShowingTodayStatistics"];
	[encoder encodeBool:isAutolockDisabledWhilePluggedIn forKey:@"isAutolockDisabledWhilePluggedIn"];
	[encoder encodeInteger:hasDisplayedDialEditHelpMessage forKey:@"hasDisplayedDialEditHelpMessage"];
	[encoder encodeBool:isPatchingAggregationDataSelected forKey:@"isPatchingAggregationDataSelected"];
    [encoder encodeInteger:detectedHardwareType forKey:@"detectedHardwareType"];
}

- (id) initWithCoder:(NSCoder*)decoder {
	if (self = [super init]) {
		self.mtusArray = [decoder decodeObjectForKey:@"mtusArray"];
		self.refreshRate = [decoder decodeIntegerForKey:@"refreshRate"];
		self.gatewayHost = [decoder decodeObjectForKey:@"gatewayHost"];

        // Here we unarchive entries for username and password, so that we can use them
        // if upgrading from a version that didn't store them in the keychain.
        // If we HAVE already upgraded, these entries will be set to @"<unused>".
        // The calling method (unarchiveFromDocumentFolder:) will take care of
        // initiating them from the Keychain.
		self.username = [decoder decodeObjectForKey:@"username"];
		self.password = [decoder decodeObjectForKey:@"password"];

		self.useSSL = [decoder decodeBoolForKey:@"useSSL"];
		curMeterTypeIdx = [decoder decodeIntegerForKey:@"curMeterTypeIdx"];
		curMtuIdx = [decoder decodeIntegerForKey:@"curMtuIdx"];
		self.isShowingTodayStatistics = [decoder decodeBoolForKey:@"isShowingTodayStatistics"];
		self.isAutolockDisabledWhilePluggedIn = [decoder decodeBoolForKey:@"isAutolockDisabledWhilePluggedIn"];
		self.hasDisplayedDialEditHelpMessage = [decoder decodeIntegerForKey:@"hasDisplayedDialEditHelpMessage"];
		self.isPatchingAggregationDataSelected = [decoder decodeBoolForKey:@"isPatchingAggregationDataSelected"];
        self.detectedHardwareType = [decoder decodeIntegerForKey:@"detectedHardwareType"];
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

	self.connectionErrorMsg = nil;
	
	NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(reloadXmlDocument) object:nil];
	[[(TedometerAppDelegate *)[[UIApplication sharedApplication] delegate] sharedOperationQueue] addOperation:op];
	[op release];
}


-(void) reloadXmlDocument {
	
	DLog(@"Reloading XML Document..." );

    // TODO: Detect hardware type only if currently unknown or hardware failure occurs;
    // persist to storage or only for duration of app running?
    
    self.detectedHardwareType = [DataLoader detectHardwareTypeWithSettingsInTedometerData: self];
    
	NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];

    BOOL success = NO;

    DataLoader *dataLoader = nil;
    if( self.detectedHardwareType == kHardwareTypeTED5000 ) {
        dataLoader = [[TED5000DataLoader alloc] init];
    }
    else if( self.detectedHardwareType == kHardwareTypeTED6000 ) {
        dataLoader = [[TED6000DataLoader alloc] init];
    }
    else {
        success = NO;
        self.connectionErrorMsg = @"Unrecognized gateway";
    }
    
    if( dataLoader != nil ) {
        NSError *error = nil;
        success = [dataLoader reload:self error:&error ];
        [dataLoader release];
    
        if( success ) {
            self.connectionErrorMsg = nil;
            self.hasEstablishedSuccessfulConnectionThisSession = YES;
        }
        else {
            if( error ) {
                self.connectionErrorMsg = [error localizedDescription];
            }
            else {
                self.connectionErrorMsg = @"Unable to download data from gateway.";
            }
        }
    }
    
    if( ! success ) {
        ALog( @"%@", self.connectionErrorMsg);
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationConnectionFailure object:self];

    }
    
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDocumentReloadDidFinish object:self];
	DLog( "Finished loading XML document." );
	[autoreleasePool drain];

}


- (void) dealloc {
	self.mtusArray = nil;
	if( gatewayHost )
		[gatewayHost release];
	[super dealloc];
}


-(BOOL)isUsingDemoAccount;
{
    BOOL usingDemoAccount = NO;
    if( [@"tedometer.googlecode.com" isEqualToString: [self.gatewayHost lowercaseString]] ) {
        usingDemoAccount = YES;
    }
    return usingDemoAccount;
}


@end
