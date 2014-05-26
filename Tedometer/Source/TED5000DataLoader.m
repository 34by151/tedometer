//
//  TED5000DataLoader.m
//  Ted-O-Meter
//
//  Created by Nathan on 5/17/14.
//
//

#import "TED5000DataLoader.h"
#import "ASIHTTPRequest.h"
#import "log.h"
#import "CXMLNode-utils.h"
#import "CXMLDocument+utils.h"
#import "VoltageMeter.h"
#import "CarbonMeter.h"
#import "CostMeter.h"
#import "PowerMeter.h"

// private
@interface DataLoader()
- (BOOL)refreshTedometerData:(TedometerData *)tedometerData fromXmlDocument:(CXMLDocument *)document;
- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document;
+ (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document intoVoltageMeter:(VoltageMeter *)meter;
+ (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document intoCostMeter:(CostMeter*)meter;
+ (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document intoCarbonMeter:(CarbonMeter*)meter;
+ (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document intoPowerMeter:(PowerMeter*)meter;

@end

@implementation TED5000DataLoader

-(BOOL)reload:(TedometerData*)tedometerData error:(NSError**)error;
{

	NSString *urlString;
    // Apple requires a demo account for testing -- just use the Google Code GIT repository for now.
	if( [tedometerData isUsingDemoAccount] ) {
		urlString = [NSString stringWithFormat:@"%@://tedometer.googlecode.com/git/Tedometer/Resources/Data/5000/1.xml", tedometerData.useSSL ? @"https" : @"http"];
    }
	else {
		urlString = [NSString stringWithFormat:@"%@://%@/api/LiveData.xml", tedometerData.useSSL ? @"https" : @"http", tedometerData.gatewayHost];
    }
    
    BOOL success = NO;
    NSError *localError = nil;
    NSString *responseContent = nil;
	
    if( [tedometerData.gatewayHost hasPrefix:@"Data/"] ) {
        // Use test data
        urlString = [tedometerData.gatewayHost stringByAppendingString: @".xml"];    // used for error reporting (below)
        NSString *path = [[NSBundle mainBundle] pathForResource:tedometerData.gatewayHost ofType:@"xml"];
        responseContent = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &localError];
    }
    else {
        
        NSURL *url = [NSURL URLWithString: urlString];
        
        ALog(@"Attempting connection with URL %@", url);
        
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setUseSessionPersistence:NO];
        if( ! [tedometerData isUsingDemoAccount] ) {
            if( tedometerData.useSSL )
                [request setValidatesSecureCertificate:NO];
            [request setUsername:tedometerData.username];
            [request setPassword:tedometerData.password];
        }
        
        [request startSynchronous];
        localError = [request error];
        if (!localError) {
            responseContent = [request responseString];
        }
    }
    
    // TODO: move connection error message handling up to calling method
    if( !localError ) {
		
		CXMLDocument *newDocument = [[[CXMLDocument alloc] initWithXMLString:responseContent options:0 error:&localError] retain];
		if( newDocument ) {
			success = YES;
			[self refreshTedometerData:tedometerData fromXmlDocument:newDocument];
		}
        else {
            if( localError && [[localError domain] isEqualToString:@"CXMLErrorDomain"] ) {
                localError = [NSError errorWithDomain:@"com.twistedrootsoftware.Ted-O-Meter"
                                             code:1
                                         userInfo:@{ NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Unable to parse data from %@", urlString],
                                                     NSLocalizedFailureReasonErrorKey: @"Error",
                                                     NSUnderlyingErrorKey: localError }];
                
            }
            else {
                
                NSDictionary *params = @{ NSLocalizedDescriptionKey: @"Failure while reading gateway data",
                                          NSLocalizedFailureReasonErrorKey: @"Error" };
                
                NSMutableDictionary *paramsWithUnderlyingError = [params mutableCopy];
                if( localError ) {
                    [paramsWithUnderlyingError setValue:localError forKey:NSUnderlyingErrorKey ];
                }
                
                localError = [NSError errorWithDomain:@"com.twistedrootsoftware.Ted-O-Meter"
                                             code:2
                                         userInfo:paramsWithUnderlyingError];
                
                [params release];
                [paramsWithUnderlyingError release];
            }
        }
	}
	

    if( !localError ) {
        *error = localError;
    }
    
    return localError == nil;
}

- (BOOL)refreshTedometerData:(TedometerData *)tedometerData fromXmlDocument:(CXMLDocument *)document;
{
    
	BOOL isSuccessful = NO;
    
	NSDictionary* gatewayTimeNodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     @"Hour", @"gatewayHour",
                                                     @"Minute", @"gatewayMinute",
                                                     @"Month", @"gatewayMonth",
                                                     @"Day", @"gatewayDayOfMonth",
                                                     @"Year", @"gatewayYear",
                                                     nil];
	isSuccessful = [document loadIntegerValuesIntoObject:tedometerData withParentNodePath:@"GatewayTime"
                                           andNodesKeyedByProperty:gatewayTimeNodesKeyedByProperty];
    
	if( isSuccessful ) {
		NSDictionary* utilityNodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     @"CarbonRate", @"carbonRate",
                                                     @"CurrentRate", @"currentRate",
                                                     @"MeterReadDate", @"meterReadDate",
                                                     @"DaysLeftInBillingCycle", @"daysLeftInBillingCycle",
                                                     nil];
		isSuccessful = [document loadIntegerValuesIntoObject:tedometerData withParentNodePath:@"Utility"
                                               andNodesKeyedByProperty:utilityNodesKeyedByProperty];
	}
	
	if( isSuccessful ) {
		NSDictionary* systemNodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"NumberMTU", @"mtuCount",
                                                    nil];
		isSuccessful = [document loadIntegerValuesIntoObject:tedometerData withParentNodePath:@"System"
											   andNodesKeyedByProperty:systemNodesKeyedByProperty];
	}
	
	if( isSuccessful ) {
		
		for( NSArray *mtuArray in tedometerData.mtusArray ) {
			for( Meter *aMeter in mtuArray ) {
				DLog(@"Refreshing data for meter %@ MTU%ld...", [aMeter meterTitle], (long)[aMeter mtuNumber]);
                if( [aMeter isMemberOfClass: [VoltageMeter class]] ) {
                    isSuccessful = [TED5000DataLoader refreshDataFromXmlDocument:document intoVoltageMeter:(VoltageMeter*)aMeter];
                }
                else if( [aMeter isMemberOfClass: [CarbonMeter class]] ) {
                    isSuccessful = [TED5000DataLoader refreshDataFromXmlDocument:document intoCarbonMeter:(CarbonMeter*)aMeter];
                }
                else if( [aMeter isMemberOfClass: [PowerMeter class]] ) {
                    isSuccessful = [TED5000DataLoader refreshDataFromXmlDocument:document intoPowerMeter:(PowerMeter*)aMeter];
                }
                else if( [aMeter isMemberOfClass: [CostMeter class]] ) {
                    isSuccessful = [TED5000DataLoader refreshDataFromXmlDocument:document intoCostMeter:(CostMeter*)aMeter];
                }
                else {
                    ALog(@"ERROR: Unrecognized meter type %@", [[aMeter class] description]);
                    isSuccessful = FALSE;
                }
                
				if( ! isSuccessful )
					break;
			}
			if( ! isSuccessful )
				break;
		}
	}
	return isSuccessful;
}


