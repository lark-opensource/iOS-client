//
//  BDWebSecureLinkManager.h
//  BDWebKit
//
//  Created by bytedance on 2020/4/16.
//

#import <Foundation/Foundation.h>
#import "BDWebSecureLinkCustomSetting.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDWebSecureLinkErrorType) {
    BDWebSecureLinkErrorType_FailNavigation,                //安全中转链接导致的FailNavigation
    BDWebSecureLinkErrorType_FailProvisionalNavigation,     //安全中转链接导致的FailProvisionalNavigation
    BDWebSecureLinkErrorType_ApiRequestFail,                //安全校验接口请求失败，包括404等网络层面失败，但是如果是无网络的情况，不计入错误中止统计中，其他情况计入统计
    BDWebSecureLinkErrorType_ApiResultError,                //安全校验接口结果失败，结果失败，可能是token计算错误等结果类型的失败，不计入错误中止统计中，但是需要关注原因
    BDWebSecureLinkErrorType_ApiResultJsonTypeError,        //安全校验接口结果成功，但是结构不是json结构
    BDWebSecureLinkErrorType_ApiRequestOverTime,            //安全校验接口请求超时
};

@interface BDWebSecureLinkManager : NSObject

+ (instancetype)shareInstance;

@property (nonatomic, strong) BDWebSecureLinkCustomSetting *customSetting;

- (void)configSecureLinkDomain:(NSString *)domain;

/// 更新cache生效的时间，默认值为15min
/// @param cacheDuration cache生效时间
- (void)updateCacheDuration:(NSInteger)cacheDuration;

/// cache 通过校验了的secure link
/// @param secureLink 安全链接
- (void)cacheSecureLink:(NSString *)secureLink;

/// 校验链接是不是在安全链接的cache中
/// @param link 需要校验的链接
- (BOOL)isLinkInSecureLinkCache:(NSString *)link;

/// cache 黑名单中的链接
/// @param dangerLink 危险链接
- (void)cacheDangerLink:(NSString *)dangerLink;

/// 校验链接是不是在黑名单链接cache中
/// @param link 需要校验的链接
- (BOOL)isLinkInDangerLinkCache:(NSString *)link;

// 新方案流程不需要灰名单
///// cache 灰名单中的链接
///// @param grayLink 灰名单链接
//- (void)cacheGrayLink:(NSString *)grayLink;
//
///// 校验链接是不是在灰名单链接cache中
///// @param link 需要校验的链接
//- (BOOL)isLinkInGrayLinkCache:(NSString *)link;

/// 将正常链接包装成安全链接
/// @param link 原请求链接
/// @param aid 活动id
/// @param scene 场景
/// @param lang 语言
- (NSString *)wrapToSecureLink:(NSString *)link aid:(int)aid scene:(NSString *)scene lang:(NSString *)lang;

- (NSString *)wrapToQuickMiddlePage:(NSString *)link aid:(int)aid scene:(NSString *)scene lang:(NSString *)lang risk:(int)risk;

/// 是否为包装了的安全链接
/// @param link 链接
- (BOOL)isSecureLink:(NSString *)link;

/// 是否因为安全链接服务错误而强制通过
- (BOOL)isLinkPassForSecureLinkServiceErr;

/// 安全链接请求发生了异常，包括wkwebview的接口fail回调以及securelink的请求超时
/// @param errorType 错误类型BDWebSecureLinkErrorType
/// @param errorCode 错误码
/// @param errorMsg 错误信息
- (void)onTriggerSecureLinkError:(BDWebSecureLinkErrorType)errorType errorCode:(NSInteger)errorCode errorMsg:(NSString *)errorMsg;

/// 请求安全校验的api
- (NSString *)seclinkApi;

@end

NS_ASSUME_NONNULL_END
