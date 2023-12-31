// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestMemoryCacheManager.h"
#import "IESForestMemoryCache.h"
#import <ByteDanceKit/BTDMacros.h>
#import <IESGeckoKit/IESGurdLogProxy.h>

static const int kDefaultPreloadCacheLimit = 4 * 1024 * 1024; // 4MB

@interface IESForestMemoryCacheManager ()

@property (nonatomic, strong) IESForestMemoryCache *generalMemoryCache;
@property (nonatomic, strong) IESForestMemoryCache *preloadMemoryCache;

@end

@implementation IESForestMemoryCacheManager

+ (instancetype)sharedInstance
{
    static IESForestMemoryCacheManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)updateCacheLimit:(NSInteger)cacheLimit
{
    IESForestMemoryCacheManager *manager = [self sharedInstance];
    [manager.generalMemoryCache updateCacheLimit:cacheLimit];
}

+ (void)updatePreloadCacheLimit:(NSInteger)cacheLimit
{
    IESForestMemoryCacheManager *manager = [self sharedInstance];
    [manager.preloadMemoryCache updateCacheLimit:cacheLimit];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _generalMemoryCache = [[IESForestMemoryCache alloc] init];
        _preloadMemoryCache = [[IESForestMemoryCache alloc] init];
        [_preloadMemoryCache updateCacheLimit:kDefaultPreloadCacheLimit];
    }
    return self;
}

- (nullable IESForestResponse *)responseForRequest:(IESForestRequest *)request
{
    NSString *resourceKey = request.identity;
    IESForestResponse *response = nil;
    if (request.enableRequestReuse) {
        response = [self.preloadMemoryCache responseForKey:resourceKey];
    }
    if (response) {
        IESGurdLogInfo(@"Forest - CacheManager: get response from preload cache for: %@", request.url);
        request.isPreloaded = YES;
        [self.preloadMemoryCache removeResponseForKey:resourceKey];
        [self.generalMemoryCache setResponse:response forKey:resourceKey];
    } else {
        response = [self.generalMemoryCache responseForKey:resourceKey];
        if (response) {
            IESGurdLogInfo(@"Forest - CacheManager: get response from general cache for: %@", request.url);
        }
    }
    return response;
}

- (BOOL)cacheResponse:(IESForestResponse *)response withRequest:(IESForestRequest *)request
{
    if (!response) {
        return NO;
    }

    NSString *resourceKey = request.identity;
    if (request.enableMemoryCache && resourceKey && response.data.length > 0) {
        response.cacheKey = resourceKey;
        response.expiredDate = response.expiredDate ?: [[NSDate date] dateByAddingTimeInterval:request.memoryExpiredTime];
        if (response.expiredDate.timeIntervalSince1970 > [[NSDate date] timeIntervalSince1970]) {
            IESForestResponse *newResponse = [IESForestResponse responseWithResponse:response];
            if (request.isPreload) {
                [self.preloadMemoryCache setResponse:newResponse forKey:resourceKey];
                IESGurdLogInfo(@"Forest - CacheManager: cache response to preload cache for request: %@", request.url);
            } else {
                [self.generalMemoryCache setResponse:newResponse forKey:resourceKey];
                IESGurdLogInfo(@"Forest - CacheManager: cache response to general cache for request: %@", request.url);
            }
            return YES;
        }
    }
    return NO;
}

- (void)clearCacheForRequest:(IESForestRequest *)request
{
    NSString *resourceKey = request.identity;
    [self.generalMemoryCache removeResponseForKey:resourceKey];
    [self.preloadMemoryCache removeResponseForKey:resourceKey];
}

- (void)clearCaches
{
    [self.generalMemoryCache removeAll];
    [self.preloadMemoryCache removeAll];
}

@end
