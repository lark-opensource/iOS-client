//
//  LKHookUtil.m
//  LarkCrashSanitizer
//
//  Created by sniperj on 2019/12/24.
//

#import "LKHookUtil.h"
#import <objc/runtime.h>


inline void
SwizzleMethod(Class _originClass, SEL _originSelector, Class _newClass, SEL _newSelector) {
    Method oriMethod = class_getInstanceMethod(_originClass, _originSelector);
    Method newMethod = class_getInstanceMethod(_newClass, _newSelector);
    class_addMethod(_originClass, _newSelector, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    BOOL isAddedMethod = class_addMethod(_originClass, _originSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (isAddedMethod) {
        class_replaceMethod(_originClass, _newSelector, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    } else {
        method_exchangeImplementations(oriMethod, newMethod);
    }
}

#ifndef DEBUG_ELSE
#ifdef DEBUG
#define DEBUG_ELSE else DEBUG_POINT
#else
#define DEBUG_ELSE
#endif
#endif

#ifndef DEBUG_POINT
#ifdef DEBUG
#define DEBUG_POINT __builtin_trap();
#else
#define DEBUG_POINT
#endif
#endif

inline bool
SwizzleClassMethod(Class cls, SEL originalSelector, SEL swizzledSelector)
{
    Class metaClass = object_getClass(cls);
    Method originMethod = class_getClassMethod(cls, originalSelector);
    Method swizzledMethod = class_getClassMethod(cls, swizzledSelector);
    if (originMethod && swizzledMethod) {
        IMP originIMP = method_getImplementation(originMethod);
        IMP swizzledIMP = method_getImplementation(swizzledMethod);
        if (originIMP && swizzledIMP && originIMP != swizzledIMP) {
            const char *originMethodType = method_getTypeEncoding(originMethod);
            const char *swizzledMethodType = method_getTypeEncoding(swizzledMethod);
            if(originMethodType && swizzledMethodType) {
                if (strcmp(originMethodType, swizzledMethodType) == 0) {
                    class_replaceMethod(metaClass, swizzledSelector, originIMP, originMethodType);
                    class_replaceMethod(metaClass, originalSelector, swizzledIMP, originMethodType);
                    return true;
                } DEBUG_ELSE
            } DEBUG_ELSE
        } DEBUG_ELSE
    } DEBUG_ELSE
    return false;
}

@implementation LKHookUtil

@end
