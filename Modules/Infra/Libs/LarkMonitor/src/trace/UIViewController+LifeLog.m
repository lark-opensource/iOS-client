//
//  UIViewController+LifeLog.m
//  LarkApp
//
//  Created by sniperj on 2019/8/5.
//

#import "UIViewController+LifeLog.h"
#import <objc/runtime.h>
#import <LarkMonitor/LarkMonitor-swift.h>
#import <Heimdallr/HMDMemoryUsage.h>
#import <LKLoadable/Loadable.h>

@implementation UIViewController(LifeLog)

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

-(void)fb_viewDidAppear:(BOOL)animated
{
    [LarkAllActionLoggerLoad logLifeCycleInfoWithInfo:[NSString stringWithFormat:@"viewDidAppear %@", self]];
    [self fb_viewDidAppear:animated];
}

-(void)fb_viewDidDisappear:(BOOL)animated
{
    [LarkAllActionLoggerLoad logLifeCycleInfoWithInfo:[NSString stringWithFormat:@"disappear %@ currentMemory %lf M", self, (double)hmd_getAppMemoryBytes() / (double)(1024 * 1024)]];
    [self fb_viewDidDisappear:animated];
}

@end

LoadableRunloopIdleFuncBegin(LarkMonitor_lifeLog)
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    [UIViewController swizzleSEL:@selector(viewDidAppear:) withSEL:@selector(fb_viewDidAppear:)];
    [UIViewController swizzleSEL:@selector(viewDidDisappear:) withSEL:@selector(fb_viewDidDisappear:)];
});
LoadableRunloopIdleFuncEnd(LarkMonitor_lifeLog)
