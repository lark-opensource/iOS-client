//
//  HMDCPUExceptionMonitor.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/4/23.
//

#import "HMDCPUExceptionMonitor.h"
#import "HMDCPUExceptionCycleDataCollector.h"
#import "HMDCPUExceptionSampleInfo.h"
#import "HMDCPUExceptionMonitor+Reporter.h"
#import "HMDCPUExceptionMonitor+Private.h"
#import "HMDCPUExceptionThermalMonitor.h"
#import "HMDCPUExceptionRecordManager.h"
#import "HMDCPUExceptionV2Record.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDCPUExceptionPerf.h"
#import "HMDThreadBacktrace.h"
#import "Heimdallr+Private.h"
#import <mach/kern_return.h>
#import "HMDCPUThreadInfo.h"
#import "hmd_symbolicator.h"
#import "NSArray+HMDSafe.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import <mach/port.h>
#import <mach/mach.h>
#import "HMDMacro.h"
#import "HMDGCD.h"
#include "HMDAsyncThread.h"
#include "HMDCPUUtilties.h"
#include <sys/time.h>
#import "HMDHermasHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"

static long long hmd_cpu_sample_cycle_start_time = 0;
static long long hmd_cpu_theraml_exception_start_time = 0;
static long long hmd_last_sample_time = 0;

/// 触发类型
typedef NS_ENUM(NSUInteger, HMDCPUExceptionMonitorExecType) {
    HMDCPUExceptionMonitorExecNormal,
    HMDCPUExceptionMonitorExecCloudCommand,
};

#pragma mark
#pragma mark---------- HMDCPUExceptionMonitor -----------
@interface HMDCPUExceptionMonitor ()<HMDCPUExceptionRecordManagerDelegate, HMDCPUExceptionThermalMonitorDelegate>

/// - config
@property (nonatomic, assign) NSInteger sampleInterval;
@property (nonatomic, strong) HMDCPUExceptionConfig *currentConfig;
@property (nonatomic, strong) HMDCPUExceptionConfig *customConfig;
@property (nonatomic, assign) float powerConsumptionThreshold;
/// - collect exception operation
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@property (nonatomic, strong) dispatch_source_t sampleTimer;
@property (nonatomic, strong) HMDCPUExceptionCycleDataCollector *cycleDataPool;
@property (nonatomic, assign) HMDCPUExceptionMonitorExecType monitorType;
@property (nonatomic, strong) HMDCPUExceptionThermalMonitor *thermalMonitor;
@property (nonatomic, copy) void (^cloudCommandCompletion)(NSDictionary *dict, BOOL success);
@property (nonatomic, assign) BOOL isTheramlSerious;
@property (nonatomic, assign) BOOL isTheramlTracking;
@property (nonatomic, assign) float powerConsumption;
/// record management
@property (nonatomic, assign) BOOL readFromDB;
@property (nonatomic, strong) HMDCPUExceptionRecordManager *recordManager;
/// TTMonitor
@property (nonatomic, strong) HMDCPUExceptionPerf *perfWatch;
/// custom scene
@property (nonatomic, strong) NSMutableArray *customScenes;
@property (nonatomic, copy) NSString *customSceneStr;

@end

@implementation HMDCPUExceptionMonitor

#pragma mark--- super implement
+ (instancetype)sharedMonitor {
    static HMDCPUExceptionMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDCPUExceptionMonitor alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}

- (void)setupData {
    self.sampleInterval = 1;
    self.powerConsumption = 0;
    self.operationQueue = dispatch_queue_create("com.heimdallr.cpuexception.monitor", DISPATCH_QUEUE_SERIAL);
    self.recordManager = [[HMDCPUExceptionRecordManager alloc] init];
    self.recordManager.delegate = self;
    self.monitorType = HMDCPUExceptionMonitorExecNormal;
    self.perfWatch = [[HMDCPUExceptionPerf alloc] init];
    self.customScenes = [NSMutableArray array];
}

- (void)start {
    [super start];
    hmd_safe_dispatch_async(self.operationQueue, ^{
        [self monitorStartAction];
    });
    [HMDDebugLogger printLog:@"CPUException-Monitor start successfully!"];
}

- (void)monitorStartAction {
    [self startCPUStatusMonitoring];
    
    if (!hermas_enabled()) {
        [self reportLocalStoredRecord];
    }
    
    [self checkThermalMonitorState];
}

