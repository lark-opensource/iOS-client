//
//  DouyinOpenSDKObjects+Privates.h
//
//
//  Created by Spiker on 2019/7/9.
//
// 双端对齐错误码: https://bytedance.feishu.cn/wiki/wikcn67w6GxyvDvKqGI0A0qj7qh

#import "DouyinOpenSDKObjects.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *kDouyinOpenSDKURLOAuthServiceName;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKURLShareServiceName;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKURLJumpServiceName;

FOUNDATION_EXTERN NSString *kDouyinOpenSDKURLHostReqPrefixString;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKURLHostRespPrefixString;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKBridgeURLHostString;

FOUNDATION_EXTERN NSString *kDouyinOpenSDKRequestIdKey;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKResponseIdKey;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKApiVersionKey;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKConsumerKeyKey;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKErrorCodeKey;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKErrorMsgKey;
FOUNDATION_EXTERN NSString *kDouyinOpenSDKFromPlatformKey;

// extraInfo 里的 key，字符串枚举（不对外直接暴露的放在此分类，对外的放主类。防止被外部知道后乱塞数据）
FOUNDATION_EXTERN DYOpenExtraInfoKey const DYOpenExtraInfoKeyShowAccountDialog; // value: string，传 1 时在抖音端内自动呼起切换账号面板（前提：允许使用切换账号功能，如实验开启等）
FOUNDATION_EXTERN DYOpenExtraInfoKey const DYOpenExtraInfoKeyShowMobExtraParams; // value: dictionary，额外上报数据，透传到抖音端内上报

@interface DouyinOpenSDKBaseRequest ()

/**
 Douyin App发送请求的id
 */
@property (nonatomic, copy, readwrite, nonnull) NSString *provider_requestId;

/**
 语言
 */
@property (nonatomic, copy, readwrite, nullable) NSString *lang;

/**
 国家
 */
@property (nonatomic, copy, readwrite, nullable) NSString *country;

/**
 Douyin 打开第三方应用使用的URL 或 第三方程序发送请求给平台程序使用的URL
 */
@property (nonatomic, strong, readwrite, nullable) NSURL *originalURL;

/**
 请求初始创建时间
 */
@property (nonatomic, strong, readwrite, nonnull) NSDate *createDate;

/**
 请求发送时间
 */
@property (nonatomic, strong, readwrite, nonnull) NSDate *sendDate;

/**
 请求发送->收到对应响应的时间
 */
@property (nonatomic, strong, readwrite, nonnull) NSDate *endDate;

@end


@interface DouyinOpenSDKBaseResponse ()

@property (nonatomic, copy, nullable) NSString *originRequestID;
@property (nonatomic, copy, readwrite, nonnull) NSString *responseId;
@property (nonatomic, copy, readwrite, nullable) NSString *lang;
@property (nonatomic, copy, readwrite, nullable) NSString *country;

NS_ASSUME_NONNULL_END
@end

