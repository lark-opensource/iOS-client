//
//  HMDSDKMonitorManager+private.h
//  AFgzipRequestSerializer-iOS13.0
//
//  Created by zhangxiao on 2019/11/3.
//

#import "HMDSDKMonitorManager.h"

@class HMDHeimdallrConfig;
@class HMDTTMonitorUserInfo;

NS_ASSUME_NONNULL_BEGIN

@interface HMDSDKMonitorManager (Privated)

- (NSString * _Nullable)sdkHostAidWithSDKAid:(NSString * _Nonnull)sdkAid;
- (HMDTTMonitorUserInfo *_Nullable)ttMonitorUserInfoWithSDKAid:(NSString *)sdkAid;

@end

NS_ASSUME_NONNULL_END
