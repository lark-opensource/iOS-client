//
//  BDPowerLogInternalSession.m
//  Jato
//
//  Created by yuanzhangjing on 2022/7/28.
//

#import "BDPowerLogInternalSession.h"
#import "BDPowerLogUtility.h"
#import "BDPowerLogManager+Private.h"
#import <Heimdallr/HMDMemoryUsage.h>
#import <Heimdallr/HMDSessionTracker.h>
#import "BDPowerLogWebKitMonitor.h"
#import "BDPowerLogNetMetrics.h"
#import "BDPLLogMonitorManager.h"
@interface BDPowerLogInternalSession()
{
    NSMutableArray *_customEvents;
    long long _begin_ts;
    long long _end_ts;
    long long _begin_sys_ts;
    long long _end_sys_ts;
    long long _begin_task_cpu_time;
    long long _end_task_cpu_time;
    
    long long _begin_webkit_cpu_time;
    long long _begin_webkit_time;
    
    long long _end_webkit_cpu_time;
    long long _end_webkit_time;
    
    host_cpu_load_info_data_t _begin_cpu_load;
    host_cpu_load_info_data_t _end_cpu_load;
    
    bd_powerlog_io_info_data _begin_io_info;
    bd_powerlog_io_info_data _end_io_info;
    
    double _begin_instant_cpu_usage;
    double _end_instant_cpu_usage;
    
    struct {
        int begin_cpu_load_valid : 1;
        int end_cpu_load_valid : 1;
        int begin_io_info_valid : 1;
        int end_io_info_valid : 1;
    }_flags;
    
    BDPowerLogNetMetrics *_beginNetMetrics;
    BDPowerLogNetMetrics *_endNetMetrics;

    int _state;
    NSString *_sessionID;
    NSLock *_lock;
    NSDictionary *_finalLogInfo;
    NSDictionary *_finalExtraLogInfo;
    
    int _num_of_active_cores;
    int _num_of_cores;
    int _num_of_cores_for_calculate;
    
    uint64_t _beginAppMemory;
    uint64_t _endAppMemory;
    uint64_t _beginDeviceMemory;
    uint64_t _endDeviceMemory;
    
    NSMutableDictionary *_beginLogMonitorMetrics;
    NSMutableDictionary *_endLogMonitorMetrics;
    
    dispatch_queue_t _work_queue;
    
    NSDictionary *_cachedData;
}
@end

@implementation BDPowerLogInternalSession

- (instancetype)init {
    if (self = [super init]) {
        _customEvents = [NSMutableArray array];
        _state = 0;
        _sessionID = [[NSUUID UUID] UUIDString];
        _lock = [[NSLock alloc] init];
        _num_of_active_cores = (int)NSProcessInfo.processInfo.activeProcessorCount;
        _num_of_cores = (int)NSProcessInfo.processInfo.processorCount;
        _num_of_cores_for_calculate = (_num_of_active_cores?:_num_of_cores)?:1;
        _work_queue = dispatch_queue_create("powerlog_internal_session_queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)addCustomEvent:(NSDictionary *)event {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (event) {
        [dict addEntriesFromDictionary:event];
    }
    [dict setValue:@(bd_powerlog_current_ts()) forKey:@"ts"];
    [self _addCustomEvent:dict];
}

- (void)addEvent:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@(bd_powerlog_current_ts()) forKey:@"ts"];
    if (params) {
        [dict addEntriesFromDictionary:params];
    }
    if (eventName) {
        [dict setValue:eventName forKey:@"event"];
    }
    [self _addCustomEvent:dict];
}

- (void)_addCustomEvent:(NSDictionary *)event {
    if (!event) {
        NSAssert(NO, @"event is null");
        return;
    }
    [_lock lock];
    
    [_customEvents addObject:event];
    
    if (_customEvents.count > BD_POWERLOG_MAX_ITEMS) {
        NSUInteger count = _customEvents.count - BD_POWERLOG_MAX_ITEMS;
        [_customEvents removeObjectsInRange:NSMakeRange(0, count)];
    }
    
    [_lock unlock];
}