- (void)stop {
    [super stop];
    hmd_safe_dispatch_async(self.operationQueue, ^{
        [self monitorStopAction];
    });
}

- (void)monitorStopAction {
    [self stopCPUStatusMonitoring];
    [self switchTheramlMonitorState:NO];
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDCPUExceptionV2Record class];
}

- (BOOL)needSyncStart {
    return NO;
}

- (BOOL)performanceDataSource {
    return NO;
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (HMDExceptionType)exceptionType {
    return HMDCPUExceptionType;
}

#pragma mark--- public method ---
// 进入用户的特定场景, 使用特定的配置
- (void)enterSpecificalSceneWithExceptionConfig:(HMDCPUExceptionConfig *)config {
    if (!self.isRunning) { return; }
    hmd_safe_dispatch_async(self.operationQueue, ^{
        [self stopCPUStatusMonitoring];
        self.customConfig = config;
        [self dealCurrentConfig:config];
        [self startCPUStatusMonitoring];
    });
}

// 用户离开特定的场景, 回复使用 slardar 的配置
- (void)leaveSpecificalScene {
    if (!self.isRunning) { return; }
    hmd_safe_dispatch_async(self.operationQueue, ^{
        self.customConfig = nil;
        [self stopCPUStatusMonitoring];
        [self dealCurrentConfig:(HMDCPUExceptionConfig *) self.config];
        [self startCPUStatusMonitoring];
    });
}

- (void)enterCustomSceneWithUniq:(NSString *_Nonnull)scene {
    if(HMDIsEmptyString(scene)) {
        return ;
    }
    hmd_safe_dispatch_async(self.operationQueue, ^{
        NSString *lastScene = [self.customScenes lastObject];
        // 去重逻辑 如果传入的 scene 当前 栈顶的一个 scene 是重复的那么不传入;
        if (![lastScene isEqualToString:scene]) {
            [self.customScenes addObject:scene];
            self.customSceneStr = [self.customScenes componentsJoinedByString:@","];
        }
    });
}

- (void)leaveCustomSceneWithUniq:(NSString *_Nonnull)scene {
    if(HMDIsEmptyString(scene)) {
        return ;
    }
    hmd_safe_dispatch_async(self.operationQueue, ^{
        [self.customScenes removeObject:scene];
        if (self.customScenes.count == 0) {
            self.customSceneStr = nil;
        } else {
            self.customSceneStr = [self.customScenes componentsJoinedByString:@","];
        }
    });
}


#pragma mark --- private api ---
// 获取一个 CPU 循环内的异常信息
- (void)fetchCloudCommandCPUExceptionOneCycleInfoWithCompletion:(void (^)(NSDictionary * _Nullable, BOOL success))completion {
    if (!self.isRunning) {
        self.cloudCommandCompletion = completion;
        [self execMonitorWithCloudCommand];
    } else if (completion) {
        completion(nil, NO);
    }
}

#pragma mark --- config ---
- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
    hmd_safe_dispatch_async(self.operationQueue, ^{
        [self dealCurrentConfig:(HMDCPUExceptionConfig *)config];
    });
}

- (void)dealCurrentConfig:(HMDCPUExceptionConfig *)cpuConfig {
    if ([cpuConfig isKindOfClass:[HMDCPUExceptionConfig class]]) {
        self.currentConfig = cpuConfig;
        self.sampleInterval = MAX(cpuConfig.sampleInterval, 1);
        self.perfWatch.enablePerfWatch = cpuConfig.enablePerformaceCollect;
        self.powerConsumptionThreshold = MAX(cpuConfig.powerConsumptionThreshold, 60);
        [self checkThermalMonitorState];
    }
}

#pragma mark--- cpu usage sample ---
// start monite cpu usage
- (void)startCPUStatusMonitoring {
    if (!self.isRunning) { return; }
    // initialize monitor cycle data
    [self setupDataForCycleStart];
    if (self.sampleTimer) {
        dispatch_source_cancel(self.sampleTimer);
        self.sampleTimer = nil;
    }
    // timer
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.operationQueue);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, self.sampleInterval * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
    __weak typeof(self) wself = self;
    dispatch_source_set_event_handler(timer, ^{
        __strong typeof(wself) sself = wself;
        [sself collectCurrentUsageRate];
    });
    dispatch_resume(timer);
    self.sampleTimer = timer;
}

