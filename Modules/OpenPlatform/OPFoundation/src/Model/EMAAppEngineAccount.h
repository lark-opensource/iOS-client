//
//  EMAAppEngineAccount.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2020/2/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMAAppEngineAccount : NSObject

/// 获取lark登录以后返回的user session
@property (nonatomic, copy, readonly) NSString *userSession;

/// 用于唯一标识一个 账户 的 token，用于隔离多账户的小程序数据
@property (nonatomic, copy, readonly) NSString *accountToken;

/// 请谨慎使用，禁止直接日志和上报（需要脱敏）
@property (nonatomic, copy, readonly) NSString *userID;

/// 脱敏后的用户ID
@property (nonatomic, copy, readonly) NSString *encyptedUserID;

/// 请谨慎使用，禁止直接日志和上报（需要脱敏）
@property (nonatomic, copy, readonly) NSString *tenantID;

/// 脱敏后的租户ID
@property (nonatomic, copy, readonly) NSString *encyptedTenantID;

- (instancetype)initWithAccount:(NSString * _Nonnull)accountToken
                         userID:(NSString * _Nonnull)userID
                    userSession:(NSString * _Nonnull)userSession
                       tenantID:(NSString * _Nonnull)tenantID;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

+ (instancetype _Nonnull)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
