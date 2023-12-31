//
//  TTAdSplashManager+Cache.h
//  FLEX
//
//  Created by yin on 2018/5/6.
//

#import "TTAdSplashManager.h"

@interface TTAdSplashManager (Cache)

/**
 广告素材缓存是否存在
 
 @param model 广告model
 @return 是否存在素材缓存
 */
+ (BOOL)isCacheExistForADModel:(TTAdSplashModel *)model;

+ (BOOL)isCacheExistWithADModel:(TTAdSplashModel *)model readyType:(TTAdSplashReadyType *)readyType;

+ (NSString *)splashResouceCachePath;

+ (float)splashResouceCacheSize;

+ (void)clearSplashResouceCache;

- (BOOL)discardAdInCache:(NSArray<NSString *> *)adIDs;

@end
