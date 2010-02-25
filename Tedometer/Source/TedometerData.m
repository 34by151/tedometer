//
//  TedometerData.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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

#define kPowerMeterIdx		0
#define kCostMeterIdx		1
#define kCarbonMeterIdx 	2
#define kVoltageMeterIdx	3

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
@synthesize hasShownFlipsideThisSession;
@synthesize isLoadingXml;
@synthesize connectionErrorMsg;
@synthesize isApplicationInactive;
@synthesize isShowingTodayStatistics;

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

				sharedTedometerData = self;
            }
        }
    }
    return sharedTedometerData;
}

- (id)copyWithZone:(NSZone *)zone { return self; }

- (id)retain { return self; }

- (unsigned)retainCount { return UINT_MAX; }

- (void)release {}

- (id)autorelease { return self; }
// ----------------------------------------------------------------------


- (NSInteger) curMeterTypeIdx {
	return curMeterTypeIdx;
}


- (void) setCurMeterTypeIdx:(NSInteger) value {
	// Adjust radians & units per meter of other meters based
	// on ratiox of now values of both meters (assume linear relationship).
	// If now value is 0, do not change (use defaults)
	
	
	//Meter *currentMeter = [[mtusArray objectAtIndex: curMeterTypeIdx] objectAtIndex:curMtuIdx];
	//Meter *newMeter = [[mtusArray objectAtIndex: value] objectAtIndex:curMtuIdx];
	
	/*
	// voltage meter doesn't share the same scale
	if( curMeterTypeIdx != kVoltageMeterIdx && value != kVoltageMeterIdx && newMeter.now > 0 && currentMeter.now > 0 ) {

		// using current radiansPerTick and meter position, calculate new unitsPerTick
		newMeter.radiansPerTick = currentMeter.radiansPerTick;
		if( currentMeter.now == 0.0 ) {
			newMeter.unitsPerTick = [newMeter meterEndMin] / 10.0;
			newMeter.radiansPerTick = meterSpan / [newMeter meterEndMin] / newMeter.unitsPerTick;
			
		}
		else
			newMeter.unitsPerTick = newMeter.now * (currentMeter.currentMaxMeterValue / (double) currentMeter.now) * (newMeter.radiansPerTick / (double) meterSpan);
	}
	 */
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


- (void) encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:mtusArray forKey:@"mtusArray"];
	[encoder encodeInteger:refreshRate forKey:@"refreshRate"];
	[encoder encodeObject:gatewayHost forKey:@"gatewayHost"];
	[encoder encodeObject:username forKey:@"username"];
	[encoder encodeObject:password forKey:@"password"];
	[encoder encodeBool:useSSL forKey:@"useSSL"];
	[encoder encodeInteger:curMeterTypeIdx forKey:@"curMeterTypeTypeIdx"];
	[encoder encodeInteger:curMtuIdx forKey:@"curMtuIdx"];
	[encoder encodeBool:isShowingTodayStatistics forKey:@"isShowingTodayStatistics"];
	[encoder encodeBool:isAutolockDisabledWhilePluggedIn forKey:@"isAutolockDisabledWhilePluggedIn"];
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
	
	if( self.isApplicationInactive || self.gatewayHost == nil || [self.gatewayHost isEqualToString:@""] ) {
		// don't show the error message if the gateway host is empty and we haven't yet shown the flip side this session,
		// since we'll be showing them the flip side automatically to let them enter the host.
		if( self.hasShownFlipsideThisSession ) {
			//[self showWarningIcon];
		}
		return;
	}
	
	//NSLog(@"Refreshing MainView data..." );
	//[self hideWarningIcon];
	//[activityIndicator startAnimating];
	NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(reloadXmlDocument) object:nil];
	[[(TedometerAppDelegate *)[[UIApplication sharedApplication] delegate] sharedOperationQueue] addOperation:op];
	[op release];
	self.isLoadingXml = YES;
}


