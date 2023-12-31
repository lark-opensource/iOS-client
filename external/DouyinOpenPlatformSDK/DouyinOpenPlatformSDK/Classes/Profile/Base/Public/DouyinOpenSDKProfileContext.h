//
//  DouyinOpenSDKProfileContext.h
//  Pods
//
//  Created by bytedance on 2022/7/1.
//

@interface DouyinOpenSDKProfileContext : NSObject

/// 登录用户 openID
@property (nonatomic, copy, nonnull) NSString *openId;

/// 登录用户 token
@property (nonatomic, copy, nonnull) NSString *accessToken;

/// 目标用户 openID
@property (nonatomic, copy, nonnull) NSString *targetOpenId;

/// 是否使用更安全的 clientTicket 方案，默认 NO。如果为 YES 的话 clientToken 可传空
@property (nonatomic, assign) BOOL useClientTicket;

/// 目标用户 token。如果使用 clientTicket 方案则可传 nil
@property (nonatomic, copy, nullable) NSString *clientToken;

/// 是否当前登录用户
- (BOOL)isHost;

/// 参数是否合法
- (BOOL)isValidParams;

@end
