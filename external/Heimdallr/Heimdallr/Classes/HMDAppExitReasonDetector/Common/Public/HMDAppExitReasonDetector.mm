//
//  HMDAppExitReasonDetector.m
//  Heimdallr-a8835012
//
//  Created by zhouyang11 on 2022/9/16.
//
#import "HMDAppExitReasonDetector+LogUpload.h"
#import "HMDAppExitReasonDetector.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#include "pthread_extended.h"
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>
#import "HMDALogProtocol.h"
#import "hmd_debug.h"
#import "HMDCPUUtilties.h"
#import "HMDDiskUsage.h"
#import "HMDMemoryUsage.h"
#import "HMDSessionTracker.h"
#import "HMDMacro.h"
#import "Heimdallr+Private.h"
#import "HMDDynamicCall.h"
#import "HMDSwizzle.h"
#import "HMDOOMAppState.h"
#import "HeimdallrUtilities.h"
#import "HMDWeakProxy.h"
#import "HMDDeviceImageTool.h"
#import "NSDictionary+HMDJSON.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNumberUtils.h"
#import "NSData+HMDJSON.h"
#import "HMDOOMCrashInfo.h"
#import "HMDInfo+AppInfo.h"
#import "HMDInfo+SystemInfo.h"
#import "HMDInfo+AutoTestInfo.h"
#import "HMDOOMCrashSDKLog.h"
#import <malloc/malloc.h>
#import "HMDFileTool.h"
#import "hmd_thread_backtrace.h"
#import "HMDGCD.h"
#import "HMDTracker.h"
#import "HMDExcludeModuleHelper.h"
#import "HMDUserDefaults.h"
#import "HMDServiceContext.h"
#import "HMDAppVCPageViewRecord.h"
#import "HMDCrashDirectory+Path.h"
#import "HMDCrashEnvironmentBinaryImages.h"
#import "HMDUITrackerTool.h"
#import "UIApplication+HMDUtility.h"
#import "HMDFileUploader.h"
#import "HMDFileWriter.hpp"
#import "HMDMemoryLogInfo.hpp"
#import "HMDCrashDirectory+Path.h"
#import "HMDCrashEnvironmentBinaryImages.h"
#import "HMDUITrackerTool.h"
#import "UIApplication+HMDUtility.h"
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDMonitorService.h"

/* 定时记录当前的 Memory 状态的时间间隔参数 (单位: s) */
#define HMDAppExitReasonDetectorUpdateSystemStateIntervalLimit    1
#define HMDAppExitReasonDetectorUpdateSystemStateIntervalDefault  60

static NSString * const kHMDUITrackerSceneDidChangeNotification = @"kHMDUITrackerSceneDidChangeNotification";
static NSString * const kHMDSlardarMallocInuseNotification = @"kHMDSlardarMallocInuseNotification";

// watchdog notification
static NSString * const HMD_OOM_watchDogTimeoutNotification = @"HMDWatchDogTimeoutNotification";
static NSString * const HMD_OOM_watchDogRecoverNotification = @"HMDWatchDogRecoverNotification";
static NSString * const HMD_OOM_watchDogMaybeNotification = @"HMDWatchDogMaybeHappenNotification";

// cpuexception natification
static NSString * const HMD_OOM_CPUExceptionHappenNotification = @"HMDCPUExceptionHappenNotification";
static NSString * const HMD_OOM_CPUExceptionRecoverNotification = @"HMDCPUExceptionRecoverNotification";

// exposed to outside
NSString * const kHMD_OOM_DirectoryName = @"HMD_OOM_Info";
NSString * const HMD_OOM_LogFileName = @"oom_log_info";

// 全局参数
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
static NSTimer *callbackTimer = nil;
static BOOL customTimer = NO;
static NSOperationQueue *serialQueue;                       // maxConcurrentOperationCount == 1 做成 serial
static BOOL isMonitorLaunched;                              // 是否 Monitor 开启 回掉方法是否储存值
static BOOL isSlardarMallocInuse;                           // SlardarMalloc是否切换成功
typedef enum {
    HMDOOMCrashAppStateUpdateTryOptimize = 0,               // So any request needs pending
    HMDOOMCrashAppStateUpdatePending,                       // When in this state, feed back will come back soon later
    HMDOOMCrashAppStateUpdateDecided                        // It is setted by pending callbacks
} HMDOOMCrashAppStateUpdate;

typedef void (*HMDOOMCrash_applicationStateIMP)(id thisSelf, SEL selector, UIApplication *application);

API_AVAILABLE(ios(13.0))
typedef void (*HMDOOMCrash_sceneStateIMP)(id thisSelf, SEL selector, UIScene *scene);

static HMDOOMCrashAppStateUpdate optimizeOption;
static BOOL requestedAppStateUpdate;

static BOOL willEnterForegroundOptimized;
static BOOL didEnterBackgroundOptimized;
static BOOL willResignActiveOptimized;
static BOOL willTerminateOptimized;
static BOOL didBecomeActiveOptimized;

static HMDOOMCrash_applicationStateIMP willEnterForegroundIMP;
static HMDOOMCrash_applicationStateIMP didEnterBackgroundIMP;
static HMDOOMCrash_applicationStateIMP willTerminateIMP;
static HMDOOMCrash_applicationStateIMP willResignActiveIMP;
static HMDOOMCrash_applicationStateIMP didBecomeActiveIMP;

API_AVAILABLE(ios(13.0))
static HMDOOMCrash_sceneStateIMP sceneWillEnterForegroundIMP;
API_AVAILABLE(ios(13.0))
static HMDOOMCrash_sceneStateIMP sceneDidEnterBackgroundIMP;
API_AVAILABLE(ios(13.0))
static HMDOOMCrash_sceneStateIMP sceneWillResignActiveIMP;
API_AVAILABLE(ios(13.0))
static HMDOOMCrash_sceneStateIMP sceneDidBecomeActiveIMP;

static NSTimeInterval updateSystemStateInterval = 0;

static dispatch_block_t s_foregroundDelayBlock = nil;

static BOOL isRunningTests(void);
static CFTimeInterval appStartTime(void);

static NSMutableSet *_delegatesSet = nil; //这里我们可以把它声明为静态变量
static BOOL _finishDetection = NO;

//private config
static BOOL _isFixNoDataMisjudgment = YES;
static BOOL _isNeedBinaryInfo = NO;

static HMDOOMCrashInfo* relaunchInfo = nil;
static HMDApplicationRelaunchReason relaunchReason = HMDApplicationRelaunchReasonNoData;
static NSString* relaunchReasonStr = @"";
static NSString *HMDAppExitBeforeHeimdallrStart = @"is_app_exit_before_heimdallr_start";
static NSString *HMDAppExitBefore10Second = @"is_app_exit_before_10_second";
static BOOL lastHMDAppExitBeforeHeimdallrStart = NO;
static BOOL lastHMDAppExitBefore10Second = NO;

typedef NS_ENUM(NSUInteger, HMDAppLifeCycleType) {
    HMDAppLifeCycleTypeDefault,     // undefined
    HMDAppLifeCycleTypeNoneScene,   // lower than iOS13 or without scene support
    HMDAppLifeCycleTypeMultiScene,  // multi windows on ipad or Carplay on iPhone
    HMDAppLifeCycleTypeSingleScene  // single scene on iPhone or iPad
};

static HMDAppLifeCycleType appLifeCycleType = HMDAppLifeCycleTypeDefault;
static NSTimeInterval time_start = 0;
static HMDFileWriter::Writer *log_info_writer = nullptr;
const size_t MAIN_FILE_DEFAULT_SIZE = getpagesize();
const size_t MAIN_FILE_SIZE = getpagesize();

static double getAppUsedMemoryPercent(HMDOOMAppStateMemoryInfo memoryInfo) {
    uint64_t appTotalMemory = hmd_getDeviceMemoryLimit();
    uint64_t lastAppTotalMemory = memoryInfo.appMemory + memoryInfo.availableMemory;
    if (appTotalMemory > 0) {
        return double(memoryInfo.appMemory) / appTotalMemory;
    }else if (lastAppTotalMemory > 0) {
        return double(memoryInfo.appMemory) / lastAppTotalMemory;
    }
    return -1;
}

static double getDeviceFreeMemoryPercent(HMDOOMAppStateMemoryInfo memoryInfo) {
    uint64_t totalSizeLevel = hmd_calculateMemorySizeLevel(memoryInfo.totalMemory);
    uint64_t usedSizeLevel = hmd_calculateMemorySizeLevel(memoryInfo.usedMemory);
    if (totalSizeLevel > 0) {
        return double(totalSizeLevel - usedSizeLevel)/totalSizeLevel;
    }
    return -1;
}

@interface HMDAppExitReasonDetector()

@property (nonatomic, strong, class) NSMutableSet<id<HMDAPPExitReasonDetectorProtocol>> *delegatesSet;
@property (nonatomic, assign, class) BOOL finishDetection;
@end

@implementation HMDAppExitReasonDetector

