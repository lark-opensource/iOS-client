//
//  BDPowerLogManager.m
//  Jato
//
//  Created by yuanzhangjing on 2022/7/25.
//

#import "HMDPowerMonitor.h"
#import "HMDPowerLogUtility.h"
#import "HMDPowerMonitorRecord.h"
#import "HMDPowerMonitorDelegate.h"
#import "HMDPowerMonitorDataCollector.h"
#import "HDMPowerMonitorInternalSession.h"

#import "HMDMonitor+Private.h"
#import "HMDPowerMonitor+Private.h"
#import "HMDPowerMonitorSession+Private.h"

#import "HMDPerformanceReporter.h"

#include <sys/sysctl.h>
#include <unistd.h>

//#import "BDPLLogMonitorManager.h"
//#import "BDPowerLogHighPowerMonitor.h"

@interface HMDPowerMonitor() <HMDPowerMonitorInternalSessionDelegate>

//@property(nonatomic,assign) BOOL isRunning;
//@property(atomic,copy) BDPowerLogConfig *config;

@property (nonatomic, weak) id<HMDPowerMonitorDelegate> delegate;
@property (nonatomic, strong) HMDPowerMonitorSession *appStateSession;
@property (atomic, assign) BOOL isForeground;

@property (nonatomic, strong) HMDPowerMonitorDataCollector *collector;
@property (nonatomic, strong) dispatch_queue_t work_queue;
@property (nonatomic, strong) NSString *globalSessionID;
@property (nonatomic, strong) NSMutableArray *sessions;
@property (nonatomic, assign) long long monitor_init_ts;
@property (nonatomic, assign) long long process_start_ts;

//@property(nonatomic,strong) BDPowerLogHighPowerMonitor *highPowerMonitor;

@property (nonatomic,assign) NSInteger currentUserInterfaceStyle;

@end

@implementation HMDPowerMonitor

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        self.work_queue = dispatch_queue_create("hmd_powerlog_manager_queue", DISPATCH_QUEUE_SERIAL);
        self.collector = [[HMDPowerMonitorDataCollector alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackgroundNotification:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForegroundNotification:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidBecomeActiveNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        self.globalSessionID = [[NSUUID UUID] UUIDString];
        self.sessions = [NSMutableArray array];
        pid_t pid = getpid();
        int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid };
        struct kinfo_proc proc;
        size_t size = sizeof(proc);
        self.monitor_init_ts = hmd_powerlog_current_ts();
        if (sysctl(mib, 4, &proc, &size, NULL, 0) == 0) {
            self.process_start_ts = (long long)((proc.kp_proc.p_starttime.tv_sec * 1000.0) + (proc.kp_proc.p_starttime.tv_usec/1000.0));
        }
    }
    return self;
}

#pragma mark - userInterfaceStyle

- (void)updateUserInterfaceStyle {
    if (@available(iOS 13.0, *)) {
        self.currentUserInterfaceStyle = [[UITraitCollection currentTraitCollection] userInterfaceStyle];
    }
}

+ (NSInteger)currentUserInterfaceStyle {
    return [[HMDPowerMonitor sharedMonitor] currentUserInterfaceStyle];
}

#pragma mark - app state session

- (void)startAppStateSession {
    dispatch_async(self.work_queue, ^{
        if (!self.appStateSession) {
            HMDPowerMonitorSession *session = [self beginSession:HMDPowerLogAppSessionName];
//            session.config.uploadWithExtraData = YES;
            self.appStateSession = session;
            self.appStateSession.identifier = HMDPowerLogAppSessionSceneName;
        }
    });
}

- (void)updateInternalSession {
    dispatch_async(self.work_queue, ^{
        [self.sessions enumerateObjectsUsingBlock:^(HMDPowerMonitorSession *_Nonnull session, NSUInteger idx, BOOL * _Nonnull stop) {
            if (session.config.uploadWhenAppStateChanged) {
                BOOL isForeground = self.isForeground;
                if (session.config.ignoreBackground && !isForeground) {
                    [session stopInternalSession];
                    HMDPowerLogInfo(@"foreground %@ internal session stop, ignore background session", session.sessionName);
                } else {
                    [session startInternalSession];
                }
            }
        }];
    });
}

- (void)stopAppStateSession {
    dispatch_async(self.work_queue, ^{
        if (self.appStateSession) {
            [self endSession:self.appStateSession];
            self.appStateSession = nil;
        }
    });
}

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification {
    if (!self.isRunning) {
        return;
    }
    if (self.isForeground) {
        self.isForeground = NO;
        [self.collector updateAppState:NO];
        [self updateInternalSession];
    }
}

- (void)appWillEnterForegroundNotification:(NSNotification *)notification {
    if (!self.isRunning) {
        return;
    }
    if (!self.isForeground) {
        self.isForeground = YES;
        [self.collector updateAppState:YES];
        [self updateInternalSession];
    }
}

