//
//  Stinger.m
//  Stinger
//
//  Created by Assuner on 2018/1/9.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import "Stinger.h"
#import <objc/runtime.h>
#import "STHookInfo.h"
#import "STHookInfoPool.h"

NSString *const StingerErrorDomain = @"StingerErrorDomain";
#define StingerError(errorCode, errorDescription) do { \
if (error) { *error = [NSError errorWithDomain:StingerErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorDescription}]; }} while(0)

static void *STSubClassKey = &STSubClassKey;

typedef NS_ENUM(NSUInteger, STHookType) {
    STHookTypeClass,
    STHookTypeInstance,
};

@implementation NSObject (Stinger)

#pragma mark - For specific class

+ (id<STToken>)st_hookInstanceMethod:(SEL)sel withOptions:(STOptions)options usingBlock:(id)block error:(NSError **)error {
    return hookMethod(STHookTypeClass, self, sel, options, block, error);
}

+ (id<STToken>)st_hookClassMethod:(SEL)sel withOptions:(STOptions)options usingBlock:(id)block error:(NSError **)error {
    return hookMethod(STHookTypeClass, object_getClass(self), sel, options, block, error);
}

#pragma mark - For specific instance

- (id<STToken>)st_hookInstanceMethod:(SEL)sel withOptions:(STOptions)options usingBlock:(id)block error:(NSError **)error {
    @synchronized(self) {
        Class stSubClass = getSTSubClass(self);
        if (!stSubClass) {
            StingerError(STHookErrorOther, @"Get subclass failed.");
            return nil;
        }
        
        NSError *innerError = nil;
        hookMethod(STHookTypeInstance, stSubClass, sel, options, block, &innerError); //hookMethod(STHookTypeInstance, stSubClass, sel, option, identifier, block);
        if (innerError) {
            if (error) {
                *error = innerError;
            }
            return nil;
        }
        
        if (!objc_getAssociatedObject(self, STSubClassKey)) {
            object_setClass(self, stSubClass);
            objc_setAssociatedObject(self, STSubClassKey, stSubClass, OBJC_ASSOCIATION_ASSIGN);
        }
        
        id<STHookInfoPool> instanceHookInfoPool = st_getHookInfoPool(self, sel);
        if (!instanceHookInfoPool) {
            instanceHookInfoPool = [STHookInfoPool poolWithTypeEncoding:nil originalIMP:NULL selector:sel];
            st_setHookInfoPool(self, sel, instanceHookInfoPool);
        }
        
        STHookInfo *instanceHookInfo = [STHookInfo infoWithSelector:sel object:self options:options block:block error:error];
        if ([instanceHookInfoPool addInfo:instanceHookInfo]) {
            return instanceHookInfo;
        }
        
        StingerError(STHookErrorOther, @"Add hook info failed.");
        return nil;
    }
}

#pragma mark - inline functions
id hookMethod(STHookType hookType, Class hookedCls, SEL sel, STOptions option, id block, NSError **error) {
    NSCParameterAssert(hookedCls);
    NSCParameterAssert(sel);
    NSCParameterAssert(block);
    
    Method m = class_getInstanceMethod(hookedCls, sel);
    NSString *errorDescription = [NSString stringWithFormat:@"SEL (%@) doesn't has a imp in Class (%@) originally", NSStringFromSelector(sel), hookedCls];
    NSCAssert(m, errorDescription);
    if (!m) {
        StingerError(STHookErrorErrorMethodNotFound, errorDescription);
        return nil;
    }
    
    const char * typeEncoding = method_getTypeEncoding(m);
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
    NSMethodSignature *blockSignature = st_getSignatureForBlock(block);
    if (!isMatched(methodSignature, blockSignature, option, hookedCls, sel)) {
        NSString *errorDescription = [NSString stringWithFormat:@"Block signature %@ doesn't match %@.", blockSignature, methodSignature];
        StingerError(STHookErrorErrorBlockNotMatched, errorDescription);
        return nil;
    }
    
    IMP originalImp = method_getImplementation(m);
    @synchronized(hookedCls) {
        id<STHookInfoPool> hookInfoPool = st_getHookInfoPool(hookedCls, sel);
        if (!hookInfoPool) {
            hookInfoPool = [STHookInfoPool poolWithTypeEncoding:[NSString stringWithUTF8String:typeEncoding] originalIMP:NULL selector:sel];
            hookInfoPool.hookedCls = hookedCls;
            hookInfoPool.statedCls = [hookedCls class];
            
            IMP stingerIMP = [hookInfoPool stingerIMP];
            hookInfoPool.originalIMP = originalImp;
            if (!class_addMethod(hookedCls, sel, stingerIMP, typeEncoding)) {
                class_replaceMethod(hookedCls, sel, stingerIMP, typeEncoding);
            }
            
            st_setHookInfoPool(hookedCls, sel, hookInfoPool);
        }
        
        if (hookType == STHookTypeInstance) {
            hookInfoPool.isInstanceHook = YES;
            return nil;
        } else {
            STHookInfo *hookInfo = [STHookInfo infoWithSelector:sel object:hookedCls options:option block:block error:nil];
            if ([hookInfoPool addInfo:hookInfo]) {
                return hookInfo;
            }
            
            StingerError(STHookErrorOther, @"Add hook info failed.");
            return nil;
        }
    }
}

