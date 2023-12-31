//
//  BDPowerLogHighPowerMonitor.m
//  Jato
//
//  Created by ByteDance on 2022/11/15.
//

#import "BDPowerLogHighPowerMonitor.h"
#import "BDPowerLogUtility.h"
#import "BDPowerLogHighPowerEvent.h"
#import "BDPowerLogManager.h"
#import <Heimdallr/HMDUserExceptionTracker.h>
#import <Heimdallr/HMDInjectedInfo.h>
#include <dlfcn.h>
#import "BDPowerLogCallTreeNode.h"
#import "BDPLLogMonitorManager.h"

#define DEBUG_LOG(...) BDPL_DEBUG_LOG_TAG(HIGH_POWER,##__VA_ARGS__)

@interface BDPowerLogHighPowerMonitor()

@property(nonatomic, assign) BOOL inHighPowerMode;
@property(nonatomic, assign) NSUInteger highPowerMetricsIndex;
@property(nonatomic, assign) BOOL isForeground;
@property(nonatomic, strong) NSMutableArray *metricsArray;
@property(nonatomic, strong) BDPowerLogHighPowerEvent *event;
@property(nonatomic, strong) NSLock *lock;

@property(nonatomic, copy) NSString *scene;
@property(nonatomic, copy) NSString *subscene;
@property(nonatomic, copy) NSString *batteryState;
@property(nonatomic, copy) NSString *powerMode;
@property(nonatomic, copy) NSString *thermalState;
@property(nonatomic, assign) int batteryLevel;

@property(nonatomic, assign) BOOL inThreadSampleMode;
@property(nonatomic, assign) long long lastThreadSampleUploadTime;
@property(nonatomic, strong) NSMutableArray *threadSamples;
@property(nonatomic, strong) dispatch_source_t timer;
@property(nonatomic, assign) long long lastSampleSysTime;
@property(nonatomic, assign) long long lastSampleCPUTime;
@property(nonatomic, assign) int threadSampleIndex;

@property(nonatomic, strong) dispatch_queue_t work_queue;

@property(nonatomic, assign) BOOL enable;

@end

@implementation BDPowerLogHighPowerMonitor

- (instancetype)init {
    if(self = [super init]) {
        self.metricsArray = [NSMutableArray array];
        self.threadSamples = [NSMutableArray array];
        self.lock = [[NSLock alloc] init];
        self.work_queue = dispatch_queue_create("powerlog_high_power_monitor", DISPATCH_QUEUE_SERIAL);
        self.config = [[BDPowerLogHighPowerConfig alloc] init];
    }
    return self;
}

#pragma mark - thread sample

- (BOOL)_checkSampleMode {
    long long ts = bd_powerlog_current_ts();
    BOOL inHighTemp = [self.thermalState isEqualToString:@"serious"] || [self.thermalState isEqualToString:@"critical"];
    
    BOOL ignoreCoolDownState = inHighTemp;
    
    if (ignoreCoolDownState) {
        DEBUG_LOG(@"in high temp, ignore cool down state");
    } else {
        if (self.lastThreadSampleUploadTime > 0 && (ts - self.lastThreadSampleUploadTime < self.config.stackSampleCoolDownInterval * 1000)) {
            DEBUG_LOG(@"in cool down state, has %ds left, return",(int)(self.config.stackSampleCoolDownInterval - (ts - self.lastThreadSampleUploadTime)/1000.0));
            return NO;
        }
    }
    
    long long timeWindow = 20 * 1000;
    __block long long cpu_time = 0;
    __block long long time = 0;
    [self.metricsArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        time += obj.delta_time;
        cpu_time += obj.delta_cpu_time;
        if (time >= timeWindow) {
            *stop = YES;
        }
    }];
    double usage = time>0?(cpu_time*100.0/time):0;
    double appUsageThreshold = [self.config appCPUUsageThreshold];
    
    DEBUG_LOG(@"check sample mode, app cpu usage = %.2f%% in last %.2fs, threshold = %.2f%% time window = %.2fs", usage, time/1000.0, appUsageThreshold, timeWindow/1000.0);
    
    if (usage >= appUsageThreshold && time >= timeWindow) {
        return YES;;
    }
    return NO;
}

- (void)_flushInvalidSamples:(long long)ts {
    long long start_ts = 0;
    if (self.inHighPowerMode) {
        start_ts = self.event.start_time;
    } else {
        int timewindow = self.config.appTimeWindow * 1000;
        start_ts = ts - timewindow;
    }
    NSAssert(start_ts > 0, @"start_ts is invalid");
    if (start_ts <= 0) {
        start_ts = ts - self.config.appTimeWindowMax * 1000;
    }
    __block NSUInteger index = NSNotFound;
    [self.threadSamples enumerateObjectsUsingBlock:^(HMDThreadBacktrace * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.timestamp * 1000 >= start_ts) {
            *stop = YES;
            return;
        }
        index = idx;
    }];
    if (index != NSNotFound) {
        [self.threadSamples removeObjectsInRange:NSMakeRange(0, MIN(index + 1, self.threadSamples.count))];
    }
    DEBUG_LOG(@"flush thread samples, current count = %lu",self.threadSamples.count);
}

