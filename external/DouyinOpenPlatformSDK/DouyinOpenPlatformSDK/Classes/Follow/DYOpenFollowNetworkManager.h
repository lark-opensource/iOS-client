//
//  DYOpenFollowNetworkManager.h
//  Pods
//
//  Created by bytedance on 2022/8/2.
//

#import <TTNetworkManager/TTPostDataHttpRequestSerializer.h>

typedef void (^DouyinFollowNetworkCompletion)(NSDictionary  * _Nullable userInfo, NSInteger errCode, NSString* _Nullable errMsg);
typedef void (^DouyinFollowUserCompletion)(NSInteger errCode, NSString* _Nullable errMsg);

NS_ASSUME_NONNULL_BEGIN

@interface DYOpenFollowRequestJSONSerializer: TTDefaultHTTPRequestSerializer

@end

@interface DYOpenFollowNetworkManager : NSObject

/// 获取关注信息
+ (void)requestFollowInfoWithOpenId:(NSString *)openId
                       targetOpenId:(NSString *)targetOpenId
                        accessToken:(NSString *)accessToken
                          clientKey:(nullable NSString *)clientKey
                         completion:(DouyinFollowNetworkCompletion)completion;

// 关注组件加关注
+ (void)followWithOpenId:(NSString *)openId
            targetOpenId:(NSString *)targetOpenId
             accessToken:(NSString *)accessToken
               clientKey:(nullable NSString *)clientKey
              completion:(DouyinFollowNetworkCompletion)completion;

// 游戏名片加关注
+(void)followUserWithOpenId:(NSString *)openId targetOpenId:(NSString *)targetOpenId accessToken:(NSString *)accessToken completion:(DouyinFollowUserCompletion)completion;

@end

NS_ASSUME_NONNULL_END
