//
//  CXMLDocument+utils.h
//  Ted-O-Meter
//
//  Created by Nathan on 5/23/14.
//
//

#import "CXMLDocument.h"

@interface CXMLDocument (utils)
- (CXMLNode *) nodeAtPath:(NSString*)nodePath;      /* path should NOT include the root node */
- (NSInteger) integerValueAtPath:(NSString*)path;   /* path should NOT include the root node */
- (NSString *) stringValueAtPath:(NSString*)path;   /* path should NOT include the root node */

- (BOOL)loadIntegerValuesIntoObject:(NSObject*) object
                 withParentNodePath:(NSString*)parentNodePath
            andNodesKeyedByProperty:(NSDictionary*)nodesKeyedByPropertyDict;
@end
