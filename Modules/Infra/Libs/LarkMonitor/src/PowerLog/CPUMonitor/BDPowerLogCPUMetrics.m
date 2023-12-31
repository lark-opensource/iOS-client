//
//  BDPowerLogCPUMetrics.m
//  Jato
//
//  Created by ByteDance on 2022/11/15.
//

#import "BDPowerLogCPUMetrics.h"
#import "BDPowerLogUtility.h"
@implementation BDPowerLogCPUMetrics

- (NSDictionary *)eventDict {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@(self.timestamp) forKey:@"ts"];
    [dict setValue:@(self.sys_ts) forKey:@"sys_ts"];
    [dict setValue:@(self.delta_time) forKey:@"delta_time"];
    [dict setValue:@(self.cpu_usage) forKey:@"cpu_usage"];
    [dict setValue:@(self.instant_cpu_usage) forKey:@"instant_cpu_usage"];
    [dict setValue:@(self.device_cpu_usage * _num_of_active_cores) forKey:@"device_total_cpu_usage"];
    if (self.webkit_cpu_usage > 0) {
        [dict setValue:@(self.webkit_cpu_usage) forKey:@"webkit_cpu_usage"];
    }
    return dict;
}

@end
