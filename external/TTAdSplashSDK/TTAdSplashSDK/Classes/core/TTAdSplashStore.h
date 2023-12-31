//
//  TTAdSplashParamsStore.h
//  TTAdSplashSDK
//
//  Created by yin on 2017/8/7.
//  Copyright © 2017年 yin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTAdSplashHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface TTAdSplashStore : NSObject

@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, copy) NSString *openUDID;
@property (nonatomic, copy) NSString *MACAddress;
@property (nonatomic, copy) NSString *OS;
@property (nonatomic, strong) NSDictionary *IPAddresses;
@property (nonatomic, copy) NSString *latitude;
@property (nonatomic, copy) NSString *longitude;

//开屏必要参数
@property (nonatomic, copy) NSString *access;
@property (nonatomic, copy) NSString *display_density;

//common params
@property (nonatomic, copy) NSString* carrier;
@property (nonatomic, copy) NSString* mcc_mnc;
@property (nonatomic, copy) NSString* iid;
@property (nonatomic, copy) NSString* ac;
@property (nonatomic, copy) NSString* channel;
@property (nonatomic, copy) NSString* appid;
@property (nonatomic, copy) NSString* app_name;
@property (nonatomic, copy) NSString* version_code;
@property (nonatomic, copy) NSString* version_name;
@property (nonatomic, copy) NSString* device_platform;

@property (nonatomic, copy) NSString* ab_version;
@property (nonatomic, copy) NSString* ab_client;
@property (nonatomic, copy) NSString* ab_group;
@property (nonatomic, copy) NSString* ab_feature;
@property (nonatomic, copy) NSString* abflag;
@property (nonatomic, copy) NSString* device_type;
@property (nonatomic, copy) NSString* device_brand;

@property (nonatomic, copy) NSString* language;
@property (nonatomic, copy) NSString* os_api;
@property (nonatomic, copy) NSString* os_version;
@property (nonatomic, copy) NSString* manifest_version_code;
@property (nonatomic, copy) NSString* resolution;
@property (nonatomic, copy) NSString* update_version_code;
@property (nonatomic, copy) NSString* userId;
@property (nonatomic, copy) NSString* isOldMode;

@property (nonatomic, copy, readonly) NSDictionary *extraParams;

+ (instancetype)shareInstance;


/**
 SDK的常规参数， 会映射到 上面的 属性当中
 @param paramsBlock 获取宿主SDK配置参数
 */
- (void)registerParamsBlock:(TTAdSplashParamBlock)paramsBlock;

/**
 业务需要透传的参数
 @param paramsBlock 获取宿主需要透传参数
 */
- (void)registerExtraParamsBlock:(TTAdSplashParamBlock)paramsBlock;

- (NSDictionary *)splashCommonParams;

+ (NSString *)splashUrl;

/**
 * 调用urlAppendDefaultParams:
 * url == [self splashUrl];
 */
+ (NSString *)splashUrlAppendParams;

/**
 * 调用url:withParamDict:
 * paramDict = [self defaultParamsDict]
 */
+ (NSString *)urlAppendDefaultParams:(NSString *)url;
/**
 *  @brief 根据 URL
 *  @param url baseUrlString
 *  @param paramDict 参数dict
 */
+ (NSString *)url:(NSString *)url withParamDict:(nullable NSDictionary *)paramDict;

/**
 *  @brief 默认请求参数
 *  [[TTAdSplashStore shareInstance] splashCommonParams]] + [[TTAdSplashStore shareInstance] extraParams]
 */
+ (NSDictionary *)defaultParamsDict;

+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
