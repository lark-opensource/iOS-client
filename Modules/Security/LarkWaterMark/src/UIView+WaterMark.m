//
//  UIView+WaterMark.m
//  WaterMark
//
//  Created by qihao on 2019/4/17.
//

#import "UIView+WaterMark.h"
#import <objc/runtime.h>
#import "LarkWaterMark/LarkWaterMark-Swift.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <LKLoadable/Loadable.h>

@implementation UIView (WaterMark)

static Class SiwzzlingViewClass(void) {
    return NSClassFromString(@"_UIRemoteView");
}

static Class UIContextViewClass(void) {
    return NSClassFromString(@"_UIContextLayerHostView");
}

- (void)waterMark_willMoveToWindow:(UIWindow*)window {
    [self waterMark_willMoveToWindow:window];

    NSAssert([self isKindOfClass:SiwzzlingViewClass()] || [self isKindOfClass:UIContextViewClass()], @"should be remote view");
    UIWindow* oldWindow = self.window;
    if (oldWindow) {
        if (oldWindow.remoteViewCount > 1) {
            oldWindow.remoteViewCount -= 1;
        } else {
            oldWindow.remoteViewCount = 0;
            WaterMarkView* waterView = oldWindow.waterMarkImageView;
            if (waterView) {
                [oldWindow addSubview:waterView];
            }
            waterView.isFirstView = true;
        }
    }
}

- (void)waterMark_didMoveToWindow {
    [self waterMark_didMoveToWindow];
    NSAssert([self isKindOfClass:SiwzzlingViewClass()] || [self isKindOfClass:UIContextViewClass()], @"should be remote view");
    UIWindow* currentWindow = self.window;
    WaterMarkView* waterView = currentWindow.waterMarkImageView;
    if (!waterView) { return; }
    if (currentWindow) {
        if (!currentWindow.remoteViewCount) {
            currentWindow.remoteViewCount = 0;
        }
        currentWindow.remoteViewCount += 1;
        UIView *view = self;
        while (view.superview && view.superview != currentWindow) {
            view = view.superview;
        }
        if ([currentWindow.subviews indexOfObject:view] < [currentWindow.subviews indexOfObject:waterView]) {
            [currentWindow insertSubview:waterView belowSubview:view];
        }
        waterView.isFirstView = false;
    }
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

@implementation UIWindow (DidAddSubview)

- (void)waterMark_didAddSubview:(UIView *)viewAdded {
    [self waterMark_didAddSubview:viewAdded];
    [self.subviews enumerateObjectsUsingBlock:^(id view, NSUInteger idx, BOOL *stop) {
        if ([view isKindOfClass:[WaterMarkView class]] && self.remoteViewCount == 0) {
            WaterMarkView *waterMarkView = (WaterMarkView *)view;
            [self bringSubviewToFront:waterMarkView];
            waterMarkView.isFirstView = true;
            *stop = YES;
        }
    }];
}

+ (void)replaceDidAddSubviewClassMethod {
    [[self class] btd_swizzleClassMethod:@selector(didAddSubview:) with:@selector(waterMark_didAddSubview:)];
}

@end


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_13_0
@implementation UIViewController (Present)

static Class SiwzzlingViewControllerClass(void) {
    return NSClassFromString(@"UIViewController");
}

- (void)waterMark_presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion {
    [self waterMark_presentViewController:viewControllerToPresent animated:flag completion:^{
        if (completion != NULL) {
            completion();
        }
        UIWindow* currentWindow = viewControllerToPresent.view.window;
        WaterMarkView* waterView = currentWindow.waterMarkImageView;
        /// 需要判断currentWindow是否有remoteView，如果有，则不能提前，不然会覆盖remoteView
        if (currentWindow && waterView && currentWindow.remoteViewCount == 0) {
            [currentWindow bringSubviewToFront:waterView];
        }
    }];
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
LoadableRunloopIdleFuncBegin(UIView_WaterMarkVC)

if (![WaterMarkSwiftFGManager isWatermarkHitTestFGOn]) {
    [UIViewController methodSiwzzling:SiwzzlingViewControllerClass()
                               origin:@selector(presentViewController:animated:completion:)
                          replacement:@selector(waterMark_presentViewController:animated:completion:)];
}

LoadableRunloopIdleFuncEnd(UIView_WaterMarkVC)
#endif

LoadableRunloopIdleFuncBegin(UIView_WaterMark)

if (![WaterMarkSwiftFGManager isWatermarkHitTestFGOn]) {
    [UIView methodSiwzzling:SiwzzlingViewClass()
                     origin:@selector(didMoveToWindow)
                replacement:@selector(waterMark_didMoveToWindow)];

    [UIView methodSiwzzling:SiwzzlingViewClass()
                     origin:@selector(willMoveToWindow:)
                replacement:@selector(waterMark_willMoveToWindow:)];


    if (@available(iOS 17.0, *)) {
        [UIView methodSiwzzling:UIContextViewClass()
                         origin:@selector(didMoveToWindow)
                    replacement:@selector(waterMark_didMoveToWindow)];
        
        [UIView methodSiwzzling:UIContextViewClass()
                         origin:@selector(willMoveToWindow:)
                    replacement:@selector(waterMark_willMoveToWindow:)];
    }
}

if (![WaterMarkSwiftFGManager isWatermarkHitTestFGOn] && [WaterMarkSwiftFGManager isWatermarkWindowFGOn]) {
    [UIWindow replaceDidAddSubviewClassMethod];
}

LoadableRunloopIdleFuncEnd(UIView_WaterMark)