- (id)createStackFrame:(uintptr_t)address index:(int)index {
    @try {
        Class cls = NSClassFromString(@"HMDThreadBacktraceFrame");
        if (cls) {
            id obj = [[cls alloc] init];
            [obj setValue:@(address) forKey:@"address"];
            [obj setValue:@(index) forKey:@"stackIndex"];
            return obj;
        }
    } @catch (NSException *exception) {
        DEBUG_LOG(@"create Stack Frame error %@",exception);
    } @finally {
        
    }

    return nil;
}

- (HMDThreadBacktrace *)_findKeyBacktrace:(NSArray<HMDThreadBacktrace *> *)backtraces {
    BDPowerLogCallTreeNode *rootNode = [self _constructCallTree:backtraces];
    if (rootNode == nil || rootNode.isLeafNode) {
        return backtraces.firstObject;
    }
    DEBUG_LOG(@"call tree %@",rootNode.callTreeDescription);
    BDPowerLogCallTreeNode *heaviestNode = [self _findHeaviestNode:rootNode];
    
    NSAssert(heaviestNode, @"heaviest node is null");
    
    if (!heaviestNode) {
        return backtraces.firstObject;
    }
    
    NSMutableArray *stackFrames = [NSMutableArray array];
    int index = 0;
    BDPowerLogCallTreeNode *node = heaviestNode;
    while (node) {
        if (!node.virtualNode) {
            id stackFrame = [self createStackFrame:node.address index:index];
            if (stackFrame) {
                [stackFrames addObject:stackFrame];
                index++;
            }
        }
        node = node.parentNode;
    }
    
    HMDThreadBacktrace *bestBacktrace = [heaviestNode findBestBacktrace];
    NSString *threadName = BDPLGetAssociation(bestBacktrace, @"bd_pl_thread_name");
    
    float weight = rootNode.weight > 0 ? (heaviestNode.weight / rootNode.weight) * 100 : 0;
    float usage = heaviestNode.count > 0 ? (heaviestNode.weight / heaviestNode.count) : 0;
    NSString *name = [NSString stringWithFormat:@"heaviest call stack %@ count:(%d/%d) weight:%.2f%% usage:%.2f%%",threadName,heaviestNode.count,rootNode.count,weight,usage];

    HMDThreadBacktrace *backtrace = [[HMDThreadBacktrace alloc] init];
    backtrace.threadIndex = 0;
    backtrace.threadID = 0;
    backtrace.threadCpuUsage = 0;
    backtrace.crashed = YES;
    backtrace.name = name;
    backtrace.stackFrames = stackFrames;
    backtrace.timestamp = 0;
    
#ifdef DEBUG
    [backtrace symbolicate:false];
    DEBUG_LOG(@"heaviest stack %@",backtrace);
#endif

    return backtrace;
}

- (BDPowerLogCallTreeNode *)_constructCallTree:(NSArray<HMDThreadBacktrace *> *)backtraces {
    BDPowerLogCallTreeNode *rootNode = [[BDPowerLogCallTreeNode alloc] init];
    rootNode.virtualNode = YES;
    for (HMDThreadBacktrace *backtrace in backtraces) {
        if (backtrace.stackFrames.count > 0) {
            rootNode.weight += backtrace.threadCpuUsage;
            BDPowerLogCallTreeNode *currentNode = rootNode;
            for (int i = (int)backtrace.stackFrames.count - 1; i >= 0; i--) {
                id stackFrame = backtrace.stackFrames[i];
                uintptr_t address = (uintptr_t)[[stackFrame valueForKey:@"address"] unsignedLongLongValue];
                currentNode = [currentNode addSubNode:address weight:backtrace.threadCpuUsage];
                [currentNode addBacktrace:backtrace];
            }
        }
    }
    return rootNode;
}

- (NSArray<BDPowerLogCallTreeNode *> *)_findHeaviestNodePath:(BDPowerLogCallTreeNode *)node {
    if (!node)
        return @[];
    NSMutableArray *ret = [NSMutableArray array];
    [ret addObject:node];
    while (node) {
        __block BDPowerLogCallTreeNode *heaviestNode = nil;
        [node.subnodes enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, BDPowerLogCallTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
            if (!heaviestNode) {
                heaviestNode = obj;
            } else if (heaviestNode.weight < obj.weight) {
                heaviestNode = obj;
            }
        }];
        if (heaviestNode) {
            [ret addObject:heaviestNode];
        }
        node = heaviestNode;
    }
    return ret;
}

- (BDPowerLogCallTreeNode *)_findHeaviestNode:(BDPowerLogCallTreeNode *)rootNode {
    if (rootNode.weight <= 0) return nil;
    NSArray<BDPowerLogCallTreeNode *> *nodes = [self _findHeaviestNodePath:rootNode];
    __block BDPowerLogCallTreeNode *ret = nil;
    [nodes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(BDPowerLogCallTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((obj.weight/rootNode.weight) * 100 >= 10) {
            ret = obj;
            *stop = YES;
        }
    }];
    return ret;
}

