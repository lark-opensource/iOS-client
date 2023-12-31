// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestRequestOperation.h"
#import "IESForestWorkflow.h"
#import "IESForestRequest.h"
#import "IESForestMemoryFetcher.h"
#import "IESForestGeckoFetcher.h"
#import "IESForestBuiltinFetcher.h"
#import "IESForestCDNFetcher.h"
#import "IESForestKit.h"
#import "IESForestKit+private.h"
#import "IESForestPreloadConfig.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>


@interface IESForestRequestOperation ()

@end

@implementation IESForestRequestOperation

- (BOOL)cancel {
    return [self.workflow cancelFetch];
}

- (instancetype)initWithRequest:(IESForestRequest *)request forestKit:(IESForestKit *)forestKit
{
    if (self = [super init]) {
        _workflow = [[IESForestWorkflow alloc] initWithFetchers:[request.actualFetcherSequence copy] request:request];
        _workflow.forestKit = forestKit;
        _url = request.url;
        _completions = [NSMutableArray array];
    }
    return self;
}

- (void)appendCompletion:(nullable IESForestCompletionHandler)completion
{
    if (completion) {
        [_completions addObject:completion];
    }
}

@end
