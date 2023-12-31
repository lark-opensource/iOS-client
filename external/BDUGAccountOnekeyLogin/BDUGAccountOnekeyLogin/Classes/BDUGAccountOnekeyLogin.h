//
//  BDUGAccountOnekeyLogin.h
//  BDUGAccountOnekeyLogin
//
//  Created by 王鹏 on 2019/5/7.
//

#import <Foundation/Foundation.h>
#import "BDUGAccountOneKeyDef.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDUGAccountOneKeyLoginDelegate <NSObject>

- (void)event:(NSString *)event params:(NSDictionary *)params;

@end


@interface BDUGOnekeyServiceConfiguration : NSObject

@property (nonatomic, copy) NSString *serviceName;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appSecret;
@property (nonatomic, assign) BOOL isTestChannel;

@end


@interface BDUGOnekeyAuthInfo : NSObject

@property (nonatomic, copy) NSString *token;
/// 新版电信SDK 需要
@property (nonatomic, copy) NSString *gwAuth;

@end


@interface BDUGAccountOnekeyLogin : NSObject

/// 当前流量卡所属运营商
@property (nonatomic, copy, readonly) NSString *service;

/// 移动取号、获取token 超时限制，单位 s, 默认3s
@property (nonatomic, assign) NSTimeInterval mobileTimeoutInterval;
/// 联通取号、获取token 超时限制，单位 s, 默认3s
@property (nonatomic, assign) NSTimeInterval unionTimeoutInterval;
/// 电信取号、获取token 超时限制，单位 s, 默认3s
@property (nonatomic, assign) NSTimeInterval telecomTimeoutInterval;

/// 业务方传入的需要在取号时传入的埋点参数
@property (nonatomic, strong) NSDictionary *extraTrackInfoOfGetPhoneNumber;
/// 业务方传入的需要在获取token时传入的埋点参数
@property (nonatomic, strong) NSDictionary *extraTrackInfoOfGetToken;

@property (nonatomic, weak) id<BDUGAccountOneKeyLoginDelegate> delegate;

+ (instancetype)sharedInstance;

/// 更新SDK相关配置
/// @{ @"onekey_login_config": @{
///      @"ct_config": @{ @"is_enable": @(1), @"timeout_sec": @(3), @"need_data": @(1) },
///      @"cu_config": @{ @"is_enable": @(1), @"timeout_sec": @(3), @"need_data": @(1) },
///      @"cm_config": @{ @"is_enable": @(1), @"timeout_sec": @(3), @"need_data": @(1) } } }
/// @param settings setting接口返回的配置，SDK内部会解析自己所需要的
- (void)updateSDKSettings:(NSDictionary *)settings;

/// 当前网络连接状态
- (BDUGAccountNetworkType)currentNetworkType;

/// 注册一键登录
/// @param serviceName 运营商 移动 BDUGAccountOnekeyMobile，电信 BDUGAccountOnekeyTelecom，联通 BDUGAccountOnekeyUnion
/// @param appId 从运营商申请的appId
/// @param appKey 从运营上申请的appKey
/// @param isTestChannel isTestChannel 已废弃
- (void)registerOneKeyLoginService:(NSString *)serviceName appId:(NSString *)appId appKey:(NSString *)appKey isTestChannel:(BOOL)isTestChannel DEPRECATED_MSG_ATTRIBUTE("请使用[BDUGAccountOnekeyLogin registerOneKeyLoginService:appId:appSecret] isTestChannel已失效");

/// 注册一键登录
/// @param serviceName 运营商 移动 BDUGAccountOnekeyMobile，电信 BDUGAccountOnekeyTelecom，联通 BDUGAccountOnekeyUnion
/// @param appId 从运营商申请的appId
/// @param appKey 从运营上申请的appKey
- (void)registerOneKeyLoginService:(NSString *)serviceName appId:(NSString *)appId appKey:(NSString *)appKey;

/// 获取一键登录的掩码手机号
/// @param completedBlock 获取手机掩码结果回调
- (void)getOneKeyLoginPhoneNumberCompleted:(void (^)(NSString *_Nullable phoneNumber, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock;

/// 获取一键登录的掩码手机号
/// @param extraTrackInfo 业务方自定义需要附加的埋点参数
/// @param completedBlock 获取手机掩码结果回调
- (void)getOneKeyLoginPhoneNumberWithExtraTrackInfo:(NSDictionary *_Nullable)extraTrackInfo
                                          completed:(void (^)(NSString *_Nullable phoneNumber, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock;

/// 获取一键登录的认证信息
/// @param extraTrackInfo 业务方自定义需要附加的埋点参数
/// @param completedBlock 获取手机掩码结果回调
- (void)getOneKeyAuthInfoWithExtraTrackInfo:(NSDictionary *_Nullable)extraTrackInfo
                                  completed:(void (^)(BDUGOnekeyAuthInfo *_Nullable authInfo, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock;

/// 获取用于本机号码验证的token
/// @param extraTrackParams 额外埋点参数
/// @param completedBlock 回调
- (void)getMobileValidateTokenWithExtraTrackParams:(NSDictionary *_Nullable)extraTrackParams
                                         completed:(void (^)(NSString *_Nullable token, NSString *_Nullable serviceName, NSError *_Nullable error))completedBlock;

@end


@interface ServiceConfiguration : BDUGOnekeyServiceConfiguration

@end

NS_ASSUME_NONNULL_END