- (NSArray *)_collectSamples:(long long)start end:(long long)end {
    NSMutableArray *array = [NSMutableArray array];
    __block NSUInteger index = 1;
    [self.threadSamples enumerateObjectsUsingBlock:^(HMDThreadBacktrace *_Nonnull backtrace, NSUInteger idx, BOOL * _Nonnull stop) {
        if (backtrace.timestamp * 1000 >= start && backtrace.timestamp * 1000 <= end) {
            backtrace.threadIndex = index;
            index++;
            [array addObject:backtrace];
        }
    }];
    HMDThreadBacktrace *keyBacktrace = [self _findKeyBacktrace:array];
    if (keyBacktrace) {
        HMDThreadBacktrace *backtrace = [[HMDThreadBacktrace alloc] init];
        backtrace.threadIndex = 0;
        backtrace.threadID = keyBacktrace.threadID;
        backtrace.threadCpuUsage = keyBacktrace.threadCpuUsage;
        backtrace.crashed = YES;
        backtrace.name = keyBacktrace.name;
        backtrace.stackFrames = keyBacktrace.stackFrames;
        backtrace.timestamp = keyBacktrace.timestamp;
        [array insertObject:backtrace atIndex:0];
    }
    return array;
}

- (void)_doSample {
    [self.lock lock];
    
    long long sys_ts = bd_powerlog_current_sys_ts();
    long long cpu_ts = bd_powerlog_task_cpu_time();

    if (self.lastSampleSysTime != 0) {
        long long delta_time = sys_ts - self.lastSampleSysTime;
        long long delta_cpu_time = cpu_ts - self.lastSampleCPUTime;
        double cpu_usage = delta_time>0?(((double)delta_cpu_time/delta_time)*100):0;
        if (cpu_usage >= [self.config appCPUUsageThreshold]) {
            DEBUG_LOG(@"do sample, time = %lldms, total cpu usage = %.2f%%, instant_cpu_usage = %.2f%%",delta_time,cpu_usage,bd_powerlog_instant_cpu_usage());
            thread_array_t         thread_list;
            mach_msg_type_number_t thread_count;

            kern_return_t kr = task_threads(mach_task_self(), &thread_list, &thread_count);
            if (kr == KERN_SUCCESS) {
                self.event.peakThreadCount = MAX(self.event.peakThreadCount, thread_count);
                NSArray *backtraces = [self _getTopThreads:thread_list thread_count:thread_count procUsage:cpu_usage deltaTime:delta_time topN:self.config.stackSampleThreadCount usageThreshold:self.config.stackSampleThreadUsageThreshold];
                if (backtraces.count) {
                    [self.threadSamples addObjectsFromArray:backtraces];
                    self.threadSampleIndex++;
                }
                
                [backtraces enumerateObjectsUsingBlock:^(HMDThreadBacktrace *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    DEBUG_LOG(@"get backtrace %@",obj);
                    BDPowerLogInfo(@"get backtrace %@",obj.name);
                }];
                
                for(size_t index = 0; index < thread_count; index++)
                    mach_port_deallocate(mach_task_self(), thread_list[index]);
                
                vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
            } else {
                DEBUG_LOG(@"task_threads error");
            }
        } else {
            DEBUG_LOG(@"do sample, skip, time = %lldms, total cpu usage = %.2f%%, instant_cpu_usage = %.2f%%",delta_time,cpu_usage,bd_powerlog_instant_cpu_usage());
        }
    }
        
    self.lastSampleSysTime = sys_ts;
    self.lastSampleCPUTime = cpu_ts;

    [self.lock unlock];
}

- (BOOL)_validateBacktrace:(HMDThreadBacktrace *)backtrace isMain:(BOOL)isMain {
    if (backtrace.stackFrames.count <= 3) {
        DEBUG_LOG(@"ignore backtrace, beacuse of frame count is less than 3, %@",backtrace.name);
        return NO;
    }
    
    if (backtrace.stackFrames.count >= 15) {
        return YES;
    }
    
    if (isMain) {
        for (int i = 0; i < backtrace.stackFrames.count && i < 4; i++) {
            uintptr_t address = 0;
            @try {
                id frame = [backtrace.stackFrames objectAtIndex:i];
                address = (uintptr_t)[[frame valueForKey:@"address"] unsignedLongLongValue];
            } @catch (NSException *exception) {
                NSAssert(NO, exception.description);
            } @finally {
                
            }
            Dl_info info = { 0 };
            if (dladdr(address, &info)) {
               NSString *funcName = info.dli_sname?[NSString stringWithUTF8String:info.dli_sname]:@"";
               NSString *p = @"mach";
               NSString *s = @"msg";
               if ([funcName hasPrefix:[NSString stringWithFormat:@"%@_%@",p,s]]) {
                    DEBUG_LOG(@"ignore backtrace, beacuse of main thread is in %@, %@",funcName, backtrace.name);
                    return NO;
                }
            }
        }
        return YES;
    }
    return YES;
}