- (void)setupDataForCycleStart {
    HMDCPUExceptionCycleDataCollector *samplePool = [[HMDCPUExceptionCycleDataCollector alloc] init];
    samplePool.thresholdConfig = self.currentConfig.cpuThreshold;
    samplePool.maxTreeDepth = self.currentConfig.maxTreeDepth;

    self.cycleDataPool = samplePool;
    hmd_cpu_sample_cycle_start_time = 0;
}

- (void)stopCPUStatusMonitoring {
    if (self.sampleTimer) {
        dispatch_source_cancel(self.sampleTimer);
        self.sampleTimer = nil;
    }
    self.cycleDataPool.endTime = hmdCPUTimestamp();
    self.cycleDataPool.startTime = hmd_cpu_sample_cycle_start_time;
    self.isTheramlTracking = NO;
    self.powerConsumption = 0;
    hmd_cpu_sample_cycle_start_time = 0;
    hmd_last_sample_time = 0;
    hmd_cpu_theraml_exception_start_time = 0;
}

// collect cpu usage per sampleInterval seconds
- (void)collectCurrentUsageRate {
    // 添加CPU异常容灾逻辑
    BOOL needDropData = hermas_enabled() ? hermas_drop_data(kModuleExceptionName) : hmd_drop_data(HMDReporterException);
    if (needDropData) {
        return;
    }
    
    if (hmd_cpu_sample_cycle_start_time == 0) { // 尚未开启一轮采样
        if(hmdCPUUsageFromClock() >= self.currentConfig.cpuThreshold) {
            hmd_cpu_sample_cycle_start_time = hmdCPUTimestamp();
            hmd_last_sample_time = hmd_cpu_sample_cycle_start_time;
        }
        return ;
    }
        
    NSMutableArray<HMDCPUThreadInfo *> *consumThreadArray = [NSMutableArray array];
    mach_msg_type_number_t threadCount = 0;
    float maxThreadUsage = 0;

    // collect thread cpu usage rate
    long long collectStart = hmdCPUTimestamp();
    float cpuUsage = [self getCPUUsageFromThreadsWithConsumThreadArray:consumThreadArray allThreadCount:&threadCount maxThreadUsage:&maxThreadUsage];
    long long collectEnd = hmdCPUTimestamp();
    [self.perfWatch exceptionThreadTimeUsage:(collectEnd - collectStart)];
    
    long long currentTime = hmdCPUTimestamp();
    float sampleInterval = (currentTime - hmd_last_sample_time) / 1000.0;
    float sampleDuration = (currentTime - hmd_cpu_sample_cycle_start_time) / 1000.0;
    float totalConsumption = self.powerConsumption + cpuUsage * sampleInterval;
    float averageUsage = totalConsumption / sampleDuration;
    hmd_last_sample_time = currentTime;
    
    // 如果这段时间的 cpu使用率 小于阈值，开启下一轮采样
    if (averageUsage < self.currentConfig.cpuThreshold) {
        [self.cycleDataPool clearAllSampleInfo];
        hmd_cpu_sample_cycle_start_time = 0;
        hmd_last_sample_time = 0;
        self.powerConsumption = 0;
        return;
    } else {
        HMDCPUExceptionSampleInfo *currentInfo = [HMDCPUExceptionSampleInfo sampleInfo];
        currentInfo.customScene = self.customSceneStr;
        currentInfo.threadCount = (int)threadCount;
        NSUInteger processorCount = [[NSProcessInfo processInfo] processorCount];
        currentInfo.averageUsage = processorCount > 0 ? (cpuUsage / (float)processorCount) : cpuUsage;
        currentInfo.processorCount = processorCount;
        currentInfo.threadsInfo = [self backtraceWithThreads:consumThreadArray maxThreadUsage:maxThreadUsage];
        currentInfo.timestamp = hmdCPUTimestamp();
        
        self.powerConsumption = totalConsumption;
        [self.cycleDataPool pushOnceSampledInfo:currentInfo];
        
        if(self.powerConsumption >= self.powerConsumptionThreshold) {
            self.powerConsumption = 0;
            [self usageExceptionInCurrentCycle];
        }
    }
}

- (void)usageExceptionInCurrentCycle {
    [self stopCPUStatusMonitoring];  // stop sample timer
    [self productionExceptionRecord];
}

