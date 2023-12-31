//
//  HMDANRMonitor.m
//  Heimdallr
//
//  Created by joy on 2018/4/26.
//

#import <stdio.h>
#include <mach/mach_host.h>
#include <mach/mach_time.h>
#import <vector>

#import "HMDANRMonitor.h"
#import "HMDMacro.h"
#import "hmd_apple_backtrace_log.h"
#import "HMDAppleBacktracesLog.h"
#import "HMDBacktraceLog.h"
#import "HMDThreadBacktrace.h"
#import "HMDThreadBacktrace+Private.h"
#import "pthread_extended.h"
#import "HMDTimeSepc.h"
#import "HMDMainRunloopMonitor.h"
#import "HMDALogProtocol.h"
#import "HMDApplicationSession.h"
#import "HMDAsyncThread.h"
#import "HMDSessionTracker.h"
#import "hmd_thread_backtrace.h"
#import "HMDAsyncImageList.h"
#import "HMDCompactUnwind.hpp"
#import "hmd_thread_backtrace.h"
#import "HMDGCD.h"
#import "hmd_apple_backtrace_log.h"
#import "HMDCPUUtilties.h"
#import "HMDFlameGraphInfo.h"
#import "HMDMainRunloopMonitorV2.h"

#ifdef DEBUG
#define DEBUG_OC_LOG(format, ...) NSLog(format, ##__VA_ARGS__);
#define DEBUG_C_LOG(format, ...) printf("[%f]" format "\n", HMD_XNUSystemCall_timeSince1970(), ##__VA_ARGS__);
#else
#define DEBUG_OC_LOG(format, ...)
#define DEBUG_C_LOG(format, ...)
#endif

#ifdef DEBUG
#define DEBUG_TIMESTAMP(x) NSTimeInterval t##x = HMD_XNUSystemCall_timeSince1970();
#else
#define DEBUG_TIMESTAMP(x)
#endif

#define DEFAULT_ANR_MAX_MAIN_THREAD_COUNT 500

struct HMDANRBacktraceHistoryInfo {
    unsigned long topAppAddr = 0; // 主线程堆栈顶部自身堆栈地址
    NSTimeInterval timestamp = 0; // 最近一次发生时间
    NSTimeInterval occurInterval = MAXFLOAT; // 最近一次发生与上一次的间隔，默认值为MAXFLOAT
    NSUInteger times = 0; // 发生次数
};

typedef NS_ENUM(NSUInteger, HMDRunloopMonitorVersion) {
    HMDRunloopMonitorVersion1,
    HMDRunloopMonitorVersion2,
};

// Notification
NSString *const HMDANRTimeoutNotification = @"HMDANRTimeoutNotification";
NSString *const HMDANROverNotification = @"HMDANROverNotification";

// 默认值
NSTimeInterval HMDANRDefaultTimeoutInterval = 0.3; // 默认卡顿超时阈值300ms
NSTimeInterval HMDANRDefaultSampleInterval = 0.1; // 默认采样间隔100ms
NSTimeInterval HMDANRDefaultSampleTimeoutInterval = 0.15; // 默认采样模式阈值卡顿150ms
BOOL HMDANRDefaultSuspend = NO; // 默认抓取全线程堆栈时不suspend
BOOL HMDANRDefaultIgnoreBacktrace = NO; // 常规模式下忽略上报堆栈
NSTimeInterval HMDANRDefaultLaunchInterval = 5.0; // 启动阶段判定阈值，默认5s
#ifdef DEBUG
BOOL HMDANRDefaultEnableSample = YES; // 默认不开启采样开关
BOOL HMDANRDefaultIgnoreBackground = YES; // 默认忽略后台卡顿采集
BOOL HMDANRDefaultIgnoreDuplicate = YES; // 默认忽略重复
#else
BOOL HMDANRDefaultEnableSample = NO; // 默认不开启采样开关
BOOL HMDANRDefaultIgnoreBackground = NO; // 默认不忽略后台卡顿采集
BOOL HMDANRDefaultIgnoreDuplicate = NO; // 默认不忽略重复
#endif