+(void)setAppExitFlagBefroHeimdallr {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //We initially thought the app would quit abnormally, make corrections when heimdal start;
        lastHMDAppExitBeforeHeimdallrStart = [[HMDUserDefaults standardUserDefaults] boolForKey:HMDAppExitBeforeHeimdallrStart];
        lastHMDAppExitBefore10Second = [[HMDUserDefaults standardUserDefaults] boolForKey:HMDAppExitBefore10Second];
        [[HMDUserDefaults standardUserDefaults] setObject:@(YES) forKey:HMDAppExitBeforeHeimdallrStart];
        [[HMDUserDefaults standardUserDefaults] setObject:@(YES) forKey:HMDAppExitBefore10Second];
        
        hmd_safe_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[HMDUserDefaults standardUserDefaults] setObject:@(NO) forKey:HMDAppExitBefore10Second];
        });
    });
    
    
}
#pragma mark - Essential Functionarity (Start/Stop)
+ (void)updateTimeInterval:(NSTimeInterval)timeInterval {
    [self setSystemStateUpdateInterval:timeInterval];
}
+ (void)registerDelegate:(id<HMDAPPExitReasonDetectorProtocol>)delegate {
    pthread_mutex_lock(&mutex);
    BOOL isFinishDetection = self.finishDetection;
    [HMDAppExitReasonDetector.delegatesSet addObject:delegate];
    pthread_mutex_unlock(&mutex);
    
    if(isFinishDetection && [delegate respondsToSelector:@selector(didDetectExitReason:desc:info:)]) {
        [delegate didDetectExitReason:relaunchReason desc:relaunchReasonStr info:relaunchInfo];
    }
}

+ (void)deregisterDelegate:(id<HMDAPPExitReasonDetectorProtocol>)delegate {
    pthread_mutex_lock(&mutex);
    [HMDAppExitReasonDetector.delegatesSet removeObject:delegate];
    if(_delegatesSet.count == 0) {
        [HMDAppExitReasonDetector stop];
    }
    pthread_mutex_unlock(&mutex);
}

+ (NSString *const _Nonnull)logFileDictionary {
    NSString *string = [NSString stringWithFormat:@"%@/%@",kHMD_OOM_DirectoryName,HMD_OOM_LogFileName];
    NSString *const log_string = string;
    return log_string;
}

+ (void)checkRebootTypeFinishWithInfo:(HMDOOMCrashInfo*)info reason:(HMDApplicationRelaunchReason)reason {
    // 如果发现 FOOM 则进行处理
    NSAssert(reason != HMDApplicationRelaunchReasonFOOM || info != nil,
             @"[HMDAppExitReasonDetector handleOOMWithReason:FOOM lastTimeDictionary: nil]");
    if(reason == HMDApplicationRelaunchReasonFOOM && info) {
        HMDExcludeModuleHelper *_excludedHelper = [[HMDExcludeModuleHelper alloc]initWithSuccess:^{
            [self excludedCompleteAndDetectOOMCrash:info];
        } failure:^{
            [self excludedCompleteWithoutOOMCrash:info];
        } timeout:^{
            [self excludedCompleteAndDetectOOMCrash:info];
        }];
        [_excludedHelper addRuntimeClassName:@"HMDWatchDogTracker"
                               forDependency:HMDExcludeModuleDependencyFailure];
        
        [_excludedHelper addRuntimeClassName:@"HMDCrashTracker"
                               forDependency:HMDExcludeModuleDependencyFailure];
        
        [_excludedHelper startDetection];
    }else if(reason == HMDApplicationRelaunchReasonTerminate && info) {
        HMDExcludeModuleHelper *_excludedHelper = [[HMDExcludeModuleHelper alloc]initWithSuccess:^{
            
            [self excludedCompleteAndDetectUserTerminate:info];
        } failure:^{
            info.detailInfo = @"ui_frozen";
            [self finishDetectionWithReason:reason info:info];
        } timeout:^{
            [self excludedCompleteAndDetectUserTerminate:info];
        }];
        
        [_excludedHelper addRuntimeClassName:@"HMDUIFrozenTracker"
                               forDependency:HMDExcludeModuleDependencyFailure];
        
        [_excludedHelper startDetection];
    } else if (reason == HMDApplicationRelaunchReasonBackgroundExit) {
        [self excludedCompleteAndDetectBackgroundExit:info];
    } else {
        [self finishDetectionWithReason:reason info:info];
    }
}

+ (void)excludedCompleteAndDetectOOMCrash:(HMDOOMCrashInfo*)info {
    if (_isNeedBinaryInfo) {
        info.binaryInfo = [self binaryInfoFromLastTimeBinaryImageSet];
    }
    [self finishDetectionWithReason:HMDApplicationRelaunchReasonFOOM info:info];
}

+ (void)excludedCompleteWithoutOOMCrash:(HMDOOMCrashInfo*)info {
    HMDApplicationRelaunchReason reason = HMDApplicationRelaunchReasonNoData;
    
    id<HMDExcludeModule> crashTracker = [HMDExcludeModuleHelper excludeModuleForRuntimeClassName:@"HMDCrashTracker"];
    id<HMDExcludeModule> watchDogTracker = [HMDExcludeModuleHelper excludeModuleForRuntimeClassName:@"HMDWatchDogTracker"];
    
    BOOL isLastTimeCrash = crashTracker.finishDetection && crashTracker.detected;
    BOOL isLastTimeWatchDog = watchDogTracker.finishDetection && watchDogTracker.detected;

    if(isLastTimeCrash) {
        reason = HMDApplicationRelaunchReasonCrash;
    }else if(isLastTimeWatchDog) {
        reason = HMDApplicationRelaunchReasonWatchDog;
    }
    [self finishDetectionWithReason:reason info:info];
}

+ (void)excludedCompleteAndDetectUserTerminate:(HMDOOMCrashInfo*)info {
    NSString *appExitDetails = @"normal";
    //TODO use setting or more reliable value
    if (info.appContinuousQuitTimes > 3) {
        appExitDetails = @"continuous_quit_by_user";
    }else if([info.thermalState isEqual: @"critical"]) {
        appExitDetails = @"too_hot";
    }
    info.detailInfo = appExitDetails;
    [self finishDetectionWithReason:HMDApplicationRelaunchReasonTerminate info:info];
}

+ (void)excludedCompleteAndDetectBackgroundExit:(HMDOOMCrashInfo*)info {
    
    if (info) {
        NSString *appExitDetails = @"normal";
        dispatch_source_memorypressure_flags_t memoryPressure = info.memoryPressure;
        double appUsedMemoryPrecent = getAppUsedMemoryPercent(info.memoryInfo);
        double deviceFreeMemoryPercent = getDeviceFreeMemoryPercent(info.memoryInfo);
        if (memoryPressure == DISPATCH_MEMORYPRESSURE_WARN || memoryPressure == DISPATCH_MEMORYPRESSURE_CRITICAL || deviceFreeMemoryPercent < 0.1) {
            appExitDetails = @"maybe background memory pressure";
        } else if (memoryPressure == 0x10 || appUsedMemoryPrecent > 0.9) {
            appExitDetails = @"maybe background OOM";
        }else if (info.isCPUException) {
            appExitDetails = @"maybe background CPU exception";
        }else if([info.thermalState isEqual: @"critical"]) {
            appExitDetails = @"maybe background cool off";
        }
        info.detailInfo = appExitDetails;
    }
    
    [self finishDetectionWithReason:HMDApplicationRelaunchReasonBackgroundExit info:info];
}