- (NSArray<HMDThreadBacktrace *> *)_getTopThreads:(thread_array_t)thread_list thread_count:(mach_msg_type_number_t)thread_count
                                        procUsage:(double)procUsage deltaTime:(int)deltaTime
                                             topN:(int)topN usageThreshold:(double)usageThreshold {
    if (topN <= 0) return nil;
    
    NSMutableArray *threads = [NSMutableArray array];

    mach_msg_type_number_t thread_basic_info_count = THREAD_BASIC_INFO_COUNT;
    thread_basic_info_data_t thread_basic_info;
    
    mach_msg_type_number_t thread_identifier_info_count = THREAD_IDENTIFIER_INFO_COUNT;
    thread_identifier_info_data_t thread_identifier_info;
        
    kern_return_t kr;
    
    double total_instant_cpu = 0;

    for (int idx = 0; idx < (int)thread_count; idx++) {
        thread_t thread_mach_port = thread_list[idx];
        kr = thread_info(thread_mach_port, THREAD_IDENTIFIER_INFO, (thread_info_t)&thread_identifier_info, &thread_identifier_info_count);
        if (kr != KERN_SUCCESS) {
            continue;
        }
        kr = thread_info(thread_mach_port, THREAD_BASIC_INFO, (thread_info_t)&thread_basic_info, &thread_basic_info_count);
        if (kr != KERN_SUCCESS) {
            continue;
        }
        double thread_cpu_usage_instant = (thread_basic_info.cpu_usage / (float)TH_USAGE_SCALE) * 100;
        total_instant_cpu += thread_cpu_usage_instant;
        if (thread_cpu_usage_instant >= usageThreshold) {
            [threads addObject:@[@(thread_cpu_usage_instant),@(thread_mach_port),@(thread_identifier_info.thread_id)]];
        }
    }
    
    if (threads.count > 0) {
        [threads sortUsingComparator:^NSComparisonResult(NSArray *_Nonnull obj1, NSArray * _Nonnull obj2) {
            return [obj2[0] compare:obj1[0]];
        }];
        NSMutableArray *backtraces = [NSMutableArray array];
        [threads enumerateObjectsUsingBlock:^(NSArray *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            double usage = [obj[0] doubleValue];
            thread_t t = (thread_t)[obj[1] unsignedIntValue];
            NSNumber *threadID = obj[2];
            if (bd_pl_get_current_thread_id() == threadID.unsignedLongLongValue) {
                DEBUG_LOG(@"ignore current thread %.2f%%, return",usage);
                return;
            }
            HMDThreadBacktraceParameter *params = [[HMDThreadBacktraceParameter alloc] init];
            params.keyThread = t;
            HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThreadWithParameter:params];
            backtrace.threadCpuUsage = usage;
            if (backtrace && [self _validateBacktrace:backtrace isMain:(BOOL)bd_pl_is_main_thread(t)]) {
                BDPLSetAssociation(backtrace, @"bd_pl_thread_id", threadID, OBJC_ASSOCIATION_COPY_NONATOMIC);
                BDPLSetAssociation(backtrace, @"bd_pl_thread_name", backtrace.name, OBJC_ASSOCIATION_COPY_NONATOMIC);
                BDPLSetAssociation(backtrace, @"bd_pl_time", @(deltaTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                BDPLSetAssociation(backtrace, @"bd_pl_sample_index", @(self.threadSampleIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                backtrace.name = [NSString stringWithFormat:@"%@ tid:0x%x p_cpu:%.2f%% p_i_cpu:%.2f%% t_i_cpu:%.2f%% dur:%dms index:%d",backtrace.name, threadID.unsignedLongLongValue, procUsage, total_instant_cpu, usage, deltaTime, self.threadSampleIndex];
                backtrace.crashed = NO;
                backtrace.timestamp = NSDate.date.timeIntervalSince1970;
                [backtraces addObject:backtrace];
                
#ifdef DEBUG
                [backtrace symbolicate:false];
#endif
                
                if (idx + 1 >= topN) {
                    *stop = YES;
                }
            }
        }];
                
        return backtraces;
    }
        
    return nil;
}

#pragma mark - high power monitor

- (void)addCPUEvent:(NSDictionary *)data {
    if (!self.enable)
        return;
    [self.lock lock];
    DEBUG_LOG(@"add cpu metrics, app cpu usage = %.2f%% device cpu usage = %.2f%% time = %.2fs",data.cpu_usage,data.device_total_cpu_usage,data.delta_time/1000.0);
    BD_ARRAY_ADD(self.metricsArray, data);
    if (self.inHighPowerMode) {
        NSAssert(self.event, @"high power event should exist!");
        BOOL stillInHighPowerMode = NO;
        if ([self _checkAppCPUFromIndex:self.highPowerMetricsIndex]) {
            DEBUG_LOG(@"still in high power mode, beacause of app cpu usage");
            BDPowerLogInfo(@"still in high power mode, beacause of app cpu usage");
            stillInHighPowerMode = YES;
        } else if ([self _checkDeviceCPUFromIndex:self.highPowerMetricsIndex]) {
            DEBUG_LOG(@"still in high power mode, beacause of device cpu usage");
            BDPowerLogInfo(@"still in high power mode, beacause of device cpu usage");
            stillInHighPowerMode = YES;
        }
        if (stillInHighPowerMode) {
            [self.event addCPUMetrics:data];
            [self _checkTimeWindowMax];
        } else {
            [self _quitHighPowerMode:@"cpu_usage_down"];
        }
    } else {
        NSAssert(self.event == nil, @"high power event should not exist!");
        [self _flushInvalidMetrics];
        BOOL inHighPowerMode = NO;
        NSString *enterReason = nil;
        NSUInteger index = NSNotFound;
        if ([self _checkAppCPUWithTimeWindow:&index]) {
            inHighPowerMode = YES;
            enterReason = @"app_cpu_usage";
        } else {
            if ([self _checkDeviceCPUWithTimeWindow:&index]) {
                inHighPowerMode = YES;
                enterReason = @"device_cpu_usage";
            }
        }
        if (inHighPowerMode) {
            DEBUG_LOG(@"enter high power mode, beacause of %@",enterReason);
            BDPowerLogInfo(@"enter high power mode, beacause of %@",enterReason);
            self.inHighPowerMode = YES;
            self.highPowerMetricsIndex = index;
            BDPowerLogHighPowerEvent *event = [[BDPowerLogHighPowerEvent alloc] init];
            event.config = self.config;
            event.isForeground = self.isForeground;
            event.scene = self.scene;
            event.subscene = self.subscene;
            event.batteryState = self.batteryState;
            event.powerMode = self.powerMode;
            event.thermalState = self.thermalState;
            event.enterReason = enterReason;
            event.startBatteryLevel = self.batteryLevel;
            NSArray *metrics = nil;
            if (index >= 0 && index < self.metricsArray.count) {
                metrics = [self.metricsArray subarrayWithRange:NSMakeRange(index, self.metricsArray.count - index)];
            } else {
                metrics = [self.metricsArray copy];
            }
            [event addCPUMetricsArray:metrics];
            self.event = event;
            [self _checkTimeWindowMax];
        }
    }
    
    if (self.config.enableStackSample) {
        if ([self _checkSampleMode]) {
            if (!self.inThreadSampleMode) {
                DEBUG_LOG(@"enter thread sample mode");
                BDPowerLogInfo(@"enter thread sample mode");
                self.inThreadSampleMode = YES;
                self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.work_queue);
                double sampleInterval = MAX(1, self.config.stackSampleInterval);
                dispatch_source_set_timer(self->_timer, DISPATCH_TIME_NOW, sampleInterval * NSEC_PER_SEC, 0);
                dispatch_source_set_event_handler(self.timer, ^{
                    [self _doSample];
                });
                dispatch_resume(self.timer);
            }
        } else {
            if (self.inThreadSampleMode) {
                DEBUG_LOG(@"quit thread sample mode");
                BDPowerLogInfo(@"quit thread sample mode");
                if (self.timer) {
                    dispatch_cancel(self.timer);
                    self.timer = NULL;
                }
                self.inThreadSampleMode = NO;
                self.lastSampleSysTime = 0;
                self.lastSampleCPUTime = 0;
            }
        }
        [self _flushInvalidSamples:data.ts];
    }

    [self.lock unlock];
}

- (void)_flushInvalidMetrics {
    int timewindow = MAX(self.config.appTimeWindow, self.config.deviceTimeWindow) * 1000;
    __block int time = 0;
    __block NSUInteger index = NSNotFound;
    [self.metricsArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        time += obj.delta_time;
        if (time >= timewindow) {
            *stop = YES;
        }
        index = idx;
    }];
    if (index != NSNotFound && index > 0) {
        [self.metricsArray removeObjectsInRange:NSMakeRange(0, MIN(index, self.metricsArray.count))];
    }
    DEBUG_LOG(@"flush cpu metrics, current count = %lu",self.metricsArray.count);
}

- (BOOL)_checkAppCPUWithTimeWindow:(NSUInteger *)fromIndex {
    long long timeWindow = self.config.appTimeWindow * 1000;
    __block long long cpu_time = 0;
    __block long long time = 0;
    __block NSUInteger index = NSNotFound;
    [self.metricsArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        time += obj.delta_time;
        cpu_time += obj.delta_cpu_time;
        if (time >= timeWindow) {
            *stop = YES;
            index = idx;
        }
    }];
    double usage = time>0?(cpu_time*100.0/time):0;
    double appUsageThreshold = [self.config appCPUUsageThreshold];
    DEBUG_LOG(@"app cpu usage = %.2f%% in last %.2fs, threshold = %.2f%%, time window = %.2fs",usage, time/1000.0, appUsageThreshold, timeWindow/1000.0);
    if (usage >= appUsageThreshold && time >= timeWindow) {
        if (fromIndex) {
            *fromIndex = index;
        }
        return YES;;
    }
    return NO;
}

