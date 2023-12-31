//
// JATAnyCallForwarder.m
// 
//
// Created by Aircode on 2022/8/12

#import "JATAnyCallForwarder.h"
#import <objc/runtime.h>

@implementation JATAnyCallForwarder

static void * IMP_resolved_method_implementation(void) {
    return NULL;
}

+ (BOOL)resolveClassMethod:(SEL)sel {
    return class_addMethod(object_getClass(self), sel, (IMP)IMP_resolved_method_implementation, "^v@:");
}


@end