NS_INLINE Class getSTSubClass(id object) {
    NSCParameterAssert(object);
    Class stSubClass = objc_getAssociatedObject(object, STSubClassKey);
    if (stSubClass) return stSubClass;
    
    /* if KVO'ed Object,we return it's subClass-> NSKVONotifying_xxx directly. */
    if ([object class] != object_getClass(object)) {
        return object_getClass(object);
    }
    
    Class isaClass = object_getClass(object);
    NSString *isaClassName = NSStringFromClass(isaClass);
    const char *subclassName = [STClassPrefix stringByAppendingString:isaClassName].UTF8String;
    stSubClass = objc_getClass(subclassName);
    if (!stSubClass) {
        stSubClass = objc_allocateClassPair(isaClass, subclassName, 0);
        NSCAssert(stSubClass, @"Class %s allocate failed!", subclassName);
        if (!stSubClass) return nil;
        
        objc_registerClassPair(stSubClass);
        Class realClass = [object class];
        hookGetClassMessage(stSubClass, realClass);
        hookGetClassMessage(object_getClass(stSubClass), realClass);
    }
    return stSubClass;
}

NS_INLINE void hookGetClassMessage(Class class, Class retClass) {
    Method method = class_getInstanceMethod(class, @selector(class));
    IMP newIMP = imp_implementationWithBlock(^(id self) {
        return retClass;
    });
    class_replaceMethod(class, @selector(class), newIMP, method_getTypeEncoding(method));
}

NS_INLINE BOOL isMatched(NSMethodSignature *methodSignature, NSMethodSignature *blockSignature, STOptions option, Class cls, SEL sel) {
    BOOL strictCheck = ((option & STOptionWeakCheckSignature) == 0);
    //argument count
    if (strictCheck && methodSignature.numberOfArguments != blockSignature.numberOfArguments) {
        NSCAssert(NO, @"count of arguments isn't equal. Class: (%@), SEL: (%@)", cls, NSStringFromSelector(sel));
        return NO;
    };
    // loc 1 should be id<StingerParams>.
    const char *firstArgumentType = [blockSignature getArgumentTypeAtIndex:1];
    if (!firstArgumentType || firstArgumentType[0] != '@') {
        NSCAssert(NO, @"argument<%s> at loc 1 should be object type. Class: (%@), SEL: (%@)", firstArgumentType, cls, NSStringFromSelector(sel));
        return NO;
    }
    // from loc 2.
    if (strictCheck) {
        for (NSInteger i = 2; i < methodSignature.numberOfArguments; i++) {
            const char *methodType = [methodSignature getArgumentTypeAtIndex:i];
            const char *blockType = [blockSignature getArgumentTypeAtIndex:i];
            if (!methodType || !blockType || methodType[0] != blockType[0]) {
                NSCAssert(NO, @"argument (%zd) type isn't equal. Class: (%@), SEL: (%@)", i, cls, NSStringFromSelector(sel));
                return NO;
            }
        }
    }
    // when STOptionInstead, returnType
    NSUInteger position = option & StingerPositionFilter;
    if (position == STOptionInstead) {
        const char *methodReturnType = methodSignature.methodReturnType;
        const char *blockReturnType = blockSignature.methodReturnType;
        if (!methodReturnType || !blockReturnType || methodReturnType[0] != blockReturnType[0]) {
            NSCAssert(NO, @"return type isn't equal. Class: (%@), SEL: (%@)", cls, NSStringFromSelector(sel));
            return NO;
        }
    }
    
    return YES;
}

@end
