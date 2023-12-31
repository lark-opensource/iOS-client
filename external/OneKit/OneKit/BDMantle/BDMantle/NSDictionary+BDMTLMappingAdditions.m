//
//  NSDictionary+BDMTLMappingAdditions.m
//  BDMantle
//
//  Created by Robert Böhnke on 10/31/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "BDMTLModel.h"

#import "NSDictionary+BDMTLMappingAdditions.h"

@implementation NSDictionary (BDMTLMappingAdditions)

+ (NSDictionary *)mtl_identityPropertyMapWithModel:(Class)modelClass {
	NSCParameterAssert([modelClass conformsToProtocol:@protocol(BDMTLModel)]);

	NSArray *propertyKeys = [modelClass propertyKeys].allObjects;

	return [NSDictionary dictionaryWithObjects:propertyKeys forKeys:propertyKeys];
}

@end
