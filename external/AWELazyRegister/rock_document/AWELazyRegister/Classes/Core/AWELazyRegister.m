//
//  AWELazyRegister.m
//  AWELazyRegister 
//
//  Created by liqingyao on 2019/11/4.
//  Copyright © 2019 liqingyao. All rights reserved.
//

#import "AWELazyRegister.h"
#include <dlfcn.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#import <QuartzCore/QuartzCore.h>

#define AWE_CALCULATE_DURATION(end, start) (floor((end-start)*1000000))

@interface AWELazyRegisterHandler : NSObject

@property (nonatomic, strong) NSValue *handlerPointer;
@property (nonatomic, assign) BOOL registed;

@end

@implementation AWELazyRegisterHandler

@end

typedef NSMutableArray<NSString *> *AWELazyRegisterHeaderInfo;
typedef NSMutableDictionary<NSString *, AWELazyRegisterHandler *> *AWELazyRegisterSectionInfo;
typedef NSMutableDictionary<NSString *, AWELazyRegisterSectionInfo> *AWELazyRegisterSegmentInfo;

static AWELazyRegisterHeaderInfo moduleNames;
static AWELazyRegisterSegmentInfo moduleDataMap;
static BOOL kAWELazyRegisterLogOpen = NO;

static void cacheSegmentInfo(const struct mach_header* mhp, intptr_t slide)  __attribute__((no_sanitize("address")))
{
    Dl_info info;
    if (dladdr(mhp, &info) == 0) {
        return;
    }
    
    if (!moduleDataMap) {
        moduleDataMap = [NSMutableDictionary dictionary];
    }
    
#ifndef __LP64__
    const struct mach_header *machOHeader = (void*)mhp;
#else
    const struct mach_header_64 *machOHeader = (void*)mhp;
#endif
    unsigned long size = 0;
    
#if DEBUG
    CFTimeInterval start = CACurrentMediaTime();
#endif
    uintptr_t *regdata = (uintptr_t *)getsectiondata(machOHeader, AWELazyRegisterSegment, AWELazyRegisterData, &size);
    if (regdata && size > 0) {
        unsigned long count = size / sizeof(lazy_register_info2);
        lazy_register_info2 *lazyRegisterInfo = (lazy_register_info2 *)regdata;
        for (int index = 0; index < count; index ++) {
            lazy_register_info2 info = lazyRegisterInfo[index];
            NSString *module = nil;
            NSString *key = nil;
#if __has_feature(address_sanitizer)
            // module
            if (info.module != nil) {
                NSString *value = [NSString stringWithUTF8String:info.module];
                if (value != nil) {
                    module = value;
                } else {
                    continue;
                }
            } else {
                continue;
            }
            // info
            if (info.key != nil) {
                NSString *value = [NSString stringWithUTF8String:info.key];
                if (value != nil) {
                    key = value;
                } else {
                    continue;
                }
            } else {
                continue;
            }
#else
            module = [NSString stringWithUTF8String:info.module];
            key = [NSString stringWithUTF8String:info.key];
#endif
            AWELazyRegisterSectionInfo sectionInfo = [moduleDataMap objectForKey:module];
            if (!sectionInfo) {
                sectionInfo = [NSMutableDictionary dictionary];
                [moduleDataMap setObject:sectionInfo forKey:module];
            }
#if DEBUG
            if ([sectionInfo objectForKey:key]) {
                if (![[NSValue valueWithPointer:info.func] isEqualToValue:sectionInfo[key].handlerPointer]) {
                    NSLog(@"AWELazyRegister:1: duplicated register key %@ for %@, %@/%@", key, module, [NSValue valueWithPointer:info.func], sectionInfo[key].handlerPointer);
                }
            }
#endif
            register_entry func = info.func;
            AWELazyRegisterHandler *handler = [[AWELazyRegisterHandler alloc] init];
            handler.registed = NO;
            handler.handlerPointer = [NSValue valueWithPointer:func];
            [sectionInfo setObject:handler forKey:key];
        }
    }
    
    // backward compatible
    if (!moduleNames) {
        moduleNames = [NSMutableArray array];
    }
    
    uintptr_t *headdata = (uintptr_t *)getsectiondata(machOHeader, AWELazyRegisterSegment, AWELazyRegisterHeader, &size);
    if (headdata && size > 0) {
        unsigned long count = size / sizeof(lazy_register_module_info);
        lazy_register_module_info *moduleInfo = (lazy_register_module_info *)headdata;
        for (int index = 0; index < count; index ++) {
            lazy_register_module_info info = moduleInfo[index];
#if __has_feature(address_sanitizer)
            if (info.module != nil) {
                NSString *module = [NSString stringWithUTF8String:info.module];
                if (module != nil) {
                    [moduleNames addObject:module];
                }
            }
#else
            NSString *module = [NSString stringWithUTF8String:info.module];
            [moduleNames addObject:module];
#endif
        }
    } else {
        // just ignore the failed situation
    }
    
    for (NSString *module in moduleNames) {
        uintptr_t *moduledata = (uintptr_t *)getsectiondata(machOHeader, AWELazyRegisterSegment, [module UTF8String], &size);
        if (moduledata && size > 0) {
            AWELazyRegisterSectionInfo sectionInfo = [moduleDataMap objectForKey:module];
            if (!sectionInfo) {
                sectionInfo = [NSMutableDictionary dictionary];
            }
            
            unsigned long count = size / sizeof(lazy_register_info);
            lazy_register_info *lazyRegisterInfo = (lazy_register_info *)moduledata;
            for (int index = 0; index < count; index ++) {
                lazy_register_info info = lazyRegisterInfo[index];
                NSString *key = nil;
#if __has_feature(address_sanitizer)
                if (info.key != nil) {
                    NSString *value = [NSString stringWithUTF8String:info.key];
                    if (value != nil) {
                        key = value;
                    } else {
                        continue;
                    }
                } else {
                    continue;
                }
#else
                key = [NSString stringWithUTF8String:info.key];
#endif
                
#if DEBUG
                if ([sectionInfo objectForKey:key]) {
                    if (![[NSValue valueWithPointer:info.func] isEqualToValue:sectionInfo[key].handlerPointer]) {
                        NSLog(@"AWELazyRegister:2: duplicated register key %@ for %@, %@/%@", key, module, [NSValue valueWithPointer:info.func], sectionInfo[key].handlerPointer);
                    }
                }
#endif
                register_entry func = info.func;
                AWELazyRegisterHandler *handler = [[AWELazyRegisterHandler alloc] init];
                handler.registed = NO;
                handler.handlerPointer = [NSValue valueWithPointer:func];
                [sectionInfo setObject:handler forKey:key];
            }
            
            [moduleDataMap setObject:sectionInfo forKey:module];
        }
    }
    
#if DEBUG
    CFTimeInterval end = CACurrentMediaTime();
    double parseDuration = AWE_CALCULATE_DURATION(end, start);
    if (parseDuration > 3) {
        NSLog(@"AWELazyRegister Parse Duration: %@", @(parseDuration));
    }
#endif
}

