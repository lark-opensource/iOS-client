//
//  NSFileHandle+Debug.m
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/20.
//

#import "NSFileHandle+Debug.h"
#import <objc/runtime.h>

@implementation NSFileHandle (Debug)

- (void)setSecureAccess:(BOOL)secureAccess
{
    objc_setAssociatedObject(self, @selector(isSecureAccess), @(secureAccess), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isSecureAccess
{
    NSNumber *value = objc_getAssociatedObject(self, @selector(isSecureAccess));
    return [value boolValue];
}

@end
