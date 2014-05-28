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

@end

@implementation TED6000DataLoader

- (id) init {
	if( self = [super init] ) {
        // initialize member variables here
        for( int i=0; i <= NUM_MTUS; ++i ) {
            overviewData[i] = [[NSMutableDictionary alloc] init];
        }
	}
	return self;
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
    
    
    // If only one MTU is installed, show MTU1 kva/pf on the net meter (the only meter visible);
    // otherwise, show the kva/pf for each MTU on the individual MTU meters.
    if( tedometerData.mtuCount == 1 && powerMeter.mtuNumber == 0 ) {
        powerMeter.kva = [[overviewData[1] objectForKey:@"kva"] intValue];
    }
    else if( tedometerData.mtuCount > 1 ) {
        powerMeter.kva = [[overviewData[powerMeter.mtuNumber] objectForKey:@"kva"] intValue];
    }
    
    voltageMeter.now = voltage;
    
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
                    DLog( @"Overview data for MTU%d: %@", mtuIdx, overviewData[mtuIdx] );
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
        
        for( NSArray *mtuArray in tedometerData.mtusArray ) {
            for( Meter *meter in mtuArray ) {
                [meter reset];
                meter.isLowPeakSupported = NO;
                meter.isAverageSupported = NO;
                NSString *desc = [overviewData[meter.mtuNumber] objectForKey:@"desc"];
                if( desc && ! [desc isEqualToString:@""] ) {
                    meter.mtuName = desc;
                }
            }
        }
        
        for( int mtuIdx=0; mtuIdx <= tedometerData.mtuCount; ++mtuIdx ) {
            NSArray* mtuArray = [tedometerData.mtusArray objectAtIndex:mtuIdx];
            
            PowerMeter *powerMeter = (PowerMeter*)[mtuArray objectAtIndex:kMeterTypePower];
            CostMeter *costMeter = (CostMeter*)[mtuArray objectAtIndex:kMeterTypeCost];
            CarbonMeter *carbonMeter = (CarbonMeter*)[mtuArray objectAtIndex:kMeterTypeCarbon];
            VoltageMeter *voltageMeter = (VoltageMeter*)[mtuArray objectAtIndex:kMeterTypeVoltage];
            
            CXMLDocument *powerXmlDoc;
            CXMLDocument *costXmlDoc;
            if( mtuIdx == 0 /* net meters */ ) {
                xmlString = [self responseStringForFilename:@"DashData.xml?T=0&D=0" tedometerData:tedometerData error:&localError];
                powerXmlDoc = [[[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError] retain];
                if( localError )
                    break;
                
                xmlString = [self responseStringForFilename:@"DashData.xml?T=1&D=0" tedometerData:tedometerData error:&localError];
                costXmlDoc = [[[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError] retain];
                if( localError )
                    break;
            }
            else {
                NSString *filename = [NSString stringWithFormat:@"DashData.xml?T=0&D=255&M=%d", mtuIdx];
                xmlString = [self responseStringForFilename:filename tedometerData:tedometerData error:&localError];
                powerXmlDoc = [[[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError] retain];
                if( localError )
                    break;
                
                filename = [NSString stringWithFormat:@"DashData.xml?T=1&D=255&M=%d", mtuIdx];
                xmlString = [self responseStringForFilename:filename tedometerData:tedometerData error:&localError];
                costXmlDoc = [[[CXMLDocument alloc] initWithXMLString:xmlString options:0 error:&localError] retain];
                if( localError )
                    break;
            }
            
            [self reloadFromXmlDocument:powerXmlDoc andTedometerData:tedometerData
                             powerMeter:powerMeter
                            carbonMeter:carbonMeter
                           voltageMeter:voltageMeter
                                  error:&localError];
            if( localError )
                break;
            
            [self reloadFromXmlDocument:costXmlDoc andTedometerData:tedometerData
                              costMeter:costMeter
                                  error:&localError];
            if( localError )
                break;
            
            [powerXmlDoc release];
            [costXmlDoc release];
            
        }
    }
   
    
    if( localError ) {
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
        
        [request startSynchronous];
        localError = [request error];
        if (!localError) {
            responseContent = [request responseString];
        }
    }
    
    if( localError ) {
        *error = localError;
        responseContent = nil;
    }
    
    
    return responseContent;
}

-(void)dealloc {
    for( int i=0; i <= NUM_MTUS; ++i ) {
        [overviewData[i] dealloc];
    }

	[super dealloc];
}



@end
