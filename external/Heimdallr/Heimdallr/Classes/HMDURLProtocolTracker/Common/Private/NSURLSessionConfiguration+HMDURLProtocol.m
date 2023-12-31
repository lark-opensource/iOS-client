//
//  NSURLSessionConfiguration+HMDURLProtocol.m
//  PrismMonitorDemo
//
//  Created by tany on 2017/4/13.
//  Copyright © 2017年 tany. All rights reserved.
//

#import "NSURLSessionConfiguration+HMDURLProtocol.h"
#import <objc/runtime.h>
#import "HMDURLProtocol.h"
#import "HMDSwizzle.h"
#import "NSURLProtocol+HMD.h"
#import "HMDMacro.h"

static IMP originProtocolClassesIMP;
static IMP hmdProtocolClassesIMP;
static NSLock *hmd_URLSessionSwizzleLock;

IMP hmd_getProtocolClassesIMP(void) {
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    return class_getMethodImplementation(cls, @selector(protocolClasses));
}

@implementation NSURLSessionConfiguration (HMDURLProtocol)

+ (void)initialize {
    if (self == [NSURLSessionConfiguration class]) {
        originProtocolClassesIMP = hmd_getProtocolClassesIMP();
        [self hmd_getHMDProtocolClassesIMP];
        hmd_URLSessionSwizzleLock = [[NSLock alloc] init];
    }
}

- (NSArray <Class>*)hmd_ty_protocolClasses {
    
    NSMutableArray *array = [NSMutableArray array];
    
    NSMutableSet *set = [NSMutableSet set];
    NSArray *registeredClasses = [NSURLProtocol hmd_registeredClasses];
    [registeredClasses enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![set containsObject:obj]) {
            [set addObject:obj];
            [array addObject:obj];
        }
    }];
    
    if (![set containsObject:HMDURLProtocol.class]) {
        [set addObject:HMDURLProtocol.class];
        [array addObject:HMDURLProtocol.class];
    }
    
    //[self ty_protocolClasses]这种调用方式由于多线程问题会造成递归调用，导致栈溢出。
    NSArray * (*ori_imp)(id,SEL,...) = (NSArray * (*)(id, SEL, ...))originProtocolClassesIMP;
    if (ori_imp) {
        NSArray *originClasses = ori_imp(self,@selector(protocolClasses));
        if ([originClasses isKindOfClass:NSArray.class]) {
            [originClasses enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![set containsObject:obj]) {
                    [set addObject:obj];
                    [array addObject:obj];
                }
            }];
        }
    }
    
    return array;
}

+ (void)hmd_exchangeProtocolClassessIMP {
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    hmd_swizzle_instance_method(cls,@selector(protocolClasses),@selector(hmd_ty_protocolClasses));
}

+ (void)hmd_getHMDProtocolClassesIMP {
    Class cls = NSClassFromString(@"__NSCFURLSessionConfiguration") ?: NSClassFromString(@"NSURLSessionConfiguration");
    hmdProtocolClassesIMP = class_getMethodImplementation(cls, @selector(hmd_ty_protocolClasses));
}

+ (void)hmd_start {
    [hmd_URLSessionSwizzleLock lock];
    IMP curProtocolClassesIMP = hmd_getProtocolClassesIMP();
    if (curProtocolClassesIMP == originProtocolClassesIMP) {
        [self hmd_exchangeProtocolClassessIMP];
    }
    [hmd_URLSessionSwizzleLock unlock];
}

+ (void)hmd_stop {
    [hmd_URLSessionSwizzleLock lock];
    IMP curProtocolClassesIMP = hmd_getProtocolClassesIMP();
    if (curProtocolClassesIMP == hmdProtocolClassesIMP) {
        [self hmd_exchangeProtocolClassessIMP];
    }
    [hmd_URLSessionSwizzleLock unlock];
}

@end
