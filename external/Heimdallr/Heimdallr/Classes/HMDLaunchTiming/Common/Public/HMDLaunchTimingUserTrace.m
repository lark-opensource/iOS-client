//
//  HMDLaunchTiming+Trace.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/7/19.
//

#import "HMDLaunchTimingUserTrace.h"
#import "HMDLaunchTiming+Private.h"
#import "HMDLaunchTaskSpan.h"
#import "HMDAppLaunchTool.h"
#import "HMDLaunchDataCollector.h"
#import "NSDictionary+HMDSafe.h"
#import "AppStartTracker.h"

NSString *const kHMDLaunchTimingTraceUserDefaultModule =  @"user";
NSString *const kHMDLaunchTimingTraceUserDefauleModule =  @"user";


@interface HMDLaunchTimingUserTrace () <HMDLaunchDataCollectorDelegate, HMDLaunchTimingListener>

@property (nonatomic, strong) HMDLaunchTraceTimingInfo *timingInfo;
@property (nonatomic, strong) NSMutableDictionary<NSString *, HMDLaunchTaskSpan *> *taskSpans;
@property (nonatomic, strong) NSMutableDictionary<NSString *, HMDLaunchTaskSpan *> *cachedSpans;
@property (nonatomic, strong) HMDLaunchDataCollector *dataCollector;
@property (atomic, assign) BOOL isOnceEnd;
@property (atomic, assign) BOOL hasSetup;
@property (atomic, assign) BOOL userTraceEnd;
@property (atomic, assign) BOOL defaultSpanEnd;

@end

@implementation HMDLaunchTimingUserTrace

#pragma mark
+ (instancetype)shared {
    static HMDLaunchTimingUserTrace *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDLaunchTimingUserTrace alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dataCollector = [[HMDLaunchDataCollector alloc] init];
        _dataCollector.datasource = self;
    }
    return self;
}

- (void)dealloc {
    [[HMDLaunchTiming shared] removeTimingListener:self];
}

#pragma mark--- start
- (void)setupTrace {
    self.hasSetup = YES;
    self.taskSpans = [NSMutableDictionary dictionary];
    self.cachedSpans = [NSMutableDictionary dictionary];
    self.timingInfo = [[HMDLaunchTraceTimingInfo alloc] init];
    self.timingInfo.collectFrom = HMDLaunchTimingCollectFromUser;
    self.timingInfo.start = [[NSDate date] timeIntervalSince1970] * 1000;
    [[HMDLaunchTiming shared] addTimingListener:self];
}

- (void)setupTraceWithStartTS:(long long)timestamp {
    if (timestamp <= 0) {
#ifdef DEBUG
        NSAssert(NO, @"[HMDLaunchTimingUserTrace setupTraceWithStartTS:] timestamp can not be zero!");
#endif
        return;
    }
    [self setupTrace];
    self.timingInfo.start = timestamp;
}

- (void)setupTraceWithStartDate:(NSDate *)date {
    if (!date) {
#ifdef DEBUG
        NSAssert(NO, @"[HMDLaunchTimingUserTrace startTraceWithDate:] date can not be empty!");
#endif
        return;
    }
    [self setupTrace];
    NSTimeInterval timeinterval = [date timeIntervalSince1970];
    self.timingInfo.start = timeinterval * 1000;
}

#pragma mark-- end
- (void)endWithCustomLaunchModel:(NSString *)launchModel scene:(NSString *)scene maxDuraion:(long long)maxDuration curDate:(NSDate *)curDate {
    if (!curDate) {
#ifdef DEBUG
        NSAssert(NO, @"[HMDLaunchTimingUserTrace startTraceWithDate:] date can not be empty!");
#endif
        return;
    }
    long long timestamp = [curDate timeIntervalSince1970] * 1000;
    [self endWithCustomLaunchModel:launchModel scene:scene maxDuraion:maxDuration curTs:timestamp];
}

- (void)endWithCustomLaunchModel:(NSString *)launchModel scene:(NSString *)scene maxDuraion:(long long)maxDuration curTs:(long long)curTS {
    if (self.isOnceEnd || !self.hasSetup) { return; }
    self.isOnceEnd = YES;
    if (maxDuration > 0 && (curTS - self.timingInfo.start > maxDuration)) {
        return;
    }
    self.timingInfo.customLaunchModel = launchModel ?: @"unknown";
    self.timingInfo.end = curTS;
    self.timingInfo.pageName = scene;
    self.timingInfo.name = @"launch_stats";
    self.timingInfo.pageType = @"launch_stats";
    self.timingInfo.prewarm = (isPrewarm() != HMDPrewarmNone) ? YES : NO;
    hmd_on_launch_monitor_queue(^{
        self.userTraceEnd = YES;
        [self endTraceAndStoreRes];
    });
}