- (BOOL)_checkAppCPUFromIndex:(NSUInteger )index {
    long long timeWindow = self.config.appTimeWindow * 1000;
    __block long long cpu_time = 0;
    __block long long time = 0;
    for (NSUInteger i = index; i < self.metricsArray.count; i++) {
        NSDictionary *obj = self.metricsArray[i];
        time += obj.delta_time;
        cpu_time += obj.delta_cpu_time;
    }
    double usage = time>0?(cpu_time*100.0/time):0;
    double appUsageThreshold = [self.config appCPUUsageThreshold];
    DEBUG_LOG(@"app cpu usage = %.2f%% in last %.2fs, threshold = %.2f%%, time window = %.2fs",usage, time/1000.0, appUsageThreshold, timeWindow/1000.0);
    if (usage >= appUsageThreshold && time >= timeWindow) {
        return YES;;
    }
    return NO;
}

- (BOOL)_checkDeviceCPUWithTimeWindow:(NSUInteger *)fromIndex {
    long long timeWindow = self.config.deviceTimeWindow * 1000;
    __block long long device_cpu_time = 0;
    __block long long time = 0;
    __block NSUInteger index = NSNotFound;
    [self.metricsArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        time += obj.delta_time;
        device_cpu_time += obj.delta_device_cpu_time;
        if (time >= timeWindow) {
            *stop = YES;
            index = idx;
        }
    }];
    double usage = time>0?(device_cpu_time*100.0/time):0;
    double deviceUsageThreshold = [self.config deviceCPUUsageThreshold];
    DEBUG_LOG(@"device cpu usage = %.2f%% in last %.2fs, threshold = %.2f%%, time window = %.2fs",usage, time/1000.0, deviceUsageThreshold, timeWindow/1000.0);
    if (usage >= deviceUsageThreshold && time >= timeWindow) {
        if (fromIndex) {
            *fromIndex = index;
        }
        return YES;
    }
    return NO;
}

