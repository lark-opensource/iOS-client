// Copyright 2022. The Cross Platform Authors. All rights reserved.

#import "IESForestResponse.h"
#import "IESForestRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESForestMemoryCache : NSObject

- (nullable IESForestResponse *)responseForKey:(NSString *)key;
- (void)setResponse:(IESForestResponse *)response forKey:(NSString *)key;
- (void)removeResponseForKey:(NSString *)key;
- (void)removeAll;

- (void)updateCacheLimit:(NSInteger)cacheLimit;

@end

NS_ASSUME_NONNULL_END
