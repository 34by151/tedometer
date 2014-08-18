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

// Path elements should be separated by periods. If a node has multiple children
// with the same name (e.g., "<MTUs><MTU/><MTU/><MTU/></MTUs>), then the path
// element may include a bracketed 0-based index to identify the child to retrieve.
//
// E.g.: "MTUs.MTU[0].MTUDescription"
//
// Paths should NOT include the root tag.
//
- (CXMLNode *) nodeAtPath:(NSString*)nodePath {
    CXMLDocument* document = self;
    
	CXMLNode *node = (CXMLNode *)[document rootElement];
	for( NSString* pathElement in [nodePath componentsSeparatedByString:@"."] ) {
        
        NSRange startRange = [pathElement rangeOfString:@"["];
        if( startRange.location != NSNotFound ) {
            NSRange endRange = [pathElement rangeOfString:@"]"];
            if( endRange.location == NSNotFound ) {
                ALog(@"Error: Invalid syntax for node path (missing closing bracket): \"%@\"", nodePath);
                node = nil;
                break;
            }
            NSString *unindexedNodeName = [pathElement substringToIndex:startRange.location];
            NSString *childIdxStr = [pathElement substringWithRange:NSMakeRange( startRange.location+1, 1 )];
            int childSearchIdx = [childIdxStr intValue];
            
            // [CXMLNode childAtIndex:] creates "text" nodes for text between tags, so to find the
            // indexed tag we need to skip over any nodes that don't have the provided tag name.
            int rawNodeIdx = 0;
            int curChildCount = 0;
            CXMLNode *foundNode = nil;
            while( rawNodeIdx < node.childCount ) {
                CXMLNode *aChild = [node childAtIndex:rawNodeIdx];
                if( [[aChild name] isEqualToString: unindexedNodeName] ) {
                    if( curChildCount == childSearchIdx ) {
                        foundNode = aChild;
                        break;
                    }
                    else {
                        ++curChildCount;
                    }
                }
                ++rawNodeIdx;
            }
            if( ! foundNode ) {
                ALog( @"Could not find indexed node '%@'.", pathElement );
                break;
            }
            else {
                node = foundNode;
                //DLog( @"Retrieved node '%@' (%@) = %@ [parent = %@]", pathElement, [node name], [node stringValue], [[node parent] name] );
            }
        }
        else {
            node = [node childNamed:pathElement];
            if( node == nil ) {
                ALog( @"Could not find node named '%@' at path '%@'.", pathElement, nodePath );
                break;
            }
            else {
                //DLog( @"Retrieved node '%@' (%@) = %@", pathElement, [node name], [node stringValue] );
            }
        }
	}
	return node;
}

-(NSNumber*) integerAtPath:(NSString*)path;
{
    return [NSNumber numberWithInteger:[self integerValueAtPath:path]];
}

- (NSInteger) integerValueAtPath:(NSString*)path;
{

    NSInteger value;
    CXMLNode *node = [self nodeAtPath:path];
    if( node == nil ) {
        DLog(@"Could not find node at path '%@'. Defaulting to 0.", path);
        value = 0;
    }
    else {
        value = [[node stringValue] integerValue];
    }
    
    return value;
}

- (NSString *) stringValueAtPath:(NSString*)path;
{
    NSString *value;
    CXMLNode *node = [self nodeAtPath:path];
    if( node == nil ) {
        DLog(@"Could not find node at path '%@'. Defaulting to nil.", path);
        value = nil;
    }
    else {
        value = [node stringValue];
    }
    
    return value;
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
		}
	}
	
	return isSuccessful;
}



@end
