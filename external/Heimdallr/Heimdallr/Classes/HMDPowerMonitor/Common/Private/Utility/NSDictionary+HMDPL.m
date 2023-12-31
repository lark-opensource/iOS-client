//
//  NSDictionary+HMDPL.m
//  Jato
//
//  Created by ByteDance on 2022/10/10.
//

#import "NSDictionary+HMDPL.h"

@implementation NSDictionary (HMDPL)

- (long long)hmd_ts {
    return [[self objectForKey:@"ts"] longLongValue];
}

- (long long)hmd_sys_ts {
    return [[self objectForKey:@"sys_ts"] longLongValue];
}

- (long long)hmd_delta_time {
    return [[self objectForKey:@"delta_time"] longLongValue];
}

- (long long)hmd_start_sys_ts {
    return self.hmd_sys_ts - self.hmd_delta_time;
}

- (long long)hmd_end_sys_ts {
    return self.hmd_sys_ts;
}

/*
- (long long)hmd_start_ts {
    return self.hmd_ts - self.hmd_delta_time;
}

- (long long)hmd_end_ts {
    return self.hmd_ts;
}

- (int)hmd_battery_level {
    return [[self hmdpl_objectForKey:@"value" cls:NSNumber.class] intValue];
}

- (NSString *)hmd_power_mode {
    return [self hmdpl_objectForKey:@"state" cls:NSString.class];
}

- (NSString *)hmd_battery_state {
    return [self hmdpl_objectForKey:@"state" cls:NSString.class];
}

- (NSString *)hmd_thermal_state {
    return [self hmdpl_objectForKey:@"state" cls:NSString.class];
}

- (NSString *)hmd_app_state {
    return [self hmdpl_objectForKey:@"state" cls:NSString.class];
}

- (BOOL)hmd_isForeground {
    return [[self hmd_app_state] isEqualToString:@"foreground"];
}

- (int)hmd_brightness {
    return [[self hmdpl_objectForKey:@"value" cls:NSNumber.class] intValue];
}

- (NSString *)hmd_net_type {
    return [self hmdpl_objectForKey:@"state" cls:NSString.class];
}

- (NSString *)hmd_scene {
    return [self hmdpl_objectForKey:@"scene" cls:NSString.class];
}

- (NSString *)hmd_subscene {
    return [self hmdpl_objectForKey:@"subscene" cls:NSString.class];
}
*/

- (id)hmdpl_objectForKey:(id<NSCopying>)key {
    if (key) {
        return [self objectForKey:key];
    }
    return nil;
}

- (id)hmdpl_objectForKey:(id<NSCopying>)key cls:(Class)cls {
    id obj = [self hmdpl_objectForKey:key];
    if ([obj isKindOfClass:cls]) {
        return obj;
    }
    return nil;
}

@end

@implementation NSMutableDictionary (HMDPL)

- (void)setHmd_ts:(long long)ts {
    [self setValue:@(ts) forKey:@"ts"];
}

- (void)setHmd_sys_ts:(long long)sys_ts {
    [self setValue:@(sys_ts) forKey:@"sys_ts"];
}

- (void)setHmd_delta_time:(long long)delta_time {
    [self setValue:@(delta_time) forKey:@"delta_time"];
}

- (void)hmdpl_setObject:(id)object forKey:(id<NSCopying>)key {
    if (key) {
        if (object) {
            [self setObject:object forKey:key];
        } else {
            [self removeObjectForKey:key];
        }
    }
}

@end

/*
@implementation NSDictionary (HMDPLCPU)

- (double)hmd_cpu_usage {
    return [[self hmdpl_objectForKey:@"cpu_usage" cls:NSNumber.class] doubleValue];
}

- (double)hmd_device_total_cpu_usage {
    return [[self hmdpl_objectForKey:@"device_total_cpu_usage" cls:NSNumber.class] doubleValue];
}

- (long long)hmd_delta_cpu_time {
    return (long long)(self.hmd_delta_time * self.hmd_cpu_usage/100);
}

- (long long)hmd_delta_device_cpu_time {
    return (long long)(self.hmd_delta_time * self.hmd_device_total_cpu_usage/100);
}

@end
*/
