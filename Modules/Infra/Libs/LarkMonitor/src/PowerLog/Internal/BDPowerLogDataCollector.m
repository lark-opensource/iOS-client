//
//  BDPowerLogDataCollector.m
//  Jato
//
//  Created by yuanzhangjing on 2022/7/26.
//

#import "BDPowerLogDataCollector.h"
#import "BDPowerLogUtility.h"
#import <Heimdallr/HMDMemoryUsage.h>
#import <mach/mach.h>
#import "BDPowerLogNetCollector.h"
#import "BDPowerLogConfig.h"
#import <TTReachability/TTReachability+Conveniences.h>
#import "BDPowerLogCPUMonitor.h"
#import "BDPowerLogHighPowerMonitor.h"
#import "BDPowerLogHighPowerConfig.h"
#import "BDPowerLogManager.h"
#import "BDPowerLogSession+Private.h"
#import "BDPowerLogWebKitMonitor.h"

#define PUSH_EVENT(name,event)\
{\
    if(event) {\
        NSMutableArray *array_ = GET_EVENTS(name);\
        [array_ addObject:event];\
        if (array_.count > BD_POWERLOG_MAX_ITEMS) {\
            NSUInteger count = array_.count - BD_POWERLOG_MAX_ITEMS;\
            [array_ removeObjectsInRange:NSMakeRange(0, count)];\
        }\
        BDPowerLogInfo(@"%s event : %@",#name,event);\
        [self notifyDataChange:@#name data:event];\
    }\
}

@interface BDPowerLogDataCollector()

@property (atomic,strong) BDPowerLogNetCollector *netCollector;
@property (nonatomic,strong) NSHashTable *listeners;
@property (nonatomic,strong) BDPowerLogSession *sceneSession;

@property (nonatomic,strong) NSDictionary *eventsMap;
@property (nonatomic,strong) dispatch_queue_t work_queue;
@property (nonatomic,strong) BDPowerLogCPUMonitor *cpuMonitor;
@property (nonatomic,strong) NSSet *needExtraEventNames;

@property (nonatomic,assign) bd_powerlog_io_info_data lastIOInfo;
@property (nonatomic,assign) void *work_queue_identifier;
@property (nonatomic,assign) BOOL isRunning;
@property (nonatomic,assign) int lastBrightness;
@property (nonatomic,assign) long long lastBrightnessUpdateTS;
@property (nonatomic,assign) uintptr_t previousViewControllerPtr;

@property (nonatomic,strong) dispatch_source_t timer;
@property (nonatomic,assign) long long timer_fired_sys_ts;
@property (nonatomic,assign) uint64_t timer_index;

@property (nonatomic,strong) dispatch_source_t cpuTimer;
@property (nonatomic,assign) long long cpu_timer_fired_sys_ts;
@property (nonatomic,assign) uint64_t cpu_timer_index;


@end

@implementation BDPowerLogDataCollector
@synthesize collectInterval = _collectInterval;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray *)arrayForKey:(NSString *)key {
    return [self.eventsMap objectForKey:key];
}

#define GetterForKey(name)\
NSString *BDPowerLogDataType_##name = @#name;\
- (NSMutableArray *)array_for_##name { \
return [self.eventsMap objectForKey:@#name]; \
}

GetterForKey(cpu)
GetterForKey(thermal_state)
GetterForKey(power_mode)
GetterForKey(battery_level)
GetterForKey(battery_state)
GetterForKey(brightness)
GetterForKey(app_state)
GetterForKey(scene)
GetterForKey(memory)
GetterForKey(io)
GetterForKey(gpu)
GetterForKey(net)
GetterForKey(net_type)

#define GET_EVENTS(name) [self array_for_##name]

- (instancetype)init {
    if (self = [super init]) {
        _collectInterval = BD_POWERLOG_DEFAULT_INTERVAL;
        self.work_queue = dispatch_queue_create("bd_powerlog_data_queue", DISPATCH_QUEUE_SERIAL);
        self.work_queue_identifier = &_work_queue_identifier;
        dispatch_queue_set_specific(self.work_queue, self.work_queue_identifier, self.work_queue_identifier, NULL);
        NSArray *eventNames = @[
            @"thermal_state",
            @"power_mode",
            @"battery_level",
            @"battery_state",
            @"brightness",
            @"app_state",
            @"scene",
            @"cpu",
            @"memory",
            @"io",
            @"gpu",
            @"net",
            @"net_type",
        ];
        _needExtraEventNames = [NSSet setWithArray:@[
            @"thermal_state",
            @"power_mode",
            @"battery_level",
            @"battery_state",
            @"brightness",
            @"app_state",
            @"scene",
            @"net_type",
        ]];
        NSMutableArray *wrappers = [NSMutableArray array];
        for (int i = 0; i < eventNames.count; i++) {
            [wrappers addObject:[NSMutableArray array]];
        }
        self.eventsMap = [NSDictionary dictionaryWithObjects:wrappers forKeys:eventNames];
        
        self.cpuMonitor = [[BDPowerLogCPUMonitor alloc] init];
                
        if (@available(iOS 11.0, *)) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(thermalStateDidChange:)
                                                         name:NSProcessInfoThermalStateDidChangeNotification
                                                       object:nil];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(powerModeDidChange:)
                                                     name:NSProcessInfoPowerStateDidChangeNotification
                                                   object:nil];
        
        if (![UIDevice currentDevice].batteryMonitoringEnabled) {
            [UIDevice currentDevice].batteryMonitoringEnabled = YES;
        }
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(batteryLevelDidChange:)
                                                     name:UIDeviceBatteryLevelDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(batteryStateDidChange:)
                                                     name:UIDeviceBatteryStateDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(brightnessDidChange:)
                                                     name:UIScreenBrightnessDidChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sceneDidUpdate:)
                                                     name:@"kHMDUITrackerSceneDidChangeNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:TTReachabilityChangedNotification
                                                   object:nil];

    }
    return self;
}

