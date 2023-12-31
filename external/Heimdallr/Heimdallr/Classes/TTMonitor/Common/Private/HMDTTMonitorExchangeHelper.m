//
//  HMDTTMonitorExchangeHelper.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 20/5/2022.
//

#include <stdatomic.h>
#include "HMDMacro.h"
#import "HMDTTMonitorExchangeHelper.h"
#import "HMDTTMonitor.h"
#import "HMDTTMonitorTracker.h"
#import "HMDInjectedInfo.h"
#import <objc/runtime.h>
#import "HMDSwizzle.h"
#import "HMDALogProtocol.h"

static atomic_bool globalIsSwizzled = NO;

@interface HMDTTMonitor()
@property (nonatomic, strong) HMDTTMonitorTracker *tracker;
@end

@implementation HMDTTMonitorExchangeHelper

static void hmd_swizzle_instance_method_with_method_from_class(Class oriCls, SEL originalSelector, Class targetCls, SEL targetSelector) {
    // In some version of TTMonitor method may not exist
    if(!class_respondsToSelector(oriCls, originalSelector)) return;
    
    IMP swizzledIMP = class_getMethodImplementation(targetCls, targetSelector);
    hmd_swizzle_instance_method_with_imp(oriCls, originalSelector, targetSelector, swizzledIMP);
}

static bool hmd_swizzle_instance_method_if_original_method_exist(Class cls, SEL originalSelector, SEL swizzledSelector) {
    // In some version of TTMonitor method may not exist
    if(!class_respondsToSelector(cls, originalSelector)) return true;
    
    return hmd_swizzle_instance_method(cls, originalSelector, swizzledSelector);
}

+ (BOOL)isSwizzled {
    return globalIsSwizzled;
}

+ (void)setIsSwizzled:(BOOL)isSwizzled {
    globalIsSwizzled = isSwizzled;
}

+ (NSLock *)globalLock {
    static dispatch_once_t onceToken;
    static NSLock *ttLock;
    dispatch_once(&onceToken, ^{
        ttLock = [NSLock new];
    });
    return ttLock;
}

+ (void)exchangeTTMonitorInterfaceIfNeeded:(NSNumber *)needHook {
    [self.globalLock lock];
    
    if (needHook.boolValue && !self.isSwizzled) {
        [self startExchangeTTMonitor];
    } else if (!needHook.boolValue && self.isSwizzled) {
        [self closeExchangeTTMonitor];
    }
    
    [self.globalLock unlock];
}

+ (void)startExchangeTTMonitor {
    NSString *originalClassString = @"TTMonitor";
    Class originalClass = NSClassFromString(originalClassString);
    
    // if there is no TTMonitor class, return
    if (!originalClass) return;
    
    if(globalIsSwizzled) return;
    globalIsSwizzled = true;
    
    Class swizzledClass = HMDTTMonitorExchangeHelper.class;

    if(originalClass != nil && swizzledClass != nil) {
    hmd_swizzle_instance_method_with_method_from_class(originalClass, NSSelectorFromString(@"trackService:status:extra:"), swizzledClass, NSSelectorFromString(@"hmdTrackService:status:extra:"));
    hmd_swizzle_instance_method_with_method_from_class(originalClass, NSSelectorFromString(@"trackService:value:extra:"), swizzledClass, NSSelectorFromString(@"hmdTrackService:value:extra:"));
    hmd_swizzle_instance_method_with_method_from_class(originalClass, NSSelectorFromString(@"trackService:attributes:"), swizzledClass, NSSelectorFromString(@"hmdTrackService:attributes:"));
    hmd_swizzle_instance_method_with_method_from_class(originalClass, NSSelectorFromString(@"trackData:type:"), swizzledClass, NSSelectorFromString(@"hmdTrackData:type:"));
    hmd_swizzle_instance_method_with_method_from_class(originalClass, NSSelectorFromString(@"trackData:logTypeStr:"), swizzledClass, NSSelectorFromString(@"hmdTrackData:logTypeStr:"));
    }
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor start exchange TTMonitor, appID : %@", [HMDInjectedInfo defaultInfo].appID);
}

+ (void)closeExchangeTTMonitor {
    NSString *classString = @"TTMonitor";
    Class TTMonitorClass = NSClassFromString(classString);
    
    // if there is no TTMonitor class, return
    if (!TTMonitorClass) return;
    
    if(!globalIsSwizzled) return;
    globalIsSwizzled = false;
    
    if(TTMonitorClass != nil) {
        hmd_swizzle_instance_method_if_original_method_exist(TTMonitorClass, NSSelectorFromString(@"trackData:type:"), NSSelectorFromString(@"hmdTrackData:type:"));
        hmd_swizzle_instance_method_if_original_method_exist(TTMonitorClass, NSSelectorFromString(@"trackData:logTypeStr:"), NSSelectorFromString(@"hmdTrackData:logTypeStr:"));
        hmd_swizzle_instance_method_if_original_method_exist(TTMonitorClass, NSSelectorFromString(@"trackService:attributes:"), NSSelectorFromString(@"hmdTrackService:attributes:"));
        hmd_swizzle_instance_method_if_original_method_exist(TTMonitorClass, NSSelectorFromString(@"trackService:status:extra:"), NSSelectorFromString(@"hmdTrackService:status:extra:"));
        hmd_swizzle_instance_method_if_original_method_exist(TTMonitorClass, NSSelectorFromString(@"trackService:value:extra:"), NSSelectorFromString(@"hmdTrackService:value:extra:"));
    }
    HMDALOG_PROTOCOL_INFO_TAG(@"HMDEventTrace", @"HMDTTMonitor close exchange TTMonitor, appID : %@", [HMDInjectedInfo defaultInfo].appID);
}


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)hmdTrackService:(nonnull NSString *)serviceName value:(nullable id)value extra:(nullable NSDictionary *)extraValue {
    if([extraValue isKindOfClass:NSMutableDictionary.class]) extraValue = [extraValue copy];
    //hook的实现要完全和TTMonitor对齐
    if (![value isKindOfClass:[NSDictionary class]] && [extraValue isKindOfClass:[NSDictionary class]] && extraValue.count > 0 && [NSJSONSerialization isValidJSONObject:extraValue]) {
        NSMutableDictionary *valueDict = [NSMutableDictionary dictionaryWithDictionary:extraValue];
        [valueDict setValue:value forKey:@"value"];
        value = valueDict;
        extraValue = nil;
    }
    [[HMDTTMonitor defaultManager] hmdTrackService:serviceName value:value extra:extraValue];
}

- (void)hmdTrackService:(nonnull NSString *)serviceName status:(NSInteger)status extra:(nullable NSDictionary *)extraValue {
    [[HMDTTMonitor defaultManager] hmdTrackService:serviceName status:status extra:extraValue];
}

- (void)hmdTrackService:(nonnull NSString *)serviceName attributes:(nullable NSDictionary *)attributes {
    [[HMDTTMonitor defaultManager] hmdTrackService:serviceName attributes:attributes];
}

- (void)hmdTrackData:(nullable NSDictionary *)data type:(HMDTTMonitorTrackerType)type {
    [[HMDTTMonitor defaultManager] hmdTrackData:data type:type];
}

- (void)hmdTrackData:(nullable NSDictionary *)data logTypeStr:(nonnull NSString *)logType {
    [[HMDTTMonitor defaultManager] hmdTrackData:data logTypeStr:logType];
}

#pragma clang diagnostic pop

@end
