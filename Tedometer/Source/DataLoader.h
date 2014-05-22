//
//  DataLoader.h
//  Ted-O-Meter
//
//  Created by Nathan on 4/29/14.
//
//

#import <Foundation/Foundation.h>
#import "TedometerData.h"

@interface DataLoader : NSObject {
}

-(BOOL)reload:(TedometerData*)tedometerData error:(NSError**)error;
+(HardwareType)detectHardwareTypeWithSettingsInTedometerData:(TedometerData *)tedometerData;


@end
