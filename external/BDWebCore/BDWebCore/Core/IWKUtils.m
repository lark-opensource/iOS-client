//
//  IWKUtils.m
//  BDWebCore
//
//  Created by li keliang on 2019/6/30.
//

#import "IWKUtils.h"
#import <objc/runtime.h>

typedef NS_OPTIONS(int, IWKBlockFlags) {
    IWKBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    IWKBlockFlagsHasSignature          = (1 << 30)
};

typedef struct _IWKBlock {
    __unused Class isa;
    IWKBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct _IWKBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        const char *signature;
        const char *layout;
    } *descriptor;
} *IWKBlockRef;

NSMethodSignature *IWK_blockMethodSignature(id block) {
    IWKBlockRef layout = (__bridge void *)block;
    if (!(layout->flags & IWKBlockFlagsHasSignature)) {
        return nil;
    }
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    if (layout->flags & IWKBlockFlagsHasCopyDisposeHelpers) {
        desc += 2 * sizeof(void *);
    }
    if (!desc) {
        return nil;
    }
    const char *signature = (*(const char **)desc);
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

BOOL IWKProtocolContainsSelector(Protocol* protocol, SEL sel) {

    struct objc_method_description description = protocol_getMethodDescription(protocol, sel, YES, YES);
    if (description.types) {
        return YES;
    }
    
    description = protocol_getMethodDescription(protocol, sel, NO, YES);
    if (description.types) {
        return YES;
    }
    return NO;
}

void IWKMetaClassSwizzle(Class class, SEL originalSelector, SEL swizzledSelector) {
    
    class = object_getClass(class);
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

void IWKClassSwizzle(Class class, SEL originalSelector, SEL swizzledSelector) {

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

void IWK_executeCleanupBlock (__strong IWK_cleanupBlock_t *block) {
    (*block)();
}
