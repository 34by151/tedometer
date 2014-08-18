//
//  Meter.h
//  Ted-O-Meter
//
//  Created by Nathan on 10/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TouchXML.h"

typedef NS_ENUM(NSInteger, MeterValueType) {
	kMeterValueTypeNow,
	kMeterValueTypeHour,
	kMeterValueTypeToday,
	kMeterValueTypeMtd,
	kMeterValueTypeProjected
};

typedef NS_ENUM(NSInteger, TotalsMeterType) {
    kTotalsMeterTypeNet = 0,
    kTotalsMeterTypeLoad,
    kTotalsMeterTypeGen
};

@interface Meter : NSObject <NSCoding> {
	
	NSInteger mtuNumber;	// 0 if net meter
    NSString *mtuName;
	NSArray *mtuMeters;		// nil if isNetMeter == NO
    TotalsMeterType totalsMeterType;
	
	NSInteger now;
	NSInteger hour;
	NSInteger today;
	NSInteger mtd;
	NSInteger projected;
	
	NSInteger todayPeakValue;
	NSInteger todayPeakHour;
	NSInteger todayPeakMinute;
	NSInteger todayMinValue;
	NSInteger todayMinHour;
	NSInteger todayMinMinute;
	
	NSInteger mtdPeakValue;
	NSInteger mtdPeakMonth;
	NSInteger mtdPeakDay;
	NSInteger mtdMinValue;
	NSInteger mtdMinMonth;
	NSInteger mtdMinDay;

	double radiansPerTick;
	double unitsPerTick;
	double zeroAngle;
	
    BOOL isAverageSupported;
    BOOL isLowPeakSupported;
    BOOL isTotalsMeterTypeSelectionSupported;
    
    NSString *infoLabel;
    
	MeterValueType meterValueType;
    
}

@property(readonly) BOOL isNetMeter;
@property(readonly) NSInteger mtuNumber;
@property(readwrite, copy) NSString* mtuName;
@property(readwrite, assign) TotalsMeterType totalsMeterType;

@property(readwrite, assign) NSInteger now;
@property(readwrite, assign) NSInteger hour;
@property(readwrite, assign) NSInteger today;
@property(readwrite, assign) NSInteger mtd;
@property(readwrite, assign) NSInteger projected;
@property(readwrite, assign) NSInteger todayPeakValue;
@property(readwrite, assign) NSInteger todayPeakHour;
@property(readwrite, assign) NSInteger todayPeakMinute;
@property(readwrite, assign) NSInteger todayMinValue;
@property(readwrite, assign) NSInteger todayMinHour;
@property(readwrite, assign) NSInteger todayMinMinute;
@property(readwrite, assign) NSInteger mtdPeakValue;
@property(readwrite, assign) NSInteger mtdPeakMonth;
@property(readwrite, assign) NSInteger mtdPeakDay;
@property(readwrite, assign) NSInteger mtdMinValue;
@property(readwrite, assign) NSInteger mtdMinMonth;
@property(readwrite, assign) NSInteger mtdMinDay;
@property(readwrite, assign) double radiansPerTick;
@property(readwrite, assign) double unitsPerTick;
@property(readwrite, assign) double zeroAngle;
@property(readonly) NSInteger maxUnitsPerTick;
@property(readonly) NSInteger minUnitsPerTick;
@property(readonly) NSInteger defaultUnitsPerTick;
@property(readonly) NSInteger maxUnitsForOffset;
@property(readwrite, assign) MeterValueType meterValueType;
@property(readonly) NSString* meterTitle;
@property(readonly) NSString* meterTitleWithMtuNumber;
@property(readonly) NSString* todayPeakTimeString;
@property(readonly) NSString* todayMinTimeString;
@property(readonly) NSString* mtdPeakTimeString;
@property(readonly) NSString* mtdMinTimeString;
@property(readonly) double currentMaxMeterValue;
@property(readonly) NSInteger todayAverage;
@property(readonly) NSInteger monthAverage;
@property(readonly) NSString* todayLowLabel;
@property(readonly) NSString* todayAverageLabel;
@property(readonly) NSString* todayPeakLabel;
@property(readonly) NSString* todayTotalLabel;
@property(readonly) NSString* todayProjectedLabel;
@property(readonly) NSString* mtdLowLabel;
@property(readonly) NSString* mtdAverageLabel;
@property(readonly) NSString* mtdPeakLabel;
@property(readonly) NSString* mtdTotalLabel;
@property(readonly) NSString* mtdProjectedLabel;
@property(getter=infoLabel, setter=setInfoLabel:, readwrite, copy) NSString* infoLabel;
@property(readwrite, assign) BOOL isAverageSupported;
@property(readwrite, assign) BOOL isLowPeakSupported;
@property(readwrite, assign) BOOL isTotalsMeterTypeSelectionSupported;

- (instancetype) init NS_DESIGNATED_INITIALIZER;
- (instancetype) initWithMtuNumber:(NSInteger)mtuNum;
- (instancetype) initNetMeterWithMtuMeters: (NSArray*)meters;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (instancetype) initWithCoder:(NSCoder*)decoder;
- (NSInteger) valueForMeterValueType:(MeterValueType)unitType;
- (NSString *) tickLabelStringForInteger:(NSInteger) value;
- (NSString *) meterStringForInteger:(NSInteger) value; 
- (NSString *) timeStringForHour:(NSInteger)anHour minute:(NSInteger)aMinute;
- (NSString *) timeStringForMonth:(NSInteger)aMonth day:(NSInteger)aDay;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *instantaneousUnit;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *cumulativeUnit;
- (void) reset;


@end
