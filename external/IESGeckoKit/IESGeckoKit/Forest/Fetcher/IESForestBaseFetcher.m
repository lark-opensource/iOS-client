// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestBaseFetcher.h"
#import "IESForestRequest.h"

@implementation IESForestBaseFetcher

- (NSString *)name
{
    return @"ForestBaseFetcher";
}

- (void)cancelFetch
{
}

- (void)fetchResourceWithRequest:(nonnull IESForestRequest *)request
                      completion:(nullable IESForestFetcherCompletionHandler)completion {
    completion(nil, [NSError new]);
}

- (void)dealloc
{
    // do nothing
}

@end
