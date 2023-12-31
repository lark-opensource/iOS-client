//
//  BDPowerLogManager.m
//  Jato
//
//  Created by yuanzhangjing on 2022/7/25.
//

#import "BDPowerLogManager.h"
#import "BDPowerLogDataCollector.h"
#import "BDPowerLogUtility.h"
#import "BDPowerLogSession+Private.h"
#import "BDPowerLogManager+Private.h"
#import "BDPowerLogInternalSession.h"
#include <sys/sysctl.h>
#include <unistd.h>
#import "BDPLLogMonitorManager.h"
#import "BDPowerLogHighPowerMonitor.h"
@interface BDPowerLogManager()<BDPowerLogInternalSessionDelegate>

@property(nonatomic,assign) BOOL isRunning;
@property(atomic,copy) BDPowerLogConfig *config;
@property(nonatomic,weak) id<BDPowerLogManagerDelegate> delegate;
@property(nonatomic,strong) BDPowerLogSession *appStateSession;
@property(atomic,assign) BOOL isForeground;

@property(nonatomic,strong) BDPowerLogDataCollector *collector;
@property(nonatomic,strong) dispatch_queue_t work_queue;
@property(nonatomic,strong) NSString *globalSessionID;
@property(nonatomic,strong) NSMutableArray *sessions;
@property(nonatomic,assign) long long monitor_init_ts;
@property(nonatomic,assign) long long process_start_ts;
@property(nonatomic,strong) BDPowerLogHighPowerMonitor *highPowerMonitor;

@property (nonatomic,assign) NSInteger currentUserInterfaceStyle;

@end

@implementation BDPowerLogManager

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        self.work_queue = dispatch_queue_create("bd_powerlog_manager_queue", DISPATCH_QUEUE_SERIAL);
        self.collector = [[BDPowerLogDataCollector alloc] init];
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
        self.monitor_init_ts = bd_powerlog_current_ts();
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
    return [[BDPowerLogManager sharedManager] currentUserInterfaceStyle];
}

#pragma mark - app state session

- (void)startAppStateSession {
    dispatch_async(self.work_queue, ^{
        if (!self.appStateSession) {
            BDPowerLogSession *session = [self beginSession:@"app_state"];
            session.config.uploadWithExtraData = YES;
            self.appStateSession = session;
        }
    });
}

