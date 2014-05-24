//
//  CXMLDocument+utils.m
//  Ted-O-Meter
//
//  Created by Nathan on 5/23/14.
//
//

#import "CXMLNode-utils.h"
#import "CXMLDocument+utils.h"
#import "log.h"

@implementation CXMLDocument (utils)

- (CXMLNode *) nodeAtPath:(NSString*)nodePath {
    CXMLDocument* document = self;
    
	CXMLNode *node = (CXMLNode *)[document rootElement];
	for( NSString* pathElement in [nodePath componentsSeparatedByString:@"."] ) {
		node = [node childNamed:pathElement];
		if( node == nil ) {
			DLog( @"Could not find node named '%@' at path '%@'.", pathElement, nodePath );
			break;
		}
	}
	return node;
}

- (BOOL)loadIntegerValuesIntoObject:(NSObject*) object
                 withParentNodePath:(NSString*)parentNodePath
            andNodesKeyedByProperty:(NSDictionary*)nodesKeyedByPropertyDict
{
	
	BOOL isSuccessful = NO;
    
	CXMLNode *parentNode = [self nodeAtPath:parentNodePath];
    
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



@end