+ (BOOL) fixNetMeterValuesFromXmlDocument:(CXMLDocument*) document
							   intoObject:(Meter*) meterObject
					  withParentMeterNode:(NSString*)parentNode
				  andNodesKeyedByProperty:(NSDictionary*)netMeterFixNodesKeyedByProperty
                       usingAggregationOp:(AggregationOp)aggregationOp
{
	BOOL isSuccessful = YES;
	
	
	long mtuCount = [TedometerData sharedTedometerData].mtuCount;
	if( [TedometerData sharedTedometerData].isPatchingAggregationDataSelected && mtuCount > 1 ) {
		
		NSMutableDictionary *mtuTotalsKeyedByProperty = [[NSMutableDictionary alloc] initWithCapacity: [netMeterFixNodesKeyedByProperty allKeys].count];
		
		for( NSInteger i=0; i < mtuCount; ++i ) {
			NSString *mtuNodePath = [NSString stringWithFormat:@"%@.MTU%ld", parentNode, (long)i+1];
			CXMLNode *mtuNode = [document nodeAtPath:mtuNodePath];
			if( ! mtuNode ) {
				isSuccessful = NO;
				continue;
			}
			
			for( NSString *aPropertyName in [netMeterFixNodesKeyedByProperty allKeys] ) {
				NSString *aNodeName = [netMeterFixNodesKeyedByProperty objectForKey:aPropertyName];
				CXMLNode *aNode = [mtuNode childNamed:aNodeName];
				NSInteger aValue;
				if( aNode == nil ) {
					DLog(@"No node found at %@.%@", mtuNodePath, aNodeName );
				}
				if( aNode != nil ) {
					aValue = [[aNode stringValue] integerValue];
                    
					NSNumber *prevValueObject = [mtuTotalsKeyedByProperty objectForKey:aPropertyName];
					if( prevValueObject ) {
						NSInteger prevValue = [prevValueObject integerValue];
						switch( aggregationOp ) {
							case kAggregationOpSum: aValue += prevValue; break;
							case kAggregationOpMax: aValue = MAX( aValue, prevValue ); break;
							case kAggregationOpMin: aValue = MIN( aValue, prevValue ); break;
							default: {
								NSException *e = [NSException exceptionWithName:@"UnrecognizedArgumentException" reason:[NSString stringWithFormat:@"Unrecognized AggregationOp: %d", aggregationOp] userInfo:nil];
								[e raise];
							}
						}
					}
					
					prevValueObject = [[NSNumber alloc] initWithInteger:aValue];
					[mtuTotalsKeyedByProperty setValue:prevValueObject forKey:aPropertyName];
					[prevValueObject release];
				}
				
			}
		}
        
		for( NSString *aPropertyName in [netMeterFixNodesKeyedByProperty allKeys] ) {
			NSNumber *prevValueObject = [mtuTotalsKeyedByProperty objectForKey:aPropertyName];
			if( prevValueObject ) {
				[meterObject setValue:prevValueObject forKey:aPropertyName];
			}
		}
		
		[mtuTotalsKeyedByProperty release];
	}
    
	return isSuccessful;
}