- (void)updateInternalSession {
    dispatch_async(self.work_queue, ^{
        [self.sessions enumerateObjectsUsingBlock:^(BDPowerLogSession *_Nonnull session, NSUInteger idx, BOOL * _Nonnull stop) {
            if (session.config.uploadWhenAppStateChanged) {
                BOOL isForeground = self.isForeground;
                if (session.config.ignoreBackground && !isForeground) {
                    [session stopInternalSession];
                    BDPowerLogInfo(@"foreground %@ internal session stop, ignore background session", session.sessionName);
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
    if(self.isForeground) {
        self.isForeground = NO;
        [self.collector updateAppState:NO];
        [self updateInternalSession];
    }
}

- (void)appWillEnterForegroundNotification:(NSNotification *)notification {
    if (!self.isRunning) {
        return;
    }
    if(!self.isForeground) {
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

- (void)internalSessionDidStart:(BDPowerLogSession *)session internalSession:(BDPowerLogInternalSession *)internalSession {
    internalSession.isForeground = self.isForeground;
    BDPowerLogInfo(@"%@ %@ internal session did start",internalSession.isForeground?@"foreground":@"background",session.sessionName);
}

- (void)internalSessionDidEnd:(BDPowerLogSession *)session internalSession:(BDPowerLogInternalSession *)internalSession {
    [self clearCacheIfNeed];
    BDPowerLogInfo(@"%@ %@ internal session did end",internalSession.isForeground?@"foreground":@"background",session.sessionName);
}

- (void)clearCacheIfNeed {
    dispatch_async(self.work_queue, ^{
        long long clearDataTime = 0;
        if (self.sessions.count == 0) {
            clearDataTime = bd_powerlog_current_sys_ts();
        } else {
            __block long long timeForClearCache = 0;
            [self.sessions enumerateObjectsUsingBlock:^(BDPowerLogSession *_Nonnull session, NSUInteger idx, BOOL * _Nonnull stop) {
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
    [[BDPowerLogManager sharedManager] queryDataFrom:start_sys_ts to:end_sys_ts completion:completion];
}

- (BDPowerLogNetMetrics *)currentNetMetrics {
    return [self.collector currentNetMetrics];
}

+ (BDPowerLogNetMetrics *)currentNetMetrics {
    return [[BDPowerLogManager sharedManager] currentNetMetrics];
}

- (void)addDataListener:(id<BDPowerLogDataListener>)listener {
    [self.collector addDataListener:listener];
}

+ (void)addDataListener:(id<BDPowerLogDataListener>)listener {
    [[BDPowerLogManager sharedManager] addDataListener:listener];
}

#pragma mark - public

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static BDPowerLogManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [[BDPowerLogManager alloc] init];
    });
    return instance;
}

+ (BOOL)isRunning {
    return [BDPowerLogManager sharedManager].isRunning;
}

- (void)start {
    if (self.isRunning) {
        return;
    }
    
    bd_pl_update_main_thread_id();
    
    self.isRunning = YES;
    self.collector.config = self.config;
    [self.collector start];
    
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
    
    BDPowerLogPerformOnMainQueue(^{
        self.isForeground = UIApplication.sharedApplication.applicationState!=UIApplicationStateBackground;
        [self updateUserInterfaceStyle];
        [self startAppStateSession];
    });
}

- (void)stop {
    if (!self.isRunning) {
        return;
    }
    self.isRunning = NO;
    [self.collector stop];
    
    dispatch_async(self.work_queue, ^{
        if (self.highPowerMonitor) {
            [self.highPowerMonitor stop];
            [self.collector removeDataListener:self.highPowerMonitor];
        }
    });
    
    [self.collector removeDataListener:BDPLLogMonitorManager.sharedManager];
                   
    [self stopAppStateSession];
}

+ (void)start {
    [[BDPowerLogManager sharedManager] start];
}

+ (void)stop {
    [[BDPowerLogManager sharedManager] stop];
}

#pragma mark - session

- (int)findMinimumCollectInterval {
    __block int ret = 0;
    [self.sessions enumerateObjectsUsingBlock:^(BDPowerLogSession *  _Nonnull session, NSUInteger idx, BOOL * _Nonnull stop) {
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

- (BDPowerLogSession *)beginSession:(NSString *)name config:(BDPowerLogSessionConfig *)config {
    if (_isRunning) {
        BDPowerLogSession *session = [BDPowerLogSession sessionWithName:name];
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

- (BDPowerLogSession *)beginSession:(NSString *)name {
    return [self beginSession:name config:nil];
}

- (void)endSession:(BDPowerLogSession *)session {
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

- (void)dropSession:(BDPowerLogSession *)session {
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

+ (BDPowerLogSession *)beginSession:(NSString *)name {
    return [[BDPowerLogManager sharedManager] beginSession:name];
}

+ (BDPowerLogSession *)beginSession:(NSString *)name config:(BDPowerLogSessionConfig *)config {
    return [[BDPowerLogManager sharedManager] beginSession:name config:config];
}

+ (void)endSession:(BDPowerLogSession *)session {
    [[BDPowerLogManager sharedManager] endSession:session];
}

+ (void)dropSession:(BDPowerLogSession *)session {
    [[BDPowerLogManager sharedManager] dropSession:session];
}

+ (void)setDelegate:(id<BDPowerLogManagerDelegate>)delegate {
    [BDPowerLogManager sharedManager].delegate = delegate;
}

+ (id<BDPowerLogManagerDelegate>)delegate {
    return [BDPowerLogManager sharedManager].delegate;
}

+ (void)setConfig:(BDPowerLogConfig *)config {
    [BDPowerLogManager sharedManager].config = config;
}

+ (BDPowerLogConfig *)config {
    return [BDPowerLogManager sharedManager].config;
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
    [[BDPowerLogManager sharedManager] beginEvent:event params:params];
}

- (void)endEvent:(NSString *)event params:(NSDictionary *)params {
    dispatch_async(self.work_queue, ^{
        if (self.appStateSession) {
            [self.appStateSession endEvent:event params:params];
        }
    });
}

+ (void)endEvent:(NSString *)event params:(NSDictionary *)params {
    [[BDPowerLogManager sharedManager] endEvent:event params:params];
}

- (void)addEvent:(NSString *)event params:(NSDictionary *)params {
    dispatch_async(self.work_queue, ^{
        if (self.appStateSession) {
            [self.appStateSession addEvent:event params:params];
        }
    });
}

+ (void)addEvent:(NSString *)eventName params:(NSDictionary *)params {
    [[BDPowerLogManager sharedManager] addEvent:eventName params:params];
}

@end