- (void)setCollectInterval:(int)collectInterval {
    if (_collectInterval != collectInterval) {
        _collectInterval = collectInterval;
        [self updateTimer];
    }
}

- (int)collectInterval {
    int ret = _collectInterval;
    ret = MAX(ret, BD_POWERLOG_MIN_INTERVAL);
    ret = MIN(ret, BD_POWERLOG_MAX_INTERVAL);
    return ret;
}

- (void)performOnWorkQueue:(dispatch_block_t)block{
    if (dispatch_get_specific(self.work_queue_identifier) == self.work_queue_identifier) {
        if (block) {
            block();
        }
    } else {
        dispatch_async(self.work_queue, block);
    }
}

- (void)performOnWorkQueueAsync:(dispatch_block_t)block{
    dispatch_async(self.work_queue, block);
}

#pragma mark - data change notification

- (void)_snapshotForThermal:(BOOL)init {
    if (!self.isRunning) {
        return;
    }
    if (@available(iOS 11.0, *)) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict.ts = bd_powerlog_current_ts();
        dict.sys_ts = bd_powerlog_current_sys_ts();
        if (init) {
            [dict setValue:@(1) forKey:@"init"];
        }
        NSString *state = BDPowerLogThermalStateName(NSProcessInfo.processInfo.thermalState);
        [dict setValue:state forKey:@"state"];
        PUSH_EVENT(thermal_state, dict)
    }
}

- (void)thermalStateDidChange:(NSNotification *)notification {
    [self performOnWorkQueueAsync:^{
        [self _snapshotForThermal:NO];
    }];
}

