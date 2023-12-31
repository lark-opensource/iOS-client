//
//  BDPowerLogCPUMetrics.h
//  Jato
//
//  Created by ByteDance on 2022/11/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogCPUMetrics : NSObject

@property (nonatomic, assign) long long timestamp;

@property (nonatomic, assign) long long sys_ts;

@property (nonatomic, assign) long long cpu_time;

@property (nonatomic, assign) long long delta_time;

@property (nonatomic, assign) long long delta_cpu_time;

@property (nonatomic, assign) double cpu_usage;

@property (nonatomic, assign) double instant_cpu_usage;

@property (nonatomic, assign) long long device_running_cpu_ticks;

@property (nonatomic, assign) long long device_total_cpu_ticks;

@property (nonatomic, assign) long long device_delta_running_cpu_ticks;

@property (nonatomic, assign) long long device_delta_total_cpu_ticks;

@property (nonatomic, assign) double device_cpu_usage;

@property (nonatomic, assign) int num_of_active_cores;

@property (nonatomic, assign) long long webkit_cpu_time;

@property (nonatomic, assign) long long webkit_time;

@property (nonatomic, assign) long long delta_webkit_cpu_time;

@property (nonatomic, assign) long long delta_webkit_time;

@property (nonatomic, assign) double webkit_cpu_usage;

- (NSDictionary *)eventDict;

@end

NS_ASSUME_NONNULL_END
