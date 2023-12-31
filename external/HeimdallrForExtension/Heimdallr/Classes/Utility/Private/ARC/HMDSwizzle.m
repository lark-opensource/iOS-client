//
//  HMDSwizzle.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/3/6.
//

#import "HMDSwizzle.h"

#ifndef DEBUG_ELSE
#ifdef DEBUG
#define DEBUG_ELSE else __builtin_trap();
#else
#define DEBUG_ELSE
#endif
#endif

static void _hmd_hookedGetClass(Class class, Class statedClass) {
    NSCParameterAssert(class);
    NSCParameterAssert(statedClass);
    Method method = class_getInstanceMethod(class, @selector(class));
    IMP newIMP = imp_implementationWithBlock(^(id self) {
        return statedClass;
    });
    class_replaceMethod(class, @selector(class), newIMP, method_getTypeEncoding(method));
}

bool hmd_swizzle_instance_method(Class cls, SEL originalSelector, SEL swizzledSelector) {
    Method originMethod = class_getInstanceMethod(cls, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSelector);
    if (originMethod && swizzledMethod) {
        IMP originIMP = method_getImplementation(originMethod);
        IMP swizzledIMP = method_getImplementation(swizzledMethod);
        if (originIMP != NULL && swizzledIMP != NULL) {
            const char *originMethodType = method_getTypeEncoding(originMethod);
            const char *swizzledMethodType = method_getTypeEncoding(swizzledMethod);
            if(originMethodType && swizzledMethodType) {
                if (strcmp(originMethodType, swizzledMethodType) == 0) {
                    class_replaceMethod(cls, swizzledSelector, originIMP, originMethodType);
                    class_replaceMethod(cls, originalSelector, swizzledIMP, originMethodType);
                    return true;
                } DEBUG_ELSE
            } DEBUG_ELSE
        } DEBUG_ELSE
    } DEBUG_ELSE
    
    return false;
}

bool hmd_swizzle_instance_method_with_imp(Class cls, SEL originalSelector, SEL swizzledSelector, IMP swizzledIMP) {
    Method originMethod = class_getInstanceMethod(cls, originalSelector);
    if (originMethod) {
        IMP originIMP = method_getImplementation(originMethod);
        const char *methodType = method_getTypeEncoding(originMethod);
        if (originIMP && swizzledIMP && originIMP != swizzledIMP) {
            if(class_addMethod(cls, swizzledSelector, originIMP, methodType)) {
                class_replaceMethod(cls, originalSelector, swizzledIMP, methodType);
                return true;
            } DEBUG_ELSE
        } DEBUG_ELSE
    } DEBUG_ELSE
    return false;
}

bool hmd_swizzle_class_method(Class cls, SEL originalSelector, SEL swizzledSelector)
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

bool hmd_swizzle_class_method_with_imp(Class cls, SEL originalSelector, SEL swizzledSelector, IMP swizzledIMP)
{
    Class metaClass = object_getClass(cls);
    Method originMethod = class_getClassMethod(metaClass, originalSelector);
    if (originMethod) {
        IMP originIMP = method_getImplementation(originMethod);
        const char *methodType = method_getTypeEncoding(originMethod);
        if (originIMP && swizzledIMP && originIMP != swizzledIMP) {
            if(class_addMethod(metaClass, swizzledSelector, originIMP, methodType)) { class_replaceMethod(metaClass, originalSelector, swizzledIMP, methodType);
                return true;
            } DEBUG_ELSE
        } DEBUG_ELSE
    } DEBUG_ELSE
    return false;
}
static NSString *Hmd_Prefix_ = @"_Hmd_Prefix_";
BOOL hmd_isa_swizzle_instance(id obj, SEL originSEL, Method swizzledMethod, BOOL mockProtection)
{
    //    const char* origin_methodEncoding = method_getTypeEncoding(class_getInstanceMethod([obj class], originSEL));
    const char* swizzled_methodEncoding = method_getTypeEncoding(swizzledMethod);
    //    NSString *str1 = [NSString stringWithCString:origin_methodEncoding encoding:kCFStringEncodingUTF8];
    //    NSString *str2 = [NSString stringWithCString:swizzled_methodEncoding encoding:kCFStringEncodingUTF8];
    //    NSLog(@"%@ %@", str1, str2);
    //    if (![str1 isEqualToString:str2]) {
    //        [NSException raise:@"methodEncoding must equal" format:@""];
    //    }
    Class statedCls = [obj class];
    Class baseCls = object_getClass(obj);
    NSString *className = NSStringFromClass(baseCls);
    // 有前缀 说明已经isa混淆了 直接再搞
    if ([className hasSuffix:Hmd_Prefix_]) {
        IMP swizzledIMP = method_getImplementation(swizzledMethod);
        return class_addMethod(baseCls, originSEL, swizzledIMP, swizzled_methodEncoding);
    }
    if (baseCls != statedCls) {
        IMP swizzledIMP = method_getImplementation(swizzledMethod);
        return class_addMethod(baseCls, originSEL, swizzledIMP, swizzled_methodEncoding);
    }
    const char *subclassName =
    [className stringByAppendingString:Hmd_Prefix_].UTF8String;
    Class subclass = objc_getClass(subclassName);
    if (subclass == nil) {
        subclass = objc_allocateClassPair(baseCls, subclassName, 0);
        if (subclass == nil) {
#ifdef DEBUG
            __builtin_trap();
#endif
            return NO;
        }
        _hmd_hookedGetClass(subclass, statedCls);
        _hmd_hookedGetClass(object_getClass(subclass), statedCls);
        if(mockProtection) {
            id initialize_block = ^(id thisSelf) {
                /* 啥子都不做就好了 */
                // 防止像 FB 一样的 SB 在 initialize 里面判断 subClass 然后抛 exception [ 烦 ]
            };
            IMP initialize_imp = imp_implementationWithBlock(initialize_block);
            class_addMethod(object_getClass(subclass), @selector(initialize), initialize_imp, "v@:");
        }
        objc_registerClassPair(subclass);
    }
    object_setClass(obj, subclass);
    IMP swizzledIMP = method_getImplementation(swizzledMethod);
    return class_addMethod(subclass, originSEL, swizzledIMP, swizzled_methodEncoding);
}