// 配置限定值
static NSTimeInterval const kSampleInvervalMin = 0.05; // 最小采样间隔50ms
static NSTimeInterval const kSampleIncrease = 1.2; // 采样间隔退火算法递增参数
static const NSUInteger kSampleMinSimilarBacktraceCount = 2; // 采样超时命中时相似堆栈重复的最小次数
static NSTimeInterval const kSampleTimeoutIntervalMin = 0.1; // 最小采样超时阈值100ms
static NSTimeInterval const kTimeoutIntervalMin = 0.1; // 最小超时100ms
static const NSTimeInterval kRecentBacktraceInterval = 60; // 最近卡顿堆栈判定阈值，1min
#define HISTORY_BACKTRACE_SIZE (10)

// 配置
static NSTimeInterval gTimeoutInterval = 0; // 超时阈值
static NSTimeInterval gSampleInterval = 0; // 采样间隔
static NSTimeInterval gSampleTimeoutInterval = 0; // 采样超时阈值
static NSTimeInterval gLaunchThreshold = 0; // 启动时间阈值
static BOOL gSuspend = NO;
static BOOL gEnableSample = NO; // 采样开关
static BOOL gIgnoreBackground = NO; // 忽略后台
static BOOL gIgnoreDuplicate = NO; // 忽略重复
static BOOL gIgnoreBacktrace = NO; // 忽略堆栈
static int gMaxContinuousReportTimes = 0;
static BOOL gEnableRunloopMonitorV2 = NO;
static NSUInteger gRunloopMonitorThreadSleepInterval = 0;

// 成员变量
static hmdbt_backtrace_t *gNormalTimeoutBT = NULL; // 常规超时抓取的堆栈
static uint64_t gANRTime = 0; //卡顿时候的时间戳，与慢函数关联
static int gNormalTimeoutBTLength = 0; // 常规超时抓取的堆栈长度
static NSTimeInterval gLastSampleDuration = 0; // 上一次采样时间
static NSTimeInterval gSimilarBacktraceDuration = 0; // 连续相似堆栈的持续时间
static NSUInteger gSimilarBacktraceCount = 0; // 连续相似堆栈次数
static unsigned long gLastSampleMainTopAppAddr = 0; // 上一次采样周期采集的主线程堆栈最顶层的应用自身调用栈地址
static hmdbt_backtrace_t *gSampleTimeoutBT = 0; // 通过采样策略命中的卡顿堆栈
static int gSampleTimeoutBTLength = 0; // 通过采样策略命中的卡顿堆栈长度
static BOOL gBlockFlag = NO;
static HMDANRBacktraceHistoryInfo *gHistoryReportInfoList[HISTORY_BACKTRACE_SIZE] = {0}; // 本次启动上报的卡顿主线堆栈信息
static int gHistoryInfoCount = 0;
static NSTimeInterval gLaunchTS = 0;
static BOOL gIsUITrackingRunloopMode = NO;
static dispatch_queue_t gSerialQueue;
static dispatch_queue_t gNotificationQueue;
static const NSTimeInterval gIntervalDivider = 4.0;
static std::vector<hmdbt_backtrace_t*> dataVec; // access in runloop queue

static HMDRunloopMonitorVersion gRunloopMonitorVersion;

@implementation HMDANRMonitorInfo
@end

@implementation HMDANRMonitor

+ (instancetype)sharedInstance {
    static HMDANRMonitor *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDANRMonitor alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        gSerialQueue = dispatch_queue_create("com.heimdallr.anr", DISPATCH_QUEUE_SERIAL);
        gNotificationQueue = dispatch_queue_create("com.heimdallr.anr.notification", DISPATCH_QUEUE_SERIAL);
        gLaunchTS = [HMDSessionTracker currentSession].timestamp;
        gTimeoutInterval = HMDANRDefaultTimeoutInterval;
        gEnableSample = HMDANRDefaultEnableSample;
        gSampleInterval = HMDANRDefaultSampleInterval;
        gSampleTimeoutInterval = HMDANRDefaultSampleTimeoutInterval;
        gIgnoreBackground = HMDANRDefaultIgnoreBackground;
        gIgnoreDuplicate = HMDANRDefaultIgnoreDuplicate;
        gSuspend = HMDANRDefaultSuspend;
        gIsUITrackingRunloopMode = NO;
        clear();
    }
    return self;
}

