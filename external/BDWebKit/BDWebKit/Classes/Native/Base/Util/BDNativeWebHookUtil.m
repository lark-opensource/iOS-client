//
//  BDNativeWebHookUtil.m
//  BDNativeWebComponent
//
//  Created by liuyunxuan on 2019/8/20.
//

#import "BDNativeWebHookUtil.h"

@implementation BDNativeWebHookUtil

+ (BOOL)swizzleClass:(Class)class
            oriMethod:(SEL)origSel_
            altMethod:(SEL)altSel_
{
    Method origMethod = class_getInstanceMethod(class, origSel_);
    if (!origMethod) {
        return NO;
    }
    
    Method altMethod = class_getInstanceMethod(class, altSel_);
    if (!altMethod) {
        return NO;
    }
    
    class_addMethod(class,
                    origSel_,
                    class_getMethodImplementation(class, origSel_),
                    method_getTypeEncoding(origMethod));
    
    class_addMethod(class,
                    altSel_,
                    class_getMethodImplementation(class, altSel_),
                    method_getTypeEncoding(altMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(class, origSel_), class_getInstanceMethod(class, altSel_));
    return YES;
}
@end