- (void)begin {
    if (_state != 0) {
        NSAssert(NO, @"session state is not 0, state = %d",_state);
        return;
    }
    _state = 1;
    _begin_ts = bd_powerlog_current_ts();
    _begin_sys_ts = bd_powerlog_current_sys_ts();
    
    dispatch_async(_work_queue, ^{
        [self _begin];
    });
}

- (void)_begin {
    _begin_task_cpu_time = bd_powerlog_task_cpu_time();
    _begin_instant_cpu_usage = bd_powerlog_instant_cpu_usage();
    
    _flags.begin_cpu_load_valid = bd_powerlog_device_cpu_load(&_begin_cpu_load) == KERN_SUCCESS;
    _flags.begin_io_info_valid = bd_powerlog_io_info(&_begin_io_info);
        
    _beginNetMetrics = [BDPowerLogManager currentNetMetrics];
        
    hmd_MemoryBytes memory = hmd_getMemoryBytes();
    _beginAppMemory = memory.appMemory;
    _beginDeviceMemory = memory.usedMemory;
    
    _begin_webkit_time = [[BDPowerLogWebKitMonitor sharedInstance] currentWebKitTime];
    
    _begin_webkit_cpu_time = [[BDPowerLogWebKitMonitor sharedInstance] currentWebKitCPUTime];
    
    NSArray<BDPLLogMonitor *> * logMonitors = [BDPLLogMonitorManager allLogMonitors];
    _beginLogMonitorMetrics = [NSMutableDictionary dictionary];
    [logMonitors enumerateObjectsUsingBlock:^(BDPLLogMonitor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.enable) {
            [_beginLogMonitorMetrics bdpl_setObject:@(obj.totalLogCount) forKey:obj.type];
        }
    }];
}

- (void)end {
    if (_state != 1) {
        NSAssert(NO, @"session state is not 1, state = %d",_state);
        return;
    }
    _state = 2;
    _end_ts = bd_powerlog_current_ts();
    _end_sys_ts = bd_powerlog_current_sys_ts();
    
    
    dispatch_block_t waitBlock = dispatch_block_create(0, ^{});
    [BDPowerLogManager queryDataFrom:_begin_sys_ts to:_end_sys_ts completion:^(NSDictionary * _Nonnull data) {
        self->_cachedData = data;
        waitBlock();
    }];
    
    dispatch_async(_work_queue, ^{
        [self _end];
        dispatch_block_wait(waitBlock, DISPATCH_TIME_FOREVER);
    });
}

- (void)_end {
    _end_task_cpu_time = bd_powerlog_task_cpu_time();
    _end_instant_cpu_usage = bd_powerlog_instant_cpu_usage();
    
    _flags.end_cpu_load_valid = bd_powerlog_device_cpu_load(&_end_cpu_load) == KERN_SUCCESS;
    _flags.end_io_info_valid = bd_powerlog_io_info(&_end_io_info);
    
    _endNetMetrics = [BDPowerLogManager currentNetMetrics];
    
    hmd_MemoryBytes memory = hmd_getMemoryBytes();
    _endAppMemory = memory.appMemory;
    _endDeviceMemory = memory.usedMemory;
    
    _end_webkit_time = [[BDPowerLogWebKitMonitor sharedInstance] currentWebKitTime];
    
    _end_webkit_cpu_time = [[BDPowerLogWebKitMonitor sharedInstance] currentWebKitCPUTime];
    
    NSArray<BDPLLogMonitor *> * logMonitors = [BDPLLogMonitorManager allLogMonitors];
    _endLogMonitorMetrics = [NSMutableDictionary dictionary];
    [logMonitors enumerateObjectsUsingBlock:^(BDPLLogMonitor * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.enable) {
            [_endLogMonitorMetrics bdpl_setObject:@(obj.totalLogCount) forKey:obj.type];
        }
    }];
}

- (int)state {
    return _state;
}

- (long long)beginSysTime {
    return _begin_sys_ts;
}

- (long long)endSysTime {
    return _end_sys_ts;
}

- (long long)totalTime {
    if (_state == 1) {
        return bd_powerlog_current_sys_ts() - _begin_sys_ts;
    } else if (_state == 2) {
        return _end_sys_ts - _begin_sys_ts;
    } else {
        return 0;
    }
}

