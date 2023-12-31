//
//  NSObject+Runtime.m
//  MailSDK
//
//  Created by tefeng liu on 2021/3/18.
//

#import "NSObject+Runtime.h"

#import <objc/runtime.h>
#import <objc/message.h>

static NSString *lkmail_suffix_ = @"_lkmail_suffix_";
static NSString *lkmail_protocol_ = @"_lkmail_protocol_";
static void _mail_hookedGetClass(Class class, Class statedClass) {
    NSCParameterAssert(class);
    NSCParameterAssert(statedClass);
    Method method = class_getInstanceMethod(class, @selector(class));
    IMP newIMP = imp_implementationWithBlock(^(id self) {
        return statedClass;
    });
    class_replaceMethod(class, @selector(class), newIMP, method_getTypeEncoding(method));
}

@implementation NSObject (BDPSwizzle)

+ (BOOL)mail_swizzleClass:(Class)originClass
                selector:(SEL)originSelector
           swizzledClass:(Class)swizzledClass
        swizzledSelector:(SEL)swizzledSelector
{
    Method originalMethod = class_getInstanceMethod(originClass, originSelector);
    if (!originalMethod) {
        return NO;
    }
    Method swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector);
    if (!swizzledMethod) {
        return NO;
    }

    BOOL didAddMethod =
    class_addMethod(originClass,
                    originSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(originClass,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }

    return YES;
}

+ (BOOL)mail_swizzleOriginInstanceMethod:(SEL)originalSEL withHookInstanceMethod:(SEL)alternateSEL
{
    return [self mail_swizzleClass:self selector:originalSEL swizzledClass:self swizzledSelector:alternateSEL];
}

+ (BOOL)mail_swizzleOriginClassMethod:(SEL)originalSEL withHookClassMethod:(SEL)alternateSEL
{
    return [self mail_swizzleClass:object_getClass(self) selector:originalSEL swizzledClass:object_getClass(self) swizzledSelector:alternateSEL];
}

- (BOOL)mail_swizzleInstanceClassIsa:(SEL)originSEL withHookInstanceMethod:(SEL)swizzledSEL
{
    Method originMethod = class_getInstanceMethod([self class], originSEL);
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSEL);
    const char* origin_methodEncoding = method_getTypeEncoding(originMethod);
    const char* swizzled_methodEncoding = method_getTypeEncoding(swizzledMethod);
    NSString *str1 = [NSString stringWithCString:origin_methodEncoding encoding:kCFStringEncodingUTF8];
    NSString *str2 = [NSString stringWithCString:swizzled_methodEncoding encoding:kCFStringEncodingUTF8];
    if (![str1 isEqualToString:str2]) {
        return NO;
    }
    Class statedCls = [self class];
    Class baseCls = object_getClass(self);
    NSString *className = NSStringFromClass(baseCls);
    // 有标记 说明已经isa混淆了 直接再搞
    if ([className hasSuffix:lkmail_suffix_]) {
        IMP swizzledIMP = method_getImplementation(swizzledMethod);
        IMP originIMP = method_getImplementation(originMethod);
        return class_addMethod(baseCls, originSEL, swizzledIMP, swizzled_methodEncoding) &
               class_addMethod(baseCls, swizzledSEL, originIMP, origin_methodEncoding);
    }
    if (baseCls != statedCls) {
        IMP swizzledIMP = method_getImplementation(swizzledMethod);
        IMP originIMP = method_getImplementation(originMethod);
        return class_addMethod(baseCls, originSEL, swizzledIMP, swizzled_methodEncoding) &
               class_addMethod(baseCls, swizzledSEL, originIMP, origin_methodEncoding);
    }
    const char *subclassName =
    [className stringByAppendingString:lkmail_suffix_].UTF8String;
    Class subclass = objc_getClass(subclassName);
    if (subclass == nil) {
        subclass = objc_allocateClassPair(baseCls, subclassName, 0);
        if (subclass == nil) {
#ifdef DEBUG
            __builtin_trap();
#endif
            return NO;
        }
        _mail_hookedGetClass(subclass, statedCls);
        _mail_hookedGetClass(object_getClass(subclass), statedCls);
//        if(mockProtection) {
//            id initialize_block = ^(id thisSelf) {
//                /* 啥子都不做就好了 */
//                // 防止像 FB 一样的 SB 在 initialize 里面判断 subClass 然后抛 exception [ 烦 ]
//            };
//            IMP initialize_imp = imp_implementationWithBlock(initialize_block);
//            class_addMethod(object_getClass(subclass), @selector(initialize), initialize_imp, "v@:");
//        }
        objc_registerClassPair(subclass);
    }
    object_setClass(self, subclass);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    IMP originIMP = method_getImplementation(originMethod);
    return class_addMethod(subclass, originSEL, swizzledIMP, swizzled_methodEncoding) &
           class_addMethod(subclass, swizzledSEL, originIMP, origin_methodEncoding);
}

- (BOOL)mail_isaSwizzleProtocol:(Protocol *)protocol
{
    Class statedCls = [self class];
    Class baseCls = object_getClass(self);
    NSString *className = NSStringFromClass(baseCls);
    // 有标记 说明已经isa混淆了 直接再搞
    if ([className hasSuffix:lkmail_suffix_]) {
        return class_addProtocol(object_getClass(self),protocol);
    }
    if (baseCls != statedCls) {
        return class_addProtocol(object_getClass(self),protocol);
    }
    const char *subclassName =
        [className stringByAppendingString:lkmail_suffix_].UTF8String;
        Class subclass = objc_getClass(subclassName);
        if (subclass == nil) {
            subclass = objc_allocateClassPair(baseCls, subclassName, 0);
            if (subclass == nil) {
#ifdef DEBUG
                __builtin_trap();
#endif
                return NO;
            }
            _mail_hookedGetClass(subclass, statedCls);
            _mail_hookedGetClass(object_getClass(subclass), statedCls);
            objc_registerClassPair(subclass);
        }
    object_setClass(self, subclass);
    return class_addProtocol(object_getClass(self),protocol);
}

- (void)callMethod:(NSString *)method
{
    SEL sel = NSSelectorFromString(method);
    ((void (*)(id, SEL))objc_msgSend)(self, sel);
}

@end

