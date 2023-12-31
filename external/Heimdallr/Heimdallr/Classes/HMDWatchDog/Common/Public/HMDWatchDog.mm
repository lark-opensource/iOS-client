//
//  HMDWatchDog.m
//  CLT
//
//  Created by sunrunwang on 2019/3/15.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <assert.h>
#import <iostream>
#import <sys/mount.h>
#import <TTReachability/TTReachability.h>
#import <vector>
#import <string>
#import <sys/mman.h>
#import <mach/mach.h>

#import "pthread_extended.h"
#import "HMDALogProtocol.h"
#import "Heimdallr+Private.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDWatchDogDelegate.h"
#import "HMDWatchDog.h"
#import "HMDThreadBacktrace.h"
#import "HMDBacktraceLog.h"
#import "HMDNetworkHelper.h"
#import "HMDSessionTracker.h"
#import "hmd_apple_backtrace_log.h"
#import "HMDTracker.h"
#import "HMDTimeSepc.h"
#import "HMDMainRunloopMonitor.h"
#import "HeimdallrUtilities.h"
#import "HMDDynamicCall.h"
#import "NSDictionary+HMDJSON.h"
#import "hmd_thread_backtrace.h"
#import "HMDHeaderLog.h"
#import "HMDDynamicCall.h"
#import "HMDTracker.h"
#import "HMDCompactUnwind.hpp"
#import "HMDWatchDogDefine.h"
#import "HMDDeadlockHeader.h"
#import "HMDCPUUtilties.h"
#import "HMDAsyncThread.h"
#import "HMDInfo+AppInfo.h"
#import "HMDABTestVids.h"
#import "HMDMainRunloopMonitorV2.h"
#import "HMDWatchDogAppExitReasonMark.h"

#if DEBUG
#define HMDWatchdogRaisePriorityCPULimit 60
#else
#define HMDWatchdogRaisePriorityCPULimit 20
#endif

typedef NS_ENUM(NSUInteger, HMDWatchDogMonitorStatus) {
    HMDWatchDogMonitorStatusNone = 0,
    HMDWatchDogMonitorStatusMonitor,
    HMDWatchDogMonitorStatusEnvUpdate,
    HMDWatchDogMonitorStatusOver,
};

struct HMDWatchdogThreadInfo {
    thread_info_data_t     info_data;
    mach_msg_type_number_t thread_count;
};

struct HMDWatchdogTimelineInfo {
    CFTimeInterval ts;
    CFTimeInterval duration;
    HMDWatchdogThreadInfo thinfo;
};

static char const *kHMDWatchDogKeyIsLaunchCrash = "is_launch_crash";
static char const *kHMDWatchDogKeyBackground = "is_background";
static char const *kHMDWatchDogKeyNetwork = "access";
static char const *kHMDWatchDogKeyMemoryUsage = "memory_usage";
static char const *kHMDWatchDogKeyFreeMemoryUsage = "free_memory_usage";
static char const *kHMDWatchDogKeyFreeDiskUsage = "free_disk_usage";
static char const *kHMDWatchDogKeyBlockDuration = "timeout_duration";
static char const *kHMDWatchDogKeyTimestamp = "timestamp";
static char const *kHMDWatchDogKeyInAppTime = "inapp_time";
static char const *kHMDWatchDogKeySettings = "settings";
static char const *kHMDWatchDogKeyOperationTrace = "operation_trace";
static char const *kHMDWatchDogKeyCustom = "custom";
static char const *kHMDWatchDogKeyFilters = "filters";
static char const *kHMDWatchDogKeySessionID = "session_id";
static char const *kHMDWatchDogKeyInternalSessionID = "internal_session_id";
static char const *kHMDWatchDogKeyLastScene = "last_scene";
static char const *kHMDWatchDogKeyBusiness = "business";
static char const *kHMDWatchDogKeyTimeline = "timeline";
static char const *kHMDWatchDogKeyDeadlock = "deadlock";
static char const *kHMDWatchDogKeyIsMainDeadlock = "is_main_thread_deadlock";
static char const *kHMDWatchDogKeyExceptionMainAdress = "exception_main_address";
static char const *kHMDWatchDogKeyPowerState = "powerState";
static char const *kHMDWatchDogKeyThermalState = "thermalState";
static char const *kHMDWatchDogKeyMainThreadCPUUssage = "main_thread_cpu_usage";
static char const *kHMDWatchDogKeyHostCPUUssage = "host_cpu_usage";
static char const *kHMDWatchDogKeyTaskCPUUssage = "task_cpu_usage";
static char const *kHMDWatchDogKeyCPUCount = "cpu_count";
static char const *kHMDWatchDogKeyAppVersion = "app_version";
static char const *kHMDWatchDogKeyBuildVersion = "build_version";
static char const *kHMDWatchDogKeyVids = "vids";


static NSString * const kHMD_WatchDog_DirectoryName = @"watch_dog"; // 文件夹名称
static const char *kHMDWatchDogMainFileName = "HMD_WatchDog_main_data"; // 主文件名
static const char *kHMDWatchDogExtraFileName = "HMD_WatchDog_second_data"; // 次文件名
static const char *kHMDWatchDogStackFlag = "[#stack-over#]";
static NSString * const KHMD_WatchDog_MaybeFlag = @"KHMD_WatchDog_maybe_data"; // 疑似watchdog文件名(临时)

// 通知
NSString *HMDWatchDogMaybeHappenNotification = @"HMDWatchDogMaybeHappenNotification";
NSString *HMDWatchDogTimeoutNotification = @"HMDWatchDogTimeoutNotification";
NSString *HMDWatchDogRecoverNotification = @"HMDWatchDogRecoverNotification";

typedef NS_ENUM(NSUInteger, HMDWatchDogNotification) {
    HMDWatchDogNotificationMaybeHappen,
    HMDWatchDogNotificationTimeout,
    HMDWatchDogNotificationRecover,
};

typedef NS_ENUM(NSUInteger, HMDRunloopMonitorVersion) {
    HMDRunloopMonitorVersion1,
    HMDRunloopMonitorVersion2,
};


// 默认值
#ifdef DEBUG
NSTimeInterval HMDWatchDogDefaultTimeoutInterval = 5.0;
NSTimeInterval HMDWatchDogDefaultSampleInterval = 1.0;
NSTimeInterval HMDWatchDogDefaultLaunchCrashThreshold = 5.0;
NSUInteger HMDWatchdogDefaultLastThreadsCount = 10;
BOOL HMDWatchDogDefaultSuspend = YES;
BOOL HMDWatchDogDefaultIgnoreBackground = NO;
BOOL HMDWatchDogDefaultUploadAlog = YES;
BOOL HMDWatchDogDefaultUploadMemoryLog = YES;
BOOL HMDWatchDogDefaultRaiseMainThreadPriority = YES;
NSTimeInterval HMDWatchdogDefaultRaiseMainThreadPriorityInterval = 3.0;
BOOL HMDWatchDogEnableRunloopMonitorV2 = YES;
NSUInteger HMDWatchDogRunloopMonitorThreadSleepInterval = 500; //500ms
BOOL HMDWatchDogDefaultEnableMonitorCompleteRunloop = YES;
#else
NSTimeInterval HMDWatchDogDefaultTimeoutInterval = 8.0;
NSTimeInterval HMDWatchDogDefaultSampleInterval = 1.0;
NSTimeInterval HMDWatchDogDefaultLaunchCrashThreshold = 5.0;
NSUInteger HMDWatchdogDefaultLastThreadsCount = 3;
BOOL HMDWatchDogDefaultSuspend = NO;
BOOL HMDWatchDogDefaultIgnoreBackground = NO;
BOOL HMDWatchDogDefaultUploadAlog = NO;
BOOL HMDWatchDogDefaultUploadMemoryLog = NO;
BOOL HMDWatchDogDefaultRaiseMainThreadPriority = NO;
NSTimeInterval HMDWatchdogDefaultRaiseMainThreadPriorityInterval = 8.0;
BOOL HMDWatchDogEnableRunloopMonitorV2 = NO;
NSUInteger HMDWatchDogRunloopMonitorThreadSleepInterval = 500; //500ms
BOOL HMDWatchDogDefaultEnableMonitorCompleteRunloop = NO;
#endif