- (NSDictionary *)findTheLastEvent:(NSArray *)events before:(long long)before_sys_ts {
    __block NSDictionary *result = nil;
    [events enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.sys_ts <= before_sys_ts) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

- (NSDictionary *)findTheFirstEvent:(NSArray *)events after:(long long)after_sys_ts {
    __block NSDictionary *result = nil;
    [events enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.sys_ts >= after_sys_ts) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

- (NSDictionary *)generateThermalSummaryInfo:(NSArray *)thermalStateEvents {
    if (@available(iOS 11.0, *)) {
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        NSDictionary *latest = [self findTheLastEvent:thermalStateEvents before:_end_sys_ts];
        [info setValue:[latest objectForKey:@"state"] forKey:@"thermal_state"];
        __block long long nominal_time = 0;
        __block long long fair_time = 0;
        __block long long serious_time = 0;
        __block long long critical_time = 0;
        
        __block long long previous_sys_ts = 0;
        __block NSString *previous_state = nil;
        [thermalStateEvents enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSString *state = [obj objectForKey:@"state"];
            long long sys_ts = obj.sys_ts;
            
            if (sys_ts < _begin_sys_ts || !previous_state) {
                previous_state = state;
                previous_sys_ts = sys_ts;
                return;
            }
            
            long long time = MIN(sys_ts, _end_sys_ts) - MAX(previous_sys_ts, _begin_sys_ts);
            if (time > 0) {
                if ([previous_state isEqualToString:@"nominal"]) {
                    nominal_time += time;
                } else if ([previous_state isEqualToString:@"fair"]) {
                    fair_time += time;
                } else if ([previous_state isEqualToString:@"serious"]) {
                    serious_time += time;
                } else if ([previous_state isEqualToString:@"critical"]) {
                    critical_time += time;
                } else {
                    NSAssert(NO, @"invalid thermal state %@",previous_state);
                }
            }
            
            if (sys_ts >= _end_sys_ts) {
                *stop = YES;
            }
    
            previous_state = state;
            previous_sys_ts = sys_ts;
        }];
        
        if (previous_sys_ts < _end_sys_ts) {
            long long time = _end_sys_ts - MAX(previous_sys_ts, _begin_sys_ts);
            if ([previous_state isEqualToString:@"nominal"]) {
                nominal_time += time;
            } else if ([previous_state isEqualToString:@"fair"]) {
                fair_time += time;
            } else if ([previous_state isEqualToString:@"serious"]) {
                serious_time += time;
            } else if ([previous_state isEqualToString:@"critical"]) {
                critical_time += time;
            } else {
                NSAssert(NO, @"invalid thermal state %@",previous_state);
            }
        }
        
        NSString *peakThermalState = nil;
        if (critical_time > 0) {
            peakThermalState = @"critical";
        } else if (serious_time > 0) {
            peakThermalState = @"serious";
        } else if (fair_time > 0) {
            peakThermalState = @"fair";
        } else if (nominal_time > 0) {
            peakThermalState = @"nominal";
        } else {
            peakThermalState = @"unknown";
        }
        
        [info setValue:peakThermalState forKey:@"peak_thermal_state"];
        [info setValue:@(nominal_time) forKey:@"thermal_nominal_time"];
        [info setValue:@(fair_time) forKey:@"thermal_fair_time"];
        [info setValue:@(serious_time) forKey:@"thermal_serious_time"];
        [info setValue:@(critical_time) forKey:@"thermal_critical_time"];

        return info;
    }
    return nil;
}

- (void)updateBatteryLevel:(NSArray *)batteryLevelEvents logInfo:(NSMutableDictionary *)logInfo {
    NSDictionary *batteryLevelEvent = [self findTheLastEvent:batteryLevelEvents before:_end_sys_ts];
    [logInfo setValue:[batteryLevelEvent objectForKey:@"value"] forKey:@"battery_level"];
    NSDictionary *firstBatteryLevelEvent = [self findTheFirstEvent:batteryLevelEvents after:_begin_sys_ts];
    if (firstBatteryLevelEvent && batteryLevelEvent) {
        int startBatteryLevel = [[firstBatteryLevelEvent objectForKey:@"value"] intValue];
        int endBatteryLevel = [[batteryLevelEvent objectForKey:@"value"] intValue];
        if (startBatteryLevel >= 0 && endBatteryLevel >= 0) {
            int batteryLevelCost = startBatteryLevel-endBatteryLevel;
            [logInfo setValue:@(batteryLevelCost) forKey:@"battery_level_cost"];
            long long totalTime = [self totalTime];
            if (totalTime > 0) {
                double batteryLevelCostSpeed = batteryLevelCost/totalTime;
                [logInfo setValue:@(batteryLevelCostSpeed) forKey:@"battery_level_cost_speed"];
            }
        } else {
            [logInfo setValue:@(-1) forKey:@"battery_level_cost"];
        }
    } else {
        [logInfo setValue:@(-1) forKey:@"battery_level_cost"];
    }
}


- (void)updateBatteryState:(NSArray *)batteryStateEvents logInfo:(NSMutableDictionary *)logInfo {
    __block NSString *state = nil;
    [batteryStateEvents enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.end_sys_ts > _end_sys_ts) {
            return;
        }
        state = [obj objectForKey:@"state"];
        if ([state isEqualToString:@"charging"]) {
            *stop = YES;
        }
    }];
    [logInfo setValue:state forKey:@"battery_state"];
}

