// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import <Foundation/Foundation.h>

#import "IESForestResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESForestMemoryCacheManager : NSObject

+ (instancetype)sharedInstance;

+ (void)updateCacheLimit:(NSInteger)cacheLimit;
+ (void)updatePreloadCacheLimit:(NSInteger)cacheLimit;

- (BOOL)cacheResponse:(IESForestResponse *)response withRequest:(IESForestRequest *)request;
- (nullable IESForestResponse *)responseForRequest:(IESForestRequest *)request;

- (void)clearCacheForRequest:(IESForestRequest *)request;
- (void)clearCaches;

@end

NS_ASSUME_NONNULL_END
