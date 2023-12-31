//
//  BDImageMonitorManager.m
//  BDWebImage
//
//  Created by fengyadong on 2017/12/6.
//

#import "BDImageMonitorManager.h"
#if __has_include("BDBaseInternal.h")
#import <BDAlogProtocol/BDAlogProtocol.h>
#endif
#import "BDWebImageManager.h"

@implementation BDImageMonitorManager

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

// 如果项目中有集成TTMonitor则优先用TTMonitor上报，因为TTMonitor埋点能通过开关控制被Heimdallr上报，反之不行
+ (void)trackData:(NSDictionary *)data logTypeStr:(NSString *)logType {
    Class hmdClass = NSClassFromString(@"HMDTTMonitor");
    if (hmdClass != nil) {
        // 使用宏来区分当前运行的是 simulator 还是真机，由于 simulator 没有appID，如果调用 defaultManager 会抛出异常
#if TARGET_IPHONE_SIMULATOR
        if ([hmdClass respondsToSelector:@selector(initMonitorWithAppID:injectedInfo:)]) {
                    id instance = [hmdClass performSelector:@selector(initMonitorWithAppID:injectedInfo:)];
#elif TARGET_OS_IPHONE
                if ([hmdClass respondsToSelector:@selector(defaultManager)]) {
                    id instance = [hmdClass performSelector:@selector(defaultManager)];
#endif
            if ([instance respondsToSelector:@selector(hmdTrackData:logTypeStr:)]) {
                @try {
                    [instance performSelector:@selector(hmdTrackData:logTypeStr:) withObject:data withObject:logType];
                } @catch (NSException *exception) {
#if __has_include("BDBaseInternal.h")
                    BDALOG_PROTOCOL_ERROR_TAG(@"BDWebImage", @"HMDTTMonitor report function error:%@", exception.reason);
#elif __has_include("BDBaseToB.h")
                    NSLog(@"[BDWebImageToB] HMDTTMonitor report function error:%@", exception.reason);
#endif
                }
            }
        }
    }
}

+ (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(NSDictionary *)extraValue {
    Class hmdClass = NSClassFromString(@"HMDTTMonitor");
    if (hmdClass != nil) {
#if TARGET_IPHONE_SIMULATOR
         if ([hmdClass respondsToSelector:@selector(initMonitorWithAppID:injectedInfo:)]) {
             id instance = [hmdClass performSelector:@selector(initMonitorWithAppID:injectedInfo:)];
#elif TARGET_OS_IPHONE
         if ([hmdClass respondsToSelector:@selector(defaultManager)]) {
             id instance = [hmdClass performSelector:@selector(defaultManager)];
#endif
            SEL selector = @selector(hmdTrackService:status:extra:);
            if ([instance respondsToSelector:selector]) {
                @try {
                    NSMethodSignature *signature = [instance methodSignatureForSelector:selector];
                    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                    [invocation setTarget:instance];
                    [invocation setSelector:selector];
                    [invocation setArgument:&serviceName atIndex:2];
                    [invocation setArgument:&status atIndex:3];
                    [invocation setArgument:&extraValue atIndex:4];
                    [invocation invoke];
                } @catch (NSException *exception) {
#if __has_include("BDBaseInternal.h")
                    BDALOG_PROTOCOL_ERROR_TAG(@"BDWebImage", @"HMDTTMonitor report function error:%@", exception.reason);
#elif __has_include("BDBaseToB.h")
                    NSLog(@"[BDWebImageToB] HMDTTMonitor report function error:%@", exception.reason);
#endif
                }
            }
        }
    }
}

+ (void)trackService:(NSString *)serviceName metric:(NSDictionary <NSString *, NSNumber *> *)metric category:(NSDictionary *)category extra:(NSDictionary *)extraValue {
    Class hmdClass = NSClassFromString(@"HMDTTMonitor");
    if (hmdClass != nil) {
#if TARGET_IPHONE_SIMULATOR
        if ([hmdClass respondsToSelector:@selector(initMonitorWithAppID:injectedInfo:)]) {
            id instance = [hmdClass performSelector:@selector(initMonitorWithAppID:injectedInfo:)];
#elif TARGET_OS_IPHONE
        if ([hmdClass respondsToSelector:@selector(defaultManager)]) {
            id instance = [hmdClass performSelector:@selector(defaultManager)];
#endif
            SEL selector = @selector(hmdTrackService:metric:category:extra:);
            if ([instance respondsToSelector:selector]) {
                @try {
                    NSMethodSignature *signature = [instance methodSignatureForSelector:selector];
                    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
                    [invocation setTarget:instance];
                    [invocation setSelector:selector];
                    [invocation setArgument:&serviceName atIndex:2];
                    [invocation setArgument:&metric atIndex:3];
                    [invocation setArgument:&category atIndex:4];
                    [invocation setArgument:&extraValue atIndex:5];
                    [invocation invoke];
                } @catch (NSException *exception) {
#if __has_include("BDBaseInternal.h")
                    BDALOG_PROTOCOL_ERROR_TAG(@"BDWebImage", @"HMDTTMonitor report function error:%@", exception.reason);
#elif __has_include("BDBaseToB.h")
                    NSLog(@"[BDWebImageToB] HMDTTMonitor report function error:%@", exception.reason);
#endif
                }
            }
        }
    }
}

#pragma clang diagnostic pop


@end