#pragma mark - Property

- (NSTimeInterval)timeoutInterval {
    return gTimeoutInterval;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    if (timeoutInterval < kTimeoutIntervalMin) {
        timeoutInterval = kTimeoutIntervalMin;
    }
    
    gTimeoutInterval = timeoutInterval;
}

- (BOOL)enableSample {
    return gEnableSample;
}

- (void)setEnableSample:(BOOL)enableSample {
#ifdef DEBUG
    // DEBUG模式下强制关闭采样模式
    gEnableSample = YES;
#else
    gEnableSample = enableSample;
#endif
}

- (NSTimeInterval)sampleInterval {
    return gSampleInterval;
}

- (void)setSampleInterval:(NSTimeInterval)sampleInterval {
    if (sampleInterval < kSampleInvervalMin) {
        sampleInterval = kSampleInvervalMin;
    }
    
    gSampleInterval = sampleInterval;
}

- (NSTimeInterval)sampleTimeoutInterval {
    return gSampleTimeoutInterval;
}

- (void)setSampleTimeoutInterval:(NSTimeInterval)sampleTimeoutInterval {
    if (sampleTimeoutInterval < kSampleTimeoutIntervalMin) {
        sampleTimeoutInterval = kSampleTimeoutIntervalMin;
    }
    
    gSampleTimeoutInterval = sampleTimeoutInterval;
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

- (BOOL)ignoreDuplicate {
    return gIgnoreDuplicate;
}

- (void)setIgnoreDuplicate:(BOOL)ignoreDuplicate {
    gIgnoreDuplicate = ignoreDuplicate;
}

- (BOOL)ignoreBacktrace {
    return gIgnoreBacktrace;
}

- (void)setIgnoreBacktrace:(BOOL)ignoreBacktrace {
    gIgnoreBacktrace = ignoreBacktrace;
}

- (NSTimeInterval)launchThreshold {
    return gLaunchThreshold;
}

- (void)setLaunchThreshold:(NSTimeInterval)launchThreshold {
    gLaunchThreshold = launchThreshold;
}

- (int)maxContinuousReportTimes {
    return gMaxContinuousReportTimes;
}

- (void)setMaxContinuousReportTimes:(int)MaxContinuousReportTimes {
    gMaxContinuousReportTimes = MaxContinuousReportTimes;
}

- (BOOL)enableRunloopMonitorV2 {
    return gEnableRunloopMonitorV2;
}

- (void)setEnableRunloopMonitorV2:(BOOL)enableRunloopMonitorV2 {
    gEnableRunloopMonitorV2 = enableRunloopMonitorV2;
}

- (NSUInteger)runloopMonitorThreadSleepInterval {
    return gRunloopMonitorThreadSleepInterval;
}

- (void)setRunloopMonitorThreadSleepInterval:(NSUInteger)runloopMonitorThreadSleepInterval {
    if (runloopMonitorThreadSleepInterval >= 32 && runloopMonitorThreadSleepInterval <= 1000) {
        gRunloopMonitorThreadSleepInterval = runloopMonitorThreadSleepInterval;
    }else {
        gRunloopMonitorThreadSleepInterval = 50;
    }
}

#pragma mark - Monitor

- (void)start {
    dispatch_async(gSerialQueue, ^{
        hmd_setup_log_header();
        hmdthread_test_queue_name_offset();
        hmd_setup_shared_image_list();
        if (gEnableRunloopMonitorV2) {
            HMDMainRunloopMonitorV2::getInstance()->addObserver(monitorCallback);
            HMDMainRunloopMonitorV2::getInstance()->updateMonitorThreadSleepInterval(uint(gRunloopMonitorThreadSleepInterval));
            gRunloopMonitorVersion = HMDRunloopMonitorVersion2;
        }else {
            HMDMainRunloopMonitor::getInstance()->addObserver(monitorCallback);
            gRunloopMonitorVersion = HMDRunloopMonitorVersion1;
        }
        DEBUG_C_LOG("ANR START");
    });
}

- (void)stop {
    dispatch_async(gSerialQueue, ^{
        if (gRunloopMonitorVersion == HMDRunloopMonitorVersion1) {
            HMDMainRunloopMonitor::getInstance()->removeObserver(monitorCallback);
        }else {
            HMDMainRunloopMonitorV2::getInstance()->removeObserver(monitorCallback);
        }
        
        DEBUG_C_LOG("ANR STOP");
    });
}

static NSTimeInterval monitorCallback(struct HMDRunloopMonitorInfo *info) {
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
            clearBacktrace();
            return -1;
            break;
        }
    }
}