- (void)appDidBecomeActiveNotification:(NSNotification *)notification {
    if (!self.isRunning) {
        return;
    }
    [self updateUserInterfaceStyle];
}

#pragma mark - internal session delegate

- (void)internalSessionDidStart:(HMDPowerMonitorSession *)session internalSession:(HDMPowerMonitorInternalSession *)internalSession {
    internalSession.isForeground = self.isForeground;
    HMDPowerLogInfo(@"%@ %@ internal session did start",internalSession.isForeground?@"foreground":@"background",session.sessionName);
}

- (void)internalSessionDidEnd:(HMDPowerMonitorSession *)session internalSession:(HDMPowerMonitorInternalSession *)internalSession {
    [self clearCacheIfNeed];
    HMDPowerLogInfo(@"%@ %@ internal session did end",internalSession.isForeground?@"foreground":@"background",session.sessionName);
}

- (void)clearCacheIfNeed {
    dispatch_async(self.work_queue, ^{
        long long clearDataTime = 0;
        if (self.sessions.count == 0) {
            clearDataTime = hmd_powerlog_current_sys_ts();
        } else {
            __block long long timeForClearCache = 0;
            [self.sessions enumerateObjectsUsingBlock:^(HMDPowerMonitorSession *_Nonnull session, NSUInteger idx, BOOL * _Nonnull stop) {
                long long ts = [session internalSessionStartSysTime];
                if (ts > 0) {
                    if (timeForClearCache == 0) {
                        timeForClearCache = ts;
                    } else {
                        timeForClearCache = MIN(ts, timeForClearCache);
                    }
                }
            }];
            clearDataTime = timeForClearCache;
        }
        if (clearDataTime > 0) {
            [self.collector clearCacheBefore:clearDataTime];
        }
    });
}

#pragma mark - private


- (void)queryDataFrom:(long long)start_sys_ts to:(long long)end_sys_ts
           completion:(void(^)(NSDictionary *data))completion {
    [self.collector queryDataFrom:start_sys_ts to:end_sys_ts completion:completion];
}

+ (void)queryDataFrom:(long long)start_sys_ts to:(long long)end_sys_ts
           completion:(void(^)(NSDictionary *data))completion {
    [[HMDPowerMonitor sharedMonitor] queryDataFrom:start_sys_ts to:end_sys_ts completion:completion];
}

/*
- (BDPowerLogNetMetrics *)currentNetMetrics {
    return [self.collector currentNetMetrics];
}

+ (BDPowerLogNetMetrics *)currentNetMetrics {
    return [[BDPowerLogManager sharedManager] currentNetMetrics];
}
*/

- (void)addDataListener:(id<HMDPowerMonitorDataListener>)listener {
    [self.collector addDataListener:listener];
}

+ (void)addDataListener:(id<HMDPowerMonitorDataListener>)listener {
    [[HMDPowerMonitor sharedMonitor] addDataListener:listener];
}

#pragma mark - public

SHAREDMONITOR(HMDPowerMonitor)

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDPowerMonitorRecord class];
}

- (void)start {
    if (self.isRunning) {
        return;
    }
    [super start];
    
//    bd_pl_update_main_thread_id();
    
    [self.collector setConfig:(HMDPowerMonitorConfig *)self.config];
    [self.collector start];
    
    /*
    if (self.config.highpowerConfig.enable) {
        dispatch_async(self.work_queue, ^{
            if (!self.highPowerMonitor) {
                self.highPowerMonitor = [[BDPowerLogHighPowerMonitor alloc] init];
                self.highPowerMonitor.config = self.config.highpowerConfig;
                BDPLLogMonitorManager.sharedManager.delegate = self.highPowerMonitor;
            }
            [self.collector addDataListener:self.highPowerMonitor];
            [self.highPowerMonitor start];
        });
    }
    
    [self.collector addDataListener:BDPLLogMonitorManager.sharedManager];
    */
    
    HMDPowerLogPerformOnMainQueue(^{
        self.isForeground = UIApplication.sharedApplication.applicationState!=UIApplicationStateBackground;
        [self updateUserInterfaceStyle];
        [self startAppStateSession];
    });
}

- (void)stop {
    if (!self.isRunning) {
        return;
    }
    [super stop];
    [self.collector stop];
    
    /*
    dispatch_async(self.work_queue, ^{
        if (self.highPowerMonitor) {
            [self.highPowerMonitor stop];
            [self.collector removeDataListener:self.highPowerMonitor];
        }
    });
    
    [self.collector removeDataListener:BDPLLogMonitorManager.sharedManager];
     */
    
    [self stopAppStateSession];
}

- (void)updateConfig:(HMDPowerMonitorConfig *)config {
    [super updateConfig:config];
    if (![config isKindOfClass:[HMDPowerMonitorConfig class]]) {
        return;
    }
    [self.collector setConfig:config];
}

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityCPUMonitor;
}

