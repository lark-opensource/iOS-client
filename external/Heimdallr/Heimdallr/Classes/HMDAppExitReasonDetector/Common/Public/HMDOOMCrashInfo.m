//
//  HMDOOMCrashInfo.m
//  Pods
//
//  Created by yuanzhangjing on 2020/3/1.
//

#import "HMDOOMCrashInfo.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDDiskUsage.h"
#import "HMDOOMAppState.h"

@implementation HMDOOMCrashInfo

- (instancetype)initWithAppState:(HMDOOMAppState *)appState
                       extraDict:(NSDictionary *)extraDict
{
    if (self = [self init]) {
        self.memoryPressure = appState.memoryPressure;
        self.memoryPressureTimestamp = appState.memoryPressureTimestamp;
        
        self.enterForegoundTime = appState.enterForegoundTime;
        self.enterBackgoundTime = appState.enterBackgoundTime;
        self.latestTime = appState.latestTime;
        
        self.internalSessionID = appState.internalSessionID;
        self.appStartTime = appState.appStartTime;

        self.appVersion = appState.appVersion;
        self.buildVersion = appState.buildVersion;
        self.sysVersion = appState.sysVersion;
        self.memoryInfo = appState.memoryInfo;
        self.exception_main_address = appState.exception_main_address;
        
        self.isSlardarMallocInuse = appState.isSlardarMallocInuse;
        self.slardarMallocUsageSize = appState.slardarMallocUsageSize;
        
        self.updateTime = [extraDict hmd_doubleForKey:@"update_time"];
        self.lastScene = [extraDict hmd_stringForKey:@"last_scene"];
        self.operationTrace = [extraDict hmd_dictForKey:@"operation_trace"];
#if RANGERSAPM
        self.freeDisk = [extraDict hmd_doubleForKey:@"free_disk"];
#endif
        self.freeDiskBlockSize = [extraDict hmd_doubleForKey:@"free_disk"];
        self.sessionID = [extraDict hmd_stringForKey:@"session_id"];
        NSInteger freeDiskBlocks = [extraDict hmd_integerForKey:@"d_zoom_free"];
        if (freeDiskBlocks == 0) {
            double freeDisk = [extraDict hmd_doubleForKey:@"free_disk"];
            freeDiskBlocks = [HMDDiskUsage getDisk300MBBlocksFrom:freeDisk];
        }
        self.freeDiskBlockSize = freeDiskBlocks;
        self.appContinuousQuitTimes = appState.appContinuousQuitTimes;
        self.thermalState  = appState.thermalState;
        self.isCPUException = appState.isCPUException;
        NSTimeInterval lastTimestamp = MAX(appState.latestTime, appState.memoryInfo.updateTime);
        self.inAppTime = lastTimestamp - appState.appStartTime;
        self.inLastSceneTime = appState.lastSenceChangedTime > 0 ? lastTimestamp - appState.lastSenceChangedTime : self.inAppTime;
        self.restartInterval = [extraDict hmd_doubleForKey:@"restart_interval"];
        self.isAppEnterBackground = appState.isAppEnterBackground;
        
    }
    return self;
}

@end
