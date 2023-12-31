//
//  HMDOOMAppState.h
//  Pods
//
//  Created by 刘夏 on 2019/11/4.
//

#import <Foundation/Foundation.h>
#import "HMDMemoryUsage.h"
#import "HMDAppStateMemoryInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDOOMAppState : NSObject

/// 新数据（读不到上次i启动记录的信息）
@property (nonatomic, assign) BOOL isNewData;

@property (nonatomic, assign) BOOL isAppEnterBackground;
@property (nonatomic, assign) BOOL isAppQuitByExit;
@property (nonatomic, assign) BOOL isAppQuitByUser;
@property (nonatomic, assign) BOOL isMonitorStopped;
@property (nonatomic, assign) dispatch_source_memorypressure_flags_t memoryPressure;
@property (nonatomic, assign) NSTimeInterval memoryPressureTimestamp;

@property (nonatomic, assign) BOOL isCrash;
@property (nonatomic, assign) BOOL isWatchDog;

@property (nonatomic, assign) NSTimeInterval enterForegoundTime;
@property (nonatomic, assign) NSTimeInterval enterBackgoundTime;
@property (nonatomic, assign) NSTimeInterval latestTime;

@property (nonatomic, copy, nullable) NSString *internalSessionID;
@property (nonatomic, assign) NSTimeInterval appStartTime;
@property (nonatomic, assign) BOOL isDebug;
@property (nonatomic, assign) BOOL isXCTest;
@property (nonatomic, copy, nullable) NSString *appVersion;
@property (nonatomic, copy, nullable) NSString *buildVersion;
@property (nonatomic, copy, nullable) NSString *sysVersion;
@property (nonatomic, copy, nullable) NSString *libraryPath;
@property (nonatomic, assign) unsigned long exception_main_address;
@property (nonatomic, assign) BOOL isSlardarMallocInuse;
@property (nonatomic, assign) size_t slardarMallocUsageSize;

@property (nonatomic, assign) HMDOOMAppStateMemoryInfo memoryInfo;

@property (nonatomic, assign) int appContinuousQuitTimes;

@property (nonatomic, copy, nullable) NSString *thermalState;

@property (nonatomic, assign) BOOL isWeakWatchDog;
@property (nonatomic, assign) BOOL isCPUException;

@property (nonatomic, assign) double lastSenceChangedTime;


// TODO: 这几个事件目前还没实现监控，完善后可以增加 FOOM 事件的准确率
// @property (nonatomic, assign) BOOL isAppBackgroundFetch;
// @property (nonatomic, assign) BOOL isAppWillSuspend;
// @property (nonatomic, assign) BOOL isAppSuspendKilled;
// @property (nonatomic, assign) BOOL isAppMainThreadBlocked;

+ (instancetype)sharedInstance;

/// 用于更新字段，会自动序列化到磁盘
- (void)update:(void (^)(HMDOOMAppState *state))block;

/// 用于更新字段，会自动序列化到磁盘
/// msync: 调用msync方法立刻同步到磁盘
- (void)update:(void (^)(HMDOOMAppState *state))block msync:(BOOL)msyncFlag;

/// 更新deadlock,  runtimelock时，需要用C方法
void hmd_updateDeadlockState(BOOL isDeadlock);

@end

NS_ASSUME_NONNULL_END
