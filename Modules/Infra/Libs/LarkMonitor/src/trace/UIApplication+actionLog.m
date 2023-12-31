//
//  UIApplication+actionLog.m
//  LarkApp
//
//  Created by sniperj on 2019/8/6.
//

#import "UIApplication+actionLog.h"
#import <LarkMonitor/LarkMonitor-swift.h>
#import <LKLoadable/Loadable.h>
#import <objc/runtime.h>


@implementation UIApplication (actionLog)

- (void)swizz_sendEvent:(UIEvent *)event {
    [LarkAllActionLoggerLoad logUIEventWithEvent:event];
    [self swizz_sendEvent:event];
}

+ (void)swizzleSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL {

    Class class = [self class];

    Method originalMethod = class_getInstanceMethod(class, originalSEL);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSEL);

    BOOL didAddMethod =
    class_addMethod(class,
                    originalSEL,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSEL,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end

LoadableRunloopIdleFuncBegin(LarkMonitor_actionLog)
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    [UIApplication swizzleSEL:@selector(sendEvent:) withSEL:@selector(swizz_sendEvent:)];
    [LarkUITracker startTrackUI];
    [LarkLifeCycleTracker startTrackUI];
});
LoadableRunloopIdleFuncEnd(LarkMonitor_actionLog)