- (void)productionExceptionRecord {
    // make summary => exception record
    long long startTime = hmdCPUTimestamp();
    HMDCPUExceptionV2Record *record = [self.cycleDataPool makeSummaryInExceptionCycle];
    long long endTime = hmdCPUTimestamp();

    // record operation time consumption
    [self.perfWatch exceptionRecordPrepareWithTimeUsage:(endTime - startTime) infoSize:[record infoSize]];
    if (hmd_log_enable()) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr CPU Exception prepare exception time comsumption: %lld", endTime - startTime);
    }

    // normal report
    if (self.monitorType == HMDCPUExceptionMonitorExecNormal) {
        self.readFromDB = NO; //
        BOOL needUploadImmediately = [self checkNeedUploadExceptionDataImmediatelyWithCPUAverageUsage:record.averageUsage];
        [self.recordManager pushRecord:record needUploadImmediately:needUploadImmediately];
        [HMDDebugLogger printLog:@"Record CPUException log successfully!"];
        [self restartUsageMonitoringAfterSleep]; // sleep 2 min and restart sample timer
        return;
    }

    // cloud command report
    if (self.monitorType ==  HMDCPUExceptionMonitorExecCloudCommand) {
        NSDictionary *reporterDict = [record reportDictionary];
        [self finishMonitorWithCloudCommandWithResult:reporterDict];
        return;
    }
}

- (void)reportLocalStoredRecord {
    // 检查上次未来得及上报的数据
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), self.operationQueue, ^{
        self.readFromDB = YES;
        [self shouldReportCPUExceptionRecordNow];
    });
}

- (void)restartUsageMonitoringAfterSleep {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((120) * NSEC_PER_SEC)), self.operationQueue, ^{
        [self startCPUStatusMonitoring];
    });
}

#pragma mark --- theraml monitor ---
- (void)checkThermalMonitorState {
    [self switchTheramlMonitorState:self.currentConfig.enableThermalMonitor];
}

- (void)switchTheramlMonitorState:(BOOL)isOn {
    if (isOn && self.isRunning) {
        if (!self.thermalMonitor) {
            self.thermalMonitor = [[HMDCPUExceptionThermalMonitor alloc] init];
            self.thermalMonitor.delegate = self;
        }
        [self.thermalMonitor start];
    } else if(self.thermalMonitor) {
        [self.thermalMonitor stop];
    }
}

/// 0: default ; 1: Fair; 2: Serious; 3: Critical
- (void)currentTheramlStateAbormal:(HMDCPUExceptionTheramlState)thermalState {
    hmd_safe_dispatch_async(self.operationQueue, ^{
        self.isTheramlSerious = YES;
        hmd_cpu_theraml_exception_start_time = hmdCPUTimestamp();
    });
}

#pragma mark--- utility ---
- (void)currentTheramlStateBecomeNormal:(HMDCPUExceptionTheramlState)thermalState {
    hmd_safe_dispatch_async(self.operationQueue, ^{
        self.isTheramlSerious = NO;
        if (self.isTheramlTracking) {
            [self usageExceptionInCurrentCycle];
            self.isTheramlTracking = NO;
        }
    });
}

#pragma mark --- collect cpu and thread info ---

// collect threads backtrace info that out of thread's cpu usage rate threshold
- (NSArray *)backtraceWithThreads:(NSMutableArray<HMDCPUThreadInfo *> *)threads maxThreadUsage:(float)maxThreadUsage {
    long long startTime = hmdCPUTimestamp();

    NSMutableArray<HMDCPUThreadInfo *> *collectThreads = [NSMutableArray array];
    // found characteristic threads
    float minUsedUsage = maxThreadUsage * self.currentConfig.characterScale;
    for (HMDCPUThreadInfo *info in threads) {
        if (info.usage < minUsedUsage) { continue; }
        HMDThreadBacktrace *trace = [HMDThreadBacktrace backtraceOfThread:info.thread symbolicate:YES skippedDepth:0 suspend:self.currentConfig.threadSuspend];
        info.weight = info.usage / (self.currentConfig.threadUsageThreshold > 0 ? self.currentConfig.threadUsageThreshold : 1);
        info.backtrace = trace;
        if (trace == nil) { continue; }
        [collectThreads hmd_addObject:info];
    }

    long long endTime = hmdCPUTimestamp();
    // time-comsuming record
    [self.perfWatch threadBackTreeWithTimeUsage:(endTime - startTime) threadCount:threads.count suspendThread:self.currentConfig.threadSuspend];
    if (hmd_log_enable()) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Heimdallr CPU Exception BackTree ThreadCount: %ld, use time: %lld", threads.count, endTime - startTime);
    }
    return [collectThreads copy];
}