- (void)_snapshotForPowerMode:(BOOL)init{
    if (!self.isRunning) {
        return;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict.ts = bd_powerlog_current_ts();
    dict.sys_ts = bd_powerlog_current_sys_ts();
    if (init) {
        [dict setValue:@(1) forKey:@"init"];
    }
    NSString *state = NSProcessInfo.processInfo.lowPowerModeEnabled?@"low":@"normal";
    [dict setValue:state forKey:@"state"];
    PUSH_EVENT(power_mode, dict)
}

- (void)powerModeDidChange:(NSNotification *)notification {
    [self performOnWorkQueueAsync:^{
        [self _snapshotForPowerMode:NO];
    }];
}

- (void)_snapshotForBatteryLevel:(BOOL)init {
    BDPowerLogPerformOnMainQueue(^{
        float batteryLevel = UIDevice.currentDevice.batteryLevel;
        if (batteryLevel < 0) {
            BDPowerLogInfo(@"battery level is invalid: %f",batteryLevel);
            return;
        }
        [self performOnWorkQueue:^{
            if (!self.isRunning) {
                return;
            }
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict.ts = bd_powerlog_current_ts();
            dict.sys_ts = bd_powerlog_current_sys_ts();
            if (init) {
                [dict setValue:@(1) forKey:@"init"];
            }
            [dict setValue:@((int)(batteryLevel*100)) forKey:@"value"];
            PUSH_EVENT(battery_level, dict)
        }];
    });
}

- (void)batteryLevelDidChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _snapshotForBatteryLevel:NO];
    });
}

- (void)_snapshotForBatteryState:(BOOL)init {
    BDPowerLogPerformOnMainQueue(^{
        UIDeviceBatteryState batteryState = UIDevice.currentDevice.batteryState;
        [self performOnWorkQueue:^{
            if (!self.isRunning) {
                return;
            }
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict.ts = bd_powerlog_current_ts();
            dict.sys_ts = bd_powerlog_current_sys_ts();
            if (init) {
                [dict setValue:@(1) forKey:@"init"];
            }
            NSString *state = BDPowerLogBatteryStateName(batteryState);
            [dict setValue:state forKey:@"state"];
            PUSH_EVENT(battery_state, dict)
        }];
    });
}

- (void)batteryStateDidChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _snapshotForBatteryState:NO];
    });
}

- (void)_snapshotForBrightness:(BOOL)init {
    if (!self.isRunning) {
        return;
    }
    int brightness = (int)(UIScreen.mainScreen.brightness*100);
    if (!init && self.lastBrightness == brightness) {
        return;
    }
    long long currentTS = bd_powerlog_current_ts();
    self.lastBrightness = brightness;
    self.lastBrightnessUpdateTS = currentTS;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), self.work_queue, ^{
        if (self.lastBrightnessUpdateTS != currentTS) { //ignore brightness update
            return;
        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict.ts = currentTS;
        dict.sys_ts = bd_powerlog_current_sys_ts();
        if (init) {
            [dict setValue:@(1) forKey:@"init"];
        }
        [dict setValue:@(brightness) forKey:@"value"];
        PUSH_EVENT(brightness, dict)
    });
}

- (void)brightnessDidChange:(NSNotification *)notification {
    [self performOnWorkQueueAsync:^{
        [self _snapshotForBrightness:NO];
    }];
}

