//
//  HMDOOMCrashDetector.m
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

/*
   [  OOM 检测原理 ]
     * 注册了 applicationDidBecomeActive willEnterBackground willTerminate
     * 注册了 atexit() signal(SIGABRT, handle)
     * 注册了 HMDCrash @"crashNotification"
     * 原理是判断上次退出原因, 如果无法决定退出原因, 认为是一次 OOM
*/

#import "HMDOOMCrashDetector.h"
#import "HMDAppExitReasonDetector.h"
#include "pthread_extended.h"

/* 定时记录当前的 Memory 状态的时间间隔参数 (单位: s) */
#define HMDOOMCrashDetectorUpdateSystemStateIntervalLimit    1
#define HMDOOMCrashDetectorUpdateSystemStateIntervalDefault  60

// 同步 HMDOODCrashConfig 仅在 start 前设置前有用 (未加锁, 请加锁访问, 只可读, 不允许写)
static NSTimeInterval updateSystemStateInterval = HMDOOMCrashDetectorUpdateSystemStateIntervalDefault;
// 全局参数
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

@implementation HMDOOMCrashDetector

#pragma mark - Essential Functionarity (Start/Stop)
+ (NSString *const)logFileDictionary {
    return [HMDAppExitReasonDetector logFileDictionary];
}

/// 主要的简单的开启方法
+ (void)startWithDelegate:(id<HMDOOMCrashDetectorDelegate>)delegate {   // @ in_sync
    //void
}

+ (void)start {
    //void
}

/// 不会完全取消一些注册的 callback 但是会尽力
/// 同时会写入上一次 OOM 已经停止, 不会在下一次 OOM 判断时出现问题
+ (void)stop {
}

+ (void)updateConfig:(HMDOOMCrashConfig *)config {
}

#pragma mark Info saving method for external invocation

+ (void)triggerCurrentEnvironmentInfomationSaving {
    [HMDAppExitReasonDetector triggerCurrentEnvironmentInformationSaving];
}

+ (void)triggerCurrentEnvironmentInfomationSavingWithAction:(NSString *)action {
    [HMDAppExitReasonDetector triggerCurrentEnvironmentInformationSavingWithAction:action];
}

+ (void)triggerCurrentEnvironmentInformationSaving {
    [HMDAppExitReasonDetector triggerCurrentEnvironmentInformationSavingWithAction:@"user sendMsg"];
}

+ (void)triggerCurrentEnvironmentInformationSavingWithAction:(NSString *)action {
    [HMDAppExitReasonDetector triggerCurrentEnvironmentInformationSavingWithAction:action];
}

#pragma mark - API for external invocation  (CAN NOT CALL INTERNALLY⚠️ )
+ (void)setSystemStateUpdateInterval:(NSTimeInterval)interval {
    if(interval < HMDOOMCrashDetectorUpdateSystemStateIntervalLimit)
        interval = HMDOOMCrashDetectorUpdateSystemStateIntervalLimit;
    pthread_mutex_lock(&mutex);
    updateSystemStateInterval = interval;
    pthread_mutex_unlock(&mutex);
}

+ (NSTimeInterval)systemStateUpdateInterval {
    pthread_mutex_lock(&mutex);
    NSTimeInterval temp = updateSystemStateInterval;
    pthread_mutex_unlock(&mutex);
    return temp;
}

+ (BOOL)findOrCreateDirectoryInPath:(NSString *)path {
    return [HMDAppExitReasonDetector findOrCreateDirectoryInPath:path];
}

@end
