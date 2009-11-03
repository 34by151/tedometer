// Borrwed from http://www.mactech.com/articles/mactech/Vol.21/21.06/XMLParser/

#import "CXMLNode.h"


@interface CXMLNode(utils)
- (CXMLNode *)childNamed:(NSString *)name;
- (NSArray *)childrenAsStrings;
@end
