//
//  BDPowerLogHighPowerEvent.m
//  Alamofire
//
//  Created by ByteDance on 2022/11/15.
//

#import "BDPowerLogHighPowerEvent.h"
#import "BDPowerLogCPUMetrics.h"
#import "NSDictionary+BDPL.h"
@interface BDPowerLogHighPowerEvent()
@end

@implementation BDPowerLogHighPowerEvent

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)addCPUMetrics:(NSDictionary *)data {
    if (data) {
        self.total_cpu_time += (int)data.delta_cpu_time;
        self.total_time += (int)data.delta_time;
        self.total_device_cpu_time += (int)(data.delta_device_cpu_time);
        
        if (self.start_time <= 0) {
            self.start_time = data.start_ts;
        } else {
            self.start_time = MIN(self.start_time, data.start_ts);
        }
        if (self.end_time <= 0) {
            self.end_time = data.end_ts;
        } else {
            self.end_time = MAX(self.end_time, data.end_ts);
        }
    }
}

- (void)addCPUMetricsArray:(NSArray *)cpuMetricsArray {
    for (BDPowerLogCPUMetrics *metrics in cpuMetricsArray) {
        [self addCPUMetrics:metrics];
    }
}

- (NSDictionary *)uploadLog {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    long long cpu_time = self.total_cpu_time;
    long long time = self.total_time;

    [dict setValue:@(time) forKey:@"total_time"];
    
    [dict setValue:@(cpu_time) forKey:@"app_cpu_time"];

    double app_cpu_usage = self.appCPUUsage;
    [dict setValue:@(app_cpu_usage) forKey:@"app_cpu_usage"];
    [dict setValue:@(self.config.appTimeWindow * 1000) forKey:@"app_time_window"];
    [dict setValue:@(self.config.appCPUTimeThreshold * 1000) forKey:@"app_cpu_time_threshold"];
    [dict setValue:@(self.config.appTimeWindowMax * 1000) forKey:@"app_time_window_max"];

    double device_cpu_usage = self.deviceCPUUsage;
    [dict setValue:@(device_cpu_usage) forKey:@"device_cpu_usage"];
    [dict setValue:@(self.config.deviceTimeWindow * 1000) forKey:@"device_time_window"];
    [dict setValue:@(self.config.deviceCPUTimeThreshold * 1000) forKey:@"device_cpu_time_threshold"];
    [dict setValue:@(self.config.deviceTimeWindowMax * 1000) forKey:@"device_time_window_max"];
    
    [dict setValue:@(self.isForeground?1:0) forKey:@"foreground"];
    [dict setValue:self.scene forKey:@"scene"];
    [dict setValue:self.subscene forKey:@"subscene"];
    [dict setValue:self.thermalState forKey:@"thermal_state"];
    [dict setValue:self.powerMode forKey:@"power_mode"];
    [dict setValue:self.batteryState forKey:@"battery_state"];
    [dict setValue:self.enterReason forKey:@"enter_reason"];
    [dict setValue:self.quitReason forKey:@"quit_reason"];
    [dict setValue:@(self.peakThreadCount) forKey:@"peak_thread_count"];
    NSString *high_power_reason = nil;
    double app_cpu_usage_threshold = self.config.appTimeWindow>0?(self.config.appCPUTimeThreshold * 100.0/self.config.appTimeWindow):0;
    if (app_cpu_usage >= app_cpu_usage_threshold) {
        high_power_reason = @"app_cpu_usage";
    } else {
        double device_cpu_usage_threshold = self.config.deviceTimeWindow>0?(self.config.deviceCPUTimeThreshold * 100.0/self.config.deviceTimeWindow):0;
        if (device_cpu_usage >= device_cpu_usage_threshold) {
            high_power_reason = @"device_cpu_usage";
        }
    }
    
    if (high_power_reason == nil) {
        high_power_reason = self.enterReason;
    }
    
    [dict setValue:high_power_reason forKey:@"high_power_reason"];
    
    int batteryLevelCost = self.startBatteryLevel - self.endBatteryLevel;
    [dict setValue:@(batteryLevelCost) forKey:@"battery_level_cost"];
    if (time > 0) {
        [dict setValue:@(batteryLevelCost/time) forKey:@"battery_level_cost_speed"];
    }
    
    if (self.stackUUID.length > 0) {
        [dict setValue:self.stackUUID forKey:@"stack_uuid"];
    }

    [dict setValue:@(self.start_time) forKey:@"start_time"];

    [dict setValue:@(self.end_time) forKey:@"end_time"];

    [dict setValue:@"cpu" forKey:@"high_power_type"];

    return dict;
}

- (double)appCPUUsage {
    long long cpu_time = self.total_cpu_time;
    long long time = self.total_time;
    double app_cpu_usage = time>0?(cpu_time*100.0/time):0;
    return app_cpu_usage;
}

- (double)deviceCPUUsage {
    long long cpu_time = self.total_device_cpu_time;
    long long total_time = self.total_time;
    double device_cpu_usage = total_time>0?(cpu_time*100.0/total_time):0;
    return device_cpu_usage;
}

@end
