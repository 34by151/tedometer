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

#define NUM_METERS	4

#define kPowerMeterIx		0
#define kCostMeterIdx		1
#define kCarbonMeterIdx 	2
#define kVoltageMeterIdx	3

@implementation TedometerData

@synthesize meters;
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

// ----------------------------------------------------------------------
// From http://www.cocoadev.com/index.pl?SingletonDesignPattern

static TedometerData *sharedTedometerData = nil;

+ (TedometerData*)sharedTedometerData
{
    @synchronized(self) {
        if (sharedTedometerData == nil) {
            [[self alloc] init];
        }
    }
    return sharedTedometerData;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
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
				
				if( [self.meters count] < NUM_METERS ) {
					NSMutableArray *newMeters = [[NSMutableArray alloc] init];
					[newMeters addObject: [[[PowerMeter alloc] init] autorelease]];
					[newMeters addObject: [[[CostMeter alloc] init] autorelease]];
					[newMeters addObject: [[[CarbonMeter alloc] init] autorelease]];
					[newMeters addObject: [[[VoltageMeter alloc] init] autorelease]];
					// TODO: Add other meters
					self.meters = newMeters;
					[newMeters release];
					
				}
				
				if( self.refreshRate == 0 )
					self.refreshRate = 10;

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

- (NSInteger) curMeterIdx {
	return curMeterIdx;
}

- (void) setCurMeterIdx:(NSInteger) value {
	// TODO: Adjust radians & units per meter of other meters based
	// on ration of now values of both meters (assume linear relationship).
	// If now value is 0, do not change (use defaults)
	
	
	Meter *newMeter = [meters objectAtIndex:value];
	Meter *currentMeter = [meters objectAtIndex:curMeterIdx];
	
	// voltage meter doesn't share the same scale
	if( curMeterIdx != kVoltageMeterIdx && value != kVoltageMeterIdx && newMeter.now > 0 && currentMeter.now > 0 ) {

		// using current radiansPerTick and meter position, calculate new unitsPerTick
		newMeter.radiansPerTick = currentMeter.radiansPerTick;
		newMeter.unitsPerTick = newMeter.now * (currentMeter.currentMaxMeterValue / (double) currentMeter.now) * (newMeter.radiansPerTick / (double) meterSpan);
	}
	curMeterIdx = value;
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
							
- (Meter*) curMeter {
	return [meters objectAtIndex:curMeterIdx];
}

- (void) activatePowerMeter {
	self.curMeterIdx = kPowerMeterIx;
}

- (void) activateCostMeter {
	self.curMeterIdx = kCostMeterIdx;
}

- (void) activateCarbonMeter {
	self.curMeterIdx = kCarbonMeterIdx;
}

- (void) activateVoltageMeter {
	self.curMeterIdx = kVoltageMeterIdx;
}


- (void) encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:meters forKey:@"meters"];
	[encoder encodeInteger:refreshRate forKey:@"refreshRate"];
	[encoder encodeObject:gatewayHost forKey:@"gatewayHost"];
	[encoder encodeObject:username forKey:@"username"];
	[encoder encodeObject:password forKey:@"password"];
	[encoder encodeBool:useSSL forKey:@"useSSL"];
	[encoder encodeInteger:curMeterIdx forKey:@"curMeterIdx"];
	[encoder encodeBool:isAutolockDisabledWhilePluggedIn forKey:@"isAutolockDisabledWhilePluggedIn"];
}

- (id) initWithCoder:(NSCoder*)decoder {
	if (self = [super init]) {
		self.meters = [decoder decodeObjectForKey:@"meters"];
		self.refreshRate = [decoder decodeIntegerForKey:@"refreshRate"];
		self.gatewayHost = [decoder decodeObjectForKey:@"gatewayHost"];
		self.username = [decoder decodeObjectForKey:@"username"];
		self.password = [decoder decodeObjectForKey:@"password"];
		self.useSSL = [decoder decodeBoolForKey:@"useSSL"];
		self.curMeterIdx = [decoder decodeIntegerForKey:@"curMeterIdx"];
		self.isAutolockDisabledWhilePluggedIn = [decoder decodeBoolForKey:@"isAutolockDisabledWhilePluggedIn"];
	}
	return self;
}

-(Meter*) nextMeter {
	NSInteger newIdx = curMeterIdx + 1;
	if( newIdx >= [meters count] )
		newIdx = 0;
	
	self.curMeterIdx = newIdx;
	
	return [meters objectAtIndex: newIdx];
}

-(Meter*) prevMeter {
	NSInteger newIdx = curMeterIdx - 1;
	if( newIdx < 0 )
		newIdx = [meters count] - 1;
	
	self.curMeterIdx = newIdx;
	
	return [meters objectAtIndex: newIdx];
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
		for( Meter *aMeter in self.meters ) {
			isSuccessful = [aMeter refreshDataFromXmlDocument:document];
			if( ! isSuccessful )
				break;
		}
	}
	return isSuccessful;
}

- (void) dealloc {
	[meters release];
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
			if( aNode == nil ) {
				NSLog(@"Could not find node named '%@' at path '%@'.", aNodeName, parentNodePath);
				isSuccessful = NO;
				break;
			}
			else {
			
				NSInteger aValue = [[aNode stringValue] integerValue];
				NSNumber *aNumberObject = [[NSNumber alloc] initWithInteger:aValue];
				[object setValue:aNumberObject forKey:aPropertyName];
				[aNumberObject release];
			}
		}
	}
	
	return isSuccessful;
}


@end
