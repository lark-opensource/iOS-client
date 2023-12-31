//
//  UIView+CALayer+LarkMainThreadCheck.m
//  Action
//
//  Created by PGB on 2019/8/12.
//

#import "UIView+CALayer+LarkMainThreadCheck.h"
#import <Heimdallr/HMDUserExceptionTracker.h>
#import <LarkMonitor/LarkMonitor-swift.h>
#import <objc/runtime.h>
#import <LKLoadable/Loadable.h>
#pragma GCC diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

bool shouldEnableMainThreadCheck() {
    #if DEBUG
    return true;
    #else
    NSString* version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    return [version containsString:@"alpha"] || [version containsString:@"beta"];
    #endif
}

bool isValidOnCurrentThread() {
    NSThread* currentThread = NSThread.currentThread;
    BOOL isValidThread = currentThread.isMainThread || [currentThread.name isEqualToString:@"WebThread"] || [currentThread.name containsString:@"apple"] || [currentThread.name containsString:@"coremedia"];
    if (isValidThread) {
        return true;
    }

    // 获取当前队列的标签
    const char *label = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    // 判断标签中是否包含另一个字符串
    BOOL isValidQueue = strstr(label, "coremedia") != NULL;
    return isValidThread || isValidQueue;
}

@implementation UIView (LarkMainThreadCheck)

- (void)swizzlingForSetNeedsDisplay {
    [self mainThreadCheck];
    [self swizzlingForSetNeedsDisplay];
}

-(void)swizzlingForSetNeedsDisplayInRect: (CGRect) rect {
    [self mainThreadCheck];
    [self swizzlingForSetNeedsDisplayInRect:rect];
}

-(void)swizzlingForSetNeedsLayout {
    [self mainThreadCheck];
    [self swizzlingForSetNeedsLayout];
}

- (void)mainThreadCheck {
    if (!isValidOnCurrentThread()) {
        [[HMDUserExceptionTracker sharedTracker] trackAllThreadsLogExceptionType:@"UI_Updating_not_on_main_thread" skippedDepth:0 customParams: nil filters:nil callback: ^(NSError *_Nullable error){}];
    }
}

+ (void)methodSwizzlingFor: (SEL) exchangedSelector exchangingSelector: (SEL) exchangingSelector {
    Method exchangedMethod = class_getInstanceMethod(UIView.class, exchangedSelector);
    Method exchangingMethod = class_getInstanceMethod(UIView.class, exchangingSelector);

    BOOL exists = !class_addMethod(UIView.class, exchangedSelector,
                                   method_getImplementation(exchangedMethod),
                                   method_getTypeEncoding(exchangedMethod));
    if (exists) {
        method_exchangeImplementations(exchangedMethod, exchangingMethod);
    }
}
@end

LoadableRunloopIdleFuncBegin(UIViewMainThreadCheck)
if (!shouldEnableMainThreadCheck()) {
    return;
}

static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    [UIView methodSwizzlingFor:@selector(setNeedsDisplay) exchangingSelector:@selector(swizzlingForSetNeedsDisplay)];
    [UIView methodSwizzlingFor:@selector(swizzlingForSetNeedsDisplayInRect:) exchangingSelector:@selector(swizzlingForSetNeedsDisplayInRect:)];
    [UIView methodSwizzlingFor:@selector(setNeedsLayout) exchangingSelector:@selector(swizzlingForSetNeedsLayout)];
});
LoadableRunloopIdleFuncEnd(UIViewMainThreadCheck)

@implementation CALayer (LarkMainThreadCheck)

- (void)swizzlingForSetNeedsDisplay {
    [self mainThreadCheck];
    [self swizzlingForSetNeedsDisplay];
}

-(void)swizzlingForSetNeedsDisplayInRect: (CGRect) rect {
    [self mainThreadCheck];
    [self swizzlingForSetNeedsDisplayInRect:rect];
}

-(void)swizzlingForSetNeedsLayout {
    [self mainThreadCheck];
    [self swizzlingForSetNeedsLayout];
}

- (void)mainThreadCheck {
    if (!isValidOnCurrentThread()) {
        [[HMDUserExceptionTracker sharedTracker] trackAllThreadsLogExceptionType:@"UI_Updating_not_on_main_thread" skippedDepth:0 customParams: nil filters:nil callback: ^(NSError *_Nullable error){}];
    }
}

+ (void)methodSwizzlingFor: (SEL) exchangedSelector exchangingSelector: (SEL) exchangingSelector {
    Method exchangedMethod = class_getInstanceMethod(CALayer.class, exchangedSelector);
    Method exchangingMethod = class_getInstanceMethod(CALayer.class, exchangingSelector);

    BOOL exists = !class_addMethod(CALayer.class, exchangedSelector,
                                   method_getImplementation(exchangedMethod),
                                   method_getTypeEncoding(exchangedMethod));
    if (exists) {
        method_exchangeImplementations(exchangedMethod, exchangingMethod);
    }
}

LoadableRunloopIdleFuncBegin(CALayerMainThreadCheck)
if (!shouldEnableMainThreadCheck()) {
    return;
}

static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    [CALayer methodSwizzlingFor:@selector(setNeedsDisplay) exchangingSelector:@selector(swizzlingForSetNeedsDisplay)];
    [CALayer methodSwizzlingFor:@selector(swizzlingForSetNeedsDisplayInRect:) exchangingSelector:@selector(swizzlingForSetNeedsDisplayInRect:)];
    [CALayer methodSwizzlingFor:@selector(setNeedsLayout) exchangingSelector:@selector(swizzlingForSetNeedsLayout)];
});
LoadableRunloopIdleFuncEnd(CALayerMainThreadCheck)

@end