+ (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document intoVoltageMeter: (VoltageMeter *) meter;
{
	
	BOOL isSuccessful = NO;
	
	/*
	 <Voltage>
	 <Total>
	 <VoltageNow>1221</VoltageNow>
	 <LowVoltageHour>1221</LowVoltageHour>
	 <LowVoltageToday>1213</LowVoltageToday>
	 <LowVoltageTodayTimeHour>0</LowVoltageTodayTimeHour>
	 <LowVoltageTodayTimeMin>8</LowVoltageTodayTimeMin>
	 <HighVoltageHour>1223</HighVoltageHour>
	 <HighVoltageToday>1223</HighVoltageToday>
	 <HighVoltageTodayTimeHour>2</HighVoltageTodayTimeHour>
	 <HighVoltageTodayTimeMin>16</HighVoltageTodayTimeMin>
	 <LowVoltageMTD>1076</LowVoltageMTD>
	 <LowVoltageMTDDateMonth>10</LowVoltageMTDDateMonth>
	 <LowVoltageMTDDateDay>15</LowVoltageMTDDateDay>
	 <HighVoltageMTD>1230</HighVoltageMTD>
	 <HighVoltageMTDDateMonth>10</HighVoltageMTDDateMonth>
	 <HighVoltageMTDDateDay>22</HighVoltageMTDDateDay>
	 </Total>
	 ...
	 </Power>
	 */
	
	NSDictionary* nodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
										  @"VoltageNow",					@"now",
										  @"HighVoltageToday",				@"todayPeakValue",
										  @"HighVoltageTodayTimeHour",		@"todayPeakHour",
										  @"HighVoltageTodayTimeMin", 		@"todayPeakMinute",
										  @"LowVoltageToday",				@"todayMinValue",
										  @"LowVoltageTodayTimeHour",		@"todayMinHour",
										  @"LowVoltageTodayTimeMin",		@"todayMinMinute",
										  @"HighVoltageMTD",				@"mtdPeakValue",
										  @"HighVoltageMTDDateMonth",		@"mtdPeakMonth",
										  @"HighVoltageMTDDateDay",			@"mtdPeakDay",
										  @"LowVoltageMTD",					@"mtdMinValue",
										  @"LowVoltageMTDDateMonth",		@"mtdMinMonth",
										  @"LowVoltageMTDDateDay",			@"mtdMinDay",
										  nil];
	NSString *parentNodePath;
	if( meter.mtuNumber == 0 )
		parentNodePath = @"Voltage.Total";
	else
		parentNodePath = [NSString stringWithFormat: @"Voltage.MTU%ld", (long)meter.mtuNumber];
	
	isSuccessful = [document loadIntegerValuesIntoObject:meter withParentNodePath:parentNodePath
                                 andNodesKeyedByProperty:nodesKeyedByProperty];
	
	[nodesKeyedByProperty release];
	
	if( meter.isNetMeter ) {
		
		// Fix peak/min for net meter
		NSDictionary *netMeterFixNodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
														 @"HighVoltageToday",		@"todayPeakValue",
														 @"PeakVoltageMTD",			@"mtdPeakValue",
														 nil];
		
		isSuccessful = [TED5000DataLoader fixNetMeterValuesFromXmlDocument:document
                                                                intoObject:meter
                                                       withParentMeterNode:@"Voltage"
                                                   andNodesKeyedByProperty:netMeterFixNodesKeyedByProperty
                                                        usingAggregationOp:kAggregationOpMax];
		
		[netMeterFixNodesKeyedByProperty release];
        
		netMeterFixNodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
                                           @"LowVoltageToday",		@"todayMinValue",
                                           @"PeaVoltageMTD",			@"mtdMinValue",
                                           nil];
		
		isSuccessful = [TED5000DataLoader fixNetMeterValuesFromXmlDocument:document
                                                                intoObject:meter
                                                       withParentMeterNode:@"Voltage" 
                                                   andNodesKeyedByProperty:netMeterFixNodesKeyedByProperty 
                                                        usingAggregationOp:kAggregationOpMin];
		
	}
	
	
	return isSuccessful;
}

