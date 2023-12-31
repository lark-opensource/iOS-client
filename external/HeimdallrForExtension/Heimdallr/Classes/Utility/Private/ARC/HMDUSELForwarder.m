//
//  HMDUSELForwarder.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/10.
//

#import "HMDUSELForwarder.h"
#import <objc/runtime.h>

@implementation HMDUSELForwarder

static void * IMP_resolved_method_implementation(void) {
    return NULL;
}

+ (BOOL)resolveClassMethod:(SEL)sel {
    return class_addMethod(object_getClass(self), sel, (IMP)IMP_resolved_method_implementation, "^v@:");
}

@end
