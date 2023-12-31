//
//  NSDictionary+BDMTLJSONKeyPath.m
//  BDMantle
//
//  Created by Robert Böhnke on 19/03/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

#import "NSDictionary+BDMTLJSONKeyPath.h"

#import "BDMTLJSONAdapter.h"

@implementation NSDictionary (BDMTLJSONKeyPath)

- (id)mtl_valueForJSONKeyPath:(NSString *)JSONKeyPath success:(BOOL *)success error:(NSError **)error {
	NSArray *components = [JSONKeyPath componentsSeparatedByString:@"."];

	id result = self;
	for (NSString *component in components) {
		// Check the result before resolving the key path component to not
		// affect the last value of the path.
		if (result == nil || result == NSNull.null) break;

		if (![result isKindOfClass:NSDictionary.class]) {
			if (error != NULL) {
				NSDictionary *userInfo = @{
					NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid JSON dictionary", @""),
					NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"JSON key path %1$@ could not resolved because an incompatible JSON dictionary was supplied: \"%2$@\"", @""), JSONKeyPath, self]
				};

				*error = [NSError errorWithDomain:BDMTLJSONAdapterErrorDomain code:BDMTLJSONAdapterErrorInvalidJSONDictionary userInfo:userInfo];
			}

			if (success != NULL) *success = NO;

			return nil;
		}

		result = result[component];
	}

	if (success != NULL) *success = YES;

	return result;
}

@end