- (void)snapshotForAppState:(BOOL)init state:(NSString *)state{
    [self performOnWorkQueue:^{
        if (!self.isRunning) {
            return;
        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict.ts = bd_powerlog_current_ts();
        dict.sys_ts = bd_powerlog_current_sys_ts();
        if (init) {
            [dict setValue:@(1) forKey:@"init"];
        }
        [dict setValue:state forKey:@"state"];
        PUSH_EVENT(app_state, dict)
        BOOL isForeground = [state isEqualToString:@"foreground"];
        [[BDPowerLogWebKitMonitor sharedInstance] updateAppState:isForeground];
    }];
}

- (void)snapshotForAppState:(BOOL)init {
    BDPowerLogPerformOnMainQueue(^{
        UIApplicationState applicationState = UIApplication.sharedApplication.applicationState;
        NSString *state;
        if (applicationState == UIApplicationStateBackground) {
            state = @"background";
        } else {
            state = @"foreground";
        }
        [self snapshotForAppState:init state:state];
    });

}

- (void)updateAppState:(BOOL)isForeground {
    if (isForeground) {
        [self snapshotForAppState:NO state:@"foreground"];
    } else {
        [self snapshotForAppState:NO state:@"background"];
    }
}

- (void)reachabilityChanged:(NSNotification *)notification {
    [self snapshotForNetType:NO];
}

- (void)snapshotForNetType:(BOOL)init{
    [self performOnWorkQueue:^{
        if (!self.isRunning) {
            return;
        }
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict.ts = bd_powerlog_current_ts();
        dict.sys_ts = bd_powerlog_current_sys_ts();
        if (init) {
            [dict setValue:@(1) forKey:@"init"];
        }
        NSString *typeString = [TTReachability currentConnectionMethodName];
        [dict setValue:typeString forKey:@"state"];
        PUSH_EVENT(net_type, dict)
    }];
}

- (void)snapshotForScene:(BOOL)init {
    BDPowerLogPerformOnMainQueue(^{
        UIViewController *vc = BDPLTopViewController();
        uintptr_t ptr = (uintptr_t)((__bridge void *)vc);
        if (self.previousViewControllerPtr == ptr) {
            return;
        }
        self.previousViewControllerPtr = ptr;
        NSString *scene = nil;
        if (vc) {
            const char *name = class_getName([vc class]);
            if (name) {
                scene = [NSString stringWithUTF8String:name];
            } else {
                scene = @"";
            }
        } else {
            scene = @"unknown";
        }
        
        __block NSString *subscene = nil;
        NSDictionary *subsceneConfig = BDPowerLogManager.config.subsceneConfig;
        if(subsceneConfig.count > 0) {
            NSArray *windows = BDPLVisibleWindows();
            [windows enumerateObjectsUsingBlock:^(UIWindow *_Nonnull window, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!window.keyWindow) {
                    UIViewController *vc = BDPLTopViewControllerForController(window.rootViewController);
                    if (!vc) {
                        return;
                    }
                    const char *window_name = class_getName([window class]);
                    NSString *windowName = window_name?[NSString stringWithUTF8String:window_name]:@"";
                    const char *vc_name = class_getName([vc class]);
                    NSString *vcName = vc_name?[NSString stringWithUTF8String:vc_name]:@"";
                    [subsceneConfig enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSDictionary* _Nonnull obj, BOOL * _Nonnull stop) {
                        if ([key isKindOfClass:NSString.class]) {
                            NSArray *windowNames = [obj bdpl_objectForKey:@"window" cls:NSArray.class];
                            NSArray *vcNames = [obj bdpl_objectForKey:@"vc" cls:NSArray.class];
                            if ([windowNames containsObject:windowName] && [vcNames containsObject:vcName]) {
                                subscene = key;
                                *stop = YES;
                            }
                        }
                    }];
                }
            }];
        }
        
        BDPL_DEBUG_LOG(@"[PL] scene = %@ subscene = %@",scene,subscene);

        [self performOnWorkQueue:^{
            if (!self.isRunning) {
                return;
            }
            BDPowerLogConfig *config = self.config;
            BOOL ignoreSceneUpdateBackgroundSession = config.ignoreSceneUpdateBackgroundSession;
            BOOL enableSceneUpdateSession = config.enableSceneUpdateSession;
            int minTime = self.config.sceneUpdateSessionMinTime * 1000;
            if (enableSceneUpdateSession) {
                if (self.sceneSession) {
                    if ([self.sceneSession totalTime] < minTime) {
                        [BDPowerLogManager dropSession:self.sceneSession];
                        BDPL_DEBUG_LOG(@"[PL] Drop Scene Update Session, total time = %lld",self.sceneSession.totalTime);
                    } else {
                        [BDPowerLogManager endSession:self.sceneSession];
                    }
                }
            }
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict.ts = bd_powerlog_current_ts();
            dict.sys_ts = bd_powerlog_current_sys_ts();
            if (init) {
                [dict setValue:@(1) forKey:@"init"];
            }
            [dict setValue:scene forKey:@"scene"];
            [dict setValue:subscene forKey:@"subscene"];
            [dict setValue:[NSString stringWithFormat:@"0x%lx",ptr] forKey:@"identifier"];
            PUSH_EVENT(scene, dict)
            
            if (enableSceneUpdateSession) {
                self.sceneSession = [BDPowerLogManager beginSession:@"scene_update"];
                self.sceneSession.config.ignoreBackground = ignoreSceneUpdateBackgroundSession;
            }
        }];
    });
}

