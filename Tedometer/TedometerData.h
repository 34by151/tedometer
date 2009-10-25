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
}

@property(readwrite, nonatomic, retain) NSArray* meters;
@property(readwrite, assign) NSInteger refreshRate;
@property(readwrite, retain) NSString* gatewayHost;
@property(readwrite, assign) NSInteger curMeterIdx;

+ (TedometerData *) sharedTedometerData;

- (Meter*) curMeter;
- (Meter*) nextMeter;
- (Meter*) prevMeter;
- (void)refreshDataFromXmlDocument:(CXMLDocument *)document;

- (void) encodeWithCoder:(NSCoder*)encoder;
- (id) initWithCoder:(NSCoder*)decoder;

+ (NSString*)archiveLocation;
+ (TedometerData *) unarchiveFromDocumentsFolder;
+ (BOOL) archiveToDocumentsFolder;

@end
