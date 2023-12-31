//
//  LarkUIRemoteInputViewControllerProtect.m
//  LarkCrashSanitizer
//
//  Created by luyz on 2023/2/8.
//

#import "LarkUIRemoteInputViewControllerProtect.h"
#import "LKHookUtil.h"
#import <LKLoadable/Loadable.h>
#import <LarkCrashSanitizer/LarkCrashSanitizer-Swift.h>

@implementation LarkUIRemoteInputViewControllerProtect

- (LarkUIRemoteInputViewControllerProtect *)_compatView { return nil; }

- (void)setTouchableView:(UIView *)view {}

- (void)tearDownInputController {}

- (void)crashShield_tearDownInputController {
    if ([self respondsToSelector:@selector(_compatView)]) {
        __typeof__(self) compatView = [self _compatView];
        if ([compatView respondsToSelector:@selector(setTouchableView:)]) {
            [compatView setTouchableView:nil];
        }
    }
    [self crashShield_tearDownInputController];
}

@end

LoadableRunloopIdleFuncBegin(LarkCrashSanitizer_compatView_crashProtect)
if (@available (iOS 16, *)) {
    NSString *class1 = @"UICompatibility";
    NSString *class2 = @"InputViewController";
    Class clazz = NSClassFromString([class1 stringByAppendingString:class2]);
    SwizzleMethod(clazz, NSSelectorFromString(@"tearDownInputController"), [LarkUIRemoteInputViewControllerProtect class], @selector(crashShield_tearDownInputController));
}
LoadableRunloopIdleFuncEnd(LarkCrashSanitizer_compatView_crashProtect)