/*
 * RunloopBegin回调
 * 处理进入Runloop监听时的首次等待时间点请求
 */
static NSTimeInterval timeoutBegin(struct HMDRunloopMonitorInfo *info) {
    // 后台过滤
    if (backgroundFilter(info)) {
        clearBacktrace();
        return -1;
    }

    // 采样模式
    if (gEnableSample && (kSampleMinSimilarBacktraceCount * gSampleInterval + kHMDMinRunloopInterval) < gTimeoutInterval) {
        return gSampleInterval;
    }
    // 常规模式
    else {
        // 等待时间进行分段
        return gTimeoutInterval/gIntervalDivider;
    }
}

/*
 * RunloopDuration回调
 * 采样 & 超时逻辑
 */
static bool triggerNormalCapture = NO;
static NSTimeInterval lastSampleDuration;

static NSTimeInterval timeoutDuration(struct HMDRunloopMonitorInfo *info) {
    if(isANRNeedPause(info->begin)) {
        return -1;
    }
    // 采样模式
    if (gEnableSample) {
        // gBlockFlag mark whether the capture has been exec
        if(triggerNormalCapture && gBlockFlag == NO && info->duration + kHMDMilliSecond >= gTimeoutInterval) {
            normalTimeoutCapture(info); // will set gBlockFlag to be yes
            return lastSampleDuration + gSampleInterval;
        }

        unsigned long addr = sampleMainThread();
        lastSampleDuration = info->duration;
        if(gBlockFlag == NO) {
            triggerNormalCapture = sample(info, addr);
            triggerNormalCapture = triggerNormalCapture && (info->duration + gSampleInterval + kHMDMinRunloopInterval > gTimeoutInterval);
            if(triggerNormalCapture) {
                return gTimeoutInterval;
            }
        }

        return info->duration + gSampleInterval;
    }
    // 常规模式
    else {
        if (info->duration + kHMDMilliSecond >= gTimeoutInterval) {
            normalTimeoutCapture(info);
            return -1;
        }
        else {
            return MIN(info->duration + gTimeoutInterval/gIntervalDivider, gTimeoutInterval);
        }
    }
}

/*
* RunloopOver回调
* 上报逻辑
*/
static  NSTimeInterval timeoutOver(struct HMDRunloopMonitorInfo *info) {
    report(info);
    clear();
    return -1;
}

#pragma mark - Support

static void clear(void) {
    clearBacktrace();
    gBlockFlag = NO;
    triggerNormalCapture = NO;
}

static void clearBacktrace(void) {
    if(dataVec.size()) {
        for(auto bt: dataVec) {
            hmdbt_dealloc_bactrace(&bt, 1);
        }
        dataVec.clear();
    }
    
    if (gNormalTimeoutBT != NULL) {
        hmdbt_dealloc_bactrace(&gNormalTimeoutBT, gNormalTimeoutBTLength);
    }
    
    if (gSampleTimeoutBT != NULL) {
        hmdbt_dealloc_bactrace(&gSampleTimeoutBT, gSampleTimeoutBTLength);
    }
    
    gNormalTimeoutBTLength = 0;
    gSampleTimeoutBTLength = 0;
    gLastSampleMainTopAppAddr = 0;
    gLastSampleDuration = 0;
    gSimilarBacktraceDuration = 0;
    gSimilarBacktraceCount = 0;
}