static void dyldImageCallback(const struct mach_header* mhp, intptr_t slide) 
{
    // If a thread created by `pthread` library loads a dylib, this function
    // will be callback at that thread and there is no autorelease pool.
    @autoreleasepool {
        cacheSegmentInfo(mhp, slide);
    }
}

@implementation AWELazyRegister

+ (void)ensureSegmentInfoLoaded
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dyld_register_func_for_add_image(dyldImageCallback);
    });
}

#pragma mark - Public

+ (void)evaluateLazyRegisterForKey:(NSString *)key ofModule:(NSString *)module
{
    [self ensureSegmentInfoLoaded];
    AWELazyRegisterSectionInfo sectionInfo = [moduleDataMap objectForKey:module];
    if (sectionInfo && [sectionInfo objectForKey:key]) {
        AWELazyRegisterHandler *handler = [sectionInfo objectForKey:key];
        [self evaluateLazyRegisterHandler:handler];
    }
}
#if INHOUSE_TARGET || DEBUG

+ (instancetype)sharedInstance
{
    static AWELazyRegister *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kAWELazyRegisterLogOpen = YES;
        manager = [[self alloc] init];
    });
    return manager;
}
#endif

+ (void)evaluateLazyRegisterForModule:(NSString *)module
{
    [self ensureSegmentInfoLoaded];
#if DEBUG
    CFTimeInterval start = CACurrentMediaTime();
#endif
    CFTimeInterval lazyStartTime = CACurrentMediaTime();
    AWELazyRegisterSectionInfo sectionInfo = [moduleDataMap objectForKey:module];
    if (sectionInfo && sectionInfo.count > 0) {
        [sectionInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, AWELazyRegisterHandler * _Nonnull handler, BOOL * _Nonnull stop) {
#if INHOUSE_TARGET || DEBUG
            if ([AWELazyRegister sharedInstance].debugIsolationRegisterBlock && [AWELazyRegister sharedInstance].debugIsolationRegisterBlock(module, key)) {
                return;
            }
#endif
            [self evaluateLazyRegisterHandler:handler];
        }];
        
        CFTimeInterval lazyCostTime  = (CACurrentMediaTime() - lazyStartTime)*1000;
        [self addLazyItemRunInfo:module count:sectionInfo.count costTime:lazyCostTime];
    }
