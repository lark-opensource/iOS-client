//
//  BDPMethodSwizzledUtilsDefine.h
//  Timor
//
//  Created by liuxiangxin on 2019/5/20.
//

#ifndef BDPMethodSwizzledUtilsDefine_h
#define BDPMethodSwizzledUtilsDefine_h

#import <objc/runtime.h>

#define SWIZZLED_SELECTOR(Class_Name, ORIGINAL_SELECTOR, SWIZZLED_SELECTOR) \
{ \
    static dispatch_once_t onceToken; \
    dispatch_once(&onceToken, ^{ \
        SEL originalSelector = @selector(ORIGINAL_SELECTOR); \
        SEL swizzledSelector = @selector(SWIZZLED_SELECTOR); \
        Method originalMethod = class_getInstanceMethod([Class_Name class], originalSelector); \
        Method swizzledMethod = class_getInstanceMethod([Class_Name class], swizzledSelector); \
        \
        BOOL didAddMethod = class_addMethod([Class_Name class], \
        originalSelector, \
        method_getImplementation(swizzledMethod), \
        method_getTypeEncoding(swizzledMethod)); \
        \
        if (didAddMethod) { \
            class_replaceMethod([Class_Name class], \
            swizzledSelector, \
            method_getImplementation(originalMethod), \
            method_getTypeEncoding(originalMethod)); \
        } else { \
            method_exchangeImplementations(originalMethod, swizzledMethod); \
        } \
    }); \
}

#endif /* BDPMethodSwizzledUtilsDefine_h */
