//
//  LarkUIKeyboardTaskQueueProtect.m
//  LarkCrashSanitizer
//
//  Created by luyz on 2023/5/16.
//

#import "LarkUIKeyboardTaskQueueProtect.h"
#import "LKHookUtil.h"
#import <LKLoadable/Loadable.h>
#import <LarkCrashSanitizer/LarkCrashSanitizer-Swift.h>
#import <Heimdallr/HMDCrashPreventMachException.h>
#include <objc/runtime.h>

#define KEYBOARD_CRASH_SCOPE "com.bytedance.lark.keyboard.taskQueue"
#define KEYBOARD_CRASH_SCOPE_LENGTH 37

#ifndef COMPILE_ASSERT
#define COMPILE_ASSERT(condition) ((void)sizeof(char[1 - 2*!(condition)]))
#endif

__kindof NSObject * HMDRetain(__kindof NSObject *object);
__kindof NSObject * HMDRelease(__kindof NSObject *object);

static Ivar where_is_array_ivar_in_class;

@implementation LarkUIKeyboardTaskQueueProtect

- (void)crashShield_promoteDeferredTaskIfIdle {
    const char *scope = KEYBOARD_CRASH_SCOPE;
    
    HMDMachRecoverContext context = {
        .context_size = sizeof(HMDMachRecoverContext),
        .scope_length = KEYBOARD_CRASH_SCOPE_LENGTH
    };
    
    COMPILE_ASSERT(sizeof((char[]){KEYBOARD_CRASH_SCOPE}) == KEYBOARD_CRASH_SCOPE_LENGTH + 1);
    
    HMDMachRecoverOption option = HMDMachRecoverOptionExceptionType_ALL |
                                  HMDMachRecoverOptionScopeCheckType_checkWhenCrash;
    
    bool crashed = HMDCrashPreventMachExceptionProtect
            (scope, option, &context, ^{
                [self crashShield_promoteDeferredTaskIfIdle];
                GCC_FORCE_NO_OPTIMIZATION
             });

    if(crashed) {
        id oldArray = object_getIvar(self, where_is_array_ivar_in_class);
        HMDRetain(oldArray);
        NSMutableArray *newArray = [NSMutableArray new];
        object_setIvar(self, where_is_array_ivar_in_class, newArray);
        [WMFSwiftLogger infoWithMessage:@"keyboardtaskqueue crash protected"];
    } else {
        //没有crash的情况，不做处理
    }
}

@end

LoadableRunloopIdleFuncBegin(LarkCrashSanitizer_UIKeyboardTaskQueue_Protect)
if (@available (iOS 16, *)) {
    Class clazz = NSClassFromString(@"UIKeyboardTaskQueue");
    where_is_array_ivar_in_class = class_getInstanceVariable(clazz, "_deferredTasks");
    if (where_is_array_ivar_in_class) {
        SwizzleMethod(clazz, NSSelectorFromString(@"promoteDeferredTaskIfIdle"), [LarkUIKeyboardTaskQueueProtect class], @selector(crashShield_promoteDeferredTaskIfIdle));
    }
}
LoadableRunloopIdleFuncEnd(LarkCrashSanitizer_UIKeyboardTaskQueue_Protect)