static NSTimeInterval kUserQuitInterval = 2.0;
static NSTimeInterval const kTimeoutIntervalMin = 1.0;
static NSTimeInterval const kSampleIntervalMin = 0.5;
static NSUInteger const kLastThreadsCountMax = 10;

// 配置
static NSTimeInterval gTimeoutInterval = 0;
static NSTimeInterval gSampleInterval = 0;
static NSUInteger gLastThreadsCount = 0;
static NSTimeInterval gLaunchCrashThreshold = 0;
static BOOL gSuspend = NO;
static BOOL gIgnoreBackground = NO;
static BOOL gUploadAlog = NO;
static BOOL gUploadMemoryLog = NO;
static BOOL gRaiseMainThreadPriority = NO;
static NSTimeInterval gRaiseMainThreadPriorityInterval = 0;
static BOOL gEnableRunloopMonitorV2 = NO;
static NSUInteger gRunloopMonitorThreadSleepInterval = 0;
static BOOL gEnableMonitorCompleteRunloop = NO;

// 变量
static HMDWatchDogMonitorStatus gStatus = HMDWatchDogMonitorStatusNone;
static BOOL gMainFileExist = NO;
static BOOL gExtraFileExist = NO;
static char *gRootDirPath = NULL;
static NSTimeInterval gLaunchTS = 0;
static std::string gTimelineSampleTag;
static std::vector<char *>gTimelineLogArray;
static unsigned int gTimelineLogThreadIndex = 10000;
static bool gNotificationTag = false;
static dispatch_queue_t gNotificationQueue = NULL;
static HMDRunloopMonitorVersion gRunloopMonitorVersion;

// watchdog optimize
static NSTimeInterval runloopDuration = 0;
static NSTimeInterval runloopAcitivityIncrement = 0;
static bool* maybeWatchDogForOOM = nullptr;
static bool maybeWatchDogForOOMLastTime = false;

static pthread_mutex_t g_params_mutex = PTHREAD_MUTEX_INITIALIZER;
static char *HMDWatchDogOperationTrace = NULL;
static char *HMDWatchDogAccess = NULL;
static char *HMDWatchDogPowerState = NULL;
static char *HMDWatchDogThermalState = NULL;
static char *HMDWatchDogSessionID = NULL;
static char *HMDWatchDogExternalSessionID = NULL;
static char *HMDWatchDogCustomContext = NULL;
static char *HMDWatchDogFilters = NULL;
static char *HMDWatchDogLastScene = NULL;
static char *HMDWatchDogBusiness = NULL;

static void exit(void);

@interface NSMutableDictionary (HMDWatchDog)
- (void)changeKey:(NSString *)key to:(NSString *)newKey;
@end

@implementation NSMutableDictionary (HMDWatchDog)
- (void)changeKey:(NSString *)key to:(NSString *)newKey {
    id value = [self valueForKey:key];
    if (value != nil) {
        [self removeObjectForKey:key];
        [self setValue:value forKey:newKey];
    }
}
@end

@interface HMDWatchDog()
{
    BOOL _isActive;
}
@end

@implementation HMDWatchDog

+ (instancetype)sharedInstance {
    static HMDWatchDog *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDWatchDog alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // 配置
        gTimeoutInterval = HMDWatchDogDefaultTimeoutInterval;
        gSampleInterval = HMDWatchDogDefaultSampleInterval;
        gLaunchCrashThreshold = HMDWatchDogDefaultLaunchCrashThreshold;
        gIgnoreBackground = HMDWatchDogDefaultIgnoreBackground;
        gSuspend = HMDWatchDogDefaultSuspend;
        gLastThreadsCount = HMDWatchdogDefaultLastThreadsCount;
        gUploadAlog = HMDWatchDogDefaultUploadAlog;
        gUploadMemoryLog = HMDWatchDogDefaultUploadMemoryLog;
        gRaiseMainThreadPriority = HMDWatchDogDefaultRaiseMainThreadPriority;
        gRaiseMainThreadPriorityInterval = HMDWatchdogDefaultRaiseMainThreadPriorityInterval;

        // 变量
        gStatus = HMDWatchDogMonitorStatusNone;
        gMainFileExist = NO;
        gExtraFileExist = NO;
        gNotificationQueue = dispatch_queue_create("com.heimdallr.watchdog.notification", DISPATCH_QUEUE_SERIAL);
        NSString *rootDirPath = [[HeimdallrUtilities heimdallrRootPath] stringByAppendingPathComponent:kHMD_WatchDog_DirectoryName];
        gRootDirPath = strdup(rootDirPath.UTF8String);
        gLaunchTS = [HMDSessionTracker currentSession].timestamp;
        atexit(exit);
    }
    
    return self;
}

- (void)dealloc
{
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        // session id
        HMDApplicationSession *session = [HMDSessionTracker currentSession];
        if (session && [session respondsToSelector:@selector(sessionID)]) {
            [session removeObserver:self forKeyPath:@"sessionID"];
        }
        
        // external session id
        HMDSessionTracker *sessionTracker = [HMDSessionTracker sharedInstance];
        if (sessionTracker && [sessionTracker respondsToSelector:@selector(eternalSessionID)]) {
            [sessionTracker removeObserver:self forKeyPath:@"eternalSessionID"];
        }
        
        // scene
        id UITracker = DC_CL(HMDUITrackerManager, sharedManager);
        if(UITracker) {
            [UITracker removeObserver:self forKeyPath:@"scene"];
        }
        
        // business、custom、filters
        HMDInjectedInfo * injectedInfo = HMDInjectedInfo.defaultInfo;
        if(injectedInfo) {
            if([injectedInfo respondsToSelector:@selector(business)]) {
                [injectedInfo removeObserver:self forKeyPath:@"business"];
            }
            
            if([injectedInfo respondsToSelector:@selector(customContext)]) {
                [injectedInfo removeObserver:self forKeyPath:@"customContext"];
            }
            
            if([injectedInfo respondsToSelector:@selector(filters)]) {
                [injectedInfo removeObserver:self forKeyPath:@"filters"];
            }
        }
    } @catch (NSException *exception) {
        
    }
}

#pragma mark - Property
- (bool)lastTimeMaybeWatchdog {
    return maybeWatchDogForOOMLastTime;
}

- (NSTimeInterval)timeoutInterval {
    return gTimeoutInterval;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    if (timeoutInterval < kTimeoutIntervalMin) {
        timeoutInterval = kTimeoutIntervalMin;
    }
    
    gTimeoutInterval = timeoutInterval;
}

- (NSTimeInterval)sampleInterval {
    return gSampleInterval;
}

