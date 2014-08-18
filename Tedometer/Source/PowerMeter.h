//
//  PowerMeter.h
//  Ted-O-Meter
//
//  Created by Nathan on 10/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Meter.h"

@interface PowerMeter : Meter <NSCoding> {

	NSInteger kva;
    NSInteger phase;

}

@property(readwrite, assign) NSInteger kva;
@property(readwrite, assign) NSInteger phase;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumberFormatter *tickLabelStringNumberFormatter;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumberFormatter *meterStringNumberFormatter;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumberFormatter *powerFactorFormatter;

@end
