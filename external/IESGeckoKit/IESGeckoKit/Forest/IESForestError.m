// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestError.h"

static NSString *const kIESForestDomain = @"IESForestErrorDomain";

@implementation IESForestError

+ (NSError *)errorWithCode:(IESForestErrorCode)code message:(NSString *)message
{
    return [[NSError alloc] initWithDomain:kIESForestDomain code:code userInfo:@{NSLocalizedDescriptionKey: message ?: @"unknow"}];
}

@end
