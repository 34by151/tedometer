//
//  TED6000DataLoader.m
//  Ted-O-Meter
//
//  Created by Nathan on 5/17/14.
//
//

#import "TED6000DataLoader.h"
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
- (NSString *) responseStringForFilename:(NSString *)filename
                           tedometerData:(TedometerData*)tedometerData
                                   error:(NSError**)error;
- (BOOL)reloadFromXmlDocument:(CXMLDocument*)xmlDoc
            andTedometerData:(TedometerData*)tedometerData
                  powerMeter:(PowerMeter*)powerMeter
                 carbonMeter:(CarbonMeter*)carbonMeter
                voltageMeter:(VoltageMeter*)voltageMeter
                       error:(NSError**)error;
- (BOOL)reloadFromXmlDocument:(CXMLDocument*)xmlDoc
            andTedometerData:(TedometerData*)tedometerData
                   costMeter:(CostMeter*)costMeter
                       error:(NSError**)error;

- (NSString*) ampsInfoLabelForCurrentInPhases:(NSArray*) phases;

@end

@implementation TED6000DataLoader

- (id) init {
	if( self = [super init] ) {
        // initialize member variables here
        for( int i=0; i < NUM_MTUS; ++i ) {
            overviewData[i] = [[NSMutableDictionary alloc] init];
        }
	}
	return self;
}


/**
 
 api/DashData.xml?T=[0|1]&D=[0|255]&M=[1..4]        (T=Type(Power,Cost); D=Data(Net,MTU); M=MTU)

 Reads api/SystemSettings.xml to get MTU count
 Reads api/DashData.xml?T=0&D=0                     [NET Power/Voltage/Carbon]
 Reads api/DashData.xml?T=1&D=0                     [NET Cost]
 For each MTU (if more than one)
    Reads api/DashData.xml?T=0&D=255&M=<mtu>        [MTU #<mtu> Power/Voltage/Carbon]
    Reads api/DashData.xml?T=1&D=255&M=<mtu>        [MTU #<mtu> Cost]
 */
