//
//  BDPUserPluginDelegate.h
//  Pods
//
//  Created by MacPu on 2018/11/3.
//  Copyright © 2018 Bytedance.com. All rights reserved.
//

#ifndef BDPUserPluginDelegate_h
#define BDPUserPluginDelegate_h

#import "BDPBasePluginDelegate.h"

static NSString *const BDPUserPluginResultErrorKey = @"BDPUserPluginResultErrorKey";

/**
 * 跟用户相关的接口
 */
@protocol BDPUserPluginDelegate <BDPBasePluginDelegate>

/**
 * 是否已经登录
 */
- (BOOL)bdp_isLogin;

/**
 * 用户id
 *  @return 获取登录过后的用户id
 */
- (nullable NSString *)bdp_userId;


/**
 * sessionId
 * @return 获取登录过后的sessionId
 */
- (nullable NSString *)bdp_sessionId;

/**
 * 应用id
 * @return 返回appId(这边实现直接返回"0")
 */
- (nullable NSString *)bdp_appId;


/**
 设备id
 @return 返回设备ID
 */
- (nullable NSString *)bdp_deviceId;

/**
租户id
 @return 返回加密的租户id
 */
- (nullable NSString *)bdp_encyptTenantId;

/**
 * 执行登录的动作
 * @param param 登录信息
 * @param completion 登录之后的回调，h如果登录成功之后，会返回用户id 和sessionID
 */
- (void)bdp_loginWithParam:(NSDictionary *)param
                completion:(void (^)(BOOL success, NSString *userId, NSString *sessionId))completion;

/**
 定制用户信息结果回调

 @param param 处理用户信息的参数
 @param completion 完成回调
 */
- (void)bdp_customUserInfoResultWithResponse:(NSDictionary *)response
                                  completion:(void(^)(BOOL success, NSDictionary *result))completion;

@end

#endif /* BDPUserPluginDelegate_h */