static time_value_t cur_wall_time_v1(void) {
    /*
    ** Monotonic timer on Mac OS is provided by mach_absolute_time(), which
    ** returns time in Mach "absolute time units," which are platform-dependent.
    ** To convert to nanoseconds, one must use conversion factors specified by
    ** mach_timebase_info().
    */
    static mach_timebase_info_data_t timebase;
    if (0 == timebase.denom) {
        mach_timebase_info(&timebase);
    }

    uint64_t usecs = mach_absolute_time();
    usecs *= timebase.numer;
    usecs /= timebase.denom;
    usecs /= 1000;

    time_value_t tnow = {0, 0};
    tnow.seconds = (int)(usecs / 1000000);
    tnow.microseconds = (int)(usecs % 1000000);

    return tnow;
}

static time_value_t cur_wall_time(void) {
    struct timespec ts = {0, 0};
    if (@available(iOS 10.0, *)) {
        clock_gettime(CLOCK_REALTIME, &ts);
        time_value_t result = {static_cast<integer_t>(ts.tv_sec), static_cast<integer_t>(ts.tv_nsec / 1000)};
        return result;
    } else {
        return cur_wall_time_v1();
    }
}

static void normalTimeoutCapture(struct HMDRunloopMonitorInfo *info) {
    gBlockFlag = YES;
    notificationTimeout(info, false);
    if (gIgnoreBacktrace) {
        return;
    }
    
    if (gSampleTimeoutBT != NULL || gNormalTimeoutBT != NULL) {
        return;
    }
    
    if (backgroundFilter(info)) {
        return;
    }

    updateRunloopMode();
    time_value_t ts = cur_wall_time();
    gANRTime = ts.seconds;
    gANRTime = gANRTime * 1000 + ts.microseconds/1000;
    gNormalTimeoutBT = hmdbt_origin_backtraces_of_all_threads(&gNormalTimeoutBTLength, 0, gSuspend, HMDBT_MAX_THREADS_COUNT);
    HMDPrint("ANR⚠️ ANR timeout in normal mode [%dms/%dms]", (int)(1000*info->duration), (int)(1000*(HMD_XNUSystemCall_timeSince1970()-info->begin)));
}

static unsigned long sampleMainThread() {
    hmdbt_backtrace_t *bt  = hmdbt_fast_backtrace_of_main_thread(0, gSuspend);
    unsigned long addr = 0;
    if(bt && dataVec.size() < DEFAULT_ANR_MAX_MAIN_THREAD_COUNT) {
        dataVec.emplace_back(bt);
        addr = topAppAddr(bt, 0);
    }
    return addr;
}

static BOOL sample(struct HMDRunloopMonitorInfo *info, unsigned long addr) {
    if (addr != 0 && addr == gLastSampleMainTopAppAddr) {
        gLastSampleMainTopAppAddr = addr;
        gSimilarBacktraceDuration += (info->duration - gLastSampleDuration);
        gSimilarBacktraceCount++;
        gLastSampleDuration = info->duration;
        if (gSimilarBacktraceDuration >= gSampleTimeoutInterval && gSimilarBacktraceCount >= kSampleMinSimilarBacktraceCount) {
            // 查看是否去重，此处不更新历史数据，历史数据仅在上报时更新
            if (checkDuplicate(addr,NO) == NULL) {
                updateRunloopMode();
                gSampleTimeoutBT = hmdbt_origin_backtraces_of_all_threads(&gSampleTimeoutBTLength, 0, gSuspend, HMDBT_MAX_THREADS_COUNT);
                DEBUG_C_LOG("ANR⚠️ Sample hitting [%dms]，address [0x%lx]", (int)(1000*info->duration), gLastSampleMainTopAppAddr);
            }
            // 命中去重策略，清空采样数据
            else {
                clearBacktrace();
            }
            
            gBlockFlag = YES;
            notificationTimeout(info, true);
            return NO;
        }
    }
    else {
        gLastSampleMainTopAppAddr = addr;
        gSimilarBacktraceDuration = (info->duration - gLastSampleDuration) * 0.5;
        gSimilarBacktraceCount = 1;
        gLastSampleDuration = info->duration;
    }

    return YES;
}

