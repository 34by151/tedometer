//
//  TED6000DataLoader.h
//  Ted-O-Meter
//
//  Created by Nathan on 5/26/14.
//
//

#import <Foundation/Foundation.h>
#import "DataLoader.h"

@interface TED6000DataLoader : DataLoader {
    NSMutableDictionary* overviewData[NUM_MTUS];
}

-(BOOL)reload:(TedometerData*)tedometerData error:(NSError**)error;

@end
