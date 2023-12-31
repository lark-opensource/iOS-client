//
//  NSObject+ACCSwizzle.m
//  Pods
//
//  Created by Hao Yipeng on 2019/12/11.
//

#import "NSObject+ACCSwizzle.h"
#import <objc/runtime.h>

@implementation NSObject (ACCSwizzle)

+ (void)acc_swizzleMethodsOfClass:(Class)cls originSelector:(SEL)originSelector targetSelector:(SEL)targetSelector
{
    Method originMethod = class_getInstanceMethod(cls, originSelector);
    Method targetMethod = class_getInstanceMethod(cls, targetSelector);
    BOOL didAddMethod = class_addMethod(cls, originSelector, method_getImplementation(targetMethod), method_getTypeEncoding(targetMethod));
    if (didAddMethod) {
        class_replaceMethod(cls, targetSelector, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, targetMethod);
    }
}

@end