static unsigned long topAppAddr(hmdbt_backtrace_t *bt, int skipBottom) {
    unsigned long topAppAddress = 0;
    // 去重时处于底层的5层堆栈不作为查找范围
    // 判断顶部app时无需跳过底部堆栈
    if (bt->frames != NULL && bt->frame_count > skipBottom) {
        hmd_async_image_list_set_reading(&shared_app_image_list, true);
        for (int i=0; i<(((int)bt->frame_count) - skipBottom); i++) {
            unsigned long address = bt->frames[i].address;
            if (hmd_async_image_containing_address(&shared_app_image_list, address)) {
                topAppAddress = address;
                break;
            }
        }
        hmd_async_image_list_set_reading(&shared_app_image_list, false);
    }

    return topAppAddress;
}

static BOOL backgroundFilter(struct HMDRunloopMonitorInfo *info) {
    if (!gIgnoreBackground) {
        return NO;
    }

    if (info != NULL && info->background) {
        return YES;
    }
    else if(HMDApplicationSession_backgroundState()) {
        return YES;
    }
    else {
        return NO;
    }
}

static void report(struct HMDRunloopMonitorInfo *info) {
    if (gBlockFlag) {
        // 通知卡顿结束
        notificationOver(info, (gSampleTimeoutBT != NULL));
    }
    
    if (backgroundFilter(info)) {
        return;
    }

    hmdbt_backtrace_t *reportBT = NULL;
    int reportBTLength = 0;
    BOOL sampleFlag = NO;
    
    if (gSampleTimeoutBT != NULL) {
        reportBT = gSampleTimeoutBT; // 指针转移至backtraces
        reportBTLength = gSampleTimeoutBTLength;
        gSampleTimeoutBT = NULL;
        gSampleTimeoutBTLength = 0;
        sampleFlag = YES;
    }
    else if(gNormalTimeoutBT != NULL) {
        reportBT = gNormalTimeoutBT;
        reportBTLength = gNormalTimeoutBTLength;
        gNormalTimeoutBT = NULL;
        gNormalTimeoutBTLength = 0;
        sampleFlag = NO;
    }

    if (reportBT == NULL || reportBTLength <= 0) {
        return;
    }
    
    __block std::vector<hmdbt_backtrace_t *> mainBacktraces(dataVec);
    dataVec.clear();
    // 去重
    if (gIgnoreDuplicate) {
        hmdbt_backtrace_t *mainBT = &(reportBT[0]);
        unsigned long currentTopAppAddr = topAppAddr(mainBT, 5);
        // 没有自身堆栈可能是抓栈失败，也可能是本身就是没有自身调用
        if (currentTopAppAddr != 0) {
            HMDANRBacktraceHistoryInfo *duplicateBTInfo = checkDuplicate(currentTopAppAddr, YES);
            // 有重复，不进行上报
            if (duplicateBTInfo != NULL) {

                DEBUG_C_LOG("ANR⚠️ Repetitive stacks [0x%lx]. No reporting!", duplicateBTInfo->topAppAddr);
                // 退火
                if (gEnableSample && duplicateBTInfo->occurInterval > 0 && duplicateBTInfo->occurInterval <= kRecentBacktraceInterval) {
                    gSampleInterval = gSampleInterval * kSampleIncrease;
                    if (gSampleInterval * kSampleMinSimilarBacktraceCount >= gTimeoutInterval) {
                        gEnableSample = NO;
                    }
                }
                
                hmdbt_dealloc_bactrace(&reportBT, reportBTLength);
                return;
            }
        }
    }

    // 上报
    NSTimeInterval timestamp = HMD_XNUSystemCall_timeSince1970();
    NSTimeInterval duration = info->duration;
    BOOL isLaunch = (info->begin - gLaunchTS) < gLaunchThreshold;
    BOOL isBackground = info->background;
    BOOL isUITrackingMode = gIsUITrackingRunloopMode;
    uint64_t anrTime = gANRTime;
    double main_thread_cpu_usage = hmdCPUUsageFromSingleThread((thread_t)hmdbt_main_thread);
    recordContinuousReport(timestamp);
    hmd_safe_dispatch_async(gSerialQueue, ^{
        hmdbt_backtrace_t *currentBT = reportBT;
        // 异步线程后获取后台状态，否则阻塞状态的主线程无法发送前后台切换通知
        if (backgroundFilter(NULL)) {
            hmdbt_dealloc_bactrace(&currentBT, reportBTLength);
            return;
        }

        // 使用C方法的符号化
        char *stacklog_c = hmd_apple_backtraces_log_of_threads(currentBT, reportBTLength, (thread_t)hmdbt_main_thread, HMDLogANR, NULL, NULL, true);
        NSString *stackLog = [NSString stringWithUTF8String:stacklog_c];
        if(stacklog_c != NULL) {
            free(stacklog_c);
            stacklog_c = NULL;
        }
        hmdbt_dealloc_bactrace(&currentBT, reportBTLength);
        HMDANRMonitorInfo *reportInfo = [[HMDANRMonitorInfo alloc] init];
        reportInfo.anrTime = anrTime;
        reportInfo.timestamp = timestamp;
        reportInfo.sampleFlag = sampleFlag;
        reportInfo.duration = duration;
        reportInfo.inAppTime = timestamp - gLaunchTS;
        reportInfo.isLaunch = isLaunch;
        reportInfo.background = isBackground;
        reportInfo.stackLog = stackLog;
        reportInfo.isUITrackingRunloopMode = isUITrackingMode;
        reportInfo.mainThreadCPUUsage = main_thread_cpu_usage;
        HMDFlameGraphInfo *info = [[HMDFlameGraphInfo alloc] initWithBacktraces:mainBacktraces];
        reportInfo.flameGraph = info.reportArray;
        reportInfo.binaryImages = info.reportImages;
        id delegate = [HMDANRMonitor sharedInstance].delegate;
        [delegate didBlockWithInfo:reportInfo];
    });
}