+ (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document intoCostMeter:(CostMeter*)meter {
	
	BOOL isSuccessful = NO;
	
	/*
	 <Cost>
	 <Total>
	 <CostNow>13</CostNow>
	 <CostHour>13</CostHour>
	 <CostTDY>250</CostTDY>
	 <CostMTD>6632</CostMTD>
	 <CostProj>13219</CostProj>
	 <PeakTdy>95</PeakTdy>
	 <PeakMTD>95</PeakMTD>
	 <PeakTdyHour>0</PeakTdyHour>
	 <PeakTdyMin>27</PeakTdyMin>
	 <PeakMTDMonth>10</PeakMTDMonth>
	 <PeakMTDDay>24</PeakMTDDay>
	 
	 <MinTdy>8</MinTdy>
	 <MinMTD>8</MinMTD>
	 <MinTdyHour>1</MinTdyHour>
	 <MinTdyMin>31</MinTdyMin>
	 <MinMTDMonth>10</MinMTDMonth>
	 <MinMTDDay>14</MinMTDDay>
	 </Total>
	 ...
	 </Power>
	 */
	
	NSDictionary* nodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          @"CostNow",		@"now",
                                          @"CostHour",		@"hour",
                                          @"CostTDY",		@"today",
                                          @"CostMTD",		@"mtd",
                                          @"CostProj",		@"projected",
                                          @"PeakTdy",		@"todayPeakValue",
                                          @"PeakTdyHour",	@"todayPeakHour",
                                          @"PeakTdyMin",	@"todayPeakMinute",
                                          @"MinTdy",		@"todayMinValue",
                                          @"MinTdyHour",	@"todayMinHour",
                                          @"MinTdyMin",		@"todayMinMinute",
                                          @"PeakMTD",		@"mtdPeakValue",
                                          @"PeakMTDMonth",	@"mtdPeakMonth",
                                          @"PeakMTDDay",	@"mtdPeakDay",
                                          @"MinMTD",		@"mtdMinValue",
                                          @"MinMTDMonth",	@"mtdMinMonth",
                                          @"MinMTDDay",		@"mtdMinDay",
                                          nil];
	
	NSString *parentNodePath;
	if( meter.mtuNumber == 0 )
		parentNodePath = @"Cost.Total";
	else
		parentNodePath = [NSString stringWithFormat: @"Cost.MTU%ld", (long)meter.mtuNumber];
	
	isSuccessful = [document loadIntegerValuesIntoObject:meter withParentNodePath:parentNodePath
                                               andNodesKeyedByProperty:nodesKeyedByProperty];
	
	[nodesKeyedByProperty release];
	
	if( meter.isNetMeter ) {
		
		// Fix peak/min for net meter
		NSDictionary *netMeterFixNodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
														 @"PeakTdy",		@"todayPeakValue",
														 @"MinTdy",			@"todayMinValue",
														 @"PeakMTD",		@"mtdPeakValue",
														 @"MinMTD",			@"mtdMinValue",
														 nil];
		
		isSuccessful = [TED5000DataLoader fixNetMeterValuesFromXmlDocument:document
                                                                intoObject:meter
                                                       withParentMeterNode:@"Cost" 
                                                   andNodesKeyedByProperty:netMeterFixNodesKeyedByProperty usingAggregationOp:kAggregationOpSum];
		
		[netMeterFixNodesKeyedByProperty release];
	}
	
	return isSuccessful;
}

