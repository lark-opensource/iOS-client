//
//  TTAdSplashManager+FirstSplash.h
//  FLEX
//
//  Created by yin on 2018/5/6.
//

#import "TTAdSplashManager.h"

@interface TTAdSplashManager (FirstSplash)

/**
 本次展示机会是否要监测首刷
 
 @return 是否监测
 */
+ (BOOL)checkoutFirstSplashEnable;

/**
 今天是否剩余展示开屏次数

 @return 是否剩余
 */
- (BOOL)remainShowCount;

/**
 今天展示了多少次开屏

 @return 展示了多少次开屏
 */
- (NSInteger)todayShowCount;

/**
 清除今天展示次数,置为0
 */
+ (void)clearTodayShowCount;

/**
 是否当天首次展示开屏

 @return 是否首次
 */
+ (BOOL)checkoutFirstLaunch;

+ (void)setFirstLaunch;

- (void)setTodaySplashShowTimes;

/**
 设置预期展示次数, 此方法不同于 setTodaySplashShowTimes,
 setTodaySplashShowTimes 是展示了才计次, 这个是符合频控条件就计次, 不一定能展示出来。
 */
- (void)setTodayExpectedShowCount;

/**
 获取预期展示次数, 不同于 todayShowCount, todayShowCount 是实际展示了的次数,
 本方法是符合频控条件的次数, >= todayShowCount.

 @return 预期展示次数
 */
- (NSInteger)todayExpectedShowCount;

/**
 清理当天预期展示(符合频控条件，有展示机会，但是不一定展示）次数.
 */
+ (void)clearTodayExpectedShowCount;

/// 如果需要则消耗全天首刷
/// @return 是否消耗
+ (BOOL)markConsumeFirstLaunchIfNeeded;

/// check 当前时间段内，分时段首刷有没有被消耗，没有被消耗就可以展示
+ (BOOL)checkShouldShowPeriodFirstLaunch;

/// 标记消耗了这个时段的首刷
+ (void)markConsumePeriodFirstLaunch;

/// 获取某个创意在这一轮次展示次数
/// @param adId 创意 ID
+ (NSUInteger)displayCountWithAdId:(NSString *)adId;

/// 累加某个创意的展示次数
/// @param adId 创意 ID
+ (void)addDisplayCountWithAdId:(NSString *)adId;

/// 清除这一轮次的所有创意展示次数，在每次预加载成功之后清除
+ (void)clearAllAdsDisplayCount;

/// 寻找当前时间内，有没有命中分时段首刷时间段，命中哪个时间段就返回哪个，没有返回 nil.
+ (NSArray *)findCurrentPeriodTime;
@end