static void updateRunloopMode() {
    gIsUITrackingRunloopMode = HMDMainRunloopMonitor::getInstance()->isUITrackingRunloopMode();
}

static void notificationTimeout(struct HMDRunloopMonitorInfo *info, bool sampleFlag) {
    NSTimeInterval ts = HMD_XNUSystemCall_timeSince1970();

    NSTimeInterval begin = info->begin;
    NSTimeInterval duration = info->duration;
    BOOL isBackground = info->background;
    BOOL isUITrackingMode = gIsUITrackingRunloopMode;

    dispatch_async(gNotificationQueue, ^{
        HMDANRMonitorInfo *object = [[HMDANRMonitorInfo alloc] init];
        object.timestamp = ts;
        object.duration = duration;
        object.background = isBackground;
        object.inAppTime = ts - gLaunchTS;
        object.isLaunch = (begin - gLaunchTS) < gLaunchThreshold;
        object.isUITrackingRunloopMode = isUITrackingMode;
        object.sampleFlag = sampleFlag;
        [[NSNotificationCenter defaultCenter] postNotificationName:HMDANRTimeoutNotification
                                                            object:object
                                                          userInfo:nil];
    });
}

static void notificationOver(struct HMDRunloopMonitorInfo *info, bool sampleFlag) {
    NSTimeInterval ts = HMD_XNUSystemCall_timeSince1970();
    NSTimeInterval begin = info->begin;
    NSTimeInterval duration = info->duration;
    BOOL isBackground = info->background;
    BOOL isUITrackingMode = gIsUITrackingRunloopMode;

    dispatch_async(gNotificationQueue, ^{
        HMDANRMonitorInfo *object = [[HMDANRMonitorInfo alloc] init];
        object.timestamp = ts;
        object.duration = duration;
        object.background = isBackground;
        object.inAppTime = ts - gLaunchTS;
        object.isLaunch = (begin - gLaunchTS) < gLaunchThreshold;
        object.isUITrackingRunloopMode = isUITrackingMode;
        object.sampleFlag = sampleFlag;
        [[NSNotificationCenter defaultCenter] postNotificationName:HMDANROverNotification
                                                            object:object
                                                          userInfo:nil];
    });
}

