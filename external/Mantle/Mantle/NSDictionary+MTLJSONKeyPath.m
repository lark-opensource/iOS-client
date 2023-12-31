//
//  NSDictionary+MTLJSONKeyPath.m
//  Mantle
//
//  Created by Robert Böhnke on 19/03/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "NSDictionary+MTLJSONKeyPath.h"

#import "MTLJSONAdapter.h"

@implementation NSDictionary (MTLJSONKeyPath)

- (id)mtl_valueForJSONKeyPathArray:(NSArray *)JSONKeyPathArray {
	id result = self;
	for (NSString *component in JSONKeyPathArray) {
		// Check the result before resolving the key path component to not
		// affect the last value of the path.
		if (result == nil || result == NSNull.null) break;
		
		if (![result isKindOfClass:NSDictionary.class]) {
			return nil;
		}
		
		result = result[component];
	}
	
	return result;
}

@end