- (void)updateCPUInfo:(NSArray *)cpuEvents logInfo:(NSMutableDictionary *)logInfo {
    long long totalTime = [self totalTime];
    long long totalCPUTime = _end_task_cpu_time-_begin_task_cpu_time;
    [logInfo setValue:@(totalCPUTime) forKey:@"total_cpu_time"];
    double totalCPUUsage = 0;
    if (totalTime > 0) {
        totalCPUUsage = (totalCPUTime * 100.0)/totalTime;
    }
    [logInfo setValue:@(totalCPUUsage) forKey:@"total_cpu_usage"];

    [logInfo setValue:@(_num_of_cores) forKey:@"num_of_cores"];
    [logInfo setValue:@(_num_of_active_cores) forKey:@"num_of_active_cores"];

    if (_flags.begin_cpu_load_valid && _flags.end_cpu_load_valid) {
        natural_t delta_user_cpu = _end_cpu_load.cpu_ticks[CPU_STATE_USER] - _begin_cpu_load.cpu_ticks[CPU_STATE_USER];
        natural_t delta_system_cpu = _end_cpu_load.cpu_ticks[CPU_STATE_SYSTEM] - _begin_cpu_load.cpu_ticks[CPU_STATE_SYSTEM];
        natural_t delta_idle_cpu = _end_cpu_load.cpu_ticks[CPU_STATE_IDLE] - _begin_cpu_load.cpu_ticks[CPU_STATE_IDLE];
        natural_t delta_nice_cpu = _end_cpu_load.cpu_ticks[CPU_STATE_NICE] - _begin_cpu_load.cpu_ticks[CPU_STATE_NICE];
        
        double device_cpu_usage = 0;
        natural_t total_cpu = delta_user_cpu + delta_system_cpu + delta_idle_cpu + delta_nice_cpu;
        natural_t active = delta_user_cpu + delta_system_cpu + delta_nice_cpu;
        if (total_cpu > 0) {
            device_cpu_usage = (active*100.0)/total_cpu;
        }
        [logInfo setValue:@(device_cpu_usage) forKey:@"device_cpu_usage"];
        [logInfo setValue:@(device_cpu_usage * _num_of_active_cores) forKey:@"device_total_cpu_usage"];
        [logInfo setValue:@(active) forKey:@"device_cpu_active_time"];
        [logInfo setValue:@(total_cpu) forKey:@"device_cpu_total_time"];
    }
    
    long long delta_webkit_cpu_time = _end_webkit_cpu_time - _begin_webkit_cpu_time;
    if (delta_webkit_cpu_time < 0)
        delta_webkit_cpu_time = 0;
    long long delta_webkit_time = _end_webkit_time - _begin_webkit_time;
    if (delta_webkit_time > 0) {
        [logInfo setValue:@(delta_webkit_time) forKey:@"webkit_time"];
        [logInfo setValue:@(delta_webkit_cpu_time) forKey:@"webkit_cpu_time"];
        [logInfo setValue:@((delta_webkit_cpu_time * 100.0)/delta_webkit_time) forKey:@"webkit_cpu_usage"];
    }

    static int total_cpu_ranges[] = {0,10,20,30,40,50,60,80,100,200,400,600};
    int total_cpu_ranges_count = sizeof(total_cpu_ranges)/sizeof(int);
    NSMutableArray *cpu_usage_times = [NSMutableArray arrayWithCapacity:total_cpu_ranges_count];
    for (int i = 0; i < total_cpu_ranges_count; i++) {
        [cpu_usage_times addObject:@(0)];
    }
    
#define update_time(val,time)\
{\
    int slot = total_cpu_ranges_count - 1;\
    for (int i = 1; i < total_cpu_ranges_count; i++) {\
        if (val < total_cpu_ranges[i]) {\
            slot = i - 1;\
            break;\
        }\
    }\
    slot = MIN(slot, total_cpu_ranges_count - 1);\
    slot = MAX(slot, 0);\
    cpu_usage_times[slot] = @([cpu_usage_times[slot] longLongValue] + time);\
}
    __block double instant_cpu_usage_sum = 0;
    __block int instant_cpu_usage_counter = 0;
    __block NSDictionary *firstValidSample = nil;
    __block NSDictionary *lastValidSample = nil;
    [cpuEvents enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        long long end_sys_ts = obj.end_sys_ts;
        long long start_sys_ts = obj.start_sys_ts;
        
        if (end_sys_ts < _begin_sys_ts || start_sys_ts > _end_sys_ts) {
            return;
        }
        if (!firstValidSample) {
            firstValidSample = obj;
        }
        lastValidSample = obj;
        
        double cpu_usage = [[obj objectForKey:@"cpu_usage"] doubleValue];
        
        double instant_cpu_usage = [[obj objectForKey:@"instant_cpu_usage"] doubleValue];
        if (instant_cpu_usage >= 0) {
            instant_cpu_usage_sum += instant_cpu_usage;
            instant_cpu_usage_counter++;
        }

        long long real_time = MIN(_end_sys_ts, end_sys_ts) - MAX(_begin_sys_ts, start_sys_ts);
        update_time(cpu_usage,real_time);
    }];
    
    if (instant_cpu_usage_counter > 0) {
        [logInfo setValue:@(instant_cpu_usage_sum/instant_cpu_usage_counter) forKey:@"instant_cpu_usage"];
    } else {
        if (_begin_instant_cpu_usage >= 0 && _end_instant_cpu_usage >= 0) {
            [logInfo setValue:@((_begin_instant_cpu_usage + _end_instant_cpu_usage)/2) forKey:@"instant_cpu_usage"];
        }
    }
    
    if (!firstValidSample) {
        long long delta_cpu_time = _end_task_cpu_time - _begin_task_cpu_time;
        long long delta_time = [self totalTime];
        double cpu_usage = 0;
        if (delta_time > 0) {
            cpu_usage = ((double)delta_cpu_time/delta_time)*100.0;
        }
        update_time(cpu_usage,delta_time);
    } else {
        {
            long long start_gap = firstValidSample.start_sys_ts - _begin_sys_ts;
            if (start_gap > 0) {
                double cpu_usage = [[firstValidSample objectForKey:@"cpu_usage"] doubleValue];
                update_time(cpu_usage,start_gap);
            }
        }
        
        {
            long long end_gap = _end_sys_ts - lastValidSample.end_sys_ts;
            if (end_gap > 0) {
                double cpu_usage = [[lastValidSample objectForKey:@"cpu_usage"] doubleValue];
                update_time(cpu_usage,end_gap);
            }
        }

    }
