//
//  TedometerData.m
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TedometerData.h"
#import "PowerMeter.h"
#import "SynthesizeSingleton.h"

@implementation TedometerData

@synthesize meters;
@synthesize refreshRate;
@synthesize gatewayHost;
@synthesize curMeterIdx;


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
				else {
					
					self.refreshRate = 3;
					NSMutableArray *newMeters = [[NSMutableArray alloc] init];
					[newMeters addObject: [[[PowerMeter alloc] init] autorelease]];
					// TODO: Add other meters
					self.meters = newMeters;
					[newMeters release];
				}
				
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
							
-(Meter*) curMeter {
	return nil;
}

- (void) encodeWithCoder:(NSCoder*)encoder {
	[encoder encodeObject:meters forKey:@"meters"];
	[encoder encodeInteger:refreshRate forKey:@"refreshRate"];
	[encoder encodeObject:gatewayHost forKey:@"gatewayHost"];
	[encoder encodeInteger:curMeterIdx forKey:@"curMeterIdx"];
}

- (id) initWithCoder:(NSCoder*)decoder {
	if (self = [super init]) {
		self.meters = [decoder decodeObjectForKey:@"meters"];
		self.refreshRate = [decoder decodeIntegerForKey:@"refreshRate"];
		self.gatewayHost = [decoder decodeObjectForKey:@"gatewayHost"];
		self.curMeterIdx = [decoder decodeIntegerForKey:@"curMeterIdx"];
	}
	return self;
}

-(Meter*) nextMeter {
	NSInteger newIdx = curMeterIdx + 1;
	if( newIdx >= [meters count] )
		newIdx = 0;
	
	curMeterIdx = newIdx;
	
	return [meters objectAtIndex: newIdx];
}

-(Meter*) prevMeter {
	NSInteger newIdx = curMeterIdx - 1;
	if( newIdx < 0 )
		newIdx = [meters count] - 1;
	
	curMeterIdx = newIdx;
	
	return [meters objectAtIndex: newIdx];
}

- (void)refreshDataFromXmlDocument:(CXMLDocument *)document {
	for( Meter *aMeter in self.meters )
		[aMeter refreshDataFromXmlDocument:document];
}

@end