- (void)setSampleInterval:(NSTimeInterval)sampleInterval {
    if (sampleInterval < kSampleIntervalMin) {
        sampleInterval = kSampleIntervalMin;
    }
    
    gSampleInterval = sampleInterval;
}

- (NSUInteger)lastThreadsCount {
    return gLastThreadsCount;
}

- (void)setLastThreadsCount:(NSUInteger)lastThreadsCount {
    if (lastThreadsCount > kLastThreadsCountMax) {
        lastThreadsCount = kLastThreadsCountMax;
    }
    
    gLastThreadsCount = lastThreadsCount;
}

- (NSTimeInterval)launchCrashThreshold {
    return gLaunchCrashThreshold;
}

- (void)setLaunchCrashThreshold:(NSTimeInterval)launchCrashThreshold {
    gLaunchCrashThreshold = launchCrashThreshold;
}

- (BOOL)suspend {
    return gSuspend;
}

- (void)setSuspend:(BOOL)suspend {
    gSuspend = suspend;
}

- (BOOL)ignoreBackground {
    return gIgnoreBackground;
}

- (void)setIgnoreBackground:(BOOL)ignoreBackground {
    gIgnoreBackground = ignoreBackground;
}

- (BOOL)uploadAlog {
    return gUploadAlog;
}

- (void)setUploadAlog:(BOOL)uploadAlog {
    gUploadAlog = uploadAlog;
}

- (BOOL)uploadMemoryLog {
    return gUploadMemoryLog;
}

- (void)setUploadMemoryLog:(BOOL)uploadMemoryLog {
    gUploadMemoryLog = uploadMemoryLog;
}

- (BOOL)raiseMainThreadPriority {
    return gRaiseMainThreadPriority;
}

- (void)setRaiseMainThreadPriority:(BOOL)raiseMainThreadPriority {
    gRaiseMainThreadPriority = raiseMainThreadPriority;
}

- (NSTimeInterval)raiseMainThreadPriorityInterval {
    return gRaiseMainThreadPriorityInterval;
}

- (void)setRaiseMainThreadPriorityInterval:(NSTimeInterval)Interval {
    gRaiseMainThreadPriorityInterval = Interval;
}

- (BOOL)enableRunloopMonitorV2 {
    return gEnableRunloopMonitorV2;
}

- (void)setEnableRunloopMonitorV2:(BOOL)enableRunloopMonitorV2  {
    gEnableRunloopMonitorV2 = enableRunloopMonitorV2;
}

- (NSUInteger)runloopMonitorThreadSleepInterval {
    return gRunloopMonitorThreadSleepInterval;
}

- (void)setRunloopMonitorThreadSleepInterval:(NSUInteger)runloopMonitorThreadSleepInterval {
    if (runloopMonitorThreadSleepInterval >= 32 && runloopMonitorThreadSleepInterval <= 1000) {
        gRunloopMonitorThreadSleepInterval = runloopMonitorThreadSleepInterval;
    }else {
        gRunloopMonitorThreadSleepInterval = HMDWatchDogRunloopMonitorThreadSleepInterval;
    }
}

- (BOOL)enableMonitorCompleteRunloop {
    return gEnableMonitorCompleteRunloop;
}

- (void)setEnableMonitorCompleteRunloop:(BOOL)enableMonitorCompleteRunloop {
    gEnableMonitorCompleteRunloop = enableMonitorCompleteRunloop;
}

#pragma mark - Public

- (void)start {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //set up image list in a high priority queue
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            hmd_setup_log_header();
            hmd_setup_shared_image_list_if_need();
            [self initInfoDict];
        });
        
        BOOL res = [self initDirectory:[NSString stringWithUTF8String:gRootDirPath]];
        if (res) {
            [self initMaybeWatchDogFlagFile];
        }
        [self checkWatchDogLastTime];
    });

    if (!_delegate) {
        return;
    }
    
    HMDLog(@"WatchDog start");
    if (gEnableRunloopMonitorV2) {
        HMDMainRunloopMonitorV2::getInstance()->addObserver(monitorCallback);
        HMDMainRunloopMonitorV2::getInstance()->updateMonitorThreadSleepInterval(uint(gRunloopMonitorThreadSleepInterval));
        HMDMainRunloopMonitorV2::getInstance()->updateEnableMonitorCompleteRunloop(gEnableMonitorCompleteRunloop);
        gRunloopMonitorVersion = HMDRunloopMonitorVersion2;
    }else {
        HMDMainRunloopMonitor::getInstance()->addObserver(monitorCallback);
        HMDMainRunloopMonitor::getInstance()->updateEnableMonitorCompleteRunloop(gEnableMonitorCompleteRunloop);
        gRunloopMonitorVersion = HMDRunloopMonitorVersion1;
    }
}

- (void)stop {
    HMDLog(@"WatchDog stop");
    if (gRunloopMonitorVersion == HMDRunloopMonitorVersion1) {
        HMDMainRunloopMonitor::getInstance()->removeObserver(monitorCallback);
    }else {
        HMDMainRunloopMonitorV2::getInstance()->removeObserver(monitorCallback);
    }
    
}

static void recordRunloopDuration(struct HMDRunloopMonitorInfo *info) {
    if ((info->runloopActivity == kCFRunLoopAfterWaiting && info->status == HMDRunloopStatusBegin) ||
        (info->runloopActivity == kCFRunLoopBeforeWaiting && info->status == HMDRunloopStatusOver)) {
        runloopDuration = 0;
        *maybeWatchDogForOOM = false;
    }
    
    if (info->status == HMDRunloopStatusBegin) {
        runloopAcitivityIncrement = 0;
    } else {
        runloopDuration -= runloopAcitivityIncrement;
        runloopAcitivityIncrement = info->duration;
        runloopDuration += runloopAcitivityIncrement;
        if (runloopDuration >= (gTimeoutInterval-kUserQuitInterval)) {
            *maybeWatchDogForOOM = true;
        }
    }
}

static NSTimeInterval monitorCallback(struct HMDRunloopMonitorInfo *info) {
    if (maybeWatchDogForOOM != nullptr) {
        recordRunloopDuration(info);
    }
    
    switch (info->status) {
        case HMDRunloopStatusBegin:
        {
            return timeoutBegin(info);
            break;
        }
        case HMDRunloopStatusDuration:
        {
            return timeoutDuration(info);
            break;
        }
        case HMDRunloopStatusOver:
        {
            return timeoutOver(info);
            break;
        }
        default:
        {
            break;
        }
    }
    
    return -1;
}

/*
* RunloopBegin回调
* 处理进入Runloop监听时的首次等待时间点请求
*/
static NSTimeInterval timeoutBegin(struct HMDRunloopMonitorInfo *info) {
    return kUserQuitInterval; // 2s
}