#undef update_time

    for (int i = 0; i < total_cpu_ranges_count; i++) {
        NSString *key = nil;
        if (i == total_cpu_ranges_count - 1) {
            key = [NSString stringWithFormat:@"cpu_usage_%d_inf_time",total_cpu_ranges[i]];
        } else {
            key = [NSString stringWithFormat:@"cpu_usage_%d_%d_time",total_cpu_ranges[i],total_cpu_ranges[i+1]];
        }
        if ([cpu_usage_times[i] longLongValue] > 0) {
            [logInfo setValue:cpu_usage_times[i] forKey:key];
        }
    }
}

- (void)updateIOInfo:(NSArray *)ioEvents logInfo:(NSMutableDictionary *)logInfo {
    if (_flags.begin_io_info_valid && _flags.end_io_info_valid) {
        long long totalTime = [self totalTime];
#define GET_DIFF_DATA(obj1,obj2,val) (obj1.val >= obj2.val)?(obj1.val - obj2.val):0
        uint64_t delta_diskio_bytesread = GET_DIFF_DATA(_end_io_info, _begin_io_info, diskio_bytesread);
        uint64_t delta_diskio_byteswritten = GET_DIFF_DATA(_end_io_info, _begin_io_info, diskio_byteswritten);
        uint64_t delta_logical_writes = GET_DIFF_DATA(_end_io_info, _begin_io_info, logical_writes);
#undef GET_DIFF_DATA
        [logInfo setValue:@(delta_diskio_bytesread) forKey:@"total_io_disk_rd"];
        [logInfo setValue:@(delta_diskio_byteswritten) forKey:@"total_io_disk_wr"];
        [logInfo setValue:@(delta_logical_writes) forKey:@"total_io_logic_wr"];
        [logInfo setValue:@(totalTime>0?((delta_diskio_bytesread * 1000.0)/totalTime):0)
                   forKey:@"total_io_disk_rd_ps"];
        [logInfo setValue:@(totalTime>0?((delta_diskio_byteswritten * 1000.0)/totalTime):0)
                   forKey:@"total_io_disk_wr_ps"];
        [logInfo setValue:@(totalTime>0?((delta_logical_writes * 1000.0)/totalTime):0)
                   forKey:@"total_io_logic_wr_ps"];
    }
}

