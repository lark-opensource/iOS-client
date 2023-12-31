//
//  HMDLaunchAnalysis.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/5/27.
//

#import "HMDLaunchTiming.h"
#import "HMDLaunchTiming+Private.h"
#import "HMDLaunchTimingConfig.h"
#import "HMDLaunchDataCollector.h"
#import "HMDAppLaunchTool.h"
#import "AppStartTracker.h"
#import "HMDLaunchPerfCollector.h"
#import "HMDInfo+AppInfo.h"
#import "HMDUserDefaults.h"
#import "Heimdallr+Private.h"
#import "HMDLaunchTimingRecord.h"
#import "HMDPerformanceReportRequest.h"
#import "HMDDebugRealConfig.h"
#import "HMDLaunchNetCollector.h"
#import "HMDGCD.h"
#import "HMDLaunchTaskSpan.h"
#import "HMDReportDowngrador.h"


#import "HMDHermasCounter.h"
#import "HMDHermasManager.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDServerStateService.h"

static NSString *const kHMDStartLastLaunchUpdateVersionCode = @"HMDLastLaunchAppUpdateVersionCode";

@interface HMDLaunchTiming ()<HMDLaunchDataCollectorDelegate, HMDPerformanceReporterDataSource>

@property (nonatomic, assign) BOOL isLaunchFinish;
@property (nonatomic, assign) long long loadTS;
@property (nonatomic, assign) long long didFinishLaunchTS;
@property (nonatomic, assign) long long firstRenderTS;
@property (nonatomic, assign) long long userfinishTS;
@property (nonatomic, strong) HMDLaunchDataCollector *dataCollector;
@property (nonatomic, strong) HMDLaunchPerfCollector *perfColletor;
@property (nonatomic, strong) HMDLaunchNetCollector *netCollector;
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@property (nonatomic, copy) NSString *userFinishStageName;
@property (nonatomic, strong, nullable) HMDPerformanceReportRequest *reportingRequest;
@property (nonatomic, strong) HMDLaunchTimingConfig *launchConfig;
@property (nonatomic, strong) NSHashTable *listenrs;
@property (nonatomic, strong) HMInstance *instance;

@end

@implementation HMDLaunchTiming

#pragma mark--- life cycle
+ (instancetype)shared {
    static HMDLaunchTiming *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enableUseAutoTrace = YES;
        _dataCollector = [[HMDLaunchDataCollector alloc] init];
        _dataCollector.datasource = self;
        _operationQueue = hmd_get_launch_monitor_queue();
        _listenrs = [NSHashTable weakObjectsHashTable];
        if (!_operationQueue) {
            _operationQueue = dispatch_queue_create("com.heimdallr.launchtiming.operation", DISPATCH_QUEUE_SERIAL);
        }
    }
    return self;
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [HMDHermasManager sharedPerformanceInstance];
    }
    return _instance;
}

- (void)start {
    [super start];
    [self startRecordLaunchStage];
}

- (void)stop {
    [super stop];
}

- (BOOL)needSyncStart {
    return YES;
}

- (BOOL)performanceDataSource {
    return YES;
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDLaunchTimingRecord class];
}

- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
    if ([config isKindOfClass:[HMDLaunchTimingConfig class]]) {
        self.launchConfig = (HMDLaunchTimingConfig *)config;
    }
}

#pragma mark--- normal public api
- (void)resetClassLoadTS:(long long)timestamp {
    self.loadTS = timestamp;
}

- (void)resetAppDidFinishTS:(long long)timestamp {
    if (timestamp > 0) {
        self.didFinishLaunchTS = timestamp;
    }
}

- (void)userLaunchFinish {
    [self userLaunchFinishWithName:@"user_finish"];
}

- (void)userLaunchFinishWithName:(NSString *)name {
    if (!self.enableUserFinish) {
        NSAssert(NO, @"if you want to use user custom launch finish, please set property 'enableUserFinish' YES while appdidfinishlaunching or appwillfinishlaunching");
        return;
    }
    if (!name || name.length == 0) {
        name = @"user_finish";
    }
    self.userFinishStageName = name;
    self.userfinishTS = [self fetchCurrentTS];
    [self appLaunchDidFinish];
}

#pragma mark--- default launch data

