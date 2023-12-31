//
//  NSDictionary+BDPL.m
//  Jato
//
//  Created by ByteDance on 2022/10/10.
//

#import "NSDictionary+BDPL.h"

@implementation NSDictionary (BDPL)

- (long long)ts {
    return [[self objectForKey:@"ts"] longLongValue];
}

- (long long)sys_ts {
    return [[self objectForKey:@"sys_ts"] longLongValue];
}

- (long long)delta_time {
    return [[self objectForKey:@"delta_time"] longLongValue];
}

- (long long)start_sys_ts {
    return self.sys_ts - self.delta_time;
}

- (long long)end_sys_ts {
    return self.sys_ts;
}

- (long long)start_ts {
    return self.ts - self.delta_time;
}

- (long long)end_ts {
    return self.ts;
}

- (int)battery_level {
    return [[self bdpl_objectForKey:@"value" cls:NSNumber.class] intValue];
}

- (NSString *)power_mode {
    return [self bdpl_objectForKey:@"state" cls:NSString.class];
}

- (NSString *)battery_state {
    return [self bdpl_objectForKey:@"state" cls:NSString.class];
}

- (NSString *)thermal_state {
    return [self bdpl_objectForKey:@"state" cls:NSString.class];
}

- (NSString *)app_state {
    return [self bdpl_objectForKey:@"state" cls:NSString.class];
}

- (BOOL)isForeground {
    return [[self app_state] isEqualToString:@"foreground"];
}

- (int)brightness {
    return [[self bdpl_objectForKey:@"value" cls:NSNumber.class] intValue];
}

- (NSString *)net_type {
    return [self bdpl_objectForKey:@"state" cls:NSString.class];
}

- (NSString *)scene {
    return [self bdpl_objectForKey:@"scene" cls:NSString.class];
}

- (NSString *)subscene {
    return [self bdpl_objectForKey:@"subscene" cls:NSString.class];
}

- (id)bdpl_objectForKey:(id<NSCopying>)key {
    if (key) {
        return [self objectForKey:key];
    }
    return nil;
}

- (id)bdpl_objectForKey:(id<NSCopying>)key cls:(Class)cls {
    id obj = [self bdpl_objectForKey:key];
    if ([obj isKindOfClass:cls]) {
        return obj;
    }
    return nil;
}

@end

@implementation NSMutableDictionary (BDPL)

- (void)setTs:(long long)ts {
    [self setValue:@(ts) forKey:@"ts"];
}

- (void)setSys_ts:(long long)sys_ts {
    [self setValue:@(sys_ts) forKey:@"sys_ts"];
}

- (void)setDelta_time:(long long)delta_time {
    [self setValue:@(delta_time) forKey:@"delta_time"];
}

- (void)bdpl_setObject:(id)object forKey:(id<NSCopying>)key {
    if (key) {
        if (object) {
            [self setObject:object forKey:key];
        } else {
            [self removeObjectForKey:key];
        }
    }
}

@end

@implementation NSDictionary (BDPLCPU)

- (double)cpu_usage {
    return [[self bdpl_objectForKey:@"cpu_usage" cls:NSNumber.class] doubleValue];
}

- (double)device_total_cpu_usage {
    return [[self bdpl_objectForKey:@"device_total_cpu_usage" cls:NSNumber.class] doubleValue];
}

- (long long)delta_cpu_time {
    return (long long)(self.delta_time * self.cpu_usage/100);
}

- (long long)delta_device_cpu_time {
    return (long long)(self.delta_time * self.device_total_cpu_usage/100);
}

@end