- (BOOL)_checkDeviceCPUFromIndex:(NSUInteger)index {
    long long timeWindow = self.config.deviceTimeWindow * 1000;
    __block long long device_cpu_time = 0;
    __block long long time = 0;
    for (NSUInteger i = index; i < self.metricsArray.count; i++) {
        NSDictionary *obj = self.metricsArray[i];
        time += obj.delta_time;
        device_cpu_time += obj.delta_device_cpu_time;
    }
    double usage = time>0?(device_cpu_time*100.0/time):0;
    double deviceUsageThreshold = [self.config deviceCPUUsageThreshold];
    DEBUG_LOG(@"device cpu usage = %.2f%% in last %.2fs, threshold = %.2f%%, time window = %.2fs",usage, time/1000.0, deviceUsageThreshold, timeWindow/1000.0);
    if (usage >= deviceUsageThreshold && time >= timeWindow) {
        return YES;
    }
    return NO;
}


- (void)_checkTimeWindowMax {
    long long time = self.event.total_time;
    long long app_time_window = self.event.config.appTimeWindowMax * 1000;
    long long device_time_window = self.event.config.deviceTimeWindowMax * 1000;
    if (time >= app_time_window || time >= device_time_window) {
        [self _quitHighPowerMode:@"exceed_time_window"];
    }
}

- (void)_quitHighPowerMode:(NSString *)reason {
    if (self.inHighPowerMode) {
        DEBUG_LOG(@"quit high power mode, reason is %@",reason);
        BDPowerLogInfo(@"quit high power mode, reason is %@",reason);
        self.event.quitReason = reason;
        self.event.endBatteryLevel = self.batteryLevel;
        NSDictionary *logInfo = nil;
        
        if (self.event.appCPUUsage >= self.config.appCPUUsageThreshold || [self.event.enterReason isEqualToString:@"app_cpu_usage"]) {
            NSArray *backtraces = [self _collectSamples:self.event.start_time end:self.event.end_time];
            if (backtraces.count) {
                self.lastThreadSampleUploadTime = bd_powerlog_current_ts();
                self.event.stackUUID = [[NSUUID UUID] UUIDString];
                logInfo = [self.event uploadLog];
                NSMutableDictionary *customFilters = [NSMutableDictionary dictionary];
                [customFilters setValue:self.event.stackUUID forKey:@"stack_uuid"];
                [customFilters setValue:self.event.isForeground?@"1":@"0" forKey:@"pl_foreground"];
                [customFilters setValue:self.event.enterReason forKey:@"pl_enter_reason"];
                [customFilters setValue:self.event.quitReason forKey:@"pl_quit_reason"];
                [customFilters setValue:self.event.scene forKey:@"pl_scene"];
                [customFilters setValue:self.event.subscene forKey:@"pl_subscene"];
                [customFilters setValue:self.event.thermalState forKey:@"pl_thermal_state"];
                [customFilters setValue:self.event.batteryState forKey:@"pl_battery_state"];
                [customFilters setValue:[@(self.event.peakThreadCount) stringValue] forKey:@"pl_peak_thread_count"];
                
                int batteryLevelCost = self.event.startBatteryLevel - self.event.endBatteryLevel;
                if (batteryLevelCost < 0) {
                    batteryLevelCost = 0;
                }
                [customFilters setValue:[@(batteryLevelCost) stringValue] forKey:@"pl_battery_level_cost"];
                [customFilters setValue:[@(batteryLevelCost) stringValue] forKey:@"pl_battery_level_cost_v2"];

                NSMutableDictionary *customParams = [NSMutableDictionary dictionary];
                NSDictionary *defaultParams = [[HMDInjectedInfo defaultInfo] customContext];
                if (logInfo.count) {
                    [customParams addEntriesFromDictionary:logInfo];
                }
                if (defaultParams.count) {
                    [customParams addEntriesFromDictionary:defaultParams];
                }
                NSDictionary *defaultFilters = [[HMDInjectedInfo defaultInfo] filters];
                if (defaultFilters.count) {
                    [customFilters addEntriesFromDictionary:defaultFilters];
                }
                HMDUserExceptionParameter *params = [HMDUserExceptionParameter initBacktraceParameterWithExceptionType:@"high_power_monitor" backtracesArray:backtraces customParams:customParams filters:customFilters];
                [[HMDUserExceptionTracker sharedTracker] trackThreadLogWithBacktraceParameter:params callback:^(NSError * _Nullable error) {
                    if (error) {
                        DEBUG_LOG(@"user exception track error %@",error);
                        BDPowerLogInfo(@"user exception track error %@",error);
                    } else {
                        DEBUG_LOG(@"user exception track success");
                        BDPowerLogInfo(@"user exception track success");
                    }
                }];
            }
        }
        
        if (!logInfo) {
            logInfo = [self.event uploadLog];
        }
        DEBUG_LOG(@"high power event upload %@",logInfo);
        BDPowerLogInfo(@"high power event upload %@",logInfo);
        [self _uploadLog:logInfo extra:nil];
        self.event = nil;
        self.inHighPowerMode = NO;
        self.highPowerMetricsIndex = NSNotFound;
        [self.metricsArray removeAllObjects];
    }
}