- (void)endTraceAndStoreRes {
    if (self.userTraceEnd && self.defaultSpanEnd) {
        self.timingInfo.taskSpans = [self.taskSpans.allValues copy];
        [self.dataCollector insertOnceCompleteTrace:self.timingInfo];
        [self.dataCollector recordOnceLaunchData];
        [self.taskSpans removeAllObjects];
        [self.cachedSpans removeAllObjects];
    }
}

- (void)cancelTrace {
    self.isOnceEnd = YES;
    self.timingInfo = nil;
    [self.taskSpans removeAllObjects];
    [self.taskSpans removeAllObjects];
}
#pragma mark--- span
- (void)instanceStartSpanWithModuleName:(NSString *)moduleName taskName:(NSString *)taskName startDate:(NSDate *)startDate forceRefresh:(BOOL)forceRefresh {
    if (!startDate) {
#ifdef DEBUG
        NSAssert(NO, @"HMDLaunchTimingUserTrace task span start date can not be empty!");
#endif
        return;
    }
    if (!self.hasSetup) { return; }
    NSString *uniqueKey = [NSString stringWithFormat:@"%@#%@", moduleName?:@"unknown", taskName?:@"unknown"];
    long long timestamp = [startDate timeIntervalSince1970] * 1000;
    BOOL isMainThread = [NSThread isMainThread];
    hmd_on_launch_monitor_queue(^{
        HMDLaunchTaskSpan *taskSpan = [self.taskSpans valueForKey:uniqueKey];
        if (!forceRefresh && taskSpan) {
            return;
        }
        HMDLaunchTaskSpan *span = [[HMDLaunchTaskSpan alloc] init];
        span.module = moduleName;
        span.name = taskName;
        span.start = timestamp;
        span.isSubThread = !isMainThread;
        [self.cachedSpans hmd_setObject:span forKey:uniqueKey];
    });
}

- (void)instanceEndSpanWithModuleName:(NSString *)moduleName taskName:(NSString *)taskName endDate:(NSDate *)date {
    if (!date) {
#ifdef DEBUG
        NSAssert(NO, @"HMDLaunchTimingUserTrace task span end date can not be empty!");
#endif
        return;
    }
    if (!self.hasSetup) { return; }
    NSString *uniqueKey = [NSString stringWithFormat:@"%@#%@", moduleName?:@"unknown", taskName?:@"unknown"];
    long long timestamp = [date timeIntervalSince1970] * 1000;
    hmd_on_launch_monitor_queue(^{
        HMDLaunchTaskSpan *taskSpan = [self.cachedSpans valueForKey:uniqueKey];
        if (!taskSpan) { return; }
        if (taskSpan.isFinish) { return; }
        taskSpan.end = timestamp;
        taskSpan.isFinish = YES;
        [self.taskSpans hmd_setObject:taskSpan forKey:uniqueKey];
    });
}

- (void)instanceRecordSpanWithModule:(NSString *)moduleName task:(NSString *)taskName start:(NSDate *)startDate end:(NSDate *)endDate {
    if (!startDate || !endDate) {
#ifdef DEBUG
        NSAssert(NO, @"HMDLaunchTimingUserTrace task span start date can not be empty!");
#endif
        return;
    }
    if (!self.hasSetup) { return; }
    NSString *uniqueKey = [NSString stringWithFormat:@"%@#%@", moduleName?:@"unknown", taskName?:@"unknown"];
    long long startTS = [startDate timeIntervalSince1970] * 1000;
    long long endTS = [endDate timeIntervalSince1970] * 1000;
    NSString *spanModule = [moduleName copy];
    NSString *spanName = [taskName copy];
    BOOL isMainThread = [NSThread isMainThread];
    hmd_on_launch_monitor_queue(^{
        HMDLaunchTaskSpan *taskSpan = [self.taskSpans valueForKey:uniqueKey];
        taskSpan.start = startTS;
        taskSpan.end = endTS;
        taskSpan.isSubThread = !isMainThread;
        taskSpan.module = spanModule;
        taskSpan.name = spanName;
        taskSpan.isFinish = YES;
        [self.taskSpans hmd_setObject:taskSpan forKey:uniqueKey];
    });
}

#pragma mark--- record delegate
- (void)hmdLaunchCollectRecord:(HMDLaunchTimingRecord *)record {
    hmd_on_launch_monitor_queue(^{
        [[HMDLaunchTiming shared] hmdLaunchCollectRecord:record];
    });
}

- (void)hmdLaunchTimingDefaultTaskSpans:(NSArray<HMDLaunchTaskSpan *> *)spans {
    if (spans) {
        NSArray *copySpan = [spans copy];
        hmd_on_launch_monitor_queue(^{
            for (HMDLaunchTaskSpan *taskSpan in copySpan) {
                if ([taskSpan isKindOfClass:[HMDLaunchTaskSpan class]]) {
                    NSString *uniqueKey = [NSString stringWithFormat:@"%@#%@", taskSpan.module, taskSpan.name];
                    [self.taskSpans hmd_setObject:taskSpan forKey:uniqueKey];
                }
            }
            self.defaultSpanEnd = YES;
            [self endTraceAndStoreRes];
        });
    }
}

