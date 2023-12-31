//
//  NSDictionary+BDPL.h
//  Jato
//
//  Created by ByteDance on 2022/10/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (BDPL)

@property (nonatomic, assign, readonly) long long ts;

@property (nonatomic, assign, readonly) long long sys_ts;

@property (nonatomic, assign, readonly) long long delta_time;

@property (nonatomic, assign, readonly) long long start_sys_ts;

@property (nonatomic, assign, readonly) long long end_sys_ts;

@property (nonatomic, assign, readonly) long long start_ts;

@property (nonatomic, assign, readonly) long long end_ts;

@property (nonatomic, assign, readonly) int battery_level;

@property (nonatomic, copy, readonly) NSString *power_mode;

@property (nonatomic, copy, readonly) NSString * battery_state;

@property (nonatomic, copy, readonly) NSString * thermal_state;

@property (nonatomic, copy, readonly) NSString * app_state;

@property (nonatomic, assign, readonly) BOOL isForeground;

@property (nonatomic, assign, readonly) int brightness;

@property (nonatomic, copy, readonly) NSString * net_type;

@property (nonatomic, copy, readonly) NSString * scene;

@property (nonatomic, copy, readonly) NSString * subscene;

@property (nonatomic, assign, readonly) double cpu_usage;

@property (nonatomic, assign, readonly) double device_total_cpu_usage;

- (id)bdpl_objectForKey:(id<NSCopying>)key;

- (id)bdpl_objectForKey:(id<NSCopying>)key cls:(Class)cls;

@end

@interface NSMutableDictionary (BDPL)

@property (nonatomic, assign) long long ts;

@property (nonatomic, assign) long long sys_ts;

@property (nonatomic, assign) long long delta_time;

- (void)bdpl_setObject:(id)object forKey:(id<NSCopying>)key;

@end

@interface NSDictionary (BDPLCPU)

@property (nonatomic, assign, readonly) double cpu_usage;

@property (nonatomic, assign, readonly) long long delta_cpu_time;

@property (nonatomic, assign, readonly) double device_total_cpu_usage;

@property (nonatomic, assign, readonly) long long delta_device_cpu_time;

@end


NS_ASSUME_NONNULL_END