-(void) reloadXmlDocument {
	
	NSLog(@"Reloading XML Document..." );
	
	NSString *urlString;
	BOOL usingDemoAccount = NO;
	if( [@"theenergydetective.com" isEqualToString: [self.gatewayHost lowercaseString]]
	   || [@"www.theenergydetective.com" isEqualToString: [self.gatewayHost lowercaseString]] ) 
	{
		usingDemoAccount = YES;
	}
	
	if( usingDemoAccount )
		urlString = @"http://www.theenergydetective.com/media/5000LiveData.xml";
	else 
		urlString = [NSString stringWithFormat:@"%@://%@/api/LiveData.xml", self.useSSL ? @"https" : @"http", self.gatewayHost];
	
	///////////////////
	// OVERRIDE FOR TESTING
	//urlString = @"http://crush.hadfieldfamily.com/ted5000/LiveDataTest.xml";
	//usingDemoAccount = YES;
	///////////////////
	
    NSURL *url = [NSURL URLWithString: urlString];
	
	NSLog(@"Attempting connection with URL %@", url);
	BOOL success = NO;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setUseSessionPersistance:NO];
	if( ! usingDemoAccount ) {
		if( self.useSSL ) 
			[request setValidatesSecureCertificate:NO];
		[request setUsername:self.username];
		[request setPassword:self.password];
	}
	
	[request start];
	NSError *error = [request error];
	if (!error) {
		NSString *response = [request responseString];
		
		CXMLDocument *newDocument = [[[CXMLDocument alloc] initWithXMLString:response options:0 error:&error] retain];
		if( newDocument ) {
			success = YES;
			self.connectionErrorMsg = nil;
			[self refreshDataFromXmlDocument: newDocument];
			
			//[self performSelectorOnMainThread:@selector(stopActivityIndicator) withObject:self waitUntilDone:NO];
			//[self performSelectorOnMainThread:@selector(hideWarningIcon) withObject:self waitUntilDone:NO];
			//[self performSelectorOnMainThread:@selector(refreshView) withObject:self waitUntilDone:NO];
		}
	}
	
	if( ! success ) {
		if( [[error domain] isEqualToString:@"CXMLErrorDomain"] ) {
			self.connectionErrorMsg = [NSString stringWithFormat:@"Unable to parse data from %@", url];
		}
		else {
			self.connectionErrorMsg = [error localizedDescription];
		}
		NSLog( @"%@", self.connectionErrorMsg);
		//[self performSelectorOnMainThread:@selector(stopActivityIndicator) withObject:self waitUntilDone:YES];
		//[self performSelectorOnMainThread:@selector(showWarningIcon) withObject:self waitUntilDone:YES];
	}
	
	// NOTE: Since this method runs in a separate thread, may need to set this with a separate method, invoked with performSelectorOnMainThread:
	self.isLoadingXml = NO;
	
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
				NSLog(@"Refreshing data for meter %@ MTU%d...", [aMeter meterTitle], [aMeter mtuNumber]);
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

+ (BOOL)loadIntegerValuesFromXmlDocument:(CXMLDocument *)document intoObject:(NSObject*) object withParentNodePath:(NSString*)parentNodePath andNodesKeyedByProperty:(NSDictionary*)nodesKeyedByPropertyDict {
	
	BOOL isSuccessful = NO; 
	
	CXMLNode *parentNode = [document rootElement];
	for( NSString* pathElement in [parentNodePath componentsSeparatedByString:@"."] ) {
		parentNode = [parentNode childNamed:pathElement];
		if( parentNode == nil ) {
			NSLog( @"Could not find node named '%@' in path '%@'.", pathElement, parentNodePath );
			break;
		}
	}
	
	if( parentNode ) {
		isSuccessful = YES;
		for( NSString *aPropertyName in [nodesKeyedByPropertyDict allKeys] ) {
			NSString *aNodeName = [nodesKeyedByPropertyDict objectForKey:aPropertyName];
			CXMLNode *aNode = [parentNode childNamed:aNodeName];
			NSInteger aValue;
			if( aNode == nil ) {
				NSLog(@"Could not find node named '%@' at path '%@'. Defaulting to 0.", aNodeName, parentNodePath);
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


@end