- (void)sceneDidUpdate:(NSNotification *)notification {
    [self snapshotForScene:NO];
}

- (void)_snapshot {
    [self performOnWorkQueue:^{
        [self _snapshotForThermal:YES];
        [self _snapshotForPowerMode:YES];
        [self _snapshotForBatteryLevel:YES];
        [self _snapshotForBatteryState:YES];
        [self _snapshotForBrightness:YES];
        [self snapshotForAppState:YES];
        [self snapshotForScene:YES];
        [self snapshotForNetType:YES];
    }];
}

- (void)_reset {
    self.timer_index = 0;
    self.cpu_timer_index = 0;
    self.lastBrightness = 0;
    [self.eventsMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray *_Nonnull obj, BOOL * _Nonnull stop) {
        [obj removeAllObjects];
    }];
}

#pragma mark - data collect

- (void)addCPUEvent {
    BDPowerLogCPUMetrics *metrics = [self.cpuMonitor collect];
    if (!metrics) {
        return;
    }
    PUSH_EVENT(cpu, [metrics eventDict]);
}

- (void)addGPUEvent {
    NSMutableDictionary* event = [NSMutableDictionary dictionary];
    event.ts = bd_powerlog_current_ts();
    event.sys_ts = bd_powerlog_current_sys_ts();
    [event setValue:@(bd_powerlog_gpu_usage()) forKey:@"gpu_usage"];
    PUSH_EVENT(gpu, event)
}

- (void)addMemoryEvent {
    hmd_MemoryBytes memory = hmd_getMemoryBytes();
    uint64_t appMemory = memory.appMemory;
    uint64_t deviceMemory = memory.usedMemory;
    double webkitMemory = [[BDPowerLogWebKitMonitor sharedInstance] currentWebKitMemory];
    
    NSMutableDictionary* event = [NSMutableDictionary dictionary];
    event.ts = bd_powerlog_current_ts();
    event.sys_ts = bd_powerlog_current_sys_ts();
    [event setValue:@(appMemory) forKey:@"app_memory"];
    [event setValue:@(deviceMemory) forKey:@"device_memory"];
    if (webkitMemory > 0) {
        [event setValue:@(webkitMemory) forKey:@"webkit_memory"];
    }
    PUSH_EVENT(memory, event)
    
    [[BDPowerLogWebKitMonitor sharedInstance] addMemoryEvent:event];
}

- (void)addIOEvent {
    bd_powerlog_io_info_data io_info;
    if (!bd_powerlog_io_info(&io_info)) {
        BDPowerLogInfo(@"io usage error index : %d",self.timer_index);
        return;
    }
    
    if (self.timer_index > 0) {
        NSMutableDictionary* event = [NSMutableDictionary dictionary];
    #define GET_DIFF_DATA(obj1,obj2,val) (obj1.val >= obj2.val)?(obj1.val - obj2.val):0
        uint64_t delta_diskio_bytesread = GET_DIFF_DATA(io_info, self.lastIOInfo, diskio_bytesread);
        uint64_t delta_diskio_byteswritten = GET_DIFF_DATA(io_info, self.lastIOInfo, diskio_byteswritten);
        uint64_t delta_logical_writes = GET_DIFF_DATA(io_info, self.lastIOInfo, logical_writes);
    #undef GET_DIFF_DATA
        uint64_t delta_time = io_info.ts - self.lastIOInfo.ts;

        event.ts = io_info.ts;
        event.sys_ts = bd_powerlog_current_sys_ts();
        event.delta_time = delta_time;
        
        [event setValue:@(delta_diskio_bytesread) forKey:@"delta_io_disk_rd"];
        [event setValue:@(delta_diskio_byteswritten) forKey:@"delta_io_disk_wr"];
        [event setValue:@(delta_logical_writes) forKey:@"delta_io_logic_wr"];

        PUSH_EVENT(io, event)
    }

    self.lastIOInfo = io_info;
}