- (void)startRecordLaunchStage {
    if (![NSThread isMainThread]) { return;}
    
    BOOL needDrop = hermas_enabled() ? [self.instance isDropData] : hmd_drop_data(HMDReporterPerformance);
    if (needDrop) return;
    
    if (self.didFinishLaunchTS <= 0) {
        self.didFinishLaunchTS = [self fetchCurrentTS];
    }
    [self setupPerfCollector];
    [self setupNetCollector];

    [self observeFirstRenderWithBlock:^{
        [self appFirstRenderCommit];
    }];
}

- (void)appFirstRenderCommit {
    self.firstRenderTS = [self fetchCurrentTS];
    if (!self.enableUserFinish) {
        [self appLaunchDidFinish];
    }
}

- (void)appLaunchDidFinish {
    if (self.isLaunchFinish) { return; }
    self.isLaunchFinish = YES;

    // timing
    long long procExec = hmdTimeWithProcessExec();
    long long loadTS = self.loadTS > 0 ? self.loadTS : (hmd_load_timestamp * 1000);
    HMDPrewarmSpan isPrewarmFlag = isPrewarm();
    if(isPrewarmFlag == HMDPrewarmExecToLoad) {
        procExec = loadTS;
    } else if(isPrewarmFlag == HMDPrewarmLoadToDidFinishLaunching) {
        procExec = [HMDWillFinishLaunchingDate timeIntervalSince1970] * 1000;
        loadTS = [HMDWillFinishLaunchingDate timeIntervalSince1970] * 1000;
    }
    HMDLaunchTimingStruct timing = {0};
    timing.proc_exec = procExec;
    timing.cls_load = loadTS;
    timing.start = procExec > 0 ? procExec : loadTS;
    timing.finish_launch = self.didFinishLaunchTS;
    timing.first_render = self.firstRenderTS;
    timing.end = self.firstRenderTS;
    timing.prewarm = (isPrewarmFlag != HMDPrewarmNone);
    if (self.enableUserFinish) {
        timing.user_finish = self.userfinishTS;
        timing.end = self.userfinishTS;
    }

    // perf
    if (self.perfColletor) {
        NSDictionary *perfData = [self.perfColletor collectLaunchStagePerf];
        [self.dataCollector insertNormalPerfData:perfData];
    }
    // launch request
    if (self.netCollector && self.netCollector.isRunning) {
        self.netCollector.launchEndTS = timing.end;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), self.operationQueue, ^{
            [self.netCollector stop];
        });
    }

    [self notifyDefaultLaunchTimingInfo:timing];
    // default task span
    if (self.enableUseAutoTrace) {
        [self useDefaultTimingTraceWithTimingStruct:timing];
    } else {
        [self.dataCollector recordOnceLaunchData];
    }
}

- (void)setupPerfCollector {
    if (self.launchConfig.enableCollectPerf) {
        self.perfColletor = [[HMDLaunchPerfCollector alloc] init];
//        self.perfColletor.targetQueue = hmd_get_launch_monitor_queue();
//        [self.perfColletor installThreadCountMonitor];
    }
}

- (void)setupNetCollector {
    if (self.launchConfig.enableCollectNet) {
        self.netCollector = [[HMDLaunchNetCollector alloc] init];
        self.netCollector.launchStartTS = hmdTimeWithProcessExec();
        [self.netCollector start];
    }
}

#pragma mark--- utilities
- (void)useDefaultTimingTraceWithTimingStruct:(HMDLaunchTimingStruct)timingStruct {
    hmd_on_launch_monitor_queue(^{
        NSArray<HMDLaunchTaskSpan *> *defaultSpans = [HMDLaunchTaskSpan defaultSpansWithTimingStruct:timingStruct endTaskName:self.userFinishStageName];
        HMDLaunchTraceTimingInfo *timingInfo = [[HMDLaunchTraceTimingInfo alloc] init];
        timingInfo.taskSpans = defaultSpans;
        timingInfo.customLaunchModel = [self launchDefaultCustomLaunchMode];
        timingInfo.collectFrom = HMDLaunchTimingCollectFromDefault;
        timingInfo.name = @"launch_stats";
        timingInfo.pageType = @"launch_stats";
        timingInfo.pageName = @"default";
        timingInfo.start = timingStruct.start;
        timingInfo.end = timingStruct.end;
        timingInfo.prewarm = timingStruct.prewarm ? YES : NO;
        [self.dataCollector insertOnceCompleteTrace:timingInfo];
        [self.dataCollector recordOnceLaunchData];
    });
}