- (BOOL)reload:(TedometerData*)tedometerData error:(NSError**)error;
{
    NSError *localError = nil;
    NSString *xmlString;
    CXMLDocument *xmlDoc;

    tedometerData.tedModel = @"TED PRO";
    
    // gateway time isn't reported by TED6000, so use iOS time
    // (time is needed for calcluating averages)
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar]
                                        components:NSMinuteCalendarUnit|NSHourCalendarUnit|NSDayCalendarUnit|NSWeekdayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit
                                        fromDate:[NSDate date]];
    tedometerData.gatewayMinute = dateComponents.minute;
    tedometerData.gatewayHour = dateComponents.hour;
    tedometerData.gatewayDayOfMonth = dateComponents.day;
    tedometerData.gatewayMonth = dateComponents.month;
    tedometerData.gatewayYear = dateComponents.year;
    
    xmlString = [self responseStringForFilename:@"SystemSettings.xml" tedometerData:tedometerData error:&localError];
    if( xmlString ) {
        xmlDoc = [[[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError] retain];
        if(xmlDoc) {
            tedometerData.mtuCount = [xmlDoc integerValueAtPath:@"NumberMTU"];
            DLog(@"NumberMTU = %ld", (long) tedometerData.mtuCount);
            tedometerData.carbonRate = [xmlDoc integerValueAtPath:@"CarbonCost"];
            DLog(@"CarbonCost = %ld", (long) tedometerData.carbonRate);
            [xmlDoc release];
            
            for( int mtuIdx=0; mtuIdx < NUM_MTUS; ++mtuIdx ) {
                if( mtuIdx == 0 ) {
                    continue;
                }
                else {
                    NSString *desc = [xmlDoc stringValueAtPath:[NSString stringWithFormat:@"MTUs.MTU[%d].MTUDescription", mtuIdx-1]];
                    if( desc ) {
                        [overviewData[mtuIdx] setObject:desc forKey:@"desc"];
                    }
                    DLog( @"Settings data for MTU%d: %@", mtuIdx, overviewData[mtuIdx] );
                }
            }

        }
    }

    if( !localError ) {
        xmlString = [self responseStringForFilename:@"Rate.xml" tedometerData:tedometerData error:&localError];
        if( xmlString ) {
            xmlDoc = [[[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError] retain];
            if(xmlDoc) {
                tedometerData.meterReadDate = [xmlDoc integerValueAtPath:@"MeterReadDate"];
                DLog(@"MeterReadDate = %ld", (long) tedometerData.meterReadDate);
                [xmlDoc release];
            }
        }
    }
    
    if( !localError ) {
        xmlString = [self responseStringForFilename:@"SystemOverview.xml" tedometerData:tedometerData error:&localError];
        if( xmlString ) {
            xmlDoc = [[[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError] retain];
            if(xmlDoc) {
                // we skip MTU 0 (the net meter) because SystemOverview.xml doesn't provide it
                for( int mtuIdx=0; mtuIdx < NUM_MTUS; ++mtuIdx ) {
                    
                    if( mtuIdx == 0 ) {
                        [overviewData[mtuIdx] setObject:@0 forKey:@"kva"];
                        [overviewData[mtuIdx] setObject:@0 forKey:@"pf"];
                    }
                    else {
                        [overviewData[mtuIdx] setObject:[NSNumber numberWithLong:[xmlDoc integerValueAtPath:[NSString stringWithFormat:@"MTUVal.MTU%d.KVA", mtuIdx]]]
                                                forKey:@"kva"];
                        [overviewData[mtuIdx] setObject:[NSNumber numberWithLong:[xmlDoc integerValueAtPath:[NSString stringWithFormat:@"MTUVal.MTU%d.PF", mtuIdx]]]
                                                 forKey:@"pf"];
                        NSNumber *ampsPhaseA = [xmlDoc integerAtPath:[NSString stringWithFormat:@"MTUVal.MTU%d.PhaseCurrent.A", mtuIdx]];
                        NSNumber *ampsPhaseB = [xmlDoc integerAtPath:[NSString stringWithFormat:@"MTUVal.MTU%d.PhaseCurrent.B", mtuIdx]];
                        NSNumber *ampsPhaseC = [xmlDoc integerAtPath:[NSString stringWithFormat:@"MTUVal.MTU%d.PhaseCurrent.C", mtuIdx]];
                        
                        [overviewData[mtuIdx] setObject:[self ampsInfoLabelForCurrentInPhases: @[ampsPhaseA, ampsPhaseB, ampsPhaseC]]
                                                 forKey:@"ampsInfoLabel"];
                        
                        DLog( @"Overview data for MTU%d: %@", mtuIdx, overviewData[mtuIdx] );
                    }
                }
                [xmlDoc release];
            }
        }
    }
    

    if( !localError ) {
        
        // From TedometerData.m: init
        // mtusArray is an NSArray of NUM_MTUS elements of type NSArray,
        // each of which is an array consisting of NUM_METER_TYPES elements of type Meter.
        //
        // [ [PowerNet,  CostNet,  CarbonNet,  VoltageNet],			// MTU0 (net)
        //   [PowerMtu1, CostMtu1, CarbonMtu1, VoltageMtu1],		// MTU1
        //	 [PowerMtu2, CostMtu2, CarbonMtu2, VoltageMtu2],		// MTU2
        //	 [PowerMtu3, CostMtu3, CarbonMtu3, VoltageMtu3],		// MTU3
        //	 [PowerMtu4, CostMtu4, CarbonMtu4, VoltageMtu4] ]		// MTU4
        
        for( int mtuIdx=0; mtuIdx <= tedometerData.mtuCount; ++mtuIdx ) {
            NSArray* mtuArray = [tedometerData.mtusArray objectAtIndex:mtuIdx];
            
            PowerMeter *powerMeter = (PowerMeter*)[mtuArray objectAtIndex:kMeterTypePower];
            CostMeter *costMeter = (CostMeter*)[mtuArray objectAtIndex:kMeterTypeCost];
            CarbonMeter *carbonMeter = (CarbonMeter*)[mtuArray objectAtIndex:kMeterTypeCarbon];
            VoltageMeter *voltageMeter = (VoltageMeter*)[mtuArray objectAtIndex:kMeterTypeVoltage];
            
            CXMLDocument *powerXmlDoc = nil;
            CXMLDocument *costXmlDoc = nil;
            if( mtuIdx == 0 /* net meters */ ) {
                NSString *filename = [NSString stringWithFormat:@"DashData.xml?T=0&D=%ld", (long) tedometerData.totalsMeterType];
                xmlString = [self responseStringForFilename:filename tedometerData:tedometerData error:&localError];
                powerXmlDoc = [[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError];
                
                if( !localError ) {
                    filename = [NSString stringWithFormat:@"DashData.xml?T=1&D=%ld", (long) tedometerData.totalsMeterType];
                    xmlString = [self responseStringForFilename:filename tedometerData:tedometerData error:&localError];
                    costXmlDoc = [[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError];
                }
            }
            else {
                NSString *filename = [NSString stringWithFormat:@"DashData.xml?T=0&D=255&M=%d", mtuIdx];
                xmlString = [self responseStringForFilename:filename tedometerData:tedometerData error:&localError];
                powerXmlDoc = [[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError];
                
                if( !localError ) {
                    filename = [NSString stringWithFormat:@"DashData.xml?T=1&D=255&M=%d", mtuIdx];
                    xmlString = [self responseStringForFilename:filename tedometerData:tedometerData error:&localError];
                    costXmlDoc = [[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError];
                }
            }
            
            if( !localError ) {
                // Reset meters here (just before we set them, after we have downloaded the new data,
                // rather than all at once before we begin downloading the data)
                // because otherwise, if latency is high, the meters can get zeroed out before the new
                // data is available, resulting in a short period of time when the meter shows zeroed values.
                for( Meter *meter in @[powerMeter, carbonMeter, voltageMeter, costMeter] ) {
                    [meter reset];
                    meter.isLowPeakSupported = NO;
                    meter.isAverageSupported = NO;
                    meter.isTotalsMeterTypeSelectionSupported = YES;
                    NSString *desc = [overviewData[meter.mtuNumber] objectForKey:@"desc"];
                    if( desc && ! [desc isEqualToString:@""] ) {
                        meter.mtuName = desc;
                    }
                    
                    if( meter.isNetMeter ) {
                        meter.totalsMeterType = tedometerData.totalsMeterType;
                    }
                }
                

                [self reloadFromXmlDocument:powerXmlDoc andTedometerData:tedometerData
                                 powerMeter:powerMeter
                                carbonMeter:carbonMeter
                               voltageMeter:voltageMeter
                                      error:&localError];
                
                if( !localError ) {
            
                    [self reloadFromXmlDocument:costXmlDoc andTedometerData:tedometerData
                                      costMeter:costMeter
                                          error:&localError];
                }
            }
            
            if( powerXmlDoc ) {
                [powerXmlDoc release];
                powerXmlDoc = nil;
            }
            if( costXmlDoc ) {
                [costXmlDoc release];
                costXmlDoc = nil;
            }
            
            if( localError )
                break;
        }
    }
   
    
    if( localError && error ) {
        *error = localError;
    }
    
    return localError == nil;
}

- (NSString *) responseStringForFilename:(NSString *)filename
                           tedometerData:(TedometerData*)tedometerData
                                   error:(NSError**)error;
{
    NSString *urlString;
    
    NSError *localError = nil;
    NSString *responseContent = nil;
	
    if( [tedometerData.gatewayHost hasPrefix:@"Data/"] ) {
        // Use test data
        filename = [filename stringByReplacingOccurrencesOfString:@"?" withString:@"_"];
        filename = [filename stringByReplacingOccurrencesOfString:@"&" withString:@"_"];
        filename = [filename stringByReplacingOccurrencesOfString:@"=" withString:@"_"];
        urlString = [NSString stringWithFormat:@"%@/%@", tedometerData.gatewayHost, filename];
        NSString *path = [[NSBundle mainBundle] pathForResource:urlString ofType:nil];
        responseContent = [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error: &localError];
    }
    else {
        
        urlString = [NSString stringWithFormat:@"%@://%@/api/%@", tedometerData.useSSL ? @"https" : @"http", tedometerData.gatewayHost, filename];

        NSURL *url = [NSURL URLWithString: urlString];
        
        ALog(@"Attempting connection with URL %@", url);
        
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        
        if( tedometerData.useSSL ) {
            [request setValidatesSecureCertificate:NO];
        }
        [request setUsername:tedometerData.username];
        [request setPassword:tedometerData.password];
        [request setUseSessionPersistence:NO];
        
        [request setTimeOutSeconds:30];
        [request startSynchronous];
        localError = [request error];
        if (!localError) {
            responseContent = [request responseString];
        }
    }
    
    if( localError && error ) {
        *error = localError;
        responseContent = nil;
    }
    
    
    return responseContent;
}

- (BOOL)reloadFromXmlDocument:(CXMLDocument*)xmlDoc
             andTedometerData:(TedometerData*)tedometerData
                   powerMeter:(PowerMeter*)powerMeter
                  carbonMeter:(CarbonMeter*)carbonMeter
                 voltageMeter:(VoltageMeter*)voltageMeter
                        error:(NSError**)error;
{
    BOOL isSuccessful = YES;
    
    
    NSInteger now = [xmlDoc integerValueAtPath:@"Now"];
    NSInteger tdy = [xmlDoc integerValueAtPath:@"TDY"];
    NSInteger mtd = [xmlDoc integerValueAtPath:@"MTD"];
    //    NSInteger avg = [xmlDoc integerValueAtPath:@"Avg"];
    NSInteger proj = [xmlDoc integerValueAtPath:@"Proj"];
    NSInteger voltage = [xmlDoc integerValueAtPath:@"Voltage"];
    //    NSInteger phase = [xmlDoc integerValueAtPath:@"Phase"];
    
    powerMeter.now = now;
    powerMeter.today = tdy;
    powerMeter.projected = proj;
    powerMeter.mtd = mtd;
    powerMeter.isAverageSupported = YES;
    
    voltageMeter.now = voltage;
    
    
    // If only one MTU is installed, show MTU1 kva/pf on the net meter (the only meter visible);
    // otherwise, show the kva/pf for each MTU on the individual MTU meters.
    if( tedometerData.mtuCount == 1 && powerMeter.mtuNumber == 0 ) {
        powerMeter.kva = [[overviewData[1] objectForKey:@"kva"] intValue];
        voltageMeter.infoLabel = (NSString*)[overviewData[1] objectForKey:@"ampsInfoLabel"];
    }
    else if( tedometerData.mtuCount > 1 ) {
        powerMeter.kva = [[overviewData[powerMeter.mtuNumber] objectForKey:@"kva"] intValue];
        voltageMeter.infoLabel = (NSString*)[overviewData[voltageMeter.mtuNumber] objectForKey:@"ampsInfoLabel"];
    }
    
    // nh 5/28/14: Attempting to calculate Amps from kwa/volts if no amp data is provided for each
    // phase, but the result seems to be what would be expected if the voltage were double.
    // Footprints shows voltage as "242/121" (where 242 fluctuates somewhat) but I'm not sure where
    // the 242 comes from.
    //    if( (!voltageMeter.infoLabel || [@"" isEqualToString:voltageMeter.infoLabel]) && voltage > 0 ) {
    //        float amps = 10.0 * (powerMeter.kva / (float) voltage);
    //        voltageMeter.infoLabel = [self ampsInfoLabelForCurrentInPhases:@[[NSNumber numberWithFloat:amps]]];
    //    }
    
    
    carbonMeter.carbonRate = tedometerData.carbonRate;
    carbonMeter.now = now;
    carbonMeter.today = tdy;
    carbonMeter.projected = proj;
    carbonMeter.mtd = mtd;
    carbonMeter.isAverageSupported = YES;
    
    return isSuccessful;
}

- (BOOL)reloadFromXmlDocument:(CXMLDocument*)xmlDoc
             andTedometerData:(TedometerData*)tedometerData
                    costMeter:(CostMeter*)costMeter
                        error:(NSError**)error;
{
    BOOL isSuccessful = YES;
    
    NSInteger now = [xmlDoc integerValueAtPath:@"Now"];
    NSInteger tdy = [xmlDoc integerValueAtPath:@"TDY"];
    NSInteger mtd = [xmlDoc integerValueAtPath:@"MTD"];
    //    NSInteger avg = [xmlDoc integerValueAtPath:@"Avg"];
    NSInteger proj = [xmlDoc integerValueAtPath:@"Proj"];
    //    NSInteger voltage = [xmlDoc integerValueAtPath:@"Voltage"];
    //    NSInteger phase = [xmlDoc integerValueAtPath:@"Phase"];
    
    costMeter.now = now;
    costMeter.today = tdy;
    costMeter.projected = proj;
    costMeter.mtd = mtd;
    costMeter.isAverageSupported = YES;
    
    return isSuccessful;
}


-(void)dealloc {
    for( int i=0; i < NUM_MTUS; ++i ) {
        [overviewData[i] release];
        overviewData[i] = nil;
    }

	[super dealloc];
}

- (NSString*) ampsInfoLabelForCurrentInPhases:(NSArray*) phases;
{
    NSString* infoLabel = @"";

    NSMutableArray *ampsArray = [[NSMutableArray alloc] init];
    for( id currentValue in phases ) {
        if( [currentValue longValue] > 0 ) {
            [ampsArray addObject:[NSString stringWithFormat:@"%0.1f A", [currentValue longValue] / 10.0]];
        }
    }
    if( [ampsArray count] > 0 ) {
        infoLabel = [NSString stringWithFormat:@"Current:\n%@", [ampsArray componentsJoinedByString:@"\n"]];
    }
    [ampsArray release];
    
    return infoLabel;
}


@end