_Nullable Method hmd_classHasInstanceMethod(Class _Nullable aClass, SEL _Nonnull selector) {
    NSCParameterAssert(selector != NULL && !class_isMetaClass(aClass));
    if(aClass != nil && selector != NULL && !class_isMetaClass(aClass)) {
        unsigned int length;
        Method *methodList = class_copyMethodList(aClass, &length);
        if(!methodList) return NULL;
        const char *selectorName = sel_getName(selector);
        for (unsigned int index = 0; index < length; index++) {
            const char *currentName =
            sel_getName(method_getName(methodList[index]));
            if(strcmp(currentName, selectorName) == 0) {
                free(methodList);
                return class_getInstanceMethod(aClass, selector);
            }
        }
        free(methodList);
    }
    return NULL;
}

_Nullable Method hmd_classHasClassMethod(Class _Nullable aClass, SEL _Nonnull selector) {
    NSCParameterAssert(selector != NULL && !class_isMetaClass(aClass));
    if(aClass != nil && selector != NULL && !class_isMetaClass(aClass)) {
        Class metaClass = object_getClass(aClass);
        unsigned int length;
        Method *methodList = class_copyMethodList(metaClass, &length);
        if(!methodList) return NULL;
        const char *selectorName = sel_getName(selector);
        for(unsigned int index = 0; index < length; index++) {
            const char *currentName =
            sel_getName(method_getName(methodList[index]));
            if(strcmp(currentName, selectorName) == 0) {
                free(methodList);
                return class_getClassMethod(aClass, selector);
            }
        }
        free(methodList);
    }
    return NULL;
}

Class _Nonnull * _Nullable objc_getSubclasses(Class _Nullable aClass, size_t * _Nonnull num) {
    if(aClass == nil || num == NULL) return NULL;
    unsigned int allClassAmount; Class *classList;
    if((classList = objc_copyClassList(&allClassAmount)) != NULL) {
        size_t count = 0;
        for(int index = 0; index < allClassAmount; index++)
            if(class_getSuperclass(classList[index]) == aClass) count++;
        if(count == 0) {
            free(classList); *num = 0;
            return NULL;
        }
        Class *result;
        if((result = (__unsafe_unretained Class *)
            malloc(sizeof(Class) * count)) != NULL) {
            int currentIndex = 0;
            for(int index = 0; index < allClassAmount; index++)
                if(class_getSuperclass(classList[index]) == aClass)
                    result[currentIndex++] = classList[index];
            
            free(classList);
            *num = count;
            return result;
        }
        free(classList);
    }
    *num = 0;           // whether NULL decided before
    return NULL;
}