+ (void)finishDetectionWithReason:(HMDApplicationRelaunchReason)reason info:(HMDOOMCrashInfo*)info{
    NSString *reasonStr = @"";
    switch (reason) {
        case HMDApplicationRelaunchReasonApplicationUpdate:
            reasonStr = @"app_update";
            break;
        case HMDApplicationRelaunchReasonSystemUpdate:
            reasonStr = @"system_update";
            break;
        case HMDApplicationRelaunchReasonTerminate:
            reasonStr = @"user_manual_terminate";
            break;
        case HMDApplicationRelaunchReasonExit:
            reasonStr = @"app_exit";
            break;
        case HMDApplicationRelaunchReasonBackgroundExit:
            reasonStr = @"background_exit";
            break;
        case HMDApplicationRelaunchReasonDebug:
            reasonStr = @"app_being_debugged";
            break;
        case HMDApplicationRelaunchReasonXCTest:
            reasonStr = @"app_being_xctested";
            break;
        case HMDApplicationRelaunchReasonDetectorStopped:
            reasonStr = @"detector_stopped";
            break;
        case HMDApplicationRelaunchReasonNoData:
            reasonStr = @"no_data";
            break;
        case HMDApplicationRelaunchReasonFOOM:
            reasonStr = @"OOMCrash";
            break;
        case HMDApplicationRelaunchReasonCrash:
            reasonStr = @"crash";
            break;
        case HMDApplicationRelaunchReasonWatchDog:
            reasonStr = @"watchdog";
            break;
        case HMDApplicationRelaunchReasonWeakWatchDog:
            reasonStr = @"weak_watchdog";
            break;
        case HMDApplicationRelaunchReasonCoverageInstall:
            reasonStr = @"coverage_install";
            break;
        case HMDApplicationRelaunchReasonHeimdallrNotStart:
            reasonStr = @"heimdallr_not_start";
            break;
        case HMDApplicationRelaunchReasonShortTime:
            reasonStr = @"app_exit_before_10s";
            break;
        case HMDApplicationRelaunchReasonSessionNotMatch:
            reasonStr = @"session_id_not_match";
            break;
        default:
            NSAssert(NO, @"[FATAL ERROR] Please preserve current environment"
                     " and contact Heimdallr developer ASAP.");
            reasonStr = @"The reason for the application's relaunching cannot be resolved";
            break;
    }
    int res = pthread_mutex_trylock(&mutex);
    relaunchReason = reason;
    relaunchInfo = info;
    relaunchReasonStr = reasonStr;
    self.finishDetection = YES;
    //deal all delegates will take a long time, get a copy to unlock early.
    NSSet *delegateSet = [self.delegatesSet copy];
    if(res == 0) {
        pthread_mutex_unlock(&mutex);
    }
    
    [delegateSet enumerateObjectsUsingBlock:^(id<HMDAPPExitReasonDetectorProtocol>  _Nonnull delegate, BOOL * _Nonnull stop) {
        if([delegate respondsToSelector:@selector(didDetectExitReason:desc:info:)]) {
            [delegate didDetectExitReason:reason desc:reasonStr info:info];
        }
    }];
    
    if (reason == HMDApplicationRelaunchReasonFOOM || reason == HMDApplicationRelaunchReasonCrash || reason == HMDApplicationRelaunchReasonWatchDog) {
        [self uploadMemoryInfo];
    } else {
        [self deleteMemoryInfo];
    }
    
    
    if (hmd_log_enable()) {
        NSDictionary *category = @{@"reason":reasonStr};
        [HMDMonitorService trackService:@"hmd_app_relaunch_reason" metrics:nil dimension:category extra:nil];
        
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"[APPExitReason] application relaunch reason: %@", reasonStr);
        
        
        NSMutableDictionary *appExitCategory = [NSMutableDictionary new];
        NSMutableDictionary *metric = [NSMutableDictionary new];
        [appExitCategory hmd_setObject:reasonStr forKey:@"app_exit_metrics"];
        if (info) {
            if (info.detailInfo) {
                [appExitCategory hmd_setObject:info.detailInfo forKey:@"app_exit_details"];
            }
            if (info.lastScene) {
                [appExitCategory hmd_setObject:info.lastScene forKey:@"scene"];
            }else {
                [appExitCategory hmd_setObject:@"unknown" forKey:@"scene"];
            }
            if (info.appContinuousQuitTimes) {
                [appExitCategory hmd_setObject:@(info.appContinuousQuitTimes) forKey:@"app_continuous_quit_times"];
            }else {
                [appExitCategory hmd_setObject:@"unknown" forKey:@"app_continuous_quit_times"];
            }
            if (info.thermalState && info.thermalState.length) {
                [appExitCategory hmd_setObject:info.thermalState forKey:@"thermal_state"];
            }else {
                [appExitCategory hmd_setObject:@"unknown" forKey:@"thermal_state"];
            }
            
            [appExitCategory hmd_setObject:@(info.isCPUException) forKey:@"cpu_overload"];
            
            [appExitCategory hmd_setObject:@(info.inAppTime) forKey:@"in_app_time"];
            
            [appExitCategory hmd_setObject:@(info.inLastSceneTime) forKey:@"in_last_scene_time"];
            
            [appExitCategory hmd_setObject:@(info.restartInterval) forKey:@"restart_interval"];
            
            [appExitCategory hmd_setObject:@(info.isAppEnterBackground) forKey:@"is_background"];
            
            [appExitCategory hmd_setObject:@(info.memoryPressure) forKey:@"memory_pressure"];
            
            [appExitCategory hmd_setObject:@(getAppUsedMemoryPercent(info.memoryInfo)) forKey:@"app_used_memory_percent"];
            
            
            [appExitCategory hmd_setObject:@(getDeviceFreeMemoryPercent(info.memoryInfo)) forKey:@"device_free_memory_percent"];
                    
            u_int64_t device_m_zoom = hmd_calculateMemorySizeLevel(info.memoryInfo.usedMemory);
            [metric hmd_setObject:@(device_m_zoom) forKey:@"device_m_zoom"];
            
            HMDLog(@"App exit⚡️ reason: %@, last scene: %@, detail:%@",  reasonStr,
                   info.lastScene, info.detailInfo?:@"null");
        }
        
        id<HMDTTMonitorServiceProtocol> defaultMonitor = hmd_get_app_ttmonitor();
        [defaultMonitor hmdTrackService:@"hmd_app_exit_reason" metric:metric category:appExitCategory.copy extra:nil];
        [[HMDAppVCPageViewRecord shared] reportLastPageViewInfoAsync];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"[APPExitReason] application relaunch reason: %@", reasonStr);
    }
}

+ (void)resetAppState {
    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState *state) {
        state.isAppQuitByExit = NO;
        state.isAppQuitByUser = NO;
        // 注意这里初始状态是后台
        state.isAppEnterBackground = YES;
        state.isMonitorStopped = YES;
        state.memoryPressure = 0;
        state.memoryPressureTimestamp = 0.0;
        
        state.isWatchDog = NO;
        state.isCrash = NO;
        state.isWeakWatchDog = NO;
        
        state.enterForegoundTime = 0;
        state.enterBackgoundTime = 0;
        state.latestTime = 0;
        
        state.internalSessionID = nil;
        state.appStartTime = 0;
        
        state.isDebug = NO;
        state.isXCTest = NO;
        state.appVersion = nil;
        state.sysVersion = nil;
        
        state.thermalState = @"unknown";
        state.isCPUException = NO;
        
        HMDOOMAppStateMemoryInfo memoryInfo = {0};
        state.memoryInfo = memoryInfo;
        
        state.lastSenceChangedTime = 0;
    }];
}

+ (void)initializeOnce_noLock {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serialQueue = [NSOperationQueue new];
        serialQueue.maxConcurrentOperationCount = 1;
        isMonitorLaunched = NO;
        
        // 主线程同步读文件，避免启动优化可能导致的主线程持续抢占CPU进而导致前后台状态被修改
        HMDOOMCrashInfo *info = NULL;
        HMDApplicationRelaunchReason reason = [self getOOMCrashInfo:&info];
        
        // 如果发现 FOOM 则进行处理,此时尝试用上次启动的数据判断 FOOM
        [self checkRebootTypeFinishWithInfo:info reason:reason];
        
        // 判断完毕重置状态
        [self resetAppState];
        
        // 注册 exit() 回调
        atexit_b(^{
            pthread_mutex_lock(&mutex);
            BOOL check = isMonitorLaunched;
            pthread_mutex_unlock(&mutex);
            
            if (check) {
                pthread_mutex_lock(&mutex);
                [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState *state) {
                    state.isAppQuitByExit = YES;
                }];
                pthread_mutex_unlock(&mutex);
                /*
                 应用退出时记录数据没有意义，此时写文件可能会导致crash/卡死
                 OOMLog("receive exit callback and save info");
                 [self storeCurrentData_lock];
                 */
            }
        });
        
        // 存入一次性不变的数据 LOCK-FREE
        if (_isFixNoDataMisjudgment) {
            [self storeOneTimeData_lock];
        }else {
            [serialQueue addOperationWithBlock:^{
                [self storeOneTimeData_lock];
            }];
        }
        
        
        // 子线程监听内存压力通知
        static dispatch_source_t source;
        unsigned long mask = DISPATCH_MEMORYPRESSURE_WARN|DISPATCH_MEMORYPRESSURE_CRITICAL|0x8|0x10|0x20;
        source = dispatch_source_create(
                                        DISPATCH_SOURCE_TYPE_MEMORYPRESSURE,
                                        0,
                                        mask,
                                        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                                        );
        
        if (!source) {
            // 不支持的系统上会出现 source 为空，fallback 为
            // DISPATCH_MEMORYPRESSURE_WARN|DISPATCH_MEMORYPRESSURE_CRITICAL
            mask = DISPATCH_MEMORYPRESSURE_WARN|DISPATCH_MEMORYPRESSURE_CRITICAL;
            source = dispatch_source_create(
                                            DISPATCH_SOURCE_TYPE_MEMORYPRESSURE,
                                            0,
                                            mask,
                                            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                                            );
        }
        
        if (source) {
            dispatch_source_set_event_handler(source, ^{
                pthread_mutex_lock(&mutex);
                BOOL launched = isMonitorLaunched;
                __block dispatch_source_memorypressure_flags_t memory_pressure = 0;
                if (launched) {
                    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState *state) {
                        state.memoryPressure = dispatch_source_get_data(source);
                        state.memoryPressureTimestamp = [[NSDate date] timeIntervalSince1970];
                        memory_pressure = state.memoryPressure;
                    }];
                }
                pthread_mutex_unlock(&mutex);
                
                if (launched) {
                    NSString *const reason = [NSString stringWithFormat:@"receive memory warning memoryPressure:%lu",memory_pressure];
                    [self dispatchStoreOneTimeCurrentDataToQueueWithAction:reason];
                }
            });
            
            dispatch_resume(source);
        }
    });
}