+ (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document intoCarbonMeter:(CarbonMeter*)meter;
{
	
	BOOL isSuccessful = [TED5000DataLoader refreshDataFromXmlDocument:document intoPowerMeter:meter];
	if( isSuccessful ) {
		isSuccessful = [document loadIntegerValuesIntoObject:meter withParentNodePath:@"Utility"
                                     andNodesKeyedByProperty:[NSDictionary dictionaryWithObject:@"CarbonRate" forKey:@"carbonRate"]];
	}
	
	return isSuccessful;
}

+ (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document intoPowerMeter:(PowerMeter*)meter;
{
	
	BOOL isSuccessful = NO;
	
	/*
	 <Power>
	 <Total>
	 <PowerNow>1570</PowerNow>
	 <PowerHour>1682</PowerHour>
	 <PowerTDY>32581</PowerTDY>
	 <PowerMTD>824305</PowerMTD>
	 <PowerProj>1681897</PowerProj>
	 <KVA>1863</KVA>
	 <PeakTdy>12265</PeakTdy>
	 <PeakMTD>12265</PeakMTD>
	 <PeakTdyHour>9</PeakTdyHour>
	 <PeakTdyMin>40</PeakTdyMin>
	 <PeakMTDMonth>10</PeakMTDMonth>
	 <PeakMTDDay>24</PeakMTDDay>
	 <MinTdy>1005</MinTdy>
	 <MinMTD>0</MinMTD>
	 <MinTdyHour>1</MinTdyHour>
	 <MinTdyMin>42</MinTdyMin>
	 <MinMTDMonth>10</MinMTDMonth>
	 <MinMTDDay>14</MinMTDDay>
	 </Total>
	 ...
	 </Power>
	 */
	
	NSDictionary* nodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          @"PowerNow",		@"now",
                                          @"PowerHour",		@"hour",
                                          @"PowerTDY",		@"today",
                                          @"PowerMTD",		@"mtd",
                                          @"KVA",			@"kva",
                                          @"PowerProj",		@"projected",
                                          @"PeakTdy",		@"todayPeakValue",
                                          @"PeakTdyHour",	@"todayPeakHour",
                                          @"PeakTdyMin",	@"todayPeakMinute",
                                          @"MinTdy",		@"todayMinValue",
                                          @"MinTdyHour",	@"todayMinHour",
                                          @"MinTdyMin",		@"todayMinMinute",
                                          @"PeakMTD",		@"mtdPeakValue",
                                          @"PeakMTDMonth",	@"mtdPeakMonth",
                                          @"PeakMTDDay",	@"mtdPeakDay",
                                          @"MinMTD",		@"mtdMinValue",
                                          @"MinMTDMonth",	@"mtdMinMonth",
                                          @"MinMTDDay",		@"mtdMinDay",
                                          nil];
	
	NSString *parentNodePath;
	if( meter.isNetMeter )
		parentNodePath = @"Power.Total";
	else
		parentNodePath = [NSString stringWithFormat: @"Power.MTU%ld", (long)meter.mtuNumber];
	
	isSuccessful = [document loadIntegerValuesIntoObject:meter withParentNodePath:parentNodePath
                                               andNodesKeyedByProperty:nodesKeyedByProperty];
	[nodesKeyedByProperty release];
	
	if( meter.isNetMeter ) {
		
		// Fix peak/min for net meter
		NSDictionary *netMeterFixNodesKeyedByProperty = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                         @"PeakTdy",		@"todayPeakValue",
                                                         @"MinTdy",			@"todayMinValue",
                                                         @"PeakMTD",		@"mtdPeakValue",
                                                         @"MinMTD",			@"mtdMinValue",
                                                         nil];
		
		isSuccessful = [TED5000DataLoader fixNetMeterValuesFromXmlDocument:document
                                                                intoObject:meter
                                                       withParentMeterNode:@"Power"
                                                   andNodesKeyedByProperty:netMeterFixNodesKeyedByProperty
                                                        usingAggregationOp:kAggregationOpSum];
        
		[netMeterFixNodesKeyedByProperty release];
	}
	
	return isSuccessful;
}


@end