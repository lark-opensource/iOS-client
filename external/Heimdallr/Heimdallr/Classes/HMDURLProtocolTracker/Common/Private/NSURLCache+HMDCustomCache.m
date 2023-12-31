//
//  NSURLCache+HMDCustomCache.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/4.
//

#import "NSURLCache+HMDCustomCache.h"
#import "HMDSwizzle.h"
#import "HMDURLCacheManager+Private.h"

static NSString * const HMDCustomCacheHTTPHandledIdentifier = @"HMDHTTPHandledIdentifier";

@implementation NSURLCache (HMDCustomCache)

+ (void)hmdExchangeCacheStoreClearMethod {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [NSURLCache hmdExchangeURLCacheStoreMethod];
    });
}

+ (void)hmdExchangeURLCacheStoreMethod {
    hmd_swizzle_instance_method([NSURLCache class], @selector(storeCachedResponse:forRequest:), @selector(hmd_storeCachedResponse:forRequest:));
}

- (void)hmd_storeCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request {
    id property = [NSURLProtocol propertyForKey:HMDCustomCacheHTTPHandledIdentifier inRequest:request];
    if (!property) {
        NSString *url = request.URL.absoluteString;
        BOOL isAvailableCustomCache = [[HMDURLCacheManager sharedInstance] checkAvailabaleCustomCachePath:url urlCacheInstance:self];
        if (isAvailableCustomCache) {
            NSMutableURLRequest *mutableRequest = [request mutableCopy];
            [NSURLProtocol setProperty:@(YES) forKey:HMDCustomCacheHTTPHandledIdentifier inRequest:mutableRequest];
            [self hmd_storeCachedResponse:cachedResponse forRequest:mutableRequest];
            return;
        }
    }
    [self hmd_storeCachedResponse:cachedResponse forRequest:request];
}

@end