+ (void)start {
    if (HMDAppExitReasonDetector.delegatesSet.count == 0) {
        return;
    }

    // App 生命周期只进行一次的初始化
    [self initializeOnce_noLock];
    
    // 每次 start 都要进行的初始化
    if (!isMonitorLaunched) {
        isMonitorLaunched = YES;
        [self turnOnApplicationStateUpdate_noLock];
        [self turnOnWatchDogStateObserver];
        [self turnOnThermalStateObserver];
        [self turnOnCPUExceptonObserver];
        
        [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState *state) {
            state.isMonitorStopped = NO;
        }];
        
        [self startSdklog];
        
        // 存入多次性可变的数据 LOCK-FREE
        [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"start"];
    }
    if(updateSystemStateInterval == 0 && callbackTimer == nil) {
        [self enableTimer_noLock];
    }else if(updateSystemStateInterval != 0 && customTimer == NO){
        [self disableTimer_noLock];
        [self enableTimer_noLock];
        customTimer = YES;
    }
    [[HMDUserDefaults standardUserDefaults] setObject:@(NO) forKey:HMDAppExitBeforeHeimdallrStart];
}

/// 不会完全取消一些注册的 callback 但是会尽力
/// 同时会写入上一次 OOM 已经停止, 不会在下一次 OOM 判断时出现问题
+ (void)stop {
    // 取消能取消的监视
    if (isMonitorLaunched) {
        isMonitorLaunched = NO;
        [self disableTimer_noLock];
        [self turnOffApplicationStateUpdate_noLock];
        [self turnOffWatchDogStateObserver];
        [self turnOffThermalStateObserver];
        [self turnOffCPUExceptonObserver];
        customTimer = NO;
        [self endSdklog];
    }
    
    // 记录 FOOM 监控已经停止
    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState *state) {
        state.isMonitorStopped = YES;
    }];
    
    // LOCK-FREE
    [serialQueue addOperationWithBlock:^{
        [self storeCurrentData_lock]; // 必须强制触发一次
    }];
}

#pragma mark - SDKLog
+ (void)startSdklog {
    NSString *log_dir = [self memoryLogProcessingPath];
    [self findOrCreateDirectoryInPath:log_dir];
    NSString *internalSessionID = [HMDSessionTracker currentSession].eternalSessionID;
    if (internalSessionID == nil) {
        return;
    }
    NSString *infoPath = [log_dir stringByAppendingPathComponent:internalSessionID];
    
    log_info_writer = new HMDFileWriter::Writer(infoPath.UTF8String,MAIN_FILE_DEFAULT_SIZE,MAIN_FILE_SIZE);

    time_start = [[NSDate date] timeIntervalSince1970]*1000;
    long long timestamp = (long long)time_start;
    log_info_writer->append(&timestamp, 6);
}

+ (void)endSdklog {
    hmd_oom_crash_close_log();
}

#pragma mark - Start/Stop Timer

+ (void)enableTimer_noLock {
    if(callbackTimer == nil) {
        HMDWeakProxy *weakProxy = [HMDWeakProxy proxyWithTarget:self];
        callbackTimer = [NSTimer timerWithTimeInterval:updateSystemStateInterval==0?HMDAppExitReasonDetectorUpdateSystemStateIntervalDefault:updateSystemStateInterval target:weakProxy selector:@selector(timerCallback) userInfo:nil repeats:YES];
        NSAssert(callbackTimer != nil, @"HMDAPPExitReasonDetector enableTimer_noLock timer nil");
        NSTimer *tempTimer = callbackTimer; // block 里面的 const-strong reference
        if(callbackTimer != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSRunLoop mainRunLoop] addTimer:tempTimer forMode:NSDefaultRunLoopMode];
            });
        }
    }
}

+ (void)disableTimer_noLock {
    if(callbackTimer != nil) {
        NSTimer *tempTimer = callbackTimer; // block 里面的 const-strong reference
        dispatch_async(dispatch_get_main_queue(), ^{
            [tempTimer invalidate];     // The NSRunLoop object removes its strong reference to the timer
        });
        callbackTimer = nil;
    }
}

#pragma mark - App Life Cycle Update

+ (void)turnOnApplicationStateUpdate_noLock {
    NSAssert(!requestedAppStateUpdate,
             @"[FATAL ERROR] Please preserve current environment"
              " and contact Heimdallr developer ASAP.");

    requestedAppStateUpdate = YES;
    
    switch (optimizeOption) {
        case HMDOOMCrashAppStateUpdateTryOptimize:
            [self pendingOptimizationRequest_noLock];
            break;
        case HMDOOMCrashAppStateUpdateDecided:
            [self addAppStateObserverWithSelf];
            break;
        default:
            NSAssert(NO, @"[FATAL ERROR] Please preserve current environment"
                         " and contact Heimdallr developer ASAP.");
        case HMDOOMCrashAppStateUpdatePending:
            break;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver: [HMDAppExitReasonDetector class] selector:@selector(sceneDidUpdate) name:kHMDUITrackerSceneDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver: [HMDAppExitReasonDetector class] selector:@selector(slardarMallocInuse) name:kHMDSlardarMallocInuseNotification object:nil];
}

+ (void)turnOffApplicationStateUpdate_noLock {
    requestedAppStateUpdate = NO;
    [[NSNotificationCenter defaultCenter] removeObserver: [HMDAppExitReasonDetector class] name:kHMDUITrackerSceneDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver: [HMDAppExitReasonDetector class] name:kHMDSlardarMallocInuseNotification object:nil];
    switch (optimizeOption) {
        case HMDOOMCrashAppStateUpdateDecided:
            if (!willEnterForegroundOptimized) {
                [[NSNotificationCenter defaultCenter] removeObserver: [HMDAppExitReasonDetector class] name:UIApplicationWillEnterForegroundNotification object:nil];
            }
            if (!didEnterBackgroundOptimized) {
                [[NSNotificationCenter defaultCenter] removeObserver: [HMDAppExitReasonDetector class] name:UIApplicationDidEnterBackgroundNotification object:nil];
            }
            if (!willTerminateOptimized) {
                [[NSNotificationCenter defaultCenter] removeObserver: [HMDAppExitReasonDetector class] name:UIApplicationWillTerminateNotification object:nil];
            }
            if (!willResignActiveOptimized) {
                [[NSNotificationCenter defaultCenter] removeObserver: [HMDAppExitReasonDetector class] name:UIApplicationWillResignActiveNotification object:nil];
            }
            if (!didBecomeActiveOptimized) {
                [[NSNotificationCenter defaultCenter] removeObserver: [HMDAppExitReasonDetector class] name:UIApplicationDidBecomeActiveNotification object:nil];
            }
            break;
        case HMDOOMCrashAppStateUpdateTryOptimize:
        default:
            NSAssert(NO, @"[FATAL ERROR] Please preserve current environment"
                         " and contact Heimdallr developer ASAP.");
        case HMDOOMCrashAppStateUpdatePending:
            break;
    }
}

