//
//  TTAdSplashStringUtils.h
//  TTAdSplashSDK
//
//  Created by yin on 2017/8/2.
//  Copyright © 2017年 yin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTAdSplashStringUtils : NSObject

/**
 *  使用str 生成NSURL, 如果生成不成功， 则尝试用UTF8，再不成功，则返回nil
 *
 *  @param str 字符串
 *
 *  @return URL
 */
+ (NSURL *)URLWithURLString:(NSString *)str;

/**
 *  将含有参数的NSDictionary转换为url格式--TTURLUtils做相应替换，不做encode
 *
 *  @param parameters 参数列表
 *
 *  @return urlString
 */
+ (NSString *)URLQueryStringWithoutEncodeWithParameters:(NSDictionary *)parameters;

/**
 *  将字符串转换为Base64位格式
 *
 *  @param str 字符串
 *
 *  @return Base64格式NSString
 */
+ (nullable NSString *)decodeStringFromBase64Str:(NSString *)str;

/**
 *  将NSTimeInterval转换为NSString，格式为yyyy-MM-dd HH:mm
 *
 *  @param timerInterval 时间戳
 *
 *  @return 时间字符串
 */
+ (NSString*)simpleDateStringSince:(NSTimeInterval)timerInterval;

/**
 *  将NSTimeInterval转换为NSString，格式为yyyy-MM-dd
 *
 *  @param timerInterval 时间戳
 *
 *  @return 字符串时间戳
 */
+ (NSString*)onlyDateStringSince:(NSTimeInterval)timerInterval;

@end

NS_ASSUME_NONNULL_END
