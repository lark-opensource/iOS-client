//
//  BDLHostProtocol.h
//  AFgzipRequestSerializer
//
//  Created by zys on 2020/2/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 获取宿主信息
 */
@protocol BDLHostProtocol <NSObject>

/**
 * 单例对象
 */
+ (instancetype)sharedInstance;

@optional

/// 应用appID
- (NSString *)appID;

- (NSString *)deviceID;

/**
 * 是否已经登录
 */
- (BOOL)isLogin;

/**
 * 用户id
 *  @return 获取登录过后的用户id
 */
- (NSString *)userId;

/**
 * sessionId
 * @return 获取登录过后的sessionId
 */
- (NSString *)sessionId;

/**
 * 执行登录的动作
 * @param param 登录信息
 * @param completion 登录之后的回调，h如果登录成功之后，会返回用户id 和sessionID
 */
- (void)loginWithParam:(NSDictionary *)param
            completion:(void (^)(BOOL success, NSString *userId, NSString *sessionId))completion;

/**
 * 获取手机号
 * @param param 授权手机号信息
 * @param completion 完成是的回调，success是返回是否有手机号。
 */
- (void)getPhoneNumberWithParam:(NSDictionary *)param completion:(void (^)(BOOL success))completion;

@end

NS_ASSUME_NONNULL_END