/// if app delegate implment app state method, swizz it. or add observer with HMDAppExitReasonDetector
/// @param aClass App delegate
+ (void)checkAPPStateObserverWithAppdelegateClass:(Class)aClass
                               sceneDelegateClass:(Class)sClass
                                    lifeCycleType:(HMDAppLifeCycleType)appLifeCycleType{
    if (!requestedAppStateUpdate) {
        return;
    }
    Method method;
    
    if(aClass && (method = hmd_classHasInstanceMethod(aClass, @selector(applicationWillTerminate:))) != NULL) {
        willTerminateIMP = (HMDOOMCrash_applicationStateIMP)method_getImplementation(method);
        hmd_insert_and_swizzle_instance_method(aClass,
                                               @selector(applicationWillTerminate:),
                                               HMDAppExitReasonDetector.class,
                                               @selector(MOCK_applicationWillTerminate:));
        willTerminateOptimized = YES;
    }
    
    if (appLifeCycleType == HMDAppLifeCycleTypeMultiScene) {
        [self addAppStateObserverWithSelf];
    }else if (appLifeCycleType == HMDAppLifeCycleTypeSingleScene) {
        if(sClass && (method = hmd_classHasInstanceMethod(sClass, @selector(sceneWillEnterForeground:))) != NULL) {
            if (@available(iOS 13.0, *)) {
                sceneWillEnterForegroundIMP = (HMDOOMCrash_sceneStateIMP)method_getImplementation(method);
                hmd_insert_and_swizzle_instance_method(sClass,
                                                       @selector(sceneWillEnterForeground:),
                                                       HMDAppExitReasonDetector.class,
                                                       @selector(MOCK_sceneWillEnterForeground:));
                willEnterForegroundOptimized = YES;
            } else {
                // Fallback on earlier versions
            }
        }
        
        if(sClass && (method = hmd_classHasInstanceMethod(sClass, @selector(sceneDidEnterBackground:))) != NULL) {
            if (@available(iOS 13.0, *)) {
                sceneDidEnterBackgroundIMP = (HMDOOMCrash_sceneStateIMP)method_getImplementation(method);
                hmd_insert_and_swizzle_instance_method(sClass,
                                                       @selector(sceneDidEnterBackground:),
                                                       HMDAppExitReasonDetector.class,
                                                       @selector(MOCK_sceneDidEnterBackground:));
                didEnterBackgroundOptimized = YES;
            } else {
                // Fallback on earlier versions
            }
        }
        
        if(sClass && (method = hmd_classHasInstanceMethod(sClass, @selector(sceneWillResignActive:))) != NULL) {
            if (@available(iOS 13.0, *)) {
                sceneWillResignActiveIMP = (HMDOOMCrash_sceneStateIMP)method_getImplementation(method);
                hmd_insert_and_swizzle_instance_method(sClass,
                                                       @selector(sceneWillResignActive:),
                                                       HMDAppExitReasonDetector.class,
                                                       @selector(MOCK_sceneWillResignActive:));
                willResignActiveOptimized = YES;
            } else {
                // Fallback on earlier versions
            }
        }
        
        if(sClass && (method = hmd_classHasInstanceMethod(sClass, @selector(sceneDidBecomeActive:))) != NULL) {
            if (@available(iOS 13.0, *)) {
                sceneDidBecomeActiveIMP = (HMDOOMCrash_sceneStateIMP)method_getImplementation(method);
                hmd_insert_and_swizzle_instance_method(sClass,
                                                       @selector(sceneDidBecomeActive:),
                                                       HMDAppExitReasonDetector.class,
                                                       @selector(MOCK_sceneDidBecomeActive:));
                didBecomeActiveOptimized = YES;
            }
        }
        [self addAppStateObserverWithSelf];
    }else if (appLifeCycleType == HMDAppLifeCycleTypeNoneScene) {
        if(aClass && (method = hmd_classHasInstanceMethod(aClass, @selector(applicationWillEnterForeground:))) != NULL) {
            willEnterForegroundIMP = (HMDOOMCrash_applicationStateIMP)method_getImplementation(method);
            hmd_insert_and_swizzle_instance_method(aClass,
                                                   @selector(applicationWillEnterForeground:),
                                                   HMDAppExitReasonDetector.class,
                                                   @selector(MOCK_applicationWillEnterForeground:));
            willEnterForegroundOptimized = YES;
        }
        
        if(aClass && (method = hmd_classHasInstanceMethod(aClass, @selector(applicationDidEnterBackground:))) != NULL) {
            didEnterBackgroundIMP = (HMDOOMCrash_applicationStateIMP)method_getImplementation(method);
            hmd_insert_and_swizzle_instance_method(aClass,
                                                   @selector(applicationDidEnterBackground:),
                                                   HMDAppExitReasonDetector.class,
                                                   @selector(MOCK_applicationDidEnterBackground:));
            didEnterBackgroundOptimized = YES;
        }
        
        if(aClass && (method = hmd_classHasInstanceMethod(aClass, @selector(applicationWillResignActive:))) != NULL) {
            willResignActiveIMP = (HMDOOMCrash_applicationStateIMP)method_getImplementation(method);
            hmd_insert_and_swizzle_instance_method(aClass,
                                                   @selector(applicationWillResignActive:),
                                                   HMDAppExitReasonDetector.class,
                                                   @selector(MOCK_applicationWillResignActive:));
            willResignActiveOptimized = YES;
        }
        
        if(aClass && (method = hmd_classHasInstanceMethod(aClass, @selector(applicationDidBecomeActive:))) != NULL) {
            didBecomeActiveIMP = (HMDOOMCrash_applicationStateIMP)method_getImplementation(method);
            hmd_insert_and_swizzle_instance_method(aClass,
                                                   @selector(applicationDidBecomeActive:),
                                                   HMDAppExitReasonDetector.class,
                                                   @selector(MOCK_applicationDidBecomeActive:));
            didBecomeActiveOptimized = YES;
        }
        [self addAppStateObserverWithSelf];
    }
    
}

+ (void)addAppStateObserverWithSelf {
    if(!willEnterForegroundOptimized) {
        [[NSNotificationCenter defaultCenter] addObserver: [HMDAppExitReasonDetector class]
                                                 selector:@selector(willEnterForegroundUpdate)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    if(!didEnterBackgroundOptimized) {
        [[NSNotificationCenter defaultCenter] addObserver: [HMDAppExitReasonDetector class]
                                                 selector:@selector(didEnterBackgroundUpdate)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    if(!willTerminateOptimized) {
        [[NSNotificationCenter defaultCenter] addObserver: [HMDAppExitReasonDetector class]
                                                 selector:@selector(receiveTerminateUpdate)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    if (!willResignActiveOptimized) {
        [[NSNotificationCenter defaultCenter] addObserver: [HMDAppExitReasonDetector class]
                                                 selector:@selector(willResignActiveUpdate)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
    }
    if (!didBecomeActiveOptimized) {
        [[NSNotificationCenter defaultCenter] addObserver: [HMDAppExitReasonDetector class]
                                                 selector:@selector(didBecomeActiveUpdate)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
}

+ (HMDAppLifeCycleType)lifeCycleType {
    if (appLifeCycleType != HMDAppLifeCycleTypeDefault) return appLifeCycleType;
    if (@available(iOS 13.0, *)) {
        BOOL sceneSupport = [HMDUITrackerTool sceneBasedSupport];
        if (!sceneSupport) {
            appLifeCycleType = HMDAppLifeCycleTypeNoneScene;
        }else {
            if ([HMDUITrackerTool multiScenesConfig]) {
                appLifeCycleType = HMDAppLifeCycleTypeMultiScene;
            }else {
                appLifeCycleType = HMDAppLifeCycleTypeSingleScene;
            }
        }
    }else {
        appLifeCycleType = HMDAppLifeCycleTypeNoneScene;
    }
    return appLifeCycleType;
}

+ (Class)sceneDelegateClass {
    if (@available(iOS 13.0, *)) {
        return UIApplication.hmdSharedApplication.connectedScenes.anyObject.delegate.class;
    }
    return nil;
}

+ (void)pendingOptimizationRequest_noLock {
#ifdef DEBUG
    __block BOOL firstTime = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        firstTime = YES;
    });
    if(!firstTime) __builtin_trap();
#endif
    if (pthread_main_np() != 0) {
        HMDAppLifeCycleType type = [self lifeCycleType];
#if RANGERSAPM
        Class appDelegateClass = object_getClass(UIApplication.sharedApplication.delegate);
#else
        Class appDelegateClass =  UIApplication.sharedApplication.delegate.class;
#endif
        Class sceneDelegateClass = [self sceneDelegateClass];
        optimizeOption = HMDOOMCrashAppStateUpdateDecided;
        [self checkAPPStateObserverWithAppdelegateClass:appDelegateClass sceneDelegateClass:sceneDelegateClass lifeCycleType:type];
    }else {
        optimizeOption = HMDOOMCrashAppStateUpdatePending;
        dispatch_async(dispatch_get_main_queue(), ^{
            HMDAppLifeCycleType type = [self lifeCycleType];
#if RANGERSAPM
            Class appDelegateClass = object_getClass(UIApplication.sharedApplication.delegate);
#else
            Class appDelegateClass =  UIApplication.sharedApplication.delegate.class;
#endif
            Class sceneDelegateClass = [self sceneDelegateClass];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                pthread_mutex_lock(&mutex);
                
                NSAssert(optimizeOption == HMDOOMCrashAppStateUpdatePending,
                         @"[FATAL ERROR] Please preserve current environment"
                          " and contact Heimdallr developer ASAP.");
                
                optimizeOption = HMDOOMCrashAppStateUpdateDecided;
                [self checkAPPStateObserverWithAppdelegateClass:appDelegateClass sceneDelegateClass:sceneDelegateClass lifeCycleType:type];
                pthread_mutex_unlock(&mutex);
            });
        });
    }
}

#pragma mark - UIApplicationDelegate Callbacks

- (void)MOCK_applicationWillTerminate:(UIApplication *)application {
    [HMDAppExitReasonDetector receiveTerminateUpdate];
    NSAssert(willTerminateIMP != NULL, @"HMDAppExitReasonDetector willTerminateIMP NULL");
    if(willTerminateIMP != NULL)
        willTerminateIMP(self, @selector(applicationWillTerminate:), application);
}

- (void)MOCK_applicationWillEnterForeground:(UIApplication *)application {
    [HMDAppExitReasonDetector willEnterForegroundUpdate];
    NSAssert(willEnterForegroundIMP != NULL, @"HMDAppExitReasonDetector willEnterForegroundIMP NULL");
    if(willEnterForegroundIMP != NULL)
        willEnterForegroundIMP(self, @selector(applicationWillEnterForeground:), application);
}

- (void)MOCK_applicationDidEnterBackground:(UIApplication *)application {
    [HMDAppExitReasonDetector didEnterBackgroundUpdate];
    NSAssert(didEnterBackgroundIMP != NULL, @"HMDAppExitReasonDetector didEnterBackgroundIMP NULL");
    if(didEnterBackgroundIMP != NULL)
        didEnterBackgroundIMP(self, @selector(applicationDidEnterBackground:), application);
}

- (void)MOCK_applicationWillResignActive:(UIApplication *)application {
    [HMDAppExitReasonDetector willResignActiveUpdate];
    NSAssert(willResignActiveIMP != NULL, @"HMDAppExitReasonDetector willResignActiveIMP NULL");
    if(willResignActiveIMP != NULL)
        willResignActiveIMP(self, @selector(applicationWillResignActive:), application);
}

- (void)MOCK_applicationDidBecomeActive:(UIApplication *)application {
    [HMDAppExitReasonDetector didBecomeActiveUpdate];
    NSAssert(didBecomeActiveIMP != NULL, @"HMDAppExitReasonDetector didBecomeActiveIMP NULL");
    if(didBecomeActiveIMP != NULL)
        didBecomeActiveIMP(self, @selector(applicationDidBecomeActive:), application);
}

- (void)MOCK_sceneWillEnterForeground:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    [HMDAppExitReasonDetector willEnterForegroundUpdate];
    NSAssert(sceneWillEnterForegroundIMP != NULL, @"HMDAppExitReasonDetector willEnterForegroundIMP NULL");
    if(sceneWillEnterForegroundIMP != NULL)
        sceneWillEnterForegroundIMP(self, @selector(sceneWillEnterForeground:), scene);
}

- (void)MOCK_sceneDidEnterBackground:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    [HMDAppExitReasonDetector didEnterBackgroundUpdate];
    NSAssert(sceneDidEnterBackgroundIMP != NULL, @"HMDAppExitReasonDetector didEnterBackgroundIMP NULL");
    if(sceneDidEnterBackgroundIMP != NULL)
        sceneDidEnterBackgroundIMP(self, @selector(sceneDidEnterBackground:), scene);
}

- (void)MOCK_sceneWillResignActive:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    [HMDAppExitReasonDetector willResignActiveUpdate];
    NSAssert(sceneWillResignActiveIMP != NULL, @"HMDAppExitReasonDetector willResignActiveIMP NULL");
    if(sceneWillResignActiveIMP != NULL)
        sceneWillResignActiveIMP(self, @selector(sceneWillResignActive:), scene);
}

- (void)MOCK_sceneDidBecomeActive:(UIScene *)scene API_AVAILABLE(ios(13.0)) {
    [HMDAppExitReasonDetector didBecomeActiveUpdate];
    NSAssert(sceneDidBecomeActiveIMP != NULL, @"HMDAppExitReasonDetector didBecomeActiveIMP NULL");
    if(sceneDidBecomeActiveIMP != NULL)
        sceneDidBecomeActiveIMP(self, @selector(sceneDidBecomeActive:), scene);
}

#pragma mark - App Life Cycle Handlers

+ (void)receiveTerminateUpdate {  // 同步操作 [ 系统 关机能执行时间很短 ]
    pthread_mutex_lock(&mutex);
    BOOL check = isMonitorLaunched;
    pthread_mutex_unlock(&mutex);
    
    if (check) {
        pthread_mutex_lock(&mutex);
        [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState *state) {
            state.isAppQuitByUser = YES;
        }];
        pthread_mutex_unlock(&mutex);
        /*
         应用退出时记录数据没有意义，此时写文件可能会导致crash/卡死
         [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"receive terminate update"];
         */
    }
}

+ (void)willEnterForegroundUpdate {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDAppExitDetector will enter foreground");
    [self receiveForegroundUpdate];
}

+ (void)didBecomeActiveUpdate {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDAppExitDetector did become active");
    [self receiveForegroundUpdate];
}

+ (void)didEnterBackgroundUpdate {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDAppExitDetector did enter background");
    [self receiveBackgroundUpdate];
}

+ (void)willResignActiveUpdate {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDAppExitDetector will resign active");
    [self receiveBackgroundUpdate];
}

+ (void)receiveForegroundUpdate {
    // App 可能出现 didFinishLaunch -> becomeActive -> 卡死，不应该作为 FOOM 判断，
    // 所以这里做 1s 的延迟再做判断。如果主线程卡死了，那么这个回调不会被执行，不会被标记为前台
    // （注意启动后初始状态是后台）状态依然是后台；如果没有卡死，而且恰好在这 1s 前又进入后台，
    // 那么这个 block 会被 cancel，我们的状态依然是后台。
    
    // 进入前台会触发两次，s_foregroundDelayBlock会覆盖，在进入后台的时候无法cancel掉被覆盖的block，可能导致前后台状态更新错误
    if (s_foregroundDelayBlock) {
        dispatch_block_cancel(s_foregroundDelayBlock);
        s_foregroundDelayBlock = nil;
    }
    
    s_foregroundDelayBlock = dispatch_block_create(DISPATCH_BLOCK_NO_QOS_CLASS, ^{
        pthread_mutex_lock(&mutex);
        BOOL check = isMonitorLaunched;
        pthread_mutex_unlock(&mutex);

        if (check) {
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDAppExitDetector start foreground update");
            pthread_mutex_lock(&mutex);
            [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState *state) {
                state.isAppQuitByUser = NO;
                state.isAppEnterBackground = NO;
            }];
            pthread_mutex_unlock(&mutex);
            [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"foreground update"];
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDAppExitDetector finish foreground update");
        }
    });
    
    // 延迟一秒钟再判断
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        s_foregroundDelayBlock);
}