/*
* RunloopDuration回调
* 进入监听 & 超时 & 采样逻辑
*/
static NSTimeInterval timeoutDuration(struct HMDRunloopMonitorInfo *info) {
    
    switch (gStatus) {
        // 2s
        case HMDWatchDogMonitorStatusNone:
        {
            HMDPrint("Watchdog⚠️ Begins to monitor [%dms]", (int)(1000*info->duration));
            if (filterBackground(info)) {
                notifyMaybeHappen(info, HMDWatchDogNotificationMaybeHappen);
                reset();
                return -1;
            }
            gStatus = HMDWatchDogMonitorStatusMonitor;
            cleanMainFile();
            writeExtraFile(info, false);
            //begin cpu statistics
            hmdHostCPUUsage(NULL);
            hmdTaskCPUUsage(NULL);
            HMDWeakWatchDog_markAppExitReasonWatchDog(true);
            return MIN(info->duration+1, gTimeoutInterval);
            break;
        }
        // 2~8s
        case HMDWatchDogMonitorStatusMonitor:
        {
            if (info->duration + kHMDMicroSecond > gTimeoutInterval) {
                if (filterBackground(info)) {
                    notifyMaybeHappen(info, HMDWatchDogNotificationTimeout);
                    reset();
                    return -1;
                }
                HMDPrint("Watchdog⚠️ Timeout [%dms]", (int)(1000*info->duration));
                cleanExtraFile();
                writeMainFile(info);
                gStatus = HMDWatchDogMonitorStatusEnvUpdate;
                raiseMainThreadPriority();
                HMDWeakWatchDog_markAppExitReasonWatchDog(false);
                HMDWatchDog_markAppExitReasonWatchDog(true);
                return info->duration + gSampleInterval;
            }
            else {
                if (filterBackground(info)) {
                    reset();
                    return -1;
                }
//              HMDPrint("Watchdog monitoring [%dms]", (int)(1000*info->duration));
                if (info->duration + kHMDMicroSecond > gRaiseMainThreadPriorityInterval) {
                    //(2,8)s
                    raiseMainThreadPriority();
                }
                updateTimeline(info, false, false);
                return MIN(info->duration+1, gTimeoutInterval);
            }
            
            break;
        }
        // 8s+
        case HMDWatchDogMonitorStatusEnvUpdate:
        {
            // 后台过滤
            if (filterBackground(info)) {
                reset();
                return -1;
            }
//          HMDPrint("Watchdog sampling[%dms]", (int)(1000*info->duration));
            writeExtraFile(info, true);
            return info->duration + gSampleInterval;
            break;
        }
        default:
        {
            reset();
            return -1;
            break;
        }
    }
}

/*
* RunloopOver回调
* 清理逻辑
*/
static NSTimeInterval timeoutOver(struct HMDRunloopMonitorInfo *info) {
    if (gNotificationTag) {
        HMDPrint("Watchdog⚠️ Recovered [%dms]", (int)(1000*info->duration));
        notifyMaybeHappen(info, HMDWatchDogNotificationRecover);
        HMDWeakWatchDog_markAppExitReasonWatchDog(false);
        HMDWatchDog_markAppExitReasonWatchDog(false);
    }
    restoreMainThreadPriority();
    reset();
    return -1;
}

