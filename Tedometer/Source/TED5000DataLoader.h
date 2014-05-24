//
//  TED5000DataLoader.h
//  Ted-O-Meter
//
//  Created by Nathan on 5/17/14.
//
//

#import <Foundation/Foundation.h>
#import "DataLoader.h"

@interface TED5000DataLoader : DataLoader {
}

-(BOOL)reload:(TedometerData*)tedometerData error:(NSError**)error;
+ (BOOL)fixNetMeterValuesFromXmlDocument:(CXMLDocument*) document
                              intoObject:(Meter*) meterObject
                     withParentMeterNode:(NSString*)parentNode
                 andNodesKeyedByProperty:(NSDictionary*)netMeterFixNodesKeyedByProperty
                      usingAggregationOp:(AggregationOp)aggregationOp;

@end