+ (void)receiveBackgroundUpdate {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDAppExitDetector receive background update");

    if (s_foregroundDelayBlock) {
        dispatch_block_cancel(s_foregroundDelayBlock);
        s_foregroundDelayBlock = nil;
    }
    
    pthread_mutex_lock(&mutex);
    BOOL check = isMonitorLaunched;
    pthread_mutex_unlock(&mutex);

    if (check) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDAppExitDetector start background update");
        pthread_mutex_lock(&mutex);
        [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState *state) {
            state.isAppEnterBackground = YES;
        }];
        pthread_mutex_unlock(&mutex);
        [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"background update"];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"HMDAppExitDetector finish background update");
    }
}

+ (void)sceneDidUpdate {
    [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"scene update"];
    NSString *vc = [HMDTracker getLastSceneIfAvailable];
    if (vc) {
        [[HMDAppVCPageViewRecord shared] recordPageViewForVCAsync:vc];
        
        pthread_mutex_lock(&mutex);
        BOOL check = isMonitorLaunched;
        pthread_mutex_unlock(&mutex);
        if (check) {
            pthread_mutex_lock(&mutex);
            [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState *state) {
                state.lastSenceChangedTime = [[NSDate date] timeIntervalSince1970];
                state.latestTime = state.lastSenceChangedTime;
            }];
            pthread_mutex_unlock(&mutex);
        }
    }
}

+ (void)slardarMallocInuse {
    isSlardarMallocInuse = YES;
    [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"slardar_malloc inuse"];
}
#pragma mark - Monitoring watchdog state

+ (void)turnOnWatchDogStateObserver {
    if (DC_CL(HMDWatchDog, sharedInstance)) {
        // watchdog可能发生
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weakWatchdogTimeout) name:HMD_OOM_watchDogMaybeNotification object:nil];
        
        // watchdog发生
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchdogTimeout) name:HMD_OOM_watchDogTimeoutNotification object:nil];
        
        // recover
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(watchdogRecover) name:HMD_OOM_watchDogRecoverNotification object:nil];
    }
}

+ (void)turnOffWatchDogStateObserver {
    if (DC_CL(HMDWatchDog, sharedInstance)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:HMD_OOM_watchDogMaybeNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:HMD_OOM_watchDogTimeoutNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:HMD_OOM_watchDogRecoverNotification object:nil];
    }
}

#pragma mark - Watchdog Handler

+ (void)weakWatchdogTimeout {
    pthread_mutex_lock(&mutex);
    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState * _Nonnull state) {
        state.isWeakWatchDog = YES;
    }];
    pthread_mutex_unlock(&mutex);
    [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"weak watchdog timeout"];
}

+ (void)watchdogTimeout {
    pthread_mutex_lock(&mutex);
    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState * _Nonnull state) {
        state.isWatchDog = YES;
        state.isWeakWatchDog = NO;
    }];
    pthread_mutex_unlock(&mutex);
    [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"watchdog timeout"];
}

+ (void)watchdogRecover {
    pthread_mutex_lock(&mutex);
    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState * _Nonnull state) {
        state.isWatchDog = NO;
        state.isWeakWatchDog = NO;
    }];
    pthread_mutex_unlock(&mutex);
    [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"watchdog recover"];
}

#pragma mark - Monitoring cpu state

+ (void)turnOnCPUExceptonObserver {
    if (DC_CL(HMDCPUTimeDetector, sharedDetector)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CPUExceptionHappenning) name:HMD_OOM_CPUExceptionHappenNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(CPUExceptionRecover) name:HMD_OOM_CPUExceptionRecoverNotification object:nil];
    }
}

+ (void)turnOffCPUExceptonObserver {
    if (DC_CL(HMDCPUTimeDetector, sharedDetector)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:HMD_OOM_CPUExceptionHappenNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:HMD_OOM_CPUExceptionRecoverNotification object:nil];
    }
}

#pragma mark - cpu Handler

+ (void)CPUExceptionHappenning {
    [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"cpu exception happen"];
    pthread_mutex_lock(&mutex);
    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState * _Nonnull state) {
        state.isCPUException = YES;
    }];
    pthread_mutex_unlock(&mutex);
}

+ (void)CPUExceptionRecover {
    [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"cpu exception recover"];
    pthread_mutex_lock(&mutex);
    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState * _Nonnull state) {
        state.isCPUException = NO;
    }];
    pthread_mutex_unlock(&mutex);
}

#pragma mark - Monitoring thermal state

+ (void)turnOnThermalStateObserver {
    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thermalStateChangeed:) name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    }
}

+ (void)turnOffThermalStateObserver {
    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    }
}
#pragma mark - Thermal Handler

+ (void)thermalStateChangeed:(NSNotification *)notification {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *thermalState = @"unknown";
        if (@available(iOS 11.0, *)) {
            NSProcessInfoThermalState thermal = [[NSProcessInfo processInfo] thermalState];
            switch (thermal) {
                case NSProcessInfoThermalStateNominal:
                    thermalState = @"nominal";
                    break;
                case NSProcessInfoThermalStateFair:
                    thermalState = @"fair";
                    break;
                case NSProcessInfoThermalStateSerious:
                    thermalState = @"serious";
                    break;
                case NSProcessInfoThermalStateCritical:
                    thermalState = @"critical";
                    break;
                default:
                    break;
            }
        }
        pthread_mutex_lock(&mutex);
        [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState * _Nonnull state) {
            state.thermalState = thermalState;
        }];
        pthread_mutex_unlock(&mutex);
    });
}