#pragma mark
#pragma mark--- public api trace
+ (void)startTrace {
    [[HMDLaunchTimingUserTrace shared] setupTrace];
}

+ (void)startTraceUseProcExec {
    long long procExec = hmdTimeWithProcessExec();
    if (procExec > 0) {
        HMDLaunchTimingUserTrace *trace = [HMDLaunchTimingUserTrace shared];
        [trace setupTraceWithStartTS:procExec];
    }
}

+ (void)startTraceWithDate:(NSDate *)date {
    // timing
    HMDLaunchTimingUserTrace *trace = [HMDLaunchTimingUserTrace shared];
    [trace setupTraceWithStartDate:date];
}


+ (void)endTraceWithLaunchModel:(HMDAPPLaunchModel)launchModel endSceneName:(NSString *)sceneName maxDuration:(long long)maxDuration endDate:(NSDate *)endDate {
    [[HMDLaunchTimingUserTrace shared] endWithCustomLaunchModel:[NSString stringWithFormat:@"%ld", launchModel]
                                                          scene:sceneName
                                                     maxDuraion:maxDuration
                                                        curDate:endDate];
}

+ (void)endTraceWithLaunchModel:(HMDAPPLaunchModel)launchModel endSceneName:(NSString *)sceneName {
    [[HMDLaunchTimingUserTrace shared] endWithCustomLaunchModel:[NSString stringWithFormat:@"%ld", launchModel]
                                                          scene:sceneName
                                                     maxDuraion:0
                                                        curDate:[NSDate date]];
}


+ (void)endTraceWithCustomLaunchModel:(NSString *)customLaunchModel
                         endSceneName:(NSString *)sceneName
                          maxDuration:(long long)maxDuration
                              endDate:(NSDate *)endDate {
    [[HMDLaunchTimingUserTrace shared] endWithCustomLaunchModel:customLaunchModel scene:sceneName maxDuraion:maxDuration curDate:endDate];
}

+ (void)endTraceWithCustomLaunchModel:(NSString *)customLaunchModel endSceneName:(NSString *)sceneName {
    [[HMDLaunchTimingUserTrace shared] endWithCustomLaunchModel:customLaunchModel scene:sceneName maxDuraion:0 curDate:[NSDate date]];
}

+ (void)cancelTrace {
    [[HMDLaunchTimingUserTrace shared] cancelTrace];
}

+ (long long)getTraceStartTimestamp {
    return [HMDLaunchTimingUserTrace shared].timingInfo.start;
}

+ (void)startSpanWithModuleName:(NSString *)moduleName taskName:(NSString *)taskName startDate:(NSDate *)startDate forceRefresh:(BOOL)forceRefresh {
    [[HMDLaunchTimingUserTrace shared] instanceStartSpanWithModuleName:moduleName taskName:taskName startDate:startDate forceRefresh:forceRefresh];
}

+ (void)startSpanWithModuleName:(NSString *)moduleName taskName:(NSString *)taskName {
    [[HMDLaunchTimingUserTrace shared] instanceStartSpanWithModuleName:moduleName taskName:taskName startDate:[NSDate date] forceRefresh:NO];
}

+ (void)startSpanWithTaskName:(NSString *)taskName {
    [[HMDLaunchTimingUserTrace shared] instanceStartSpanWithModuleName:kHMDLaunchTimingTraceUserDefaultModule taskName:taskName startDate:[NSDate date] forceRefresh:NO];
}

+ (void)endSpanWithModuleName:(NSString *)moduleName taskName:(NSString *)taskName endDate:(NSDate *)date {
    [[HMDLaunchTimingUserTrace shared] instanceEndSpanWithModuleName:moduleName taskName:taskName endDate:date];
}

+ (void)endSpanWithModuleName:(NSString *)moduleName taskName:(NSString *)taskName {
    [[HMDLaunchTimingUserTrace shared] instanceEndSpanWithModuleName:moduleName taskName:taskName endDate:[NSDate date]];
}

+ (void)endSpanWithTaskName:(NSString *)taskName {
    [[HMDLaunchTimingUserTrace shared] instanceEndSpanWithModuleName:kHMDLaunchTimingTraceUserDefaultModule taskName:taskName endDate:[NSDate date]];
}

+ (void)recordSpanWithModule:(NSString *)moduleName task:(NSString *)taskName start:(NSDate *)startDate end:(NSDate *)endDate {
    [[HMDLaunchTimingUserTrace shared] instanceRecordSpanWithModule:moduleName task:taskName start:startDate end:endDate];
}

@end