static void notifyMaybeHappen(struct HMDRunloopMonitorInfo *info, HMDWatchDogNotification type) {
    NSTimeInterval duration = info->duration;
    NSTimeInterval begin = info->begin;
    BOOL background = info->background;
    dispatch_async(gNotificationQueue, ^{
        NSString *notificationName = nil;
        switch (type) {
            case HMDWatchDogNotificationMaybeHappen: {
                gNotificationTag = true;
                notificationName = HMDWatchDogMaybeHappenNotification;
                break;
            }
            case HMDWatchDogNotificationTimeout: {
                gNotificationTag = true;
                notificationName = HMDWatchDogTimeoutNotification;
                break;
            }
            case HMDWatchDogNotificationRecover: {
                if (gNotificationTag) {
                    notificationName = HMDWatchDogRecoverNotification;
                    gNotificationTag = false;
                }
                else {
                    return;
                }
                break;
            }
            default:
                return;
        }
        
        NSDictionary *userInfo = @{
            @"duration" : @(duration),
            @"begin":@(begin),
            @"background":@(background),
        };
        
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

#pragma mark - Clean File

static void exit(void) {
    //自动化测试团队需求：在子线程强行退出app，但是还记录卡死日志
    if (pthread_main_np() != 0)
    {
        // 该方法要求快速响应，只强制删除Main File, Extra File可以不删除
        deleteFile(kHMDWatchDogMainFileName);
    }
}

static void reset(void) {
    cleanMainFile();
    cleanExtraFile();
    gStatus = HMDWatchDogMonitorStatusNone;
    
    // 清理timeline数据
    gTimelineLogThreadIndex = 10000;
    for (int i=0; i<gTimelineLogArray.size(); i++) {
        char *log = gTimelineLogArray[i];
        if (log != NULL) {
            free(log);
        }
    }
    
    gTimelineLogArray.clear();
    gTimelineSampleTag.clear();
}

static BOOL deleteFile(const char *fileName) {
    if (fileName == NULL) {
        return NO;
    }
    
    size_t filePathSize = strlen(gRootDirPath) + strlen(fileName) + 100;
    char *filePath = (char *)malloc(filePathSize);
    if (filePath == NULL) {
        return false;
    }
    
    snprintf(filePath, filePathSize, "%s/%s", gRootDirPath, fileName);
    BOOL rst = (remove(filePath) == 0);
    free(filePath);
    return rst;
}

static void cleanMainFile(void) {
    if(gMainFileExist) {
        deleteFile(kHMDWatchDogMainFileName);
        gMainFileExist = NO;
    }
}

static void cleanExtraFile(void) {
    if(gExtraFileExist) {
        deleteFile(kHMDWatchDogExtraFileName);
        gExtraFileExist = NO;
    }
}

#pragma mark - write file

static void writeMainFile(HMDRunloopMonitorInfo *info) {
    size_t filePathSize = strlen(gRootDirPath) + strlen(kHMDWatchDogMainFileName) + 100;
    char *filePath = (char *)malloc(filePathSize);
    if (filePath == NULL) {
        return;
    }
    
    snprintf(filePath, filePathSize, "%s/%s", gRootDirPath, kHMDWatchDogMainFileName);
    HMDWatchdogTimelineInfo timelineInfo = updateTimeline(info, false, true);
    char *log = hmd_apple_backtraces_log_of_all_threads((thread_t)hmdbt_main_thread, 0, 0, gSuspend, HMDLogWatchDog, NULL, NULL);
    if (log == NULL) {
        HMDPrint("Watchdog❌ cannot get stacks");
        HMD_ALOG_PROTOCOL_ERROR_TAG("Heimdallr", "[WatchDog] Log failed");
        free(filePath);
        return;
    }
    
    FILE *fp = fopen(filePath, "w"); //若没有文件则创建文件，已存在文件则覆盖原文件
    if (fp == NULL) {
        free(log);
        free(filePath);
        HMD_ALOG_PROTOCOL_ERROR_TAG("Heimdallr", "[WatchDog] main file open failed");
        return;
    }
    
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    double memoryUsage = memoryBytes.appMemory / (double)HMD_MB;
    double freeMemoryUsage = memoryBytes.availabelMemory / (double)HMD_MB;
    double freeDiskUsage = freeDiskSpace() / (double)HMD_MB;
    CFTimeInterval inAppTime = timelineInfo.ts - gLaunchTS;
    double main_thread_cpu_usage = hmdCPUUsageFromSingleThread((thread_t)hmdbt_main_thread);
    hmd_host_cpu_usage_info host_cpu_usage = {0};
    hmdHostCPUUsage(&host_cpu_usage);
    hmd_task_cpu_usage_info task_cpu_usage = {0};
    hmdTaskCPUUsage(&task_cpu_usage);
    int cpu_count = hmdCountOfCPUCores();
    HMDPrint("Watchdog⚠️ current main_thread cpu usage: %.2f%%  host cpu usage: %.2f%%, task cpu usage: %.2f%%, cpu count: %d",main_thread_cpu_usage, host_cpu_usage.total*100, task_cpu_usage.total*100, cpu_count);
    //死锁检测
    bool isCycle = false;
    bool isMainThreadCycle = false;
    char *lock_graph_buffer = fech_app_deadlock_str(&isCycle, &isMainThreadCycle);
    
    //main函数地址,用于关联Metrickit数据
    unsigned long main_adress = hmdbt_get_app_main_addr();
    
    //vid
    hmd_ab_test_vids_t *vid_info = hmd_get_vid_info();
    char *vids = NULL;
    if (vid_info && vid_info->vid_count >0 && vid_info->offset < HMD_MAX_VID_LIST_LENGTH) {
        size_t offset = vid_info->offset;
        vids = (char *)malloc(offset);
        strncpy(vids, vid_info->vids, offset);
    }

    int lock_rst = pthread_mutex_lock(&g_params_mutex);

    fprintf(fp, "%s%s{\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":%s,\"%s\":%s,\"%s\":%s,\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":%f,\"%s\":%f,\"%s\":%f,\"%s\":%f,\"%s\":%f,\"%s\":%f,\"%s\":%s,\"%s\":%s,\"%s\":{\"%s\":%f,\"%s\":%f,\"%s\":%f,\"%s\":%lu,\"%s\":%s,\"%s\":%s},\"%s\":\"%s\",\"%s\":%s,\"%s\":%s,\"%s\":%lu,\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":%.2f,\"%s\":%.2f,\"%s\":%.2f,\"%s\":%d,\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":[%s]}",
            log, kHMDWatchDogStackFlag,
            kHMDWatchDogKeySessionID, (HMDWatchDogSessionID != NULL) ? HMDWatchDogSessionID : "unknown",
            kHMDWatchDogKeyInternalSessionID, (HMDWatchDogExternalSessionID != NULL) ? HMDWatchDogExternalSessionID : "unknown",
            kHMDWatchDogKeyLastScene, (HMDWatchDogLastScene != NULL) ? HMDWatchDogLastScene : "unknown",
            kHMDWatchDogKeyOperationTrace, (HMDWatchDogOperationTrace != NULL) ? HMDWatchDogOperationTrace : "{}",
            kHMDWatchDogKeyCustom, (HMDWatchDogCustomContext != NULL) ? HMDWatchDogCustomContext : "{}",
            kHMDWatchDogKeyFilters, (HMDWatchDogFilters != NULL) ? HMDWatchDogFilters : "{}",
            kHMDWatchDogKeyNetwork, (HMDWatchDogAccess != NULL) ? HMDWatchDogAccess : "",
            kHMDWatchDogKeyBusiness, (HMDWatchDogBusiness != NULL) ? HMDWatchDogBusiness : "unknown",
            kHMDWatchDogKeyBlockDuration, info->duration,
            kHMDWatchDogKeyMemoryUsage, memoryUsage,
            kHMDWatchDogKeyFreeMemoryUsage, freeMemoryUsage,
            kHMDWatchDogKeyFreeDiskUsage, freeDiskUsage,
            kHMDWatchDogKeyTimestamp, timelineInfo.ts,
            kHMDWatchDogKeyInAppTime, inAppTime,
            kHMDWatchDogKeyBackground, info->background ? "true" : "false",
            kHMDWatchDogKeyIsLaunchCrash, (inAppTime - info->duration < gLaunchCrashThreshold) ? "true" : "false",
            kHMDWatchDogKeySettings,
            "timeoutInterval", gTimeoutInterval,
            "sampleInterval", gSampleInterval,
            "launchCrashThreshold", gLaunchCrashThreshold,
            "lastThreadsCount", (unsigned long)gLastThreadsCount,
            "suspend", gSuspend ? "true" : "false",
            "ignoreBackground", gIgnoreBackground ? "true" : "false",
            kHMDWatchDogKeyTimeline, gTimelineSampleTag.c_str(),
            kHMDWatchDogKeyDeadlock, (!lock_graph_buffer || (strlen(lock_graph_buffer)==0))?"[]":lock_graph_buffer,
            kHMDWatchDogKeyIsMainDeadlock, isMainThreadCycle ? "true" : "false",
            kHMDWatchDogKeyExceptionMainAdress, main_adress,
            kHMDWatchDogKeyPowerState,(HMDWatchDogPowerState != NULL) ? HMDWatchDogPowerState : "unknown",
            kHMDWatchDogKeyThermalState, (HMDWatchDogThermalState != NULL) ? HMDWatchDogThermalState : "unknown",
            kHMDWatchDogKeyMainThreadCPUUssage, main_thread_cpu_usage,
            kHMDWatchDogKeyHostCPUUssage, host_cpu_usage.total*100,
            kHMDWatchDogKeyTaskCPUUssage, task_cpu_usage.total*100,
            kHMDWatchDogKeyCPUCount, cpu_count,
            kHMDWatchDogKeyAppVersion, [HMDInfo defaultInfo].shortVersion.length > 0 ? [HMDInfo defaultInfo].shortVersion.UTF8String : "unknown",
            kHMDWatchDogKeyBuildVersion, [HMDInfo defaultInfo].buildVersion.length > 0 ? [HMDInfo defaultInfo].buildVersion.UTF8String : "unknown",
            kHMDWatchDogKeyVids, vids ?:"");
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_params_mutex);
    }
    fclose(fp);
    free(filePath);
    free(log);
    free(lock_graph_buffer);
    if (vids) {
        free(vids);
    }
//    ALOG_PROTOCOL_WARN_TAG("Heimdallr", "[WatchDog] Main file update");
    gMainFileExist = YES;
    notifyMaybeHappen(info, HMDWatchDogNotificationTimeout);
}

static void writeExtraFile(HMDRunloopMonitorInfo *info, bool capture) {
    size_t filePathLength = strlen(gRootDirPath) + strlen(kHMDWatchDogExtraFileName) + 100;
    char *filePath = (char *)malloc(filePathLength);
    if (filePath == NULL) {
        return;
    }
    
    snprintf(filePath, filePathLength, "%s/%s", gRootDirPath, kHMDWatchDogExtraFileName);
    
    HMDWatchdogTimelineInfo timelineInfo = updateTimeline(info, capture, false);
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    double memoryUsage = memoryBytes.appMemory / (double)HMD_MB;
    double freeMemoryUsage = memoryBytes.availabelMemory / (double)HMD_MB;
    double freeDiskUsage = freeDiskSpace() / (double)HMD_MB;
    FILE *fp = fopen(filePath, "w"); // 如果没有文件创建文件，如果有覆盖原文件
    if (fp == NULL) {
        HMD_ALOG_PROTOCOL_ERROR_TAG("Heimdallr", "[WatchDog] Extra file open failed");
        free(filePath);
        return;
    }
    
    CFTimeInterval inAppTime = timelineInfo.ts - gLaunchTS;
    
    // 写入timeline log
    for (int i=0; i<gTimelineLogArray.size(); i++) {
        char *timelineLog = gTimelineLogArray[i];
        if (timelineLog != NULL) {
            fputs(timelineLog, fp);
        }
    }
    
    fputs(kHMDWatchDogStackFlag, fp);
    
    // 写入环境变量json
    int lock_rst = pthread_mutex_lock(&g_params_mutex);
    fprintf(fp, "{\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":\"%s\",\"%s\":%s,\"%s\":%f,\"%s\":%f,\"%s\":%f,\"%s\":%f,\"%s\":%f,\"%s\":%f,\"%s\":%s,\"%s\":\"%s\"}",
            kHMDWatchDogKeySessionID, (HMDWatchDogSessionID != NULL) ? HMDWatchDogSessionID : "unknown",
            kHMDWatchDogKeyInternalSessionID, (HMDWatchDogExternalSessionID != NULL) ? HMDWatchDogExternalSessionID : "unknown",
            kHMDWatchDogKeyLastScene, (HMDWatchDogLastScene != NULL) ? HMDWatchDogLastScene : "unknown",
            kHMDWatchDogKeyOperationTrace, (HMDWatchDogOperationTrace != NULL) ? HMDWatchDogOperationTrace : "{}",
            kHMDWatchDogKeyBlockDuration, info->duration,
            kHMDWatchDogKeyMemoryUsage, memoryUsage,
            kHMDWatchDogKeyFreeMemoryUsage, freeMemoryUsage,
            kHMDWatchDogKeyFreeDiskUsage, freeDiskUsage,
            kHMDWatchDogKeyTimestamp, timelineInfo.ts,
            kHMDWatchDogKeyInAppTime, inAppTime,
            kHMDWatchDogKeyBackground, info->background ? "true" : "false",
            kHMDWatchDogKeyTimeline, gTimelineSampleTag.c_str());
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_params_mutex);
    }
    
    fclose(fp);
    free(filePath);
    gExtraFileExist = YES;
