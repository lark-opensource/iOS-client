//
//  HMDURLCacheManager+Private.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/2/4.
//

#import "HMDURLCacheManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDURLCacheManager (Private)

- (void)start;
- (void)stop;
- (BOOL)managerIsRunning;
- (BOOL)checkAvailabaleCustomCachePath:(NSString *)url urlCacheInstance:(NSURLCache *)urlCache;

@end

NS_ASSUME_NONNULL_END
