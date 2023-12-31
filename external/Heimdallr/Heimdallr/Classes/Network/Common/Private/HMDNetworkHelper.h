//
//  HMDNetworkHelper.h
//  Heimdallr
//
//  Created by fengyadong on 2018/1/26.
//

#import <Foundation/Foundation.h>

@interface HMDNetworkHelper : NSObject

/**
 *  返回网络连接状态的字符串描述, SIM 卡为主卡
 *
 *  @return 字符串描述
 */
+ (nullable NSString *)connectTypeName;

/**
 *  返回网络连接状态的字符串描述, SIM卡的状态读取的是流量卡的
 *
 *  @return 字符串描述
 */
+ (nullable NSString *)connectTypeNameForCellularDataService;

/**
 *  返回网络连接状态的数字描述，用户可能有多个sim卡, 这里是以主卡为准
 *
 *  @return 数字描述
 */
+ (NSInteger)connectTypeCode;

/**
 *  返回网络连接状态的数字描述，用户可能有多个sim卡, 这里是以流量卡为准
 *
 *  @return 数字描述
 */
+ (NSInteger)connectTypeCodeForCellularDataService;

#if !SIMPLIFYEXTENSION
/**
 *  获取carrierName
 *
 *  @return carrierName
 */
+ (nullable NSString *)carrierName;

/**
 *  获取mobileCountryCode，用户可能有多个sim卡
 *
 *  @return mobileCountryCode
 */
+ (nullable NSString *)carrierMCC;

/**
 *  获取mobileNetworkCode，用户可能有多个sim卡
 *
 *  @return mobileNetworkCode
 */
+ (nullable NSString *)carrierMNC;

/**
 *  获取运营商所在国家/地区编码，用户可能有多个sim卡
 *
 *  @return 运营商所在国家/地区编码，根据国际惯例要大写，如CN，US等
 */
+ (nullable NSArray<NSString *> *)carrierRegions;

#endif

// 获取当前的网络制式，例如：GPRS、CDMA等，用户可能有多个sim卡
+ (nullable NSString *)currentRadioAccessTechnology;

/// current network quality code
+ (NSInteger)currentNetQuality;

@end