- (void)_uploadLog:(NSDictionary *)logInfo extra:(NSDictionary *)extra {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            if ([BDPowerLogManager.delegate respondsToSelector:@selector(uploadEvent:logInfo:extra:)]) {
                [BDPowerLogManager.delegate uploadEvent:@"power_log_high_power_event_dev" logInfo:logInfo extra:extra];
            }
        } @catch (NSException *exception) {
            DEBUG_LOG(@"high power event upload exception %@",exception);
        } @finally {

        }
    });
}

#pragma mark - log monitor delegate

- (void)onHighFrequentEvents:(BDPLLogMonitor *)monitor deltaTime:(long long)deltaTime count:(long long)count counterDict:(NSDictionary *)counterDict {
    
    NSArray *topCounterDict = [self topCategoryData:counterDict];
    
    NSString *keyLog = [[[topCounterDict firstObject] allKeys] firstObject];
    
    BDPowerLogInfo(@"high frequent event %@ %@", monitor.type, topCounterDict);

    NSMutableDictionary *logInfo = [NSMutableDictionary dictionary];
    
    [logInfo setValue:@(deltaTime) forKey:@"total_time"];
    
    [logInfo setValue:keyLog forKey:@"key_log"];

    [logInfo setValue:[NSString stringWithFormat:@"%@_log_count",monitor.type] forKey:@"enter_reason"];

    [logInfo setValue:@(count) forKey:@"log_count"];
    
    double deltaCountPerSec = count / (deltaTime / 1000.0);
    [logInfo setValue:@(deltaCountPerSec) forKey:@"log_count_per_sec"];

    [logInfo setValue:@(monitor.config.timewindow * 1000) forKey:@"time_window"];
    [logInfo setValue:@(monitor.config.logThreshold) forKey:@"log_threshold"];
    [logInfo setValue:@(monitor.config.logThresholdPerSecond) forKey:@"log_threshold_per_sec"];
    
    [logInfo setValue:@(self.isForeground?1:0) forKey:@"foreground"];
    [logInfo setValue:self.scene forKey:@"scene"];
    [logInfo setValue:self.subscene forKey:@"subscene"];
    [logInfo setValue:self.thermalState forKey:@"thermal_state"];
    [logInfo setValue:self.powerMode forKey:@"power_mode"];
    [logInfo setValue:self.batteryState forKey:@"battery_state"];
    [logInfo setValue:@"log" forKey:@"high_power_type"];

    long long ts = bd_powerlog_current_ts();
    [logInfo setValue:@(ts - deltaTime) forKey:@"start_time"];
    [logInfo setValue:@(ts) forKey:@"end_time"];
    
    BDPowerLogInfo(@"high power event upload %@",logInfo);
    [self _uploadLog:logInfo extra:nil];

    
    NSMutableDictionary *customFilters = [NSMutableDictionary dictionary];
    [customFilters setValue:[logInfo bdpl_objectForKey:@"time_window"] forKey:@"pl_time_window"];
    [customFilters setValue:[logInfo bdpl_objectForKey:@"log_threshold"] forKey:@"pl_log_threshold"];
    [customFilters setValue:self.isForeground?@"1":@"0" forKey:@"pl_foreground"];
    [customFilters setValue:[logInfo bdpl_objectForKey:@"enter_reason"] forKey:@"pl_enter_reason"];
    [customFilters setValue:[logInfo bdpl_objectForKey:@"scene"] forKey:@"pl_scene"];
    [customFilters setValue:[logInfo bdpl_objectForKey:@"subscene"] forKey:@"pl_subscene"];
    [customFilters setValue:[logInfo bdpl_objectForKey:@"thermal_state"] forKey:@"pl_thermal_state"];
    [customFilters setValue:[logInfo bdpl_objectForKey:@"battery_state"] forKey:@"pl_battery_state"];
    [customFilters setValue:[logInfo bdpl_objectForKey:@"key_log"] forKey:@"pl_key_log"];
    [customFilters setValue:@"log" forKey:@"pl_high_power_type"];
    NSDictionary *defaultFilters = [[HMDInjectedInfo defaultInfo] filters];
    if (defaultFilters.count) {
        [customFilters addEntriesFromDictionary:defaultFilters];
    }
    
    NSMutableDictionary *customParams = [NSMutableDictionary dictionary];
    NSDictionary *defaultParams = [[HMDInjectedInfo defaultInfo] customContext];
    if (logInfo.count) {
        [customParams addEntriesFromDictionary:logInfo];
    }
    if (defaultParams.count) {
        [customParams addEntriesFromDictionary:defaultParams];
    }
    
    NSMutableString *topLogString = [NSMutableString string];
    [topCounterDict enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull dict, NSUInteger idx, BOOL * _Nonnull stop) {
        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (topLogString.length > 0) {
                [topLogString appendString:@"\n"];
            }
            [topLogString appendFormat:@"%@=%@",key,obj];
        }];
    }];
    [customParams setValue:topLogString forKey:@"top_logs"];
    
    HMDUserExceptionParameter *params = [HMDUserExceptionParameter initBaseParameterWithExceptionType:@"high_power_monitor" title:[NSString stringWithFormat:@"HighFrequency_%@",monitor.type] subTitle:[NSString stringWithFormat:@"HeaviestLog:%@",keyLog] customParams:customParams filters:customFilters];
    [[HMDUserExceptionTracker sharedTracker] trackBaseExceptionWithBacktraceParameter:params callback:^(NSError * _Nullable error) {
        if (error) {
            DEBUG_LOG(@"user exception track error %@",error);
            BDPowerLogInfo(@"user exception track error %@",error);
        } else {
            DEBUG_LOG(@"user exception track success");
            BDPowerLogInfo(@"user exception track success");
        }
    }];
}

