//
//  CXMLDocument+utils.h
//  Ted-O-Meter
//
//  Created by Nathan on 5/23/14.
//
//

#import "CXMLDocument.h"

@interface CXMLDocument (utils)
- (CXMLNode *) nodeAtPath:(NSString*)nodePath;
- (BOOL)loadIntegerValuesIntoObject:(NSObject*) object
                 withParentNodePath:(NSString*)parentNodePath
            andNodesKeyedByProperty:(NSDictionary*)nodesKeyedByPropertyDict;
@end