- (void)updateGPUInfo:(NSArray *)gpuEvents logInfo:(NSMutableDictionary *)logInfo {
    __block int counter = 0;
    __block double gpu_usage_sum = 0;
    [gpuEvents enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        long long sys_ts = obj.sys_ts;
        if (sys_ts < _begin_sys_ts || sys_ts > _end_sys_ts) {
            return;
        }
        double gpu_usage = [[obj objectForKey:@"gpu_usage"] doubleValue];
        gpu_usage_sum += gpu_usage;
        counter++;
    }];
    if (counter > 0) {
        [logInfo setValue:@(gpu_usage_sum/counter) forKey:@"total_gpu_usage"];
    }
}

- (void)updateMemoryInfo:(NSArray *)memoryEvents logInfo:(NSMutableDictionary *)logInfo {
    __block int counter = 0;
    __block double app_mem_usage_sum = 0;
    __block double device_mem_usage_sum = 0;
    __block double webkit_mem_usage_sum = 0;
    __block int webkit_mem_counter = 0;
    [memoryEvents enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        long long sys_ts = obj.sys_ts;
        if (sys_ts < _begin_sys_ts || sys_ts > _end_sys_ts) {
            return;
        }
        double app_memory = [[obj objectForKey:@"app_memory"] doubleValue];
        double device_memory = [[obj objectForKey:@"device_memory"] doubleValue];
        app_mem_usage_sum += app_memory;
        device_mem_usage_sum += device_memory;
        counter++;
        
        double webkit_memory = [[obj objectForKey:@"webkit_memory"] doubleValue];
        if (webkit_memory > 0) {
            webkit_mem_usage_sum += webkit_memory;
            webkit_mem_counter++;
        }
    }];
    app_mem_usage_sum += _beginAppMemory;
    app_mem_usage_sum += _endAppMemory;
    device_mem_usage_sum += _beginDeviceMemory;
    device_mem_usage_sum += _endDeviceMemory;
    counter += 2;
    if (counter > 0) {
        [logInfo setValue:@(app_mem_usage_sum/counter) forKey:@"app_memory"];
        [logInfo setValue:@(device_mem_usage_sum/counter) forKey:@"device_memory"];
    }
    if (webkit_mem_counter > 0) {
        [logInfo setValue:@(webkit_mem_usage_sum/webkit_mem_counter) forKey:@"webkit_memory"];
    }
}