- (void)observeFirstRenderWithBlock:(dispatch_block_t)block {
    if (@available(iOS 13.0, *)) {
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopActivity activities = kCFRunLoopBeforeTimers;
        CFRunLoopObserverRef observer =
            CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
                if (activity == kCFRunLoopBeforeTimers) {
                    CFRunLoopRemoveObserver(mainRunloop, observer, kCFRunLoopCommonModes);
                    CFRelease(observer);
                    if (block) {block();}
                }
            });
        CFRunLoopAddObserver(mainRunloop, observer, kCFRunLoopCommonModes);
    } else {
        CFRunLoopRef mainRunloop = [[NSRunLoop mainRunLoop] getCFRunLoop];
        CFRunLoopPerformBlock(mainRunloop, NSDefaultRunLoopMode, block);
    }
}


- (BOOL)isLaunchAfterUpdate {
    static BOOL isUpdate = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *curUpdateVersion = [HMDInfo defaultInfo].buildVersion;
        NSString *lastUpdateVersion = [[HMDUserDefaults standardUserDefaults] objectForKeyCompatibleWithHistory:kHMDStartLastLaunchUpdateVersionCode];
        if ([lastUpdateVersion isKindOfClass:[NSString class]] &&
            [curUpdateVersion isEqualToString:lastUpdateVersion]) {
            isUpdate = NO;
        } else {
            [[HMDUserDefaults standardUserDefaults] setObject:curUpdateVersion?:@"" forKey:kHMDStartLastLaunchUpdateVersionCode];
            isUpdate = YES;
        }

    });
    return isUpdate;
}


- (long long)fetchCurrentTS {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

- (NSString *)launchDefaultCustomLaunchMode {
    return [self isLaunchAfterUpdate] ? @"1" : @"2";
}


#pragma mark --- data collector dataSource
- (void)hmdLaunchCollectRecord:(HMDLaunchTimingRecord *)record {
    if (![record isKindOfClass:[HMDLaunchTimingRecord class]]) { return; }
    hmd_on_launch_monitor_queue(^{
        NSUInteger enableUpload = [HMDLaunchTiming shared].config.enableUpload ? 1 : 0;
        record.enableUpload = enableUpload;
        if (hermas_enabled()) {
            record.sequenceCode = record.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:@"HMDLaunchTimingRecord"] : -1;
            [self.instance recordData:record.reportDictionary];
        } else {
            Heimdallr *heimdallr = [HMDLaunchTiming shared].heimdallr;
            if ([heimdallr.database insertObjects:@[record] into:[HMDLaunchTimingRecord tableName]]) {
                [heimdallr updateRecordCount:1];
            }
        }
    });
}

#pragma mark --- listener
- (void)notifyDefaultLaunchTimingInfo:(HMDLaunchTimingStruct)timingStruct {
    hmd_on_launch_monitor_queue(^{
        NSArray<HMDLaunchTaskSpan *> *defaultSpans = [HMDLaunchTaskSpan defaultSpansWithTimingStruct:timingStruct endTaskName:self.userFinishStageName];
        [self excuteListenerSpansWithSpans:defaultSpans];
    });
}

- (void)excuteListenerSpansWithSpans:(NSArray <HMDLaunchTaskSpan *> *)spans {
    for (id <HMDLaunchTimingListener> listener in self.listenrs.allObjects) {
        if ([listener respondsToSelector:@selector(hmdLaunchTimingDefaultTaskSpans:)]) {
            [listener hmdLaunchTimingDefaultTaskSpans:spans];
        }
    }
}

- (void)addTimingListener:(id<HMDLaunchTimingListener>)listener {
    if (listener) {
        [self.listenrs addObject:listener];
    }
}

- (void)removeTimingListener:(id<HMDLaunchTimingListener>)listener {
    if (listener) {
        [self.listenrs removeObject:listener];
    }
}

#pragma - mark drop data
- (void)dropAllDataForServerState {
    if (hermas_enabled()) {
        return;
    }
    
    hmd_on_launch_monitor_queue(^{
        [[Heimdallr shared].database deleteAllObjectsFromTable:[[self storeClass] tableName]];
    });
}

@end
