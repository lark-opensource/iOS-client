//
//  NSArray+BDMTLManipulationAdditions.m
//  BDMantle
//
//  Created by Josh Abernathy on 9/19/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSArray+BDMTLManipulationAdditions.h"

@interface NSArray (BDMTLDeclarations)

// This declaration is needed so BDMantle can be compiled with SDK 6 / 10.8.
- (id)firstObject;

@end

@implementation NSArray (BDMTLManipulationAdditions)

- (id)mtl_firstObject {
	return self.firstObject;
}

- (instancetype)mtl_arrayByRemovingObject:(id)object {
	NSMutableArray *result = [self mutableCopy];
	[result removeObject:object];
	return result;
}

- (instancetype)mtl_arrayByRemovingFirstObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(1, self.count - 1)];
}

- (instancetype)mtl_arrayByRemovingLastObject {
	if (self.count == 0) return self;

	return [self subarrayWithRange:NSMakeRange(0, self.count - 1)];
}

@end