- (void)updateNetInfo:(NSArray *)events logInfo:(NSMutableDictionary *)logInfo {
    long long totalTime = [self totalTime];
    if (_beginNetMetrics && _endNetMetrics) {
        long long net_count = _endNetMetrics.reqCount - _beginNetMetrics.reqCount;
        long long send_bytes = _endNetMetrics.sendBytes - _beginNetMetrics.sendBytes;
        long long recv_bytes = _endNetMetrics.recvBytes - _beginNetMetrics.recvBytes;
        BD_DICT_SET(logInfo, @"net_count", @(net_count));
        BD_DICT_SET(logInfo, @"net_send_bytes", @(send_bytes));
        BD_DICT_SET(logInfo, @"net_recv_bytes", @(recv_bytes));
        
        BD_DICT_SET(logInfo, @"net_count_ps", @(totalTime>0?(net_count*1.0/totalTime):0));
        BD_DICT_SET(logInfo, @"net_send_bytes_ps", @(totalTime>0?(send_bytes*1.0/totalTime):0));
        BD_DICT_SET(logInfo, @"net_recv_bytes_ps", @(totalTime>0?(recv_bytes*1.0/totalTime):0));
        
        long long device_send_bytes = MAX(_endNetMetrics.deviceSendBytes - _beginNetMetrics.deviceSendBytes, 0);
        long long device_recv_bytes = MAX(_endNetMetrics.deviceRecvBytes - _beginNetMetrics.deviceRecvBytes, 0);
        BD_DICT_SET(logInfo, @"net_device_send_bytes", @(device_send_bytes));
        BD_DICT_SET(logInfo, @"net_device_recv_bytes", @(device_recv_bytes));
        BD_DICT_SET(logInfo, @"net_device_send_bytes_ps", @(totalTime>0?(device_send_bytes*1.0/totalTime):0));
        BD_DICT_SET(logInfo, @"net_device_recv_bytes_ps", @(totalTime>0?(device_recv_bytes*1.0/totalTime):0));
    }
}

- (void)generateLogInfo:(void(^)(NSDictionary * _Nullable logInfo,NSDictionary * _Nullable extra))completion {
    if (_state != 2) {
        NSAssert(NO, @"session state is not 2, state = %d",_state);
        if (completion) {
            completion(nil,nil);
        }
        return;
    }
    if (![BDPowerLogManager isRunning]) {
        if (completion) {
            completion(nil,nil);
        }
        return;
    }
    
    NSDictionary *finalLogInfo = nil;
    NSDictionary *finalExtraLogInfo = nil;
    [_lock lock];
    if (_finalLogInfo) {
        finalLogInfo = _finalLogInfo;
    }
    if (_finalExtraLogInfo) {
        finalExtraLogInfo = _finalExtraLogInfo;
    }
    [_lock unlock];
    
    if (finalLogInfo && finalExtraLogInfo) {
        if (completion) {
            completion(finalLogInfo,finalExtraLogInfo);
        }
        return;
    }
    
    dispatch_async(_work_queue, ^{
        [self _generateLogInfo:^(NSDictionary * _Nullable logInfo,NSDictionary * _Nullable extra) {
            [self->_lock lock];
            if (self->_finalLogInfo) {
                logInfo = self->_finalLogInfo;
            } else {
                self->_finalLogInfo = logInfo;
            }
            if (self->_finalExtraLogInfo) {
                extra = self->_finalExtraLogInfo;
            } else {
                self->_finalExtraLogInfo = extra;
            }
            [self->_lock unlock];
            if (completion) {
                completion(logInfo,extra);
            }
        }];
    });
}

- (void)updateLogCount:(NSMutableDictionary *)logInfo {
    long long totalTime = [self totalTime];
    if(_beginLogMonitorMetrics.count > 0 && _endLogMonitorMetrics.count > 0) {
        [_beginLogMonitorMetrics enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, NSNumber *_Nonnull obj, BOOL * _Nonnull stop) {
            long long beginLogCount = obj.longLongValue;
            NSNumber *endValue = [_endLogMonitorMetrics bdpl_objectForKey:key cls:NSNumber.class];
            if (endValue) {
                long long logCount = endValue.longLongValue - beginLogCount;
                if (logCount >= 0) {
                    [logInfo setValue:@(logCount) forKey:[NSString stringWithFormat:@"%@_log_count",key]];
                    if (totalTime > 0) {
                        [logInfo setValue:@(logCount/(totalTime/1000.0)) forKey:[NSString stringWithFormat:@"%@_log_count_per_sec",key]];
                    }
                }
            }
        }];
    }
}

