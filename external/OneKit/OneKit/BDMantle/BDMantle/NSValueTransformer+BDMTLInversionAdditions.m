//
//  NSValueTransformer+BDMTLInversionAdditions.m
//  BDMantle
//
//  Created by Justin Spahr-Summers on 2013-05-18.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "NSValueTransformer+BDMTLInversionAdditions.h"
#import "BDMTLTransformerErrorHandling.h"
#import "BDMTLValueTransformer.h"

@implementation NSValueTransformer (BDMTLInversionAdditions)

- (NSValueTransformer *)mtl_invertedTransformer {
	NSParameterAssert(self.class.allowsReverseTransformation);

	if ([self conformsToProtocol:@protocol(BDMTLTransformerErrorHandling)]) {
		NSParameterAssert([self respondsToSelector:@selector(reverseTransformedValue:success:error:)]);

		id<BDMTLTransformerErrorHandling> errorHandlingSelf = (id)self;

		return [BDMTLValueTransformer transformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
			return [errorHandlingSelf reverseTransformedValue:value success:success error:error];
		} reverseBlock:^(id value, BOOL *success, NSError **error) {
			return [errorHandlingSelf transformedValue:value success:success error:error];
		}];
	} else {
		return [BDMTLValueTransformer transformerUsingForwardBlock:^(id value, BOOL *success, NSError **error) {
			return [self reverseTransformedValue:value];
		} reverseBlock:^(id value, BOOL *success, NSError **error) {
			return [self transformedValue:value];
		}];
	}
}

@end
