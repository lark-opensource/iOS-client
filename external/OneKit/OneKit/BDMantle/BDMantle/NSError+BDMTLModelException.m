//
//  NSError+BDMTLModelException.m
//  BDMantle
//
//  Created by Robert Böhnke on 7/6/13.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "BDMTLModel.h"

#import "NSError+BDMTLModelException.h"

// The domain for errors originating from BDMTLModel.
static NSString * const BDMTLModelErrorDomain = @"BDMTLModelErrorDomain";

// An exception was thrown and caught.
static const NSInteger BDMTLModelErrorExceptionThrown = 1;

// Associated with the NSException that was caught.
static NSString * const BDMTLModelThrownExceptionErrorKey = @"BDMTLModelThrownException";

@implementation NSError (BDMTLModelException)

+ (instancetype)mtl_modelErrorWithException:(NSException *)exception {
	NSParameterAssert(exception != nil);

	NSDictionary *userInfo = @{
		NSLocalizedDescriptionKey: exception.description,
		NSLocalizedFailureReasonErrorKey: exception.reason,
		BDMTLModelThrownExceptionErrorKey: exception
	};

	return [NSError errorWithDomain:BDMTLModelErrorDomain code:BDMTLModelErrorExceptionThrown userInfo:userInfo];
}

@end
