//
//  HMDSwizzle.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/3/6.
//

#import "HMDSwizzle.h"
#import "HMDMacro.h"

#pragma mark - [DEBUG] validate block signature 声明开始

#ifdef DEBUG

#define HMD_VALIDATE_BLOCK_TYPE_ENCODING(isClass, class_name, method_name, methodEncoding, block) \
        hmd_validate_block_typeEncoding((isClass), (class_name), (method_name), (methodEncoding), (block))

static void hmd_validate_block_typeEncoding(bool isClass,
                                            const char * class_name,
                                            const char * method_name,
                                            const char * method_typeEncoding,
                                            id block);

#else

#define HMD_VALIDATE_BLOCK_TYPE_ENCODING(isClass, class_name, method_name, methodEncoding, block)

#endif /* DEBUG */

#pragma mark   [DEBUG] validate block signature 声明结束

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

bool hmd_swizzle_instance_method_with_block(Class cls, SEL originalSelector, SEL swizzledSelector, id block) {
    if (block) {
        IMP newImplementation = imp_implementationWithBlock(block);
        return hmd_swizzle_instance_method_with_imp(cls, originalSelector, swizzledSelector, newImplementation);
    }
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

bool hmd_swizzle_class_method_with_block(Class cls, SEL originalSelector, SEL swizzledSelector, id block) {
    if (block) {
        IMP newImplementation = imp_implementationWithBlock(block);
        return hmd_swizzle_class_method_with_imp(cls, originalSelector, swizzledSelector, newImplementation);
    }
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
        DEBUG_RETURN_NONE;
    }
    const char *encodeType = method_getTypeEncoding(root);
    HMD_VALIDATE_BLOCK_TYPE_ENCODING(false, class_getName(aClass), sel_getName(originSEL), encodeType, impBlock);
    
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
        DEBUG_RETURN_NONE;
    }
    const char *encodeType = method_getTypeEncoding(rootOriginMethod);
    HMD_VALIDATE_BLOCK_TYPE_ENCODING(true, class_getName(aClass), sel_getName(originSEL), encodeType, impBlock);
    
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

