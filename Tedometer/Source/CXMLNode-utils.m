//
//  CXMLNode-utils.m
//  AdvancedBlogTutorial
//
//  Created by Nathan on 10/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CXMLNode-utils.h"


@implementation CXMLNode(utils)

- (CXMLNode *)childNamed:(NSString *)name
{
	NSEnumerator *e = [[self children] objectEnumerator];
	
	CXMLNode *node;
	while (node = [e nextObject]) 
		if ([[node name] isEqualToString:name])
			return node;
    
	return nil;
}

- (NSArray *)childrenAsStrings
{
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity:
							[[self children] count]];
	NSEnumerator *e = [[self children] objectEnumerator];
	CXMLNode *node;
	while (node = [e nextObject])
		[ret addObject:[node stringValue]];
	
	return ret;
}
@end