#pragma mark - Interruptible part

+ (void)timerCallback {
    pthread_mutex_lock(&mutex);
    BOOL check = isMonitorLaunched;
    pthread_mutex_unlock(&mutex);
    if(check) {
        [self dispatchStoreOneTimeCurrentDataToQueueWithAction:@"timer callback"];
        [[HMDAppVCPageViewRecord shared] writePageViewInfoToFileAsync];
    }
}

#pragma mark Info saving method for external invocation

+ (void)triggerCurrentEnvironmentInfomationSaving {
    [self triggerCurrentEnvironmentInformationSaving];
}

+ (void)triggerCurrentEnvironmentInfomationSavingWithAction:(NSString *)action {
    [self triggerCurrentEnvironmentInformationSavingWithAction:action];
}

+ (void)triggerCurrentEnvironmentInformationSaving {
    [self triggerCurrentEnvironmentInformationSavingWithAction:@"user sendMsg"];
}

+ (void)triggerCurrentEnvironmentInformationSavingWithAction:(NSString *)action {
    pthread_mutex_lock(&mutex);
    BOOL check = isMonitorLaunched;
    pthread_mutex_unlock(&mutex);
    if(check) {
        [self dispatchStoreOneTimeCurrentDataToQueueWithAction:action.length>0?action:@"user sendMsg"];
    }
}

#pragma mark Optimized asynchronous/cancelable method

// 仅对于 nontification center callback 做出的优化
// 实际上是对 - storeCurrentData_lock 的包装, 放到其他线程执行
+ (void)dispatchStoreOneTimeCurrentDataToQueueWithAction:(NSString *)action {
    [serialQueue cancelAllOperations];
    [serialQueue addOperationWithBlock:^{
        pthread_mutex_lock(&mutex);
        BOOL check = isMonitorLaunched;
        pthread_mutex_unlock(&mutex);
        if (check) {
            NSString *msg = action ?: @"save info";
            if (!log_info_writer) return;
            const char *msg_reason = msg.UTF8String;
            size_t size = strlen(msg_reason);
            log_info_writer->append(&size, 1);
            log_info_writer->append(msg_reason, size);
            [self storeCurrentData_lock];
        }
    }];
}

#pragma mark - Save current Environment Status like memory information

/// 仅一次性记录的函数
+ (void)storeOneTimeData_lock {
    NSString *appVersion = [HMDInfo defaultInfo].shortVersion;
    NSString *buildVersion = [HMDInfo defaultInfo].buildVersion;
    NSString *systemVersion = [HMDInfo defaultInfo].systemVersion;
    NSString *libraryPath = [HeimdallrUtilities libraryPath];
    //BOOL is not equivalent to bool https://nshipster.cn/bool/
    BOOL isDebugging = hmddebug_isBeingTraced() ? YES : NO;
    // bugfix by hy 修复 [XCTestProbe, isTesting] 无法区分自动化测试场景 BOOL isXCTest = DC_IS(DC_CL(XCTestProbe, isTesting), NSNumber).boolValue;
    BOOL isXCTest = isRunningTests();
    
    NSString *internalSessionID = [HMDSessionTracker currentSession].eternalSessionID;
    
    NSAssert(internalSessionID != nil, @"[HMDAppExitReasonDetector storeOneTimeData_lock] sessionID nil");
    NSAssert(appVersion != nil, @"[HMDAppExitReasonDetector storeOneTimeData_lock] applicationVersion nil");
    NSAssert(systemVersion != nil, @"[HMDAppExitReasonDetector storeOneTimeData_lock] systemVersion nil");
    
    double start_time = appStartTime();
    
    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState * _Nonnull state) {
        state.internalSessionID = internalSessionID?:@"";
        state.appVersion = appVersion?:@"";
        state.buildVersion = buildVersion?:@"";
        state.sysVersion = systemVersion?:@"";
        state.isDebug = isDebugging;
        state.isXCTest = isXCTest;
        state.libraryPath = libraryPath;
        state.appStartTime = start_time;
        state.exception_main_address = hmdbt_get_app_main_addr();
    } msync:YES];
    
    //延迟1s避免启动卡死被判定为OOM
    hmd_safe_dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState * _Nonnull state) {
            state.isAppEnterBackground = HMDApplicationSession_backgroundState();
        }];
    });
}

/// 多次记录的函数
+ (void)storeCurrentData_lock {
    hmd_MemoryBytesExtend memoryBytesExtend = hmd_getMemoryBytesExtend();
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];

    uint64_t appMemoryPeak = hmd_getAppMemoryPeak();
    HMDOOMAppStateMemoryInfo memoryInfo = {
        .updateTime = timestamp,
        .appMemory = memoryBytesExtend.memoryBytes.appMemory,
        .usedMemory = memoryBytesExtend.memoryBytes.usedMemory,
        .totalMemory = memoryBytesExtend.memoryBytes.totalMemory,
        .availableMemory = memoryBytesExtend.memoryBytes.availabelMemory,
        .appMemoryPeak = appMemoryPeak,
        .totalVirtualMemory = memoryBytesExtend.totalVirtualMemory,
        .usedVirtualMemory = memoryBytesExtend.virtualMemory
    };
    
    uint64_t slardarMallocUsage = hmd_getSlardarMallocMemory();
    
    [[HMDOOMAppState sharedInstance] update:^(HMDOOMAppState * _Nonnull state) {
        state.memoryInfo = memoryInfo;
        state.latestTime = timestamp;
        state.isSlardarMallocInuse = isSlardarMallocInuse;
        state.slardarMallocUsageSize = slardarMallocUsage;
    }];
    
    //save file
    NSInteger freeDiskBlocks = [HMDDiskUsage getRecentCachedFreeDisk300MBlockSize];
    NSString *lastScene = [HMDTracker getLastSceneIfAvailable];
    NSDictionary *operationTrace = [HMDTracker getOperationTraceIfAvailable];
    NSString *sessionID = [HMDSessionTracker currentSession].sessionID;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict hmd_setObject:HMDSessionTracker.currentSession.eternalSessionID forKey:@"internal_session_id"];
    [dict hmd_setObject:@(freeDiskBlocks) forKey:@"d_zoom_free"];
#if RANGERSAPM
    double freeDiskSpace = [HMDDiskUsage getRecentCachedFreeDiskSpace] / HMD_MB; // 单位MB
    [dict hmd_setObject:@(freeDiskSpace) forKey:@"free_disk"];
#endif
    [dict hmd_setObject:lastScene forKey:@"last_scene"];
    [dict hmd_setObject:operationTrace forKey:@"operation_trace"];
    [dict hmd_setObject:sessionID forKey:@"session_id"];
    [dict hmd_setObject:@(timestamp) forKey:@"update_time"];
    
    NSTimeInterval time_end = [[NSDate date] timeIntervalSince1970]*1000;
    int logTime = (int)(time_end - time_start);
    u_int32_t app_memory = memoryBytesExtend.memoryBytes.appMemory/HMD_MB;
    u_int32_t used_memory = round(memoryBytesExtend.memoryBytes.usedMemory/(HMD_MB*30))*30;
    u_int64_t virtual_memory = memoryBytesExtend.virtualMemory/HMD_MB;
    int cpu_usage = hmdCPUUsageFromThread();
    const char *m_last_scene = lastScene.UTF8String;
    
    auto logInfo = MemoryLog::MemoryLogInfo(logTime, app_memory, used_memory, virtual_memory, cpu_usage, m_last_scene);
    logInfo.write_to(*log_info_writer);

    [self saveData:dict];
}

#pragma mark - Logic for Storage

+ (BOOL)saveData:(NSDictionary *)data {
    NSString *dir = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kHMD_OOM_DirectoryName];
    [self findOrCreateDirectoryInPath:dir];
    NSString *path = [dir stringByAppendingPathComponent:@"oom_extra_info"];
    BOOL isSuccess = [[data hmd_jsonData] writeToFile:path atomically:YES];
    return isSuccess;
}

+ (BOOL)findOrCreateDirectoryInPath:(NSString *)path {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL isDictionary;
    BOOL isExist = [manager fileExistsAtPath:path isDirectory:&isDictionary];
    if(isExist) {
        if(isDictionary) return YES;
    }
    else {
        return hmdCheckAndCreateDirectory(path);
    }
    return NO;
}

