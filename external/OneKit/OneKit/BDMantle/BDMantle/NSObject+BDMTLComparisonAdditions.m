//
//  NSObject+BDMTLComparisonAdditions.m
//  BDMantle
//
//  Created by Josh Vera on 10/26/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//
//  Portions copyright (c) 2011 Bitswift. All rights reserved.
//  See the LICENSE file for more information.
//

#import "NSObject+BDMTLComparisonAdditions.h"

BOOL BDMTLEqualObjects(id obj1, id obj2) {
	return (obj1 == obj2 || [obj1 isEqual:obj2]);
}
