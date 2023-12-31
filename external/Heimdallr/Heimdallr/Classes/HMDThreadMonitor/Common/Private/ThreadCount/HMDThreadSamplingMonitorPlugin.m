//
//  HMDThreadSamplingMonitorPlugin.m
//  Heimdallr-a8835012
//
//  Created by bytedance on 2022/9/2.
//

#import "HMDThreadSamplingMonitorPlugin.h"
#import "HMDThreadMonitorTool.h"
#import "HMDAppleBacktracesLog.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDThreadMonitorConfig.h"
#import "HMDAsyncThread.h"
#import "HMDUITrackerTool.h"
#import "HMDDynamicCall.h"
#import "HMDUserExceptionTracker.h"
#import "HMDALogProtocol.h"
#import "HMDSessionTracker.h"
#import "HMDMacro.h"
#import "HMDServiceContext.h"

@interface HMDThreadSamplingMonitorPlugin ()

@property (nonatomic, assign) BOOL isRunning;
@property (nonatomic, assign) NSInteger sampleInterval;
@property (nonatomic, assign) BOOL enableBacktrace;
@property (nonatomic, strong) dispatch_source_t sampleTimer;
@property (nonatomic, assign) NSInteger threadCountThreshold;
@property (nonatomic, assign) NSInteger specialThreadThreshold;
@property (nonatomic, copy) NSDictionary *specialThreadWhiteList;

@end

@implementation HMDThreadSamplingMonitorPlugin

+ (instancetype)pluginInstance {
    static HMDThreadSamplingMonitorPlugin *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDThreadSamplingMonitorPlugin alloc] init];
    });

    return instance;
}

#pragma mark --- life cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        _sampleInterval = 300;
    }
    return self;
}

- (void)start {
    if (!self.isRunning) {
        self.isRunning = YES;
        [self startTimerSampling];
    }
}

- (void)stop {
    self.isRunning = NO;
    [self stopTimerSampling];
}

- (void)setupThreadConfig:(HMDThreadMonitorConfig *)config {
    if ([config isKindOfClass:[HMDThreadMonitorConfig class]]) {
        self.sampleInterval = config.threadSampleInterval;
        self.enableBacktrace = config.enableBacktrace;
        self.specialThreadWhiteList = config.specialThreadWhiteList;
        self.threadCountThreshold = config.threadCountThreshold;
        self.specialThreadThreshold = config.specialThreadThreshold;
    }
}


#pragma mark --- thread collect
// start monite cpu usage
- (void)startTimerSampling {
    dispatch_on_thread_monitor_queue(^{
        if (!self.isRunning) {
            return;
        }
        if (self.sampleTimer) {
            dispatch_source_cancel(self.sampleTimer);
            self.sampleTimer = nil;
        }
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, hmd_get_thread_monitor_queue());
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, self.sampleInterval * NSEC_PER_SEC, 0.01 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            [self collectThreadInfo];
        });
        dispatch_resume(timer);
        self.sampleTimer = timer;
    });
}
    
- (void)stopTimerSampling {
    dispatch_on_thread_monitor_queue(^{
        if (self.sampleTimer) {
            dispatch_source_cancel(self.sampleTimer);
            self.sampleTimer = nil;
        }
    });
    
}


- (void)collectThreadInfo {
    HMDThreadMonitorInfo *info = [[HMDThreadMonitorTool shared] getAllThreadInfo];
    if(info) {
        [self uploadAllThreadCount:info];
    }
    if(self.enableBacktrace) {
        NSInteger threshold = [self.specialThreadWhiteList hmd_integerForKey:info.mostThread] ?: self.specialThreadThreshold;
        if(info.mostThreadCount >= threshold) {
            NSMutableDictionary *filters = [NSMutableDictionary dictionary];
            NSString *levelStr = [HMDThreadMonitorTool getSpecialThreadLevel:info.mostThreadCount];
            [filters hmd_setObject:levelStr forKey:@"special_thread_level"];
            [filters hmd_setObject:info.mostThread forKey:@"special_thread"];
            [filters hmd_setObject:@"timer_callback" forKey:@"special_thread_exception_type"];
            [self uploadAllThreadBacktracesExceptionType:kHMDSPECIALTHREADCOUNTEXCEPTION specialThreadID:info.mostThreadID extInfo:filters];
        }
        else if(info.allThreadCount > self.threadCountThreshold) {
            NSMutableDictionary *filters = [NSMutableDictionary dictionary];
            NSUInteger level = info.allThreadCount / 50;
            NSString *levelStr = [NSString stringWithFormat:@"%lu~%lu", level * 50, (level + 1) * 50];
            [filters hmd_setObject:levelStr forKey:@"total_thread_level"];
            [self uploadAllThreadBacktracesExceptionType:kHMDTHREADCOUNTEXCEPTION specialThreadID:info.mostThreadID extInfo:filters];
        }
    }
    return ;
}

- (void)uploadAllThreadCount:(HMDThreadMonitorInfo *)info {
    NSMutableDictionary *metric = [NSMutableDictionary dictionaryWithDictionary:[info.allThreadDic copy]];
    [metric hmd_setObject:@(info.allThreadCount) forKey:@"threads_total_number"];
    
    id<HMDUITrackerManagerSceneProtocol> monitor = hmd_get_uitracker_manager();
    NSString *scene = [monitor scene];
    NSString *inappTimeLevel = [HMDThreadMonitorTool getInAppTimeLevel:[HMDSessionTracker currentSession].timeInSession];
    NSMutableDictionary *category = [NSMutableDictionary new];
    [category hmd_setObject:info.mostThread forKey:@"most_thread"];
    [category hmd_setObject:scene forKey:@"scene"];
    [category hmd_setObject:inappTimeLevel forKey:@"inapp_time"];
    
    id<HMDTTMonitorServiceProtocol> ttmonitor = hmd_get_app_ttmonitor();
    [ttmonitor hmdTrackService:@"threads_count_level" metric:metric category:category extra:nil];
}

- (void)uploadAllThreadBacktracesExceptionType:(NSString *)type
                               specialThreadID:(thread_t)threadID
                                       extInfo:(NSDictionary *)info {
    HMDUserExceptionParameter *param = [HMDUserExceptionParameter initAllThreadParameterWithExceptionType:type
                                                                                             customParams:info
                                                                                                  filters:info];
    param.keyThread = threadID;
    [[HMDUserExceptionTracker sharedTracker] trackThreadLogWithParameter:param
                                                                callback:^(NSError * _Nullable error) {
        if (error) {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDThreadMonitor ] upload user exception failed with error %@", error);
        }
    }];
}

@end
