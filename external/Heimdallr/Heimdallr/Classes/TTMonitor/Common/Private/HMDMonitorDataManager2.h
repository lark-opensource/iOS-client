//
//  HMDMonitorDataManager2.h
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 16/3/2022.
//

#import <Foundation/Foundation.h>
#import "HMDConfigManager.h"

NS_ASSUME_NONNULL_BEGIN

@class HMDHeimdallrConfig;
@class HMDTTMonitorUserInfo;

@interface HMDMonitorDataManager2 : NSObject

@property (nonatomic, strong, readonly) HMDHeimdallrConfig *config;
@property (atomic, strong, readonly) HMDConfigManager *configManager;
@property (nonatomic, strong, readwrite) HMDTTMonitorUserInfo *injectedInfo;
@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, assign, readonly) BOOL needCache; // 未获取到采样率，需要缓存埋点数据
@property (nonatomic, copy, readwrite) dispatch_block_t stopCacheBlock; // 已有采样率，停止缓存的回调

- (instancetype)initMonitorWithAppID:(NSString *)appID injectedInfo:(HMDTTMonitorUserInfo *)info;
- (id)init __attribute__((unavailable("please use initWithConfig: method")));
+ (instancetype)new __attribute__((unavailable("please use initWithConfig: method")));

@end

NS_ASSUME_NONNULL_END
