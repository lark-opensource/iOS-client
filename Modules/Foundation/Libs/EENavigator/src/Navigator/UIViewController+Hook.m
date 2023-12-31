//
//  UIViewController+Hook.m
//  EENavigator
//
//  Created by liuwanlin on 2018/9/29.
//

#import "UIViewController+Hook.h"
#import <objc/runtime.h>
#import "EENavigator/EENavigator-Swift.h"
#import "LKLoadable/Loadable.h"

#pragma GCC diagnostic ignored "-Wundeclared-selector"

@implementation UIViewController(Hook)

+ (void)hook {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self performSelector: @selector(swizzleMethod)];
    });

    [UIViewController methodSiwzzling:[self class]
                               origin:@selector(viewDidAppear:)
                          replacement:@selector(navigator_viewDidAppear:)];
}

- (void)navigator_viewDidAppear:(BOOL)animated {
    [self navigator_viewDidAppear:animated];
    [Navigator.shared didAppearTimeTrackerToVC:self];
}

+ (void)methodSiwzzling:(Class)cls origin:(SEL)original replacement:(SEL)replacement {
    Method originalMethod = class_getInstanceMethod(cls, original);
    IMP originalImplementation = method_getImplementation(originalMethod);
    const char *originalArgTypes = method_getTypeEncoding(originalMethod);

    Method replacementMethod = class_getInstanceMethod(cls, replacement);
    IMP replacementImplementation = method_getImplementation(replacementMethod);
    const char *replacementArgTypes = method_getTypeEncoding(replacementMethod);

    if (class_addMethod(cls, original, replacementImplementation, replacementArgTypes)) {
        class_replaceMethod(cls, replacement, originalImplementation, originalArgTypes);
    } else {
        method_exchangeImplementations(originalMethod, replacementMethod);
    }
}

@end

LoadableRunloopIdleFuncBegin(EENavigator_UIViewController_Hook)

[UIViewController hook];

LoadableRunloopIdleFuncEnd(EENavigator_UIViewController_Hook)