- (NSString *)currentUserInterfaceStyleString {
    NSInteger interfaceStyle = [BDPowerLogManager currentUserInterfaceStyle];
    if (interfaceStyle == 1) {
        return @"light";
    }
    else if (interfaceStyle == 2) {
        return @"dark";
    }
    return @"unspecified";
}

- (void)_generateLogInfo:(void(^)(NSDictionary * _Nullable logInfo,NSDictionary * _Nullable extra))completion {
    NSMutableDictionary *logInfo = [NSMutableDictionary dictionary];
    
    [logInfo setValue:_sessionID forKey:@"session_id"];
    [logInfo setValue:@(_begin_ts) forKey:@"start_ts"];
    [logInfo setValue:@(_end_ts) forKey:@"end_ts"];
    [logInfo setValue:@(_begin_sys_ts) forKey:@"start_sys_ts"];
    [logInfo setValue:@(_end_sys_ts) forKey:@"end_sys_ts"];
    [logInfo setValue:@([self totalTime]) forKey:@"total_time"];
    [logInfo setValue:[self currentUserInterfaceStyleString] forKey:@"user_interface_style"];
    [logInfo setValue:@((long long)([HMDSessionTracker currentSession].timeInSession * 1000)) forKey:@"inapp_time"];

    [_lock lock];
    NSArray *customEvents = [_customEvents copy];
    [_lock unlock];
    
    [logInfo setValue:@(self.isForeground?1:0) forKey:@"foreground"];
    
    [self updateLogCount:logInfo];
    
    long long end_sys_ts = self->_end_sys_ts;
    
    NSDictionary *data = _cachedData;
    NSAssert(data != nil, @"powerlog data is nil");
    if (data) {
        NSArray *powerModeEvents = [data objectForKey:@"power_mode_events"];
        NSDictionary *powerModeEvent = [self findTheLastEvent:powerModeEvents before:end_sys_ts];
        [logInfo setValue:[powerModeEvent objectForKey:@"state"] forKey:@"power_mode"];

        NSArray *thermalStateEvents = [data objectForKey:@"thermal_state_events"];
        NSDictionary *thermalSummaryInfo = [self generateThermalSummaryInfo:thermalStateEvents];
        if (thermalSummaryInfo) {
            [logInfo addEntriesFromDictionary:thermalSummaryInfo];
        }

        NSArray *brightnessEvents = [data objectForKey:@"brightness_events"];
        NSDictionary *brightnessEvent = [self findTheLastEvent:brightnessEvents before:end_sys_ts];
        [logInfo setValue:[brightnessEvent objectForKey:@"value"] forKey:@"brightness"];
       
        [self updateBatteryLevel:[data objectForKey:@"battery_level_events"] logInfo:logInfo];

        [self updateBatteryState:[data objectForKey:@"battery_state_events"] logInfo:logInfo];
        
        [self updateCPUInfo:[data objectForKey:@"cpu_events"] logInfo:logInfo];
        
        NSArray *sceneEvents = [data objectForKey:@"scene_events"];
        NSDictionary *sceneEvent = [self findTheLastEvent:sceneEvents before:end_sys_ts];
        [logInfo setValue:[sceneEvent objectForKey:@"scene"] forKey:@"scene"];
        [logInfo setValue:[sceneEvent objectForKey:@"subscene"] forKey:@"subscene"];
        
        [self updateIOInfo:[data objectForKey:@"io_events"] logInfo:logInfo];
        
        [self updateGPUInfo:[data objectForKey:@"gpu_events"] logInfo:logInfo];
        
        [self updateMemoryInfo:[data objectForKey:@"memory_events"] logInfo:logInfo];
                    
        [self updateNetInfo:BD_DICT_GET(data, @"net_events") logInfo:logInfo];
    }
    
    NSMutableDictionary *extraInfo = [NSMutableDictionary dictionary];
    if (customEvents) {
        [extraInfo setValue:customEvents forKey:@"custom_events"];
    }
    if (data) {
        [extraInfo addEntriesFromDictionary:data];
    }
    
    if (completion) {
        completion(logInfo,extraInfo);
    }
}

@end