Class _Nonnull * _Nullable objc_getAllSubclasses(Class _Nullable aClass, size_t * _Nonnull num) {
    if(aClass == nil || num == NULL) return NULL;
    unsigned int allClassAmount; Class *classList;
    if((classList = objc_copyClassList(&allClassAmount)) != NULL) {
        size_t count = 0;
        for(int index = 0; index < allClassAmount; index++) {
            Class superClass = class_getSuperclass(classList[index]);
            while(superClass && superClass != aClass)
                superClass = class_getSuperclass(superClass);
            if(superClass) count++;
        }
        if(count == 0) {
            free(classList); *num = 0;
            return NULL;
        }
        Class *result;
        if((result = (__unsafe_unretained Class *)
            malloc(sizeof(Class) * count)) != NULL) {
            int currentIndex = 0;
            for(int index = 0; index < allClassAmount; index++) {
                Class superClass = class_getSuperclass(classList[index]);
                while(superClass && superClass != aClass)
                    superClass = class_getSuperclass(superClass);
                if(superClass) result[currentIndex++] = classList[index];
            }
            free(classList);
            *num = count;
            return result;
        }
        free(classList);
    }
    *num = 0;       // whether NULL decided before
    return NULL;
}

void hmd_mockClassTreeForInstanceMethod(Class _Nullable aClass, SEL _Nonnull originSEL, SEL _Nonnull mockSEL, id _Nonnull impBlock) {
    Method root;
    if(aClass == nil || originSEL == NULL || mockSEL == NULL || impBlock == nil || !(root = hmd_classHasInstanceMethod(aClass, originSEL))) {
#ifdef DEBUG
        __builtin_trap();
#endif
        return;
    }
    const char *encodeType = method_getTypeEncoding(root);
    IMP imp; Class *allSubclasses; size_t count;
    if((imp = imp_implementationWithBlock(impBlock)) != NULL) {
        if((allSubclasses = objc_getAllSubclasses(aClass, &count)) != NULL) {
            for(size_t index = 0; index < count; index++) {
                Method eachSubOriginMethod;
                if((eachSubOriginMethod = hmd_classHasInstanceMethod
                    (allSubclasses[index], originSEL)) != NULL &&
                   class_addMethod(allSubclasses[index], mockSEL, imp, encodeType)) {
                       Method eachSubMockedMethod;
                       if((eachSubMockedMethod =
                           hmd_classHasInstanceMethod(allSubclasses[index], mockSEL)) != NULL)
                           method_exchangeImplementations(eachSubMockedMethod, eachSubOriginMethod);
                   }
            }
            free(allSubclasses);
        }
        if(class_addMethod(aClass, mockSEL, imp, encodeType)) {
            Method rootMockedMethod;
            if((rootMockedMethod = hmd_classHasInstanceMethod(aClass, mockSEL)) != NULL)
                method_exchangeImplementations(rootMockedMethod, root);
        }
    }
}

void hmd_mockClassTreeForClassMethod(Class _Nullable aClass, SEL _Nonnull originSEL, SEL _Nonnull mockSEL, id _Nonnull impBlock) {
    Method rootOriginMethod;
    if(aClass == nil || originSEL == NULL || mockSEL == NULL || impBlock == nil || !(rootOriginMethod = hmd_classHasClassMethod(aClass, originSEL))) {
#ifdef DEBUG
        __builtin_trap();
#endif
        return;
    }
    const char *encodeType = method_getTypeEncoding(rootOriginMethod);
    IMP imp; Class *allSubclasses; size_t count;
    if((imp = imp_implementationWithBlock(impBlock)) != NULL) {
        if((allSubclasses = objc_getAllSubclasses(aClass, &count)) != NULL) {
            for(size_t index = 0; index < count; index++) {
                Method eachSubOriginMethod;
                if((eachSubOriginMethod = hmd_classHasClassMethod
                    (allSubclasses[index], originSEL)) != NULL &&
                   class_addMethod(object_getClass(allSubclasses[index]), mockSEL, imp, encodeType)) {
                       Method eachSubMockedMethod;
                       
                       if((eachSubMockedMethod =
                           hmd_classHasClassMethod(allSubclasses[index], mockSEL)) != NULL)
                           method_exchangeImplementations(eachSubMockedMethod, eachSubOriginMethod);
                   }
            }
            free(allSubclasses);
        }
        if(class_addMethod(object_getClass(aClass), mockSEL, imp, encodeType)) {
            Method rootMockedMethod;
            if((rootMockedMethod =
                hmd_classHasClassMethod(aClass, mockSEL)) != NULL)
                method_exchangeImplementations(rootMockedMethod,
                                               rootOriginMethod);
        }
    }
}