#pragma mark - override

- (void)startWithInterval:(CFTimeInterval)interval {
    
}

- (void)setTimerRefresh:(NSTimeInterval)refreshInterval {
    
}

#pragma mark - session

- (int)findMinimumCollectInterval {
    __block int ret = 0;
    [self.sessions enumerateObjectsUsingBlock:^(HMDPowerMonitorSession *  _Nonnull session, NSUInteger idx, BOOL * _Nonnull stop) {
        int inteval = session.config.dataCollectInterval;
        if (inteval > 0) {
            if (ret <= 0) {
                ret = inteval;
            } else {
                if (inteval < ret) {
                    ret = inteval;
                }
            }
        }
    }];
    return ret;
}

- (HMDPowerMonitorSession *)beginSession:(NSString *)name config:(HMDPowerMonitorSessionConfig *)config {
    if (self.isRunning) {
        HMDPowerMonitorSession *session = [HMDPowerMonitorSession sessionWithName:name];
        [session addCustomFilter:@{
            @"global_session_id":self.globalSessionID?:@"",
            @"process_start_ts":@(self.process_start_ts),
            @"monitor_init_ts":@(self.monitor_init_ts),
        }];
        session.delegate = self;
        if (config) {
            session.config = config;
        }
        [session begin];
        dispatch_async(self.work_queue, ^{
            int interval = session.config.dataCollectInterval;
            if (interval > 0) {
                self.collector.collectInterval = MIN(self.collector.collectInterval, interval);
            }
            BD_ARRAY_ADD(self.sessions, session);
        });
        return session;
    }
    return nil;
}

- (HMDPowerMonitorSession *)beginSession:(NSString *)name {
    return [self beginSession:name config:nil];
}

- (void)endSession:(HMDPowerMonitorSession *)session {
    if (session) {
        [session end];
        dispatch_async(self.work_queue, ^{
            [self.sessions removeObject:session];
            int interval = [self findMinimumCollectInterval];
            if (interval > 0) {
                self.collector.collectInterval = interval;
            } else {
                self.collector.collectInterval = BD_POWERLOG_DEFAULT_INTERVAL;
            }
        });
    }
}

- (void)dropSession:(HMDPowerMonitorSession *)session {
    if (session) {
        [session drop];
        dispatch_async(self.work_queue, ^{
            [self.sessions removeObject:session];
            int interval = [self findMinimumCollectInterval];
            if (interval > 0) {
                self.collector.collectInterval = interval;
            } else {
                self.collector.collectInterval = BD_POWERLOG_DEFAULT_INTERVAL;
            }
        });
    }
}

+ (HMDPowerMonitorSession *)beginSession:(NSString *)name {
    return [[HMDPowerMonitor sharedMonitor] beginSession:name];
}

+ (HMDPowerMonitorSession *)beginSession:(NSString *)name config:(HMDPowerMonitorSessionConfig *)config {
    return [[HMDPowerMonitor sharedMonitor] beginSession:name config:config];
}

+ (void)endSession:(HMDPowerMonitorSession *)session {
    [[HMDPowerMonitor sharedMonitor] endSession:session];
}

+ (void)dropSession:(HMDPowerMonitorSession *)session {
    [[HMDPowerMonitor sharedMonitor] dropSession:session];
}

+ (void)setDelegate:(id<HMDPowerMonitorDelegate>)delegate {
    [HMDPowerMonitor sharedMonitor].delegate = delegate;
}

+ (id<HMDPowerMonitorDelegate>)delegate {
    return [HMDPowerMonitor sharedMonitor].delegate;
}

#pragma mark - event

- (void)beginEvent:(NSString *)event params:(NSDictionary *)params {
    dispatch_async(self.work_queue, ^{
        if (self.appStateSession) {
            [self.appStateSession beginEvent:event params:params];
        }
    });
}

+ (void)beginEvent:(NSString *)event params:(NSDictionary *)params {
    [[HMDPowerMonitor sharedMonitor] beginEvent:event params:params];
}

- (void)endEvent:(NSString *)event params:(NSDictionary *)params {
    dispatch_async(self.work_queue, ^{
        if (self.appStateSession) {
            [self.appStateSession endEvent:event params:params];
        }
    });
}

+ (void)endEvent:(NSString *)event params:(NSDictionary *)params {
    [[HMDPowerMonitor sharedMonitor] endEvent:event params:params];
}

- (void)addEvent:(NSString *)event params:(NSDictionary *)params {
    dispatch_async(self.work_queue, ^{
        if (self.appStateSession) {
            [self.appStateSession addEvent:event params:params];
        }
    });
}

+ (void)addEvent:(NSString *)eventName params:(NSDictionary *)params {
    [[HMDPowerMonitor sharedMonitor] addEvent:eventName params:params];
}

@end
