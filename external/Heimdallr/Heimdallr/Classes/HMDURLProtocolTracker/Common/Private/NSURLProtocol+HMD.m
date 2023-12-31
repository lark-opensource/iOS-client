//
//  NSURLProtocol+HMD.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/4/25.
//

#import "NSURLProtocol+HMD.h"
#import "HMDURLProtocol.h"
#import "HMDSwizzle.h"

static NSMutableArray *_registeredClasses;

@implementation NSURLProtocol (HMD)

+(void)load
{
    if (self == NSURLProtocol.class) {
        hmd_swizzle_class_method(NSURLProtocol.class, @selector(registerClass:), @selector(hmd_registerClass:));
        hmd_swizzle_class_method(NSURLProtocol.class, @selector(unregisterClass:), @selector(hmd_unregisterClass:));
    }
}

+ (NSArray *)hmd_registeredClasses
{
    @synchronized (self) {
        return [_registeredClasses copy];
    }
}

/***
 registerClass 和 unregisterClass 内部会触发dispatch_once_token;
 dispatch_once_token内部会调用registeredClasses引发死锁
 ***/

+ (BOOL)hmd_registerClass:(Class)protocolClass
{
    if (protocolClass == HMDURLProtocol.class) {
        NSArray *classes = nil;
        @synchronized (self) {
            if (!_registeredClasses) {
                _registeredClasses = [NSMutableArray array];
            }
            [_registeredClasses removeObject:protocolClass];
            [_registeredClasses addObject:protocolClass];
            classes = [_registeredClasses copy];
        }
        [classes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self hmd_unregisterClass:obj];
            __unused BOOL success = [self hmd_registerClass:obj];
        }];
        return YES;
    }else{
        BOOL success = [self hmd_registerClass:protocolClass];
        if (success) {
            @synchronized (self) {
                if (!_registeredClasses) {
                    _registeredClasses = [NSMutableArray array];
                }
                [_registeredClasses removeObject:protocolClass];
                [_registeredClasses insertObject:protocolClass atIndex:0];
            }
        }
        return success;
    }
}

+ (void)hmd_unregisterClass:(Class)protocolClass
{
    [self hmd_unregisterClass:protocolClass];
    @synchronized (self) {
        [_registeredClasses removeObject:protocolClass];
    }
}

@end
