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

}

@property(readwrite, assign) NSInteger kva;

- (NSNumberFormatter *)tickLabelStringNumberFormatter;
- (NSNumberFormatter *)meterStringNumberFormatter;
- (NSNumberFormatter *)powerFactorFormatter;

@end
