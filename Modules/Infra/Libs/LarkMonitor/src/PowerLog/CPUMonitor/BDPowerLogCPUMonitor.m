//
//  BDPowerLogCPUMonitor.m
//  Jato
//
//  Created by ByteDance on 2022/11/15.
//

#import "BDPowerLogCPUMonitor.h"
#import "BDPowerLogUtility.h"
#import "BDPowerLogWebKitMonitor.h"
@interface BDPowerLogCPUMonitor()
{
    int _num_of_active_cores;
}

@property(nonatomic,strong) BDPowerLogCPUMetrics *cpuMetrics;

@end

@implementation BDPowerLogCPUMonitor

- (instancetype)init {
    if (self = [super init]) {
        _num_of_active_cores = (int)[NSProcessInfo processInfo].activeProcessorCount;
        if (_num_of_active_cores == 0) {
            _num_of_active_cores = (int)[NSProcessInfo processInfo].processorCount;
            if (_num_of_active_cores == 0) {
                _num_of_active_cores = 1;
            }
        }
    }
    return self;
}

- (BDPowerLogCPUMetrics *_Nullable)_collect {
    BDPowerLogCPUMetrics *metrics = [[BDPowerLogCPUMetrics alloc] init];
    metrics.num_of_active_cores = _num_of_active_cores;
    metrics.timestamp = bd_powerlog_current_ts();
    metrics.sys_ts = bd_powerlog_current_sys_ts();
    metrics.cpu_time = (long long)(clock()/(CLOCKS_PER_SEC * 0.001));;
    host_cpu_load_info_data_t cpu_load_info;
    kern_return_t kr = bd_powerlog_device_cpu_load(&cpu_load_info);
    if (kr == KERN_SUCCESS) {
        metrics.device_total_cpu_ticks = cpu_load_info.cpu_ticks[CPU_STATE_USER] + cpu_load_info.cpu_ticks[CPU_STATE_SYSTEM] + cpu_load_info.cpu_ticks[CPU_STATE_IDLE] + cpu_load_info.cpu_ticks[CPU_STATE_NICE];
        metrics.device_running_cpu_ticks = cpu_load_info.cpu_ticks[CPU_STATE_USER] + cpu_load_info.cpu_ticks[CPU_STATE_SYSTEM] + cpu_load_info.cpu_ticks[CPU_STATE_NICE];
    }
    metrics.instant_cpu_usage = bd_powerlog_instant_cpu_usage();
    metrics.webkit_cpu_time = [[BDPowerLogWebKitMonitor sharedInstance] currentWebKitCPUTime];
    metrics.webkit_time = [[BDPowerLogWebKitMonitor sharedInstance] currentWebKitTime];
    return metrics;
}

- (BDPowerLogCPUMetrics *_Nullable)collect {
    if (!self.cpuMetrics) {
        self.cpuMetrics = [self _collect];
        return nil;
    }
    BDPowerLogCPUMetrics *pre = self.cpuMetrics;
    BDPowerLogCPUMetrics *current = [self _collect];
    
    long long delta_time = current.sys_ts - pre.sys_ts;
    long long delta_cpu_time = current.cpu_time - pre.cpu_time;

    current.delta_time = delta_time;
    current.delta_cpu_time = delta_cpu_time;
    current.cpu_usage = delta_time>0?(((double)delta_cpu_time/delta_time)*100):0;
    
    long long device_delta_total_cpu_ticks = current.device_total_cpu_ticks - pre.device_total_cpu_ticks;
    long long device_delta_running_cpu_ticks = current.device_running_cpu_ticks - pre.device_running_cpu_ticks;
    current.device_delta_running_cpu_ticks= device_delta_running_cpu_ticks;
    current.device_delta_total_cpu_ticks = device_delta_total_cpu_ticks;
    if (device_delta_total_cpu_ticks > 0) {
        current.device_cpu_usage = (device_delta_running_cpu_ticks * 100.0)/device_delta_total_cpu_ticks;
    }
    
    long long delta_webkit_time = current.webkit_time - pre.webkit_time;
    long long delta_webkit_cpu_time = current.webkit_cpu_time - pre.webkit_cpu_time;
    if (delta_webkit_cpu_time < 0)
        delta_webkit_cpu_time = 0;

    current.delta_webkit_time = delta_webkit_time;
    current.delta_webkit_cpu_time = delta_webkit_cpu_time;
    current.webkit_cpu_usage = delta_webkit_time > 0 ? (delta_webkit_cpu_time * 100.0)/delta_webkit_time : 0;
    
    self.cpuMetrics = current;
    return current;
}

@end