BOOL hmd_insert_and_swizzle_instance_method_optimized = NO;
void hmd_insert_and_swizzle_instance_method (Class _Nullable originalClass, SEL _Nonnull originalSelector, Class _Nullable   targetClass, SEL _Nonnull targetSelector) {
    NSCParameterAssert(!(originalSelector == NULL || targetSelector == NULL));
    if(originalClass == nil || originalSelector == NULL || targetClass == nil || targetSelector == NULL) return;
    Method originalMethod = hmd_classHasInstanceMethod(originalClass, originalSelector);
    if(originalMethod == NULL) {
        // originalMethod not exist in originalClass
        DEBUG_RETURN_NONE;
    }

    if (hmd_insert_and_swizzle_instance_method_optimized) {
        Method preSwizzledMethod = class_getInstanceMethod(originalClass, targetSelector);
        if (preSwizzledMethod != NULL) {
            IMP preSwizzledIMP = method_getImplementation(preSwizzledMethod);
            IMP originalIMP = method_getImplementation(originalMethod);
            class_replaceMethod(originalClass, originalSelector, preSwizzledIMP, method_getTypeEncoding(originalMethod));
            class_replaceMethod(originalClass, targetSelector, originalIMP, method_getTypeEncoding(originalMethod));
            return;
        }
    } else {
        Method preSwizzledMethod = hmd_classHasInstanceMethod(originalClass, targetSelector);
        if(preSwizzledMethod != NULL) {
            method_exchangeImplementations(originalMethod, preSwizzledMethod);
            return;
        }
    }

    Method targetMethod = class_getInstanceMethod(targetClass, targetSelector);
    if(targetMethod != NULL) {
        BOOL addResult=class_addMethod(originalClass, targetSelector, method_getImplementation(targetMethod), method_getTypeEncoding(targetMethod));
        if(addResult){
            Method swizzleMethod = class_getInstanceMethod(originalClass, targetSelector);
            if (hmd_insert_and_swizzle_instance_method_optimized) {
                IMP originalIMP = method_getImplementation(originalMethod);
                IMP swizzledIMP = method_getImplementation(swizzleMethod);
                class_replaceMethod(originalClass, targetSelector, originalIMP, method_getTypeEncoding(originalMethod));
                class_replaceMethod(originalClass, originalSelector, swizzledIMP, method_getTypeEncoding(swizzleMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzleMethod);
            }
        } DEBUG_ELSE // add targetMethod to original failed
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
        // originalMethod not exist in originalClass (including super)
        DEBUG_RETURN_NONE;
    }
    
    if(targetMethod == NULL || targetIMP == NULL) {
        // targetMethod not exist in targetClass (including super)
        DEBUG_RETURN_NONE;
    }
    
    if (!(originMethodType != NULL && targetMethodType != NULL && strcmp(originMethodType, targetMethodType)) == 0) {
        // originMethod and targetMethod have different typeEncoding
        DEBUG_RETURN_NONE;
    }
    
    if (originalClass == targetClass) {
        class_replaceMethod(metaClass, targetSelector, originIMP, originMethodType);
        class_replaceMethod(metaClass, originalSelector, targetIMP, originMethodType);
        return;
    }
    
    class_addMethod(metaClass, targetSelector, originIMP, originMethodType);
    class_replaceMethod(metaClass, originalSelector, targetIMP, originMethodType);
}

_Nullable Method hmd_classSearchInstanceMethodUntilClass(Class _Nullable aClass, SEL _Nonnull selector, Class _Nullable untilClassExcluded) {
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

_Nullable Method hmd_classSearchClassMethodUntilClass(Class _Nullable aClass, SEL _Nonnull selector, Class _Nullable untilClassExcluded) {
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

#pragma mark - [DEBUG] validate block signature 定义开始

#ifdef DEBUG

static const char * _Nonnull skipTypeModifierEncoding(const char *_Nonnull encoding);
static const char *block_getSignatureForBlock(id block);

static NSString * _Nullable block_method_not_match_reason(bool isClass,
                                                          const char * method_typeEncoding,
                                                          const char * block_typeEncoding);


static void hmd_validate_block_typeEncoding(bool isClass,
                                            const char * class_name,
                                            const char * method_name,
                                            const char * method_typeEncoding,
                                            id block) {
    #ifndef DEBUG
    #error hmd_validate_block_typeEncoding should only be compiled in DEBUG mode
    #endif
    
    NSString * _Nullable reason = block_method_not_match_reason(isClass, method_typeEncoding, block_getSignatureForBlock(block));
    if(reason == nil) return;
    
    // 如果在这里崩溃了，请检查 reason 的值，是崩溃原因
    DEBUG_ERROR("[HMDSwizzle][Block] %s[%s %s] type encoding check failed, reason %s", isClass?"+":"-", class_name, method_name, reason.UTF8String);
}

static NSString * _Nullable block_method_not_match_reason(bool isClass,
                                                          const char * method_typeEncoding,
                                                          const char * block_typeEncoding) {
    // 返回 NULL 意味着匹配成功，否则是错误原因
    #ifndef DEBUG
    #error block_method_not_match_reason should only be compiled in DEBUG mode
    #endif
    
    if(method_typeEncoding == nil ||
       block_typeEncoding == nil) {
        return [NSString stringWithFormat:@"invalid input method_typeEncoding %s block_typeEncoding %s", method_typeEncoding, block_typeEncoding];
    }
    
    NSMethodSignature *method_sig = [NSMethodSignature signatureWithObjCTypes:method_typeEncoding];
    
    NSMethodSignature *block_sig = [NSMethodSignature signatureWithObjCTypes:block_typeEncoding];
    
    if(method_sig == nil || block_sig == nil) {
        return [NSString stringWithFormat:@"failed to create method signature from method_typeEncoding %s block_typeEncoding %s", method_typeEncoding, block_typeEncoding];
    }
    
    NSUInteger method_args_count = method_sig.numberOfArguments;
    NSUInteger block_args_count = block_sig.numberOfArguments;
    
    if(method_args_count != block_args_count) {
        return [NSString stringWithFormat:@"arguments count not match, method args count %lu, block args count %lu", (unsigned long)method_args_count, (unsigned long)block_args_count];
    }
    
    if(block_args_count < 2) {
        return [NSString stringWithFormat:@"invalid block typeEncoding with count less than two, typeEncoding %s", block_typeEncoding];
    }
    
    const char * _Nullable firstInvisibleArgumentType = [block_sig getArgumentTypeAtIndex:0];
    
    if(firstInvisibleArgumentType == NULL) {
        return [NSString stringWithFormat:@"failed to get block invisible argument, whole block typeEncoding %s", block_typeEncoding];
    }
    
    firstInvisibleArgumentType = skipTypeModifierEncoding(firstInvisibleArgumentType);
    
    if(firstInvisibleArgumentType[0] != '@') {
        return [NSString stringWithFormat:@"block invisible argument is not object, this is not block signature, whole block typeEncoding %s", block_typeEncoding];
    }
    
    const char * _Nullable firstSeeAbleArgumentType = [block_sig getArgumentTypeAtIndex:1];
    
    if(firstSeeAbleArgumentType == NULL) {
        return [NSString stringWithFormat:@"failed to get block first arguments, whole block typeEncoding %s", block_typeEncoding];
    }
    
    firstSeeAbleArgumentType = skipTypeModifierEncoding(firstSeeAbleArgumentType);
    
    if(isClass) {
        if(firstSeeAbleArgumentType[0] != '#') {
            if(firstSeeAbleArgumentType[0] == '@') {
                return [NSString stringWithFormat:@"block mocked for Class method not instance, argument should be Class"];
            } else if(firstSeeAbleArgumentType[0] == '^') {
                return [NSString stringWithFormat:@"block should be Class type, should not be pointer"];
            } else {
                return [NSString stringWithFormat:@"block first argument should be object type or id, type %c", firstSeeAbleArgumentType[0]];
            }
        }
    } else {
        if(firstSeeAbleArgumentType[0] != '@') {
            if(firstSeeAbleArgumentType[0] == '#') {
                return [NSString stringWithFormat:@"block mocked for instance method not class, argument should be object type or id"];
            } else if(firstSeeAbleArgumentType[0] == '^') {
                return [NSString stringWithFormat:@"block should be object type, should not be pointer"];
            } else {
                return [NSString stringWithFormat:@"block first argument should be object type or id, type %c", firstSeeAbleArgumentType[0]];
            }
        }
    }
    
    for(NSUInteger index = 2; index < block_args_count; index++) {
        const char *methodType = [method_sig getArgumentTypeAtIndex:index];
        const char *blockType = [block_sig getArgumentTypeAtIndex:index];
        
        if(methodType == NULL) {
            return [NSString stringWithFormat:@"failed to get method NO.%lu arguments, whole method typeEncoding %s", (unsigned long)(index + 1), method_typeEncoding];
        }
        
        if(blockType == NULL) {
            return [NSString stringWithFormat:@"failed to get block NO.%lu arguments, whole block typeEncoding %s", (unsigned long)(index + 1), block_typeEncoding];
        }
        
        methodType = skipTypeModifierEncoding(methodType);
        blockType = skipTypeModifierEncoding(blockType);
        
        if(methodType[0] != blockType[0]) {
            return [NSString stringWithFormat:@"method and block does not match at NO.%lu arguments, method type %c, block type %c, whole method typeEncoding %s, whole block typeEncoding %s", (unsigned long)(index + 1), methodType[0], blockType[0], method_typeEncoding, block_typeEncoding];
        }
    }
    
    const char *methodReturnType = method_sig.methodReturnType;
    const char *blockReturnType = block_sig.methodReturnType;
    
    if(methodReturnType == NULL) {
        return [NSString stringWithFormat:@"failed to get method return type, whole method typeEncoding %s", method_typeEncoding];
    }
    
    if(blockReturnType == NULL) {
        return [NSString stringWithFormat:@"failed to get block return type, whole block typeEncoding %s", block_typeEncoding];
    }
    
    methodReturnType = skipTypeModifierEncoding(methodReturnType);
    blockReturnType = skipTypeModifierEncoding(blockReturnType);
    
    if(methodReturnType[0] != blockReturnType[0]) {
        return [NSString stringWithFormat:@"method and block does not match return argument type, method type %c, block type %c, whole method typeEncoding %s, whole block typeEncoding %s", methodReturnType[0], blockReturnType[0], method_typeEncoding, block_typeEncoding];
    }
    
    return nil;
}

static const char * _Nonnull skipTypeModifierEncoding(const char *_Nonnull encoding) {
    CLANG_DIAGNOSTIC_PUSH
    CLANG_DIAGNOSTIC_IGNORE_NONNULL
    if(encoding == NULL) DEBUG_RETURN(NULL);
    CLANG_DIAGNOSTIC_POP
    
    static const char *qualifiersAndComments = "nNoOrRV\"";
    while (encoding[0] != '\0' && strchr(qualifiersAndComments, encoding[0])) {
        if (encoding[0] == '"') {
            encoding++;
            
            while(encoding[0] != '\0' && encoding[0] != '"')
                encoding++;
        }
        else encoding++;
    }
    return encoding;
}

enum {
    BLOCK_DEALLOCATING =      (0x0001),  // runtime
    BLOCK_REFCOUNT_MASK =     (0xfffe),  // runtime
    BLOCK_NEEDS_FREE =        (1 << 24), // runtime
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25), // compiler
    BLOCK_HAS_CTOR =          (1 << 26), // compiler: helpers have C++ code
    BLOCK_IS_GC =             (1 << 27), // runtime
    BLOCK_IS_GLOBAL =         (1 << 28), // compiler
    BLOCK_USE_STRET =         (1 << 29), // compiler: undefined if !BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE  =    (1 << 30)  // compiler
};

// revised new layout

#define BLOCK_DESCRIPTOR_1 1
struct Block_descriptor_1 {
    unsigned long int reserved;
    unsigned long int size;
};

#define BLOCK_DESCRIPTOR_2 1
struct Block_descriptor_2 {
    // requires BLOCK_HAS_COPY_DISPOSE
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *);
};

#define BLOCK_DESCRIPTOR_3 1
struct Block_descriptor_3 {
    // requires BLOCK_HAS_SIGNATURE
    const char *signature;
    const char *layout;
};

struct Block_layout {
    void *isa;
    volatile int flags; // contains ref count
    int reserved;
    void (*invoke)(void *, ...);
    struct Block_descriptor_1 *descriptor;
    // imported variables
};


static const char *block_getSignatureForBlock(id block) {
    struct Block_layout *layout = (__bridge void *)block;
    if (!(layout->flags & BLOCK_HAS_SIGNATURE))
        return nil;
    
    void *descRef = layout->descriptor;
    descRef += 2 * sizeof(unsigned long int);
    
    if (layout->flags & BLOCK_HAS_COPY_DISPOSE)
        descRef += 2 * sizeof(void *);
    
    if (!descRef) return nil;
    
    return (*(const char **)descRef);
}

#endif /* DEBUG */

#pragma mark   [DEBUG] validate block signature 定义结束