#if DEBUG
    CFTimeInterval end = CACurrentMediaTime();
    double evaluateDuration = AWE_CALCULATE_DURATION(end, start);
    if (evaluateDuration > 3) {
        NSLog(@"AWELazyRegister Evaluate Duration for %@ : %@", module, @(evaluateDuration));
    }
#endif
}

+ (BOOL)canEvaluateLazyRegisterForKey:(NSString *)key ofModule:(NSString *)module
{
    [self ensureSegmentInfoLoaded];
    AWELazyRegisterSectionInfo sectionInfo = [moduleDataMap objectForKey:module];
    return (sectionInfo && [sectionInfo objectForKey:key]);
}

+ (NSArray<NSString *> *)lazyRegisterKeysInModule:(NSString *)module
{
    return [[moduleDataMap objectForKey:module] allKeys];
}

#pragma mark - Private

+ (void)evaluateLazyRegisterHandler:(AWELazyRegisterHandler *)handler
{
    if (handler && handler.handlerPointer && !handler.registed) {
        register_entry func = [handler.handlerPointer pointerValue];
        func();
        handler.registed = YES;
    }
}

#pragma mark - Lazy Log Info

+ (NSMutableDictionary *)lazyRunLogParams {
    static NSMutableDictionary *runInfoDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        runInfoDict = [NSMutableDictionary dictionaryWithCapacity:30];
    });
    return runInfoDict;
}

+ (NSRecursiveLock *)lazyRunLogLock {
    static NSRecursiveLock *runLock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        runLock = [[NSRecursiveLock alloc] init];
    });
    return runLock;
}

+ (void)addLazyItemRunInfo:(NSString *)lazyName count:(NSInteger)count costTime:(CFTimeInterval)time {
    if (!kAWELazyRegisterLogOpen || lazyName.length == 0) {
        return;
    }
    NSString *countKey = [NSString stringWithFormat:@"LazyCount_%@",lazyName];
    NSString *timeKey = [NSString stringWithFormat:@"LazyTime_%@",lazyName];
    NSDictionary *lazyItemParams = @{countKey:@(count), timeKey:@(time)};
    NSRecursiveLock *lazyLock = [self lazyRunLogLock];
    if (lazyLock == nil) {
        return;
    }
    [lazyLock lock];
    NSMutableDictionary *lazyInfo = [self lazyRunLogParams];
    [lazyInfo addEntriesFromDictionary:lazyItemParams];
    [lazyLock unlock];
}

+ (NSDictionary *)lazyRegisterRunLogParams {
    if (!kAWELazyRegisterLogOpen) {
        return nil;
    }
    NSDictionary *runLogParams = nil;
    NSRecursiveLock *lazyLock = [self lazyRunLogLock];
    if (lazyLock == nil) {
        return nil;
    }
    [lazyLock lock];
    runLogParams = [[self lazyRunLogParams] copy];
    [lazyLock unlock];
    return runLogParams;
}

@end


