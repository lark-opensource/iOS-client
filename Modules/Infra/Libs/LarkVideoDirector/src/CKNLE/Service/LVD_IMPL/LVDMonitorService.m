//
//  LVDMonitorService.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/20.
//

#import "LVDMonitorService.h"
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation LVDMonitorService

+ (void)trackService:(nullable NSString *)serviceName attributes:(nullable NSDictionary *)attributes {
    [LVDCameraMonitor trackWithEvent:serviceName params:attributes];
}

+ (void)trackService:(nullable NSString *)serviceName status:(NSInteger)status extra:(nullable NSDictionary *)extraValue {
    [LVDCameraMonitor trackWithEvent:serviceName params:extraValue];
}

+ (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(NSDictionary *)extraValue extraParamsOption:(TTMonitorExtraParamsOption)option {
    [LVDCameraMonitor trackWithEvent:serviceName params:extraValue];
}

+ (void)startTimingForKey:(nonnull id<NSCopying>)key {
}

+ (BOOL)endTimingForKey:(nonnull id<NSCopying>)key service:(nullable NSString *)service label:(nullable NSString *)label {
    return YES;
}

+ (BOOL)endTimingForKey:(nonnull id<NSCopying>)key service:(nullable NSString *)service label:(nullable NSString *)label duration:(nullable NSTimeInterval *)duration {
    return YES;
}

+ (void)cancelTimingForKey:(nonnull id<NSCopying>)key {
}

+ (void)trackService:(nullable NSString *)serviceName floatValue:(float)value extra:(nullable NSDictionary *)extraValue {
    [LVDCameraMonitor trackWithEvent:serviceName params:extraValue];
}

+ (void)trackData:(nullable NSDictionary *)data logTypeStr:(nullable NSString *)logType {
    [LVDCameraMonitor trackWithEvent:logType params:data];
}

+ (NSTimeInterval)timeIntervalForKey:(nonnull id<NSCopying>)key {
    return 0;
}

@end
