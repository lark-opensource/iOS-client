//
//  NSObject+TSAddition.m
//  TSPrivacyKit
//
//  Created by PengYan on 2020/7/15.
//

#import "NSObject+TSAddition.h"
#import <objc/runtime.h>
#import "TSPKConfigs.h"
#import "TSPKUtils.h"

@implementation NSObject (TSAddition)

+ (BOOL)ts_needSkipHook:(SEL)origSelector with:(SEL)newSelector {
    NSString *api = [TSPKUtils concateClassName:[self ts_className] method:NSStringFromSelector(origSelector)];
    
    NSNumber *isEnable = [[TSPKConfigs sharedConfig] isApiEnable:api];
    if (isEnable != nil) {
        return ![isEnable boolValue];
    }
    
    return NO;
}

+ (BOOL)ts_swizzleInstanceMethod:(SEL)origSelector with:(SEL)newSelector {
    if ([self ts_needSkipHook:origSelector with:origSelector]) {
        return NO;
    }
    
    Method originalMethod = class_getInstanceMethod(self, origSelector);
    Method swizzledMethod = class_getInstanceMethod(self, newSelector);
    if (!originalMethod || !swizzledMethod) {
        return NO;
    }
    if (class_addMethod(self,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        class_replaceMethod(self,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        class_replaceMethod(self,
                            newSelector,
                            class_replaceMethod(self,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
    return YES;
}

+ (BOOL)ts_swizzleClassMethod:(SEL)origSelector with:(SEL)newSelector {
    if ([self ts_needSkipHook:origSelector with:origSelector]) {
        return NO;
    }
    
    Class cls = [self class];
    Method originalMethod = class_getClassMethod(cls, origSelector);
    Method swizzledMethod = class_getClassMethod(cls, newSelector);
    if (!originalMethod || !swizzledMethod) {
        return NO;
    }
    Class metacls = objc_getMetaClass(NSStringFromClass(cls).UTF8String);
    if (class_addMethod(metacls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        class_replaceMethod(metacls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    return YES;
}

/// Generally used for hook delegate method
+ (BOOL)ts_swzzileMethodWithOrigClass:(Class)origClass origSelector:(SEL)origSelector origBackupSelectorClass:(Class)origBackupSelectorClass newSelector:(SEL)newSelector newClass:(Class)newClass {
    if (!origClass) {
        return NO;
    }
    // if origClass already add new method, return
    Method newSelectorMethod = class_getInstanceMethod(origClass, newSelector);
    if (newSelectorMethod) {
        return NO;
    }
    // if origClass not implemented the origSelector method, add the method first
    if (!class_getInstanceMethod(origClass, origSelector)) {
        Method origBackupMethod = class_getInstanceMethod(origBackupSelectorClass, origSelector);
        if (!origBackupMethod) {
            return NO;
        }
        class_addMethod(origClass, origSelector, method_getImplementation(origBackupMethod), method_getTypeEncoding(origBackupMethod));
    }
    Method newMethod = class_getInstanceMethod(newClass, newSelector);
    if (!newMethod) {
        return NO;
    }
    Method origMethod = class_getInstanceMethod(origClass, origSelector);
    BOOL isAddNewMethod = class_addMethod(origClass, origSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (isAddNewMethod) {
        class_replaceMethod(origClass,
                            newSelector,
                            method_getImplementation(origMethod),
                            method_getTypeEncoding(origMethod));
    } else {
        class_replaceMethod(origClass,
                            newSelector,
                            class_replaceMethod(origClass,
                                                origSelector,
                                                method_getImplementation(newMethod),
                                                method_getTypeEncoding(newMethod)),
                            method_getTypeEncoding(origMethod));
    }
    
    return YES;
}

+ (NSString *)ts_className
{
    return NSStringFromClass(self);
}

- (NSString *)ts_className
{
    return [NSString stringWithUTF8String:class_getName([self class])];
}


@end
