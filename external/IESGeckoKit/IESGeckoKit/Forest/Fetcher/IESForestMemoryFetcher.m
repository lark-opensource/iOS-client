#import "IESForestMemoryFetcher.h"

#import "IESForestDefines.h"
#import "IESForestResponse.h"
#import "IESForestRequest.h"
#import "IESForestMemoryCacheManager.h"
#import "IESForestError.h"

#import <IESGeckoKit/IESGurdLogProxy.h>
// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <ByteDanceKit/BTDMacros.h>

@implementation IESForestMemoryFetcher
+ (NSString *)fetcherName
{
    return @"Memory";
}

- (NSString *)name
{
    return @"Memory";
}

- (void)fetchResourceWithRequest:(IESForestRequest *)request
                      completion:(IESForestFetcherCompletionHandler)completion
{
    NSAssert(completion != nil, @"comletion in fetcher should NOT be nil!");
    request.metrics.memoryStart = [[NSDate date] timeIntervalSince1970] * 1000;
    IESForestFetcherCompletionHandler wrapCompletion = ^(IESForestResponse* response, NSError *error) {
        self.request.metrics.memoryFinish = [[NSDate date] timeIntervalSince1970] * 1000;
        if (!completion || self.isCanceled) {
            return;
        }
        if (error) {
            self.request.memoryError = [error localizedDescription];
//            IESGurdLogInfo(@"Forest - Memory: request [%@] error: %@", self.request.url, self.request.memoryError);
        } else {
            self.request.isFromMemory = YES;
//            IESGurdLogInfo(@"Forest - Memory: request [%@] success", self.request.url);
        }
        completion(response, error);
    };

    IESForestResponse *response = [[IESForestMemoryCacheManager sharedInstance] responseForRequest:request];

    NSString *errorMessage = nil;
    IESForestErrorCode errorCode = 0;
    if (!response) {
        errorMessage = @"No cache available";
        errorCode = IESForestErrorMemoryNoCache;
        
    } else if (!response.expiredDate || response.expiredDate.timeIntervalSince1970 < [[NSDate date] timeIntervalSince1970]) {
        errorMessage = @"Cache expired";
        errorCode = IESForestErrorMemoryCacheExpired;
    }
    
    if (errorMessage == nil) {
        response.fetcher = [self name];
        wrapCompletion(response, nil);
    } else {
        wrapCompletion(nil, [IESForestError errorWithCode:errorCode message:errorMessage]);
    }
}

@end