//    ALOG_PROTOCOL_WARN_TAG("Heimdallr", "[WatchDog] Extra file update");
    if (!capture) {
        notifyMaybeHappen(info, HMDWatchDogNotificationMaybeHappen);
    }
}

#pragma mark - thread priority

static int old_priority = -1;

//if the main thread is running and in a low cpu usage, try to raise main thread priority after writeMainFile for watchdog.
static bool raiseMainThreadPriority() {
    if (!gRaiseMainThreadPriority) {
        return false;
    }
    //Priority has been raised
    if (old_priority > 0) {
        return false;
    }
    thread_extended_info thread_info;
    kern_return_t kr = hmdthread_getExtendInfo(hmdbt_main_thread, &thread_info);
    if (kr == KERN_SUCCESS
        && thread_info.pth_run_state == TH_STATE_RUNNING
        && thread_info.pth_curpri < thread_info.pth_maxpriority
        && double(thread_info.pth_cpu_usage)/TH_USAGE_SCALE*100 < HMDWatchdogRaisePriorityCPULimit) {
        bool ret = hmdthread_setPriority(hmdbt_main_pthread, thread_info.pth_maxpriority);
        if (ret) {
            HMDPrint("Watchdog⚠️ main thread running slowly（current main thread cpu usage: %.2f）, try to raise priority, priority:%d ⤴️ %d",double(thread_info.pth_cpu_usage)/TH_USAGE_SCALE*100, thread_info.pth_curpri, thread_info.pth_maxpriority);
            old_priority = thread_info.pth_priority;
            return true;
        }
    }
    return false;
}

static bool restoreMainThreadPriority() {
    if (!gRaiseMainThreadPriority) {
        return false;
    }
    if (old_priority > 0) {
        hmdthread_setPriority(hmdbt_main_pthread, old_priority);
        old_priority = -1;
        return true;
    }
    return false;
}



#pragma mark - Read File （OC Method）

- (void)checkWatchDogLastTime {
    NSString *mainFileName = [NSString stringWithUTF8String:kHMDWatchDogMainFileName];
    NSString *extraFileName = [NSString stringWithUTF8String:kHMDWatchDogExtraFileName];
    NSData *mainData = [self dataWithFileName:mainFileName];
    NSData *extraData = [self dataWithFileName:extraFileName];
    if (mainData) {
        deleteFile(kHMDWatchDogMainFileName);
    }
    
    if (extraData) {
        deleteFile(kHMDWatchDogExtraFileName);
    }
    
    if (mainData == nil && extraData == nil) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
        NSDictionary *mainDictionary = [self dictionaryWithData:mainData fileName:mainFileName];
        NSDictionary *extraDictionary = [self dictionaryWithData:extraData fileName:extraFileName];
        
        if(!mainDictionary && extraDictionary) {
            // 发生2s卡死，但在8s前程序退出
            HMDPrint("Watchdog ⚠️ Last launch of Watchdog was suspected to be stuck! User quitted forcedly.");
            [self.delegate watchDogDidDetectUserForceQuitWithData:extraDictionary];
        }
        else if(mainDictionary) {
            // 发生卡死
            if(extraDictionary) { // 发生卡死，且需要更新MainFile中的信息
                NSMutableDictionary *copied = [mainDictionary mutableCopy];
                [extraDictionary enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    @autoreleasepool {
                        // Extra File中存储的只是主线程堆栈，要合入到Main File的Stack中
                        if ([key isEqualToString:kHMDWatchDogExportKeyStack]) {
                            NSString *stack = [copied objectForKey:kHMDWatchDogExportKeyStack];
                            if (stack && [stack isKindOfClass:[NSString class]] && stack.length > 0 && obj && [obj isKindOfClass:[NSString class]] && [obj length] > 0) {
                                NSMutableString *combineStack = [[NSMutableString alloc] initWithString:stack];
                                NSRange range = [combineStack rangeOfString:@"Thread 1 name:"];
                                if (range.location != NSNotFound) {
                                    [combineStack insertString:obj atIndex:range.location];
                                    [copied setObject:[combineStack copy] forKey:key];
                                }
                            }
                        }
                        else {
                            [copied setObject:obj forKey:key];
                        }
                    }
                }];
                mainDictionary = [copied copy];
            }
            
            [self.delegate watchDogDidDetectSystemKillWithData:mainDictionary];
            HMDPrint("Watchdog⚠️ Last launch of Watchdog was stuck! Reporting stacks.");
        }
        else {
            [self.delegate watchDogDidNotHappenLastTime];
        }
    });
}

- (NSData *)dataWithFileName:(NSString *)fileName {
    NSString *filePath = [[NSString stringWithUTF8String:gRootDirPath] stringByAppendingPathComponent:fileName];
    return [NSData dataWithContentsOfFile:filePath];
}

- (NSDictionary *)dictionaryWithData:(NSData *)data fileName:(NSString *)fileName {
    if (!data) {
        return nil;
    }
    
    NSString *originStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray<NSString *> *strList = nil;
    if (originStr) {
        strList = [originStr componentsSeparatedByString:[NSString stringWithUTF8String:kHMDWatchDogStackFlag]];
    }
    
    // V2版本文件结构，格式：stack+flag+json
    if (strList && strList.count == 2) {
        NSString *stack = strList[0];
        NSString *infoJsonString = strList[1];
        NSData *jsonData = [infoJsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = nil;
        NSError *error = nil;
        try {
            dict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        } catch (NSException *exception) {
        }
        
        if (!dict) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[WatchDog] %@ file v2 decode failed with error %@", fileName, error);
            return nil;
        }
        
        if (stack && [stack isKindOfClass:[NSString class]] && stack.length > 0) {
            NSMutableDictionary *mDict = [NSMutableDictionary dictionaryWithDictionary:dict];
            [mDict setObject:stack forKey:kHMDWatchDogExportKeyStack];
            return [mDict copy];
        }
        else {
            return dict;
        }
    }
    // V1版本文件结构，格式：json
    else {
        NSKeyedUnarchiver *unarv = nil;
        @try {
            if (@available(iOS 11.0, *)) {
                if([NSKeyedUnarchiver instancesRespondToSelector:@selector(initForReadingFromData:error:)]) {
                    unarv = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:nil];
                    unarv.requiresSecureCoding = NO;
                }
                else {
                    unarv = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
                }
            }
            else {
                unarv = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            }
        } @catch (NSException *exception) {
            unarv = nil;
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[WatchDog] %@ file v1 archive failed with exception %@", fileName, exception);
        }
        
        if (unarv) {
            NSDictionary *dict = [unarv decodeObjectForKey:NSKeyedArchiveRootObjectKey];
            [unarv finishDecoding];
            if (!dict) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[WatchDog] %@ file v1 decode failed", fileName);
                return nil;
            }
            else {
                NSDictionary *remapDict = [self remapDictionaryFormV1ToV2:dict];
                return remapDict;
            }
        }
    }
    
    return nil;
}