static HMDANRBacktraceHistoryInfo *checkDuplicate(unsigned long addr, BOOL updateHistory) {
    if (!gIgnoreDuplicate || addr == 0) {
        return NULL;
    }

    NSTimeInterval currentTS = HMD_XNUSystemCall_timeSince1970();
    // 查重，从最近发生的开始遍历
    for (int i=(gHistoryInfoCount-1); i>=0; i--) {
        HMDANRBacktraceHistoryInfo *info = gHistoryReportInfoList[i];
        if (info->topAppAddr == addr) {
            if (updateHistory) {
                info->times++;
                info->occurInterval = currentTS - info->timestamp;
                info->timestamp = currentTS;
                // 冒泡，当前info移动至末尾
                for (int j=i; j<(gHistoryInfoCount-1); j++) {
                    HMDANRBacktraceHistoryInfo *temp = gHistoryReportInfoList[j];
                    gHistoryReportInfoList[j] = gHistoryReportInfoList[j+1];
                    gHistoryReportInfoList[j+1] = temp;
                }
            }

            return info;
        }
    }

    if (!updateHistory) {
        return NULL;
    }

    // 更新历史记录
    if (gHistoryInfoCount >= HISTORY_BACKTRACE_SIZE) {
        HMDANRBacktraceHistoryInfo *temp = gHistoryReportInfoList[0];
        gHistoryReportInfoList[0] = NULL;
        free(temp);
        for (int i=1; i<gHistoryInfoCount; i++) {
            gHistoryReportInfoList[i-1] = gHistoryReportInfoList[i];
        }
        gHistoryReportInfoList[gHistoryInfoCount-1] = NULL;
        gHistoryInfoCount--;
    }

    HMDANRBacktraceHistoryInfo *currentInfo = (HMDANRBacktraceHistoryInfo *)malloc(sizeof(HMDANRBacktraceHistoryInfo));
    if (currentInfo != NULL) {
        currentInfo->topAppAddr = addr;
        currentInfo->timestamp = currentTS;
        currentInfo->times = 1;
        currentInfo->occurInterval = MAXFLOAT;
        gHistoryReportInfoList[gHistoryInfoCount] = currentInfo;
        gHistoryInfoCount++;
    }
    
    return NULL;
}

#define HMD_ANR_CONTINUOUS_REPORT_TIME_INTERVAL 10
static NSTimeInterval anr_wakeup_time = 0;
static void recordContinuousReport(NSTimeInterval currentTime) {
    static NSTimeInterval lastReportTime;
    static int continuous_report_times;
    static const NSTimeInterval delay_time_unit = 120.f; //120s
    static int abnormal_report_times;
    
    if (gMaxContinuousReportTimes == 0) return;
    
    if (currentTime - lastReportTime < HMD_ANR_CONTINUOUS_REPORT_TIME_INTERVAL)
        continuous_report_times++;
    else
        continuous_report_times = 0;
    
    lastReportTime = currentTime;
    
    if (continuous_report_times >= gMaxContinuousReportTimes) {
        //A lot of ANR were reported in a short period of time, so it need to pause for a while
        abnormal_report_times++;
        continuous_report_times = 0;
        anr_wakeup_time = currentTime + abnormal_report_times*delay_time_unit;
    }
    
}

static BOOL isANRNeedPause(NSTimeInterval currentTime) {
    if (gMaxContinuousReportTimes == 0) return NO;
    
    if (currentTime >= anr_wakeup_time) return NO;
    
    return YES;
}

@end
