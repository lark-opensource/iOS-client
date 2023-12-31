//
//  NSDate+BDPExtension.h
//  Timor
//
//  Created by houjihu on 2020/6/17.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (BDPExtension)

#pragma mark - Timestamp Helper
/// 获取当前时间的时间戳
+ (NSInteger)bdp_currentTimestampInMilliseconds;

/// 时间戳 -> date
+ (NSDate *)bdp_dateFromTimestampInMilliseconds:(NSInteger)timestamp;

@end

NS_ASSUME_NONNULL_END
