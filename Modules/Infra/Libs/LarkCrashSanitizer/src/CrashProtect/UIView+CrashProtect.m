#import <objc/runtime.h>
#import <LarkFoundation/LKEncryptionTool.h>
#import <UIKit/UIKit.h>
#import "LKHookUtil.h"
#import <LKLoadable/Loadable.h>
#import <LarkCrashSanitizer/LarkCrashSanitizer-Swift.h>

@interface UIView (crash)

@end

@implementation UIView (crash)

- (void)s_layoutIfNeeded {
    if (![NSThread isMainThread]) {
        [self tagSwiftLogger];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAssert(false, @"s_layoutIfNeeded failed");
            [self s_layoutIfNeeded];
        });
    } else {
        [self s_layoutIfNeeded];
    }
}

- (void)s_setNeedsLayout {
    if (![NSThread isMainThread]) {
        [self tagSwiftLogger];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAssert(false, @"s_setNeedsLayout failed");
            [self s_setNeedsLayout];
        });
    } else {
        [self s_setNeedsLayout];
    }
}

- (void)s_layoutSubviews {
    if (![NSThread isMainThread]) {
        [self tagSwiftLogger];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAssert(false, @"s_layoutSubviews failed");
            [self s_layoutSubviews];
        });
    } else {
        [self s_layoutSubviews];
    }
}

- (void)s_setNeedsUpdateConstraints {
    if (![NSThread isMainThread]) {
        [self tagSwiftLogger];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAssert(false, @"s_setNeedsUpdateConstraints failed");
            [self s_setNeedsUpdateConstraints];
        });
    } else {
        [self s_setNeedsUpdateConstraints];
    }
}

- (void)tagSwiftLogger {
    NSArray *syms = [NSThread  callStackSymbols];
    NSString *info = @"";
    if ([syms count] > 1) {
        info = [NSString stringWithFormat:@"autolayout:<%@ %p> %@ - caller: %@ ", [self class], self, NSStringFromSelector(_cmd),[syms objectAtIndex:1]];
    } else {
        info = [NSString stringWithFormat:@"autolayout:<%@ %p> %@", [self class], self, NSStringFromSelector(_cmd)];
    }

    [WMFSwiftLogger infoWithMessage:info];
}

@end
