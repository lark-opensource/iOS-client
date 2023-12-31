//
//  HMDCPUMonitor.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDMonitor.h"

@class HMDCPUMonitorRecord;

extern HMDMonitorName _Nullable const kHMDCPUMonitorName;
extern NSString *_Nonnull const kHMDModuleCPUMonitor;//CPU监控

@interface HMDCPUMonitorConfig : HMDMonitorConfig

@property (nonatomic, assign) BOOL enableThreadCPU;

@end


@interface HMDCPUMonitor : HMDMonitor

- (nonnull instancetype)init __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));
+ (nonnull instancetype)new __attribute__((unavailable("Use +sharedMonitor to retrieve the shared instance.")));

/// CPU 的使用信息 不包含 app 的使用情况(not include record.appUsage;),如果想回去全部值,请使用 refresh 接口;
- (nonnull HMDCPUMonitorRecord *)cpuUsageInfoWithoutAPPUsage;

- (void)enterCustomSceneWithUniq:(NSString *_Nonnull)scene;
- (void)leaveCustomSceneWithUniq:(NSString *_Nonnull)scene;

+ (nonnull HMDCPUMonitorRecord *)cpuUsageInfo;

@end