- (void)addNetEvent {
    NSDictionary *event = [self.netCollector collect];
    PUSH_EVENT(net, event);
}

- (void)timerFired {
    if (!self.isRunning) {
        return;
    }
    
    long long sys_ts = bd_powerlog_current_sys_ts();
    if (sys_ts - self.timer_fired_sys_ts < (int)((BD_POWERLOG_DEFAULT_INTERVAL * 1000.0)/2)) {
        return;
    }
    
    [self addGPUEvent];
    [self addMemoryEvent];
    [self addIOEvent];
    [self addNetEvent];
        
    self.timer_fired_sys_ts = sys_ts;
    self.timer_index++;
}

- (void)cpuTimerFired {
    if (!self.isRunning) {
        return;
    }
    
    long long sys_ts = bd_powerlog_current_sys_ts();
    if (sys_ts - self.cpu_timer_fired_sys_ts < (int)((self.collectInterval * 1000.0)/2)) {
        return;
    }
    [self addCPUEvent];
        
    self.cpu_timer_fired_sys_ts = sys_ts;
    self.cpu_timer_index++;
}

#pragma mark - process control

- (void)start {
    [self performOnWorkQueue:^{
        if (self.isRunning) {
            return;
        }
        self.isRunning = YES;
        
        if (self.config.enableNetMonitor) {
            if(!self.netCollector) {
                self.netCollector = [[BDPowerLogNetCollector alloc] init];
            }
            self.netCollector.enableURLSessionMetrics = self.config.enableURLSessionMetrics;
            self.netCollector.enable = self.config.enableNetMonitor;
        }
        
        if (self.config.enableWebKitMonitor) {
            [[BDPowerLogWebKitMonitor sharedInstance] start];
        }
        
        [self _snapshot];
        
        [self startTimerNoQueue];
    }];
}

- (void)startTimerNoQueue {
    if (self.timer) {
        dispatch_cancel(self.timer);
        self.timer = NULL;
    }
    
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.work_queue);
    dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, BD_POWERLOG_DEFAULT_INTERVAL * NSEC_PER_SEC, 0);
    WEAK_SELF
    dispatch_source_set_event_handler(self.timer, ^{
        STRONG_SELF
        if (!strongSelf)
            return;
        [strongSelf timerFired];
    });
    dispatch_resume(self.timer);
    
    
    if (self.cpuTimer) {
        dispatch_cancel(self.cpuTimer);
        self.cpuTimer = NULL;
    }
    self.cpuTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.work_queue);
    dispatch_source_set_timer(self.cpuTimer, DISPATCH_TIME_NOW, self.collectInterval * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(self.cpuTimer, ^{
        STRONG_SELF
        if (!strongSelf)
            return;
        [strongSelf cpuTimerFired];
    });
    dispatch_resume(self.cpuTimer);
    
    BDPL_DEBUG_LOG(@"PowerLog Data Collector Timer Update %d",self.collectInterval);
}

- (void)updateTimer {
    [self performOnWorkQueue:^{
        if (!self.isRunning) {
            return;
        }
        [self startTimerNoQueue];
    }];
}

- (void)stop {
    [self performOnWorkQueue:^{
        if (!self.isRunning) {
            return;
        }
        if (self.timer) {
            dispatch_cancel(self.timer);
            self.timer = NULL;
        }
        
        if (self.cpuTimer) {
            dispatch_cancel(self.cpuTimer);
            self.cpuTimer = NULL;
        }
        
        [self _reset];
        self.isRunning = NO;
        self.netCollector.enable = NO;
        [[BDPowerLogWebKitMonitor sharedInstance] stop];
    }];
}

