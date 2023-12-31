//
//  HMDUSELForwarder.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/10.
//

#include "HMDMacro.h"
#import "HMDUSELForwarder.h"
#import <objc/runtime.h>

HMD_EXTERN void * HMDUSELForwarder_IMP_resolved_method_implementation(void);

@implementation HMDUSELForwarder

+ (BOOL)resolveClassMethod:(SEL)sel {
    return class_addMethod(object_getClass(self), sel, (IMP)HMDUSELForwarder_IMP_resolved_method_implementation, "^v@:");
}

@end
