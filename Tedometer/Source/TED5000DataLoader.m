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

// private
@interface DataLoader()
- (BOOL)refreshTedometerData:(TedometerData *)tedometerData fromXmlDocument:(CXMLDocument *)document;
- (BOOL)refreshDataFromXmlDocument:(CXMLDocument *)document;
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
	isSuccessful = [TED5000DataLoader loadIntegerValuesFromXmlDocument:document intoObject:tedometerData withParentNodePath:@"GatewayTime"
                                           andNodesKeyedByProperty:gatewayTimeNodesKeyedByProperty];
    
	if( isSuccessful ) {
		NSDictionary* utilityNodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys:
                                                     @"CarbonRate", @"carbonRate",
                                                     @"CurrentRate", @"currentRate",
                                                     @"MeterReadDate", @"meterReadDate",
                                                     @"DaysLeftInBillingCycle", @"daysLeftInBillingCycle",
                                                     nil];
		isSuccessful = [TED5000DataLoader loadIntegerValuesFromXmlDocument:document intoObject:tedometerData withParentNodePath:@"Utility"
                                               andNodesKeyedByProperty:utilityNodesKeyedByProperty];
	}
	
	if( isSuccessful ) {
		NSDictionary* systemNodesKeyedByProperty = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    @"NumberMTU", @"mtuCount",
                                                    nil];
		isSuccessful = [TED5000DataLoader loadIntegerValuesFromXmlDocument:document intoObject:tedometerData withParentNodePath:@"System"
											   andNodesKeyedByProperty:systemNodesKeyedByProperty];
	}
	
	if( isSuccessful ) {
		
		for( NSArray *mtuArray in tedometerData.mtusArray ) {
			for( Meter *aMeter in mtuArray ) {
				DLog(@"Refreshing data for meter %@ MTU%ld...", [aMeter meterTitle], (long)[aMeter mtuNumber]);
				isSuccessful = [aMeter refreshDataFromXmlDocument:document];
				if( ! isSuccessful )
					break;
			}
			if( ! isSuccessful )
				break;
		}
	}
	return isSuccessful;
}

+ (CXMLNode *) nodeInXmlDocument:(CXMLDocument *)document atPath:(NSString*)nodePath {
    
	CXMLNode *node = [document rootElement];
	for( NSString* pathElement in [nodePath componentsSeparatedByString:@"."] ) {
		node = [node childNamed:pathElement];
		if( node == nil ) {
			DLog( @"Could not find node named '%@' at path '%@'.", pathElement, nodePath );
			break;
		}
	}
	return node;
}

+ (BOOL)loadIntegerValuesFromXmlDocument:(CXMLDocument *)document intoObject:(NSObject*) object withParentNodePath:(NSString*)parentNodePath andNodesKeyedByProperty:(NSDictionary*)nodesKeyedByPropertyDict {
	
	BOOL isSuccessful = NO;
    
	CXMLNode *parentNode = [TED5000DataLoader nodeInXmlDocument:document atPath:parentNodePath];
    
	if( parentNode ) {
		isSuccessful = YES;
		for( NSString *aPropertyName in [nodesKeyedByPropertyDict allKeys] ) {
			NSString *aNodeName = [nodesKeyedByPropertyDict objectForKey:aPropertyName];
			CXMLNode *aNode = [parentNode childNamed:aNodeName];
			NSInteger aValue;
			if( aNode == nil ) {
				DLog(@"Could not find node named '%@' at path '%@'. Defaulting to 0.", aNodeName, parentNodePath);
				aValue = 0;
			}
			else {
				aValue = [[aNode stringValue] integerValue];
			}
			
			NSNumber *aNumberObject = [[NSNumber alloc] initWithInteger:aValue];
			[object setValue:aNumberObject forKey:aPropertyName];
			[aNumberObject release];
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
			CXMLNode *mtuNode = [TED5000DataLoader nodeInXmlDocument:document atPath:mtuNodePath];
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


@end