- (float)getCPUUsageFromThreadsWithConsumThreadArray:(NSMutableArray<HMDCPUThreadInfo *> *)threadInfoArray
                                      allThreadCount:(mach_msg_type_number_t *)threadCount
                                      maxThreadUsage:(float *)maxThreadUsage {
    thread_array_t threadList;
    thread_extended_info_t extendedInfoTh;

    float cpuUsage = 0;
    float consumUsageAll = 0;
    float curMaxThreadUsage = 0;
    //    unsigned short extra_thread_count = 0;

    // get threads in the task
    kern_return_t kr = task_threads(mach_task_self(), &threadList, threadCount);
    if (kr != KERN_SUCCESS) {
        return -1.0;
    }

    thread_info_data_t thinfo;
    mach_msg_type_number_t threadInfoCount;

    // for each thread
    for (int idx = 0; idx < (int) (*threadCount); idx++) {
        thread_t currentThread = threadList[idx];
        threadInfoCount = THREAD_INFO_MAX;
        kr = thread_info(currentThread, THREAD_EXTENDED_INFO, (thread_info_t) thinfo, &threadInfoCount);
        if (kr != KERN_SUCCESS) {
            return -1.0;
        }

        float currentUsage = 0;
        extendedInfoTh = (thread_extended_info_t) thinfo;
        if (!(extendedInfoTh->pth_flags & TH_FLAGS_IDLE)) {
            currentUsage = ((float)extendedInfoTh->pth_cpu_usage) / ((float) TH_USAGE_SCALE);
            cpuUsage += currentUsage;
            if (currentThread == (thread_t) hmdthread_self()) {
                if ((currentUsage > self.currentConfig.threadUsageThreshold)) {
                    [self.perfWatch monitorThreadCPUUsgeOutOfThreshold:currentUsage];
                    // 当前的 CPU 异常监控线程使用率过高的时候, 没办法上报 打一个 alog
                    if (hmd_log_enable()) {
                        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"HMDCPUException thread use cpu out of theshold: %lf", currentUsage);
                    }
                }
                continue;
            }
        }
        // 采样线程的两个条件
        // 1. 当前的线程 CPU 使用率大于设定的阈值 (默认 0.05)
        if ((currentUsage > self.currentConfig.threadUsageThreshold) && currentUsage > 0) {
            if (currentUsage > curMaxThreadUsage) {
                curMaxThreadUsage = currentUsage;
            }

            HMDCPUThreadInfo *threadInfo = [[HMDCPUThreadInfo alloc] init];
            threadInfo.thread = currentThread;
            threadInfo.usage = currentUsage;
            threadInfo.priority = extendedInfoTh->pth_priority;
            [threadInfoArray hmd_addObject:threadInfo];
            consumUsageAll += currentUsage;
        }
    }

    *maxThreadUsage = curMaxThreadUsage;

    for(size_t index = 0; index < (int)(*threadCount); index++) {
        mach_port_deallocate(mach_task_self(), threadList[index]);
    }

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)threadList, (*threadCount) * sizeof(thread_t));
    NSAssert(kr == KERN_SUCCESS,@"The value is not valid");
    return cpuUsage;
}


#pragma mark --- cloud command ---
// 命令下发下来的时候命令没有执行
- (void)execMonitorWithCloudCommand {
    self.monitorType = HMDCPUExceptionMonitorExecCloudCommand;
    hmd_safe_dispatch_async(self.operationQueue, ^{
        [self stopCPUStatusMonitoring];
        self.currentConfig.cpuThreshold = 0;
        self.sampleInterval = 1;
        self.currentConfig.threadUsageThreshold = 0.05;
        [self startCPUStatusMonitoring];
    });
}

- (void)finishMonitorWithCloudCommandWithResult:(NSDictionary *)result {
    if (self.cloudCommandCompletion) {
        self.cloudCommandCompletion(result, YES);
    }
    self.monitorType = HMDCPUExceptionMonitorExecNormal;
}


- (BOOL)checkNeedUploadExceptionDataImmediatelyWithCPUAverageUsage:(float)averageUsage {
    if (averageUsage > 0.9) {
        return NO;
    }
    if (@available(iOS 11.0, *)) {
        NSProcessInfoThermalState thermalState = [[NSProcessInfo processInfo] thermalState];
        if (thermalState == NSProcessInfoThermalStateSerious ||
            thermalState == NSProcessInfoThermalStateCritical) {
            return NO; // 如果当前设备温度比较高的话 下次启动再上报
        }
    }
    return YES;
}

@end