#pragma mark - Inferring form OOM
+ (HMDApplicationRelaunchReason)getOOMCrashInfo:(HMDOOMCrashInfo * _Nullable  *)info {
    
    HMDOOMAppState *appState = [HMDOOMAppState sharedInstance];
    if (appState.isNewData) {
        // 没有上次退出状态的记录
        return HMDApplicationRelaunchReasonNoData;
    }

    if([appState.internalSessionID isEqualToString:[HMDSessionTracker sharedInstance].lastTimeEternalSessionID]) {
        NSTimeInterval lastTimestamp = MAX(appState.latestTime, appState.memoryInfo.updateTime);
        CFTimeInterval restartInterval = appStartTime()-lastTimestamp;
        if (restartInterval < 20) {
            appState.appContinuousQuitTimes = appState.appContinuousQuitTimes + 1;
        }else {
            appState.appContinuousQuitTimes = 0;
        }
        if (info) {
            NSString *dir = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kHMD_OOM_DirectoryName];
            NSString *path = [dir stringByAppendingPathComponent:@"oom_extra_info"];
            NSData *extraData = [NSData dataWithContentsOfFile:path];
                    
            NSMutableDictionary *extraInfo = [[extraData hmd_jsonObject] mutableCopy];
            
            if (![appState.internalSessionID isEqualToString:[extraInfo hmd_stringForKey:@"internal_session_id"]]) {
                extraInfo = nil;
            }
            
            [extraInfo hmd_setObject:@(restartInterval) forKey:@"restart_interval"];
            
            [extraInfo hmd_setObject:@(restartInterval) forKey:@"restart_interval"];
            
            *info = [[HMDOOMCrashInfo alloc] initWithAppState:appState extraDict:extraInfo];
            
            (*info).isMemoryDumpInterrupt = DC_IS(DC_CL(HMDMemoryGraphGenerator, lastTimeMemoryDumpInterrupt), NSNumber).boolValue;
        }
        
        if (appState.isDebug) {
            return HMDApplicationRelaunchReasonDebug;
        }
        
        if (appState.isXCTest) {
            return HMDApplicationRelaunchReasonXCTest;
        }
        
        
        if (appState.isCrash) {
            return HMDApplicationRelaunchReasonCrash;
        }
        
        if (appState.isWatchDog) {
            return HMDApplicationRelaunchReasonWatchDog;
        }
        
        if (appState.isAppQuitByUser) {
            return HMDApplicationRelaunchReasonTerminate;
        }
        
        if (appState.isWeakWatchDog) {
            return HMDApplicationRelaunchReasonWeakWatchDog;
        }
        
        if (appState.isAppQuitByExit) {
            return HMDApplicationRelaunchReasonExit;
        }
        
        NSString *previousBuildVersion = appState.buildVersion;
        NSString *buildVersion = [HMDInfo defaultInfo].buildVersion;

        if (![buildVersion isEqualToString:previousBuildVersion]) {
            return HMDApplicationRelaunchReasonApplicationUpdate;
        }
        
        NSString *sysVersion = [HMDInfo defaultInfo].systemVersion;
        NSString *previousSysVersion = appState.sysVersion;
        if (![sysVersion isEqualToString:previousSysVersion]) {
            return HMDApplicationRelaunchReasonSystemUpdate;
        }
        
        NSString *libraryPath = [HeimdallrUtilities libraryPath];
        NSString *previousLibraryPath = appState.libraryPath;
        if (![libraryPath isEqualToString:previousLibraryPath]) {
            return HMDApplicationRelaunchReasonCoverageInstall;
        }
        
        if (appState.isMonitorStopped) {
            return HMDApplicationRelaunchReasonDetectorStopped;
        }
        
        if (appState.isAppEnterBackground) {
            return HMDApplicationRelaunchReasonBackgroundExit;
        }
        
        return HMDApplicationRelaunchReasonFOOM;
    }
    
    if (lastHMDAppExitBeforeHeimdallrStart) {
        return HMDApplicationRelaunchReasonHeimdallrNotStart;
    }
    
    if (lastHMDAppExitBefore10Second) {
        return HMDApplicationRelaunchReasonShortTime;
    }
    
    return HMDApplicationRelaunchReasonSessionNotMatch;
}

+ (NSString*)binaryInfoFromLastTimeBinaryImageSet {
    id<HMDExcludeModule> _Nullable module;
    if((module = [HMDExcludeModuleHelper excludeModuleForRuntimeClassName:@"HMDCrashTracker"]) == nil)
        return nil;
            
    // LastTime Directory
    NSString * _Nullable lastTimeDirectory;
    if((lastTimeDirectory = HMDCrashDirectory.lastTimeDirectory) == nil)
        return nil;  // 意味着崩溃模块还没有启动 (理论上不应该)
    
    NSFileManager *manager = NSFileManager.defaultManager;
    
    // Contents of LastTime Directory
    // Folder with UUID <27F32EC2-3EEE-4F8D-A5D6-B80641407F24>
    NSArray<NSString *> * contents = [manager contentsOfDirectoryAtPath:lastTimeDirectory error:nil];
    if(contents.count == 0) return nil;
    
    // crashDataPath consist of binaryImage SDKLog etc.
    NSString *crashDataDirectory = [lastTimeDirectory stringByAppendingPathComponent:contents.firstObject];
    
    BOOL isDirectory;
    if(![manager fileExistsAtPath:crashDataDirectory isDirectory:&isDirectory])
        return nil;
    
    if(!isDirectory) return nil;
    
    HMDImageOpaqueLoader *imageLoader = [[HMDImageOpaqueLoader alloc] initWithDirectory:crashDataDirectory];
    
    // Access all images using this method
    NSArray<HMDCrashBinaryImage *> * _Nullable images = imageLoader.currentlyUsedImages;
    
    NSMutableString* string = [NSMutableString stringWithString:@"\nBinary Images:\n"];
    for(HMDCrashBinaryImage *image in images) {
        BOOL isExcutable = image.isMain;
        NSString* arch = image.arch;
        NSString*image_name = image.path.lastPathComponent;
        
        [string appendFormat:@"%#10lx - %#10lx %s%@ %@ <%@> %@\n",
         (unsigned long)(image.base),
         (unsigned long)(image.base+image.size-1),
         isExcutable?"+":" ",
         image_name?:@"null",
         arch,
         image.uuid,
         image.path];
    }
    
    return string.copy;
}

#pragma mark - API for external invocation  (CAN NOT CALL INTERNALLY⚠️ )
+ (void)setSystemStateUpdateInterval:(NSTimeInterval)interval {
    if(interval < HMDAppExitReasonDetectorUpdateSystemStateIntervalLimit)
        interval = HMDAppExitReasonDetectorUpdateSystemStateIntervalLimit;
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

#pragma mark - get/set
+ (NSMutableSet *)delegatesSet {
    if(_delegatesSet == nil) {
        _delegatesSet = [NSMutableSet set];
    }
    return _delegatesSet;
}

+ (void)setDelegatesSet:(NSMutableSet *)delegatesSet {
    _delegatesSet = delegatesSet;
}

+ (BOOL)finishDetection {
    return _finishDetection;
}

+ (void)setFinishDetection:(BOOL)finishDetection {
    _finishDetection = finishDetection;
}

+ (BOOL)isFixNoDataMisjudgment {
    return _isFixNoDataMisjudgment;
}

+ (void)setIsFixNoDataMisjudgment:(BOOL)isFixNoDataMisjudgment {
    _isFixNoDataMisjudgment = isFixNoDataMisjudgment;
}

+ (BOOL)isNeedBinaryInfo {
    return _isNeedBinaryInfo;
}

+ (void)setIsNeedBinaryInfo:(BOOL)isNeedBinaryInfo {
    _isNeedBinaryInfo = isNeedBinaryInfo;
}

+ (HMDApplicationRelaunchReason)appRelaunchReason {
    return relaunchReason;
}
#pragma mark - memory loginfo

+ (void)uploadMemoryInfo {
    NSString* manner = @"exception";
    HMDStopUpload exceptionStopUpload = [HMDInjectedInfo defaultInfo].exceptionStopUpload;
    if ((exceptionStopUpload && exceptionStopUpload())) {
        NSDictionary *category = @{@"status":@(0), @"reason":@"exceptionStopUpload", @"activateManner":manner};
        DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:syncWrite:, @"slardar_memory_loginfo_upload", nil, category, nil, YES);
        HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"Disables uploading exception so hmd can't upload memory_loginfo.");
        return;
    }
    [self uploadMemoryInfoAsync];
}

+ (void)deleteMemoryInfo {
    [self deleteLastMemoryInfo];
}

@end

static BOOL isRunningTests(void) {
    // 自动化测试
    if ([HMDInfo isBytest]) {
        return YES;
    }
    // 自动化UI测试
    if (hmd_device_image_index_named("BDiOSpy", false) < UINT32_MAX) {
        return YES;
    }
    // 单元测试/UI测试
    if (hmd_device_image_index_named("XCTAutomationSupport", false) < UINT32_MAX) {
        return YES;
    }
    if (hmd_device_image_index_named("libXCTTargetBootstrapInject", false) < UINT32_MAX) {
        return YES;
    }
    if (hmd_device_image_index_named("libgmalloc", false) < UINT32_MAX) {
        return YES;
    }

    return NO;
}

static CFTimeInterval appStartTime(void) {
    static CFTimeInterval start_time;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        if (@available(iOS 15.0, *)) {
            start_time = [HMDSessionTracker currentSession].timestamp;
        } else {
            pid_t pid = getpid();
            int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid };
            struct kinfo_proc proc;
            size_t size = sizeof(proc);
            if (sysctl(mib, 4, &proc, &size, NULL, 0) == 0) {
                start_time = proc.kp_proc.p_starttime.tv_sec + ((double)proc.kp_proc.p_starttime.tv_usec/1000000);
            } else {
                start_time = [HMDSessionTracker currentSession].timestamp;
            }
        }
    });
    
    return start_time;
}