- (BOOL)initDirectory:(NSString *)path {
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isEst = [manager fileExistsAtPath:path isDirectory:&isDir];
    if(isEst && isDir) {
        return YES;
    }
    
    NSError *error = nil;
    BOOL rst = [manager createDirectoryAtPath:path
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:&error];
    if (error) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[Watchdog] Init directory failed with error %@", error);
    }
    
    return rst;
}

- (void)initMaybeWatchDogFlagFile {
    NSString *maybeWatchdogFilePath = [[NSString stringWithUTF8String:gRootDirPath] stringByAppendingPathComponent:KHMD_WatchDog_MaybeFlag];
    int m_fd = open(maybeWatchdogFilePath.UTF8String, O_CREAT|O_RDWR, S_IRUSR|S_IWUSR);
    if (m_fd != -1) {
        int res = ftruncate(m_fd, 10);
        if (res == 0) {
            maybeWatchDogForOOM = (bool*)mmap(nullptr, 10, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_FILE, m_fd, 0);
            if (maybeWatchDogForOOM != MAP_FAILED) {
                maybeWatchDogForOOMLastTime = *maybeWatchDogForOOM;
                *maybeWatchDogForOOM = false;
                return;
            }
        }
        close(m_fd);
    }
}

- (NSDictionary *)remapDictionaryFormV1ToV2:(NSDictionary *)dict {
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *remapDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_backtrace" to:kHMDWatchDogExportKeyStack];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_isLaunchCrash" to:kHMDWatchDogExportKeyIsLaunchCrash];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_isBackground" to:kHMDWatchDogExportKeyIsBackground];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_connectTypeName" to:kHMDWatchDogExportKeyNetwork];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_memoryUsage" to:kHMDWatchDogExportKeyMemoryUsage];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_freeMemoryUsage" to:kHMDWatchDogExportKeyFreeMemoryUsage];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_freeDiskUsage" to:kHMDWatchDogExportKeyFreeDiskUsage];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_timeoutDuration" to:kHMDWatchDogExportKeyTimeoutDuration];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_timeStamp" to:kHMDWatchDogExportKeyTimestamp];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_inAppTime" to:kHMDWatchDogExportKeyinAppTime];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_setting" to:kHMDWatchDogExportKeySettings];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_operationTrace" to:kHMDWatchDogExportKeyOperationTrace];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_sessionID" to:kHMDWatchDogExportKeySessionID];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_internalSessionID" to:kHMDWatchDogExportKeyInternalSessionID];
        [remapDict changeKey:@"HMD_WatchDog_exposedData_lastScene" to:kHMDWatchDogExportKeylastScene];
        return [remapDict copy];
    }
    
    return nil;
}

#pragma mark - C Support

static unsigned long long freeDiskSpace(void) {
    struct statfs s;
    int ret = statfs(hmd_home_path, &s);
    if (ret == 0) {
        return s.f_bavail * s.f_bsize;
    }
    
    return 0;
}

static bool updateTimelineLog(struct HMDRunloopMonitorInfo *info, struct HMDWatchdogTimelineInfo *timelineInfo) {
    // 不需要进行主线程采样
    NSUInteger currentThreadsCount = gLastThreadsCount;
    if (currentThreadsCount == 0) {
        return true;
    }
    
    hmdbt_backtrace_t *bt = hmdbt_origin_backtrace_of_main_thread(0, gSuspend, true);
    if (bt->name == NULL) {
        bt->name = (char *)malloc(sizeof(char)*200);
    }

    if (bt->name != NULL) {
        snprintf(bt->name, sizeof(char)*200, "Obtained stacks of main thread when main thread was stuck after %.2fs", timelineInfo->duration);
//        appendThreadInfo(bt->name, 200, &(timelineInfo->thinfo));
    }
    
    bt->thread_idx = gTimelineLogThreadIndex++;

    char *newLog = hmd_apple_clear_backtrace_log_of_thread(bt);
    hmdbt_dealloc_bactrace(&bt, 1);
    if (newLog == NULL) {
        return false;
    }
    
    while (gTimelineLogArray.size() >= currentThreadsCount) {
        char *deleteLog = gTimelineLogArray[0];
        free(deleteLog);
        gTimelineLogArray.erase(gTimelineLogArray.begin());
    }
    
    gTimelineLogArray.push_back(newLog);
//   HMDPrint("WatchDog timeline[%lu]", gTimelineLogArray.size());
    return true;
}

static HMDWatchdogTimelineInfo updateTimeline(struct HMDRunloopMonitorInfo *info, bool capture, bool tag) {
    HMDWatchdogTimelineInfo timelineInfo = {0};
    timelineInfo.ts = HMD_XNUSystemCall_timeSince1970();
    timelineInfo.duration = info->duration;
    timelineInfo.thinfo = getMainThreadInfo();
    bool log_failed = false;
    if (capture) {
        log_failed = !updateTimelineLog(info, &timelineInfo);
    }
    
    char str[30] = {0};
    thread_basic_info_t basic_info = (timelineInfo.thinfo.thread_count > 0) ? (thread_basic_info_t)timelineInfo.thinfo.info_data : NULL;
    if (tag || log_failed) {
            snprintf(str, sizeof(str), "{%.3f(%d/%d/%.2f)}-", timelineInfo.ts - info->begin, (basic_info==NULL)?(-1):basic_info->run_state, (basic_info==NULL)?(-1):basic_info->flags, (basic_info==NULL)?(-1):basic_info->cpu_usage / (float)TH_USAGE_SCALE * 100.0);
        }
        else {
            snprintf(str, sizeof(str), "%.3f(%d/%d/%.2f)-", timelineInfo.ts - info->begin, (basic_info==NULL)?(-1):basic_info->run_state, (basic_info==NULL)?(-1):basic_info->flags, (basic_info==NULL)?(-1):basic_info->cpu_usage / (float)TH_USAGE_SCALE * 100.0);
        }

    gTimelineSampleTag.append(str);
    return timelineInfo;
}

static bool filterBackground(HMDRunloopMonitorInfo *info) {
    if (gIgnoreBackground) {
        if (info->background) {
            return true;
        }
        
        info->background = HMDApplicationSession_backgroundState();
        if (info->background) {
            return true;
        }
    }
    
    return false;
}

