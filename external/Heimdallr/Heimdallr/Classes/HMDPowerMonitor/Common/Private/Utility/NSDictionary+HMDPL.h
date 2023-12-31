//
//  NSDictionary+BDPL.h
//  Jato
//
//  Created by ByteDance on 2022/10/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (HMDPL)

@property (nonatomic, assign, readonly) long long hmd_ts;

@property (nonatomic, assign, readonly) long long hmd_sys_ts;

@property (nonatomic, assign, readonly) long long hmd_delta_time;

@property (nonatomic, assign, readonly) long long hmd_start_sys_ts;

@property (nonatomic, assign, readonly) long long hmd_end_sys_ts;

/*
@property (nonatomic, assign, readonly) long long hmd_start_ts;

@property (nonatomic, assign, readonly) long long hmd_end_ts;

@property (nonatomic, assign, readonly) int hmd_battery_level;

@property (nonatomic, copy, readonly) NSString *hmd_power_mode;

@property (nonatomic, copy, readonly) NSString *hmd_battery_state;

@property (nonatomic, copy, readonly) NSString *hmd_thermal_state;

@property (nonatomic, copy, readonly) NSString *hmd_app_state;

@property (nonatomic, assign, readonly) BOOL hmd_isForeground;

@property (nonatomic, assign, readonly) int hmd_brightness;

@property (nonatomic, copy, readonly) NSString *hmd_net_type;

@property (nonatomic, copy, readonly) NSString *hmd_scene;

@property (nonatomic, copy, readonly) NSString *hmd_subscene;

@property (nonatomic, assign, readonly) double hmd_cpu_usage;

@property (nonatomic, assign, readonly) double hmd_device_total_cpu_usage;
*/

- (id)hmdpl_objectForKey:(id<NSCopying>)key;

- (id)hmdpl_objectForKey:(id<NSCopying>)key cls:(Class)cls;

@end

@interface NSMutableDictionary (HMDPL)

@property (nonatomic, assign) long long hmd_ts;

@property (nonatomic, assign) long long hmd_sys_ts;

@property (nonatomic, assign) long long hmd_delta_time;

- (void)hmdpl_setObject:(id)object forKey:(id<NSCopying>)key;

@end

/*
@interface NSDictionary (HMDPLCPU)

@property (nonatomic, assign, readonly) double hmd_cpu_usage;

@property (nonatomic, assign, readonly) long long hmd_delta_cpu_time;

@property (nonatomic, assign, readonly) double hmd_device_total_cpu_usage;

@property (nonatomic, assign, readonly) long long hmd_delta_device_cpu_time;

@end
*/

NS_ASSUME_NONNULL_END
