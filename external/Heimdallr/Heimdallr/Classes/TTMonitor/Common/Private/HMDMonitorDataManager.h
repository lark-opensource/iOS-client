//
//  HMDMonitorDataManager.h
//  Heimdallr
//
//  Created by 王佳乐 on 2018/10/25.
//

#import <Foundation/Foundation.h>
#import "HMDConfigManager.h"

@class HMDHeimdallrConfig;
@class HMDRecordStore;
@class HMDPerformanceReporter;
@class HMDHeimdallrConfig;
@class HMDTTMonitorUserInfo;

@interface HMDMonitorDataManager : NSObject

@property (nonatomic, strong, readonly) HMDHeimdallrConfig *config;
@property (nonatomic, strong, readwrite) HMDRecordStore *store;
@property (atomic, strong, readonly) HMDPerformanceReporter *reporter;
@property (atomic, strong, readonly) HMDConfigManager *configManager;
@property (nonatomic, strong, readwrite) HMDTTMonitorUserInfo *injectedInfo;
@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, assign, readonly) BOOL needCache; // 未获取到采样率，需要缓存埋点数据
@property (nonatomic, copy, readwrite) dispatch_block_t stopCacheBlock; // 已有采样率，停止缓存的回调

- (instancetype)initMonitorWithAppID:(NSString *)appID injectedInfo:(HMDTTMonitorUserInfo *)info;
- (id)init __attribute__((unavailable("please use initWithConfig: method")));
+ (instancetype)new __attribute__((unavailable("please use initWithConfig: method")));
- (BOOL)isMainAppMonitor;

@end