static HMDWatchdogThreadInfo getMainThreadInfo(void) {
    HMDWatchdogThreadInfo info = {0};
    info.thread_count = THREAD_INFO_MAX;
    kern_return_t kr = thread_info((thread_t)hmdbt_main_thread, THREAD_BASIC_INFO, (thread_info_t)info.info_data, &(info.thread_count));
    if (kr != KERN_SUCCESS) {
        info.thread_count = 0;
    }
    
    return info;
}

void appendThreadInfo(char *buffer, unsigned int size, HMDWatchdogThreadInfo *info) {
    if (buffer == NULL || size == 0 || info == NULL || info->thread_count == 0) {
        return;
    }

    const char *run_state = "";
    const char *flags = "";
    char cpu_usage[30] = {0};
    thread_basic_info_t basic_info_th = (thread_basic_info_t)info->info_data;
    snprintf(cpu_usage, sizeof(cpu_usage), "(cpu_usage: %.2f%%) ", basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0);
    switch (basic_info_th->run_state) {
        case TH_STATE_RUNNING:
        {
            run_state = "(run_state: running) ";
            break;
        }
        case TH_STATE_STOPPED:
        {
            run_state = "(run_state: stopped) ";
            break;
        }
        case TH_STATE_WAITING:
        {
            run_state = "(run_state: waiting) ";
            break;
        }
        case TH_STATE_UNINTERRUPTIBLE:
        {
            run_state = "(run_state: uninteruptible) ";
            break;
        }
        case TH_STATE_HALTED:
        {
            run_state = "(run_state: Halted) ";
            break;
        }
        default:
            break;
    }

    switch (basic_info_th->flags) {
        case TH_FLAGS_SWAPPED:
        {
            flags = "(flags: swapped out) ";
            break;
        }
        case TH_FLAGS_IDLE:
        {
            flags = "(flags: idle) ";
            break;
        }
        case TH_FLAGS_GLOBAL_FORCED_IDLE:
        {
            flags = "(flags: global forced idle) ";
            break;
        }
        default:
            break;
    }
    
    size_t appendList_length = strlen(run_state) + strlen(flags) + strlen(cpu_usage) + 1;
    char *appendList = (char *)calloc(appendList_length, sizeof(char));
    if (appendList) {
        snprintf(appendList, appendList_length, "%s%s%s", run_state, flags, cpu_usage);
        size_t buffer_length = strlen(buffer);
        size_t remainder = size - 1 - buffer_length; //buffer剩余可用大小
        strncat(buffer, appendList, remainder<appendList_length?remainder:appendList_length);
        free(appendList);
    }
}


#pragma mark - Info Dict

// 初始化运行时参数，由于在卡死log写入时无法访问OC方法，所以需要提前将所需参数内容转化成C
- (void)initInfoDict {
    
    // access
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkAccessChanged:)
                                                 name:TTReachabilityChangedNotification
                                               object:nil];
    [self networkAccessChanged:nil];
    
    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thermalStateChangeed:) name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    }
    [self thermalStateChangeed:nil];
    if (@available(iOS 9.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerStateChangeed:) name:NSProcessInfoPowerStateDidChangeNotification object:nil];
    }
    [self powerStateChangeed:nil];
    
    // session id
    HMDApplicationSession *session = [HMDSessionTracker currentSession];
    if (session && [session respondsToSelector:@selector(sessionID)]) {
        [session addObserver:self
                  forKeyPath:@"sessionID"
                     options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                     context:NULL];
    }
    
    // external session id
    HMDSessionTracker *sessionTracker = [HMDSessionTracker sharedInstance];
    if (sessionTracker && [sessionTracker respondsToSelector:@selector(eternalSessionID)]) {
        [sessionTracker addObserver:self
                         forKeyPath:@"eternalSessionID"
                            options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                            context:NULL];
    }
    
    // UITracker
    id UITracker = DC_CL(HMDUITrackerManager, sharedManager);
    if(UITracker) {
        // operation trace
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sceneDidUpdate)
                                                     name:@"kHMDUITrackerSceneDidChangeNotification"
                                                   object:nil];
        // scene
        if ([UITracker respondsToSelector:@selector(scene)]) {
            [UITracker addObserver:self
                        forKeyPath:@"scene"
                           options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                           context:NULL];
        }
    }
    
    // business、custom、filters
    HMDInjectedInfo * injectedInfo = HMDInjectedInfo.defaultInfo;
    if(injectedInfo) {
        if([injectedInfo respondsToSelector:@selector(business)]) {
            [injectedInfo addObserver:self
                           forKeyPath:@"business"
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
        }
        
        if([injectedInfo respondsToSelector:@selector(customContext)]) {
            [injectedInfo addObserver:self
                           forKeyPath:@"customContext"
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
        }
        
        if([injectedInfo respondsToSelector:@selector(filters)]) {
            [injectedInfo addObserver:self
                           forKeyPath:@"filters"
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
        }
    }
}

- (void)sceneDidUpdate {
    NSDictionary *dic = [HMDTracker getOperationTraceIfAvailable];
    [self updateInfoWithVariable:&HMDWatchDogOperationTrace value:dic];
}

- (void)networkAccessChanged:(NSNotification *)notification {
    NSString *access = [HMDNetworkHelper connectTypeName];
    [self updateInfoWithVariable:&HMDWatchDogAccess value:access];
}

- (void)powerStateChangeed:(NSNotification *)notification {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *powerState = @"normal";
        if (@available(iOS 9.0, *)) {
            if ([[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
                powerState = @"low";
            }
        }
        [self updateInfoWithVariable:&HMDWatchDogPowerState value:powerState];
    });
}

- (void)thermalStateChangeed:(NSNotification *)notification {
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
        [self updateInfoWithVariable:&HMDWatchDogThermalState value:thermalState];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    id value = [change valueForKey:NSKeyValueChangeNewKey];
    if ([keyPath isEqualToString:@"sessionID"]) {
        [self updateInfoWithVariable:&HMDWatchDogSessionID value:value];
    }
    else if([keyPath isEqualToString:@"eternalSessionID"]) {
        [self updateInfoWithVariable:&HMDWatchDogExternalSessionID value:value];
    }
    else if([keyPath isEqualToString:@"customContext"]) {
        [self updateInfoWithVariable:&HMDWatchDogCustomContext value:value];
    }
    else if([keyPath isEqualToString:@"filters"]) {
        [self updateInfoWithVariable:&HMDWatchDogFilters value:value];
    }
    else if([keyPath isEqualToString:@"scene"]){
        [self updateInfoWithVariable:&HMDWatchDogLastScene value:value];
    }
    else if ([keyPath isEqualToString:@"business"]) {
        [self updateInfoWithVariable:&HMDWatchDogBusiness value:value];
    }
}

- (void)updateInfoWithVariable:(char **)var value:(id)value {
    if (var == NULL) {
        return;
    }
    
    char *newVar = NULL;
    
    if (value == nil) {
        newVar = NULL;
    }
    else if ([value isKindOfClass:[NSString class]]) {
        newVar = strdup(((NSString *)value).UTF8String);
    }
    else if ([value isKindOfClass:[NSDictionary class]]) {
        NSString * strValue = ((NSDictionary *)value).hmd_jsonString;
        if (strValue) {
            newVar = strdup(strValue.UTF8String);
        }else {
            NSAssert(NO, @"info value must be valid JSON object!");
            newVar = NULL;
        }
    }
    
    int lock_rst = pthread_mutex_lock(&g_params_mutex);
    if ((*var) != NULL) {
        free(*var);
        *var = NULL;
    }
    
    *var = newVar;
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_params_mutex);
    }
}

@end