void hmd_insert_and_swizzle_instance_method (Class _Nullable originalClass, SEL _Nonnull originalSelector, Class _Nullable   targetClass, SEL _Nonnull targetSelector) {
    NSCParameterAssert(!(originalSelector == NULL || targetSelector == NULL));
    if(originalClass == nil || originalSelector == NULL || targetClass == nil || targetSelector == NULL) return;
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    if(originalMethod == NULL) {
#ifdef DEBUG
        HMDPrint("hmd_insert_and_swizzle_instance_method originalMethod not exist in originalClass (including super)");
        __builtin_trap();
#endif
        return;
    }
    Method preSwizzledMethod = hmd_classHasInstanceMethod(originalClass, targetSelector);
    if(preSwizzledMethod != NULL) {
        method_exchangeImplementations(originalMethod, preSwizzledMethod);
        return;
    }
    Method targetMethod = class_getInstanceMethod(targetClass, targetSelector);
    if(targetMethod != NULL) {
        BOOL addResult=class_addMethod(originalClass, targetSelector, method_getImplementation(targetMethod), method_getTypeEncoding(targetMethod));
        if(addResult){
            Method swizzleMethod = class_getInstanceMethod(originalClass, targetSelector);
            method_exchangeImplementations(originalMethod, swizzleMethod);
        }
        else
        {
#ifdef DEBUG
            HMDPrint("hmd_insert_and_swizzle_instance_method add targetMethod to original failed");
            __builtin_trap();
#endif
        }
        
    }
}

void hmd_insert_and_swizzle_class_method (Class _Nullable originalClass, SEL _Nonnull originalSelector, Class _Nullable   targetClass, SEL _Nonnull targetSelector) {
    NSCParameterAssert(!(originalSelector == NULL || targetSelector == NULL));
    if(originalClass == nil || originalSelector == NULL || targetClass == nil || targetSelector == NULL) return;
    Class metaClass = object_getClass(originalClass);
    Method originalMethod = class_getClassMethod(originalClass, originalSelector);
    Method targetMethod = class_getClassMethod(targetClass, targetSelector);
    IMP originIMP = method_getImplementation(originalMethod);
    IMP targetIMP = method_getImplementation(targetMethod);
    const char *originMethodType = method_getTypeEncoding(originalMethod);
    const char *targetMethodType = method_getTypeEncoding(targetMethod);
    if(originalMethod == NULL || originIMP == NULL) {
#ifdef DEBUG
        fprintf(stderr, "hmd_insert_and_swizzle_class_method originalMethod not exist in originalClass (including super)");
        __builtin_trap();
#endif
        return;
    }
    
    if(targetMethod == NULL || targetIMP == NULL) {
#ifdef DEBUG
        fprintf(stderr, "hmd_insert_and_swizzle_class_method targetMethod not exist in targetClass (including super)");
        __builtin_trap();
#endif
        return;
    }
    
    if (!(originMethodType != NULL && targetMethodType != NULL && strcmp(originMethodType, targetMethodType)) == 0) {
#ifdef DEBUG
        fprintf(stderr, "hmd_insert_and_swizzle_class_method originMethod and targetMethod have different typeEncoding");
        __builtin_trap();
#endif
        return;
    }
    
    if (originalClass == targetClass) {
        class_replaceMethod(metaClass, targetSelector, originIMP, originMethodType);
        class_replaceMethod(metaClass, originalSelector, targetIMP, originMethodType);
        return;
    }
    
    class_addMethod(metaClass, targetSelector, originIMP, originMethodType);
    class_replaceMethod(metaClass, originalSelector, targetIMP, originMethodType);
}

_Nullable Method ca_classSearchInstanceMethodUntilClass(Class _Nullable aClass, SEL _Nonnull selector, Class _Nullable untilClassExcluded) {
    NSCParameterAssert(selector != NULL && !class_isMetaClass(aClass));
    if(aClass != nil && selector != NULL && !class_isMetaClass(aClass)) {
        Class currentClass = aClass;
        while(currentClass != NULL && currentClass != untilClassExcluded) {
            Method currentMethod = hmd_classHasInstanceMethod(currentClass, selector);
            if(currentMethod) return currentMethod;
            else currentClass = class_getSuperclass(currentClass);
        }
    }
    return NULL;
}

_Nullable Method ca_classSearchClassMethodUntilClass(Class _Nullable aClass, SEL _Nonnull selector, Class _Nullable untilClassExcluded) {
    NSCParameterAssert(selector != NULL && !class_isMetaClass(aClass));
    if(aClass != nil && selector != NULL && !class_isMetaClass(aClass)) {
        Class currentClass = aClass;
        while(currentClass != NULL && currentClass != untilClassExcluded) {
            Method currentMethod = hmd_classHasClassMethod(currentClass, selector);
            if(currentMethod) return currentMethod;
            else currentClass = class_getSuperclass(currentClass);
        }
    }
    return NULL;
}

