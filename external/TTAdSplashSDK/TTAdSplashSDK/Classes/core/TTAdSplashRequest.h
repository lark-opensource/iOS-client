//
//  TTAdSplashRequest.h
//  Article
//
//  Created by Zhang Leonardo on 12-11-13.
//
//

#import <Foundation/Foundation.h>

@class TTAdSplashModel;

@interface TTAdSplashRequest : NSObject

+ (instancetype)shareInstance;

- (void)startFetchADInfo;

/**
 *  @brief 发送广告展示的请求，用于总库存两预估，详情见wiki
 *  wiki: https://docs.bytedance.net/doc/UeDoxwYBWgPQEQhRfmXEyc
 */
- (void)sendStockHint:(BOOL)showLimitNotSatisfied;

- (void)sendStockHint:(BOOL)showLimitNotSatisfied extra:(NSDictionary *)extra;


+ (NSInteger)requstShowLimit;

+ (NSInteger)requestSplashInterval;

+ (NSInteger)reqeustLeaveInterval;

/**
 *  @return 开屏停止投放时间段，在该时间段内，无论下发什么数据一律不投放广告。下发的数据为停投的开始时间和结束时间，单位是秒
 */
+ (NSArray<NSNumber *> *)requestPenaltyPeriod;

/**
 * @return 热启动App请求广告的最小时间间隔，单位:秒
 */
+ (double)requestSplashLoadInterval;


/**
 是否有必要请求 ack, 通过打包下发字段控制.
 */
+ (BOOL)isNeedRequestAck;

/// 全局的 logo_extra，不和某个创意绑定，在下发数据的最外层
+ (NSString *)globalLogExtra;

+ (NSDictionary <NSString *, NSArray*> *)periodTimeList;

/// 冷启动开屏频控间隔
+ (NSInteger)coldBootInterval;
@end
