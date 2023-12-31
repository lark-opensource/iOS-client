//
//  NSDate+AWEAdditions.h
//  AWEFoundationKit-Pods-Aweme
//
//  Created by 陈煜钏 on 2020/2/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (AWEAdditions)

// 单位：ms
+ (void)awe_adjustWithServerTime:(long long)serverTime;

// 单位：ms
+ (long long)awe_currentServerTime;

@end

NS_ASSUME_NONNULL_END
