//
//  NetworkManager.h
//  DouyinOpenSDKExtension
//
//  Created by bytedance on 2022/2/10.
//

#import <UIKit/UIKit.h>
#import "DYOpenNetworkManager.h"
#import "DouyinOpenSDKProfileContext.h"
#import "DouyinOpenSDKProfile.h"

NS_ASSUME_NONNULL_BEGIN

@interface DYOpenProfileNetworkManager : NSObject

/// 获取资料
+(void)requestProfileGuardWithContext:(DouyinOpenSDKProfileContext *)context cardType:(DouyinOpenSDKProfileCardType)cardType completion:(DouyinOpenNetworkCompletion)completion;

/// 获取视频列表
+(void)requestVideoGuardWithContext:(DouyinOpenSDKProfileContext *)context awemeIds:(NSArray<NSString *>*)awemeIds cardType:(DouyinOpenSDKProfileCardType)cardType completion:(DouyinOpenNetworkCompletion)completion;

/// 更新名片展示方式
+(void)updateProfileGuardWithShowType:(DYOpenProfileShowType)showType cardType:(DouyinOpenSDKProfileCardType)cardType openId:(NSString*)openId accessToken:(NSString *)accessToken completion:(DouyinOpenNetworkCompletion)completion;

@end

NS_ASSUME_NONNULL_END