- (NSArray<NSDictionary *> *)topCategoryData:(NSDictionary *)counterDict {
    NSArray *sortedKeys = [counterDict keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *_Nonnull obj1, NSNumber *_Nonnull obj2) {
        return [obj2 compare:obj1];
    }];
    NSMutableArray *array = [NSMutableArray array];
    [sortedKeys enumerateObjectsUsingBlock:^(NSString *  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:@{key:[counterDict objectForKey:key]?:@(0)}];
        if (idx >= 9) {
            *stop = YES;
        }
    }];
    return array;
}

#pragma mark - state update

- (void)updateAppState:(BOOL)isForeground {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        self.isForeground = isForeground;
        if (isForeground) {
            [self _quitHighPowerMode:@"enter_foreground"];
        } else {
            [self _quitHighPowerMode:@"enter_background"];
        }
        [self.lock unlock];
    });
}

- (void)updateScene:(NSString *)scene subscene:(NSString *_Nullable)subscene {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        self.scene = scene;
        self.subscene = subscene;
        [self.lock unlock];
    });
}

- (void)updateThermalState:(NSString *)thermalState {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        self.thermalState = thermalState;
        [self.lock unlock];
    });
}

- (void)updateBatteryState:(NSString *)batteryState {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        self.batteryState = batteryState;
        [self.lock unlock];
    });
}

- (void)updatePowerMode:(NSString *)powerMode {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        self.powerMode = powerMode;
        [self.lock unlock];
    });
}

- (void)updateBatteryLevel:(int)batteryLevel {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        self.batteryLevel = batteryLevel;
        [self.lock unlock];
    });
}

- (void)dataChanged:(NSString *)dataType data:(NSDictionary *)data init:(BOOL)init {
    if (!self.enable)
        return;
    if ([dataType isEqualToString:@"battery_level"]) {
        [self updateBatteryLevel:data.battery_level];
    } else if ([dataType isEqualToString:@"power_mode"]) {
        [self updatePowerMode:data.power_mode];
    } else if ([dataType isEqualToString:@"battery_state"]) {
        [self updateBatteryState:data.battery_state];
    } else if ([dataType isEqualToString:@"thermal_state"]) {
        [self updateThermalState:data.thermal_state];
    } else if ([dataType isEqualToString:@"app_state"]) {
        [self updateAppState:[data.app_state isEqualToString:@"foreground"]];
    } else if ([dataType isEqualToString:@"scene"]) {
        [self updateScene:data.scene subscene:data.subscene];
    } else if ([dataType isEqualToString:@"cpu"]) {
        [self addCPUEvent:data];
    }
}

- (void)start {
    self.enable = YES;
}

- (void)stop {
    self.enable = NO;
}

@end

#undef DEBUG_LOG