#pragma mark - data process

- (NSArray *)_filterData:(long long)start_sys_ts end:(long long)end_sys_ts array:(NSArray *)array needExtra:(BOOL)needExtra {
    NSMutableArray *result = [NSMutableArray array];
    __block NSDictionary *lastItemBefore = nil;
    __block NSDictionary *firstItemAfter = nil;
    [array enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.end_sys_ts < start_sys_ts) {
            lastItemBefore = obj;
        } else if (obj.start_sys_ts > end_sys_ts) {
            if (!firstItemAfter) {
                firstItemAfter = obj;
            }
        } else {
            [result addObject:obj];
        }
    }];
    if (needExtra) {
        if (firstItemAfter) {
            [result addObject:firstItemAfter];
        }
        if (lastItemBefore) {
            [result insertObject:lastItemBefore atIndex:0];
        }
    }
    return result;
}

- (void)queryDataFrom:(long long)start_sys_ts to:(long long)end_sys_ts
           completion:(void(^)(NSDictionary *data))completion {
    [self performOnWorkQueue:^{
        if (!self.isRunning) {
            if (completion) {
                completion(nil);
            }
            return;
        }
        NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
        [self.eventsMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray *_Nonnull obj, BOOL * _Nonnull stop) {
            BOOL needExtra = [self.needExtraEventNames containsObject:key];
            NSArray *events = [self _filterData:start_sys_ts end:end_sys_ts array:obj needExtra:needExtra];
            [mdict setValue:events forKey:[NSString stringWithFormat:@"%@_events",key]];
        }];
        if (completion) {
            completion(mdict);
        }
    }];

}

- (void)_clearCacheBefore:(long long)sys_ts array:(NSMutableArray *)array {
    __block NSUInteger targetIndex = NSNotFound;
    [array enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.end_sys_ts >= sys_ts) {
            *stop = YES;
        } else {
            targetIndex = idx;
        }
    }];
    
    if (targetIndex != NSNotFound) {
        if (targetIndex > 0) {
            [array removeObjectsInRange:NSMakeRange(0, targetIndex)];
        }
    }
}

- (void)clearCacheBefore:(long long)sys_ts {
    [self performOnWorkQueue:^{
        if (!self.isRunning) {
            return;
        }
        
        [self.eventsMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray *_Nonnull obj, BOOL * _Nonnull stop) {
            [self _clearCacheBefore:sys_ts array:obj];
        }];
    }];
}

#pragma mark - public

- (BDPowerLogNetMetrics *)currentNetMetrics {
    return [self.netCollector currentNetMetrics];
}

#pragma mark - listener

- (void)addDataListener:(id<BDPowerLogDataListener>)listener {
    if (!listener)
        return;
    [self performOnWorkQueue:^{
        if(!self.listeners) {
            self.listeners = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        }
        if (![self.listeners containsObject:listener]) {
            [self.listeners addObject:listener];
            if ([listener respondsToSelector:@selector(dataChanged:data:init:)]) {
                [self.eventsMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray *_Nonnull obj, BOOL * _Nonnull stop) {
                    NSDictionary *data = obj.lastObject;
                    if (data) {
                        [listener dataChanged:key data:data init:YES];
                    }
                }];
            }
        }
    }];
}

- (void)removeDataListener:(id<BDPowerLogDataListener>)listener {
    if (!listener)
        return;
    [self performOnWorkQueue:^{
        if(self.listeners) {
            [self.listeners removeObject:listener];
        }
    }];
}

- (void)notifyDataChange:(NSString *)dataType data:(NSDictionary *)data {
    [self performOnWorkQueue:^{
        if (self.listeners) {
            for (id<BDPowerLogDataListener> listener in self.listeners) {
                if ([listener respondsToSelector:@selector(dataChanged:data:init:)]) {
                    [listener dataChanged:dataType data:data init:NO];
                }
            }
        }
    }];
}

@end
