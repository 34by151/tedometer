//
//  DataLoader.m
//  Ted-O-Meter
//
//  Created by Nathan on 4/29/14.
//
//

#import "DataLoader.h"
#import "ASIHTTPRequest.h"
#import "log.h"

// private
@interface DataLoader()
@end


@implementation DataLoader

-(BOOL)reload:(TedometerData*)tedometerData error:(NSError**)error;
{
    [NSException raise:@"Invoked abstract method" format:@"Invoked abstract method"];
    return NO;
}

+(HardwareType)detectHardwareTypeWithSettingsInTedometerData:(TedometerData *)tedometerData;
{
    HardwareType hardwareType = kHardwareTypeUnknown;
    

    if( [tedometerData isUsingDemoAccount] ) {
        hardwareType = kHardwareTypeTED5000;
    }
    else if ( [tedometerData.gatewayHost hasPrefix:@"Data/"] ) {
        if( [tedometerData.gatewayHost hasPrefix:@"Data/5000"] ) {
            hardwareType = kHardwareTypeTED5000;
        }
        else if( [tedometerData.gatewayHost hasPrefix:@"Data/6000"] ) {
            hardwareType = kHardwareTypeTED6000;
        }
    }
    else {
        @autoreleasepool {

            NSString *urlString = [NSString stringWithFormat:@"%@://%@/Footprints.html",
                                   tedometerData.useSSL ? @"https" : @"http",
                                   tedometerData.gatewayHost];
            NSError *error = nil;
            NSString *responseContent = nil;

            
            NSURL *url = [NSURL URLWithString: urlString];
            
            ALog(@"Attempting to detect hardware type with URL %@", url);
            
            ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
            [request setUseSessionPersistence:NO];
            if( tedometerData.useSSL ) {
                    [request setValidatesSecureCertificate:NO];
            }
            [request setUsername:tedometerData.username];
            [request setPassword:tedometerData.password];
            
            [request startSynchronous];
            error = [request error];
            if (error) {
                ALog( @"%@", [error localizedDescription]);
            }
            else {
                responseContent = [request responseString];

                if( [responseContent rangeOfString:@"<title>TED 5000</title>"].location != NSNotFound ) {
                    hardwareType = kHardwareTypeTED5000;
                }
                else {
                    // make sure it has TED in the title, just to be sure we actually connected to a TED gateway
                    if( [responseContent rangeOfString:@"<title>TED"].location == NSNotFound ) {
                        hardwareType = kHardwareTypeUnknown;
                    }
                    else {
                        // Has TED in the title but it's not a 5000; assume it's a 6000 (TED Pro)
                        hardwareType = kHardwareTypeTED6000;
                    }
                }
            }

        }
    }
    

    ALog( @"Detected hardware type: %ld", (long) hardwareType );

    return hardwareType;
}


@end
