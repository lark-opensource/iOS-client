//
//  UIViewController+HMDControllerMonitor.m
//  Heimdallr
//
//  Created by joy on 2018/5/14.
//

#import "UIViewController+HMDControllerMonitor.h"
#import "HMDControllerMonitor.h"
#import "UIViewController+HMDUITracker.h"
#import <objc/runtime.h>
#import "HMDTimeSepc.h"

@implementation UIViewController (HMDControllerMonitor)

- (void)didFinishConcurrentRendering {
    NSTimeInterval timestamp = HMD_XNUSystemCall_timeSince1970() * 1000;
    if ([self.hmdPageInitStartTime doubleValue] > 1) {
        [[HMDControllerMonitor sharedInstance] addControllerMonitorWithPageName:NSStringFromClass([self class]) methodSelector:@"render_total" timeInterval:(timestamp - [self.hmdPageInitStartTime doubleValue]) isFirstOpen:[self.hmdIsFirstOpen boolValue]];
    }
}

- (void)didFnishConcurrentRendering {
    [self didFinishConcurrentRendering];
}

- (void)hmd_initActionStart {
    NSTimeInterval startTime = HMD_XNUSystemCall_timeSince1970() * 1000;
    
    self.hmdPageInitStartTime = [NSNumber numberWithDouble:startTime];
    
    self.hmdIsFirstOpen = @(YES);
}
- (void)hmd_initViewActionEnd {
    NSTimeInterval endTime = HMD_XNUSystemCall_timeSince1970() * 1000;
    
    [[HMDControllerMonitor sharedInstance] addControllerMonitorWithPageName:NSStringFromClass([self class]) methodSelector:NSStringFromSelector(@selector(init)) timeInterval:(endTime - [self.hmdPageInitStartTime doubleValue]) isFirstOpen:[self.hmdIsFirstOpen boolValue]];
}
- (void)hmd_loadViewActionStart {
    NSTimeInterval startTime = HMD_XNUSystemCall_timeSince1970() * 1000;

    self.hmdLoadViewStartTime = [NSNumber numberWithDouble:startTime];
}
- (void)hmd_loadViewActionEnd {
    NSTimeInterval endTime = HMD_XNUSystemCall_timeSince1970() * 1000;
    NSTimeInterval loadTime = endTime - [self.hmdLoadViewStartTime doubleValue];
    self.hmdLoadViewTime = [NSNumber numberWithDouble:loadTime];
    
    [[HMDControllerMonitor sharedInstance] addControllerMonitorWithPageName:NSStringFromClass([self class]) methodSelector:NSStringFromSelector(@selector(loadView)) timeInterval:loadTime isFirstOpen:[self.hmdIsFirstOpen boolValue]];
}

- (void)hmd_viewDidLoadActionStart {
    NSTimeInterval startTime = HMD_XNUSystemCall_timeSince1970() * 1000;
    self.hmdViewDidLoadStartTime = [NSNumber numberWithDouble:startTime];
}
- (void)hmd_viewDidLoadActionEnd {
    NSTimeInterval endTime = HMD_XNUSystemCall_timeSince1970() * 1000;
    NSTimeInterval didLoadTime = endTime - [self.hmdViewDidLoadStartTime doubleValue];
    self.hmdViewDidLoadTime = [NSNumber numberWithDouble:didLoadTime];
    
    [[HMDControllerMonitor sharedInstance] addControllerMonitorWithPageName:NSStringFromClass([self class]) methodSelector:NSStringFromSelector(@selector(viewDidLoad)) timeInterval:didLoadTime isFirstOpen:[self.hmdIsFirstOpen boolValue]];
}
- (void)hmd_viewWillAppearActionStart {
    NSTimeInterval startTime = HMD_XNUSystemCall_timeSince1970() * 1000;
    self.hmdViewWillAppearStartTime = [NSNumber numberWithDouble:startTime];
}
- (void)hmd_viewWillAppearActionEnd {
    NSTimeInterval endTime = HMD_XNUSystemCall_timeSince1970() * 1000;
    NSTimeInterval willAppearTime = endTime - [self.hmdViewWillAppearStartTime doubleValue];
    self.hmdViewWillAppearTime = [NSNumber numberWithDouble:willAppearTime];
    
    [[HMDControllerMonitor sharedInstance] addControllerMonitorWithPageName:NSStringFromClass([self class]) methodSelector:@"viewWillAppear" timeInterval:willAppearTime isFirstOpen:[self.hmdIsFirstOpen boolValue]];
}
- (void)hmd_viewDidAppearActionStart {
    NSTimeInterval startTime = HMD_XNUSystemCall_timeSince1970() * 1000;
    self.hmdViewDidAppearStartTime = [NSNumber numberWithDouble:startTime];
}
- (void)hmd_viewDidAppearActionEnd {
    NSTimeInterval endTime = HMD_XNUSystemCall_timeSince1970() * 1000;
    NSTimeInterval didAppearTime = endTime - [self.hmdViewDidAppearStartTime doubleValue];
    
    [[HMDControllerMonitor sharedInstance] addControllerMonitorWithPageName:NSStringFromClass([self class]) methodSelector:@"viewDidAppear" timeInterval:didAppearTime isFirstOpen:[self.hmdIsFirstOpen boolValue]];
    
    NSTimeInterval methodsTotalTime = [self.hmdLoadViewTime doubleValue] + [self.hmdViewDidLoadTime doubleValue] + [self.hmdViewWillAppearTime doubleValue] + didAppearTime;
    
    [[HMDControllerMonitor sharedInstance] addControllerMonitorWithPageName:NSStringFromClass([self class]) methodSelector:@"methodsTotalTime" timeInterval:methodsTotalTime isFirstOpen:[self.hmdIsFirstOpen boolValue]];

    self.hmdIsFirstOpen = @(NO);
}

#pragma mark - setter and getter

- (NSNumber *)hmdLoadViewTime {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHmdLoadViewTime:(NSNumber *)hmdLoadViewTime {
    objc_setAssociatedObject(self, @selector(hmdLoadViewTime), hmdLoadViewTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)hmdViewWillAppearTime {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHmdViewWillAppearTime:(NSNumber *)hmdViewWillAppearTime {
    objc_setAssociatedObject(self, @selector(hmdViewWillAppearTime), hmdViewWillAppearTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)hmdViewDidLoadTime {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHmdViewDidLoadTime:(NSNumber *)hmdViewDidLoadTime {
    objc_setAssociatedObject(self, @selector(hmdViewDidLoadTime), hmdViewDidLoadTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)hmdLoadViewStartTime {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHmdLoadViewStartTime:(NSNumber *)hmdLoadViewStartTime {
    objc_setAssociatedObject(self, @selector(hmdLoadViewStartTime), hmdLoadViewStartTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)hmdViewDidLoadStartTime {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setHmdViewDidLoadStartTime:(NSNumber *)hmdViewDidLoadStartTime {
    objc_setAssociatedObject(self, @selector(hmdViewDidLoadStartTime), hmdViewDidLoadStartTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)hmdViewWillAppearStartTime {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setHmdViewWillAppearStartTime:(NSNumber *)hmdViewWillAppearStartTime {
    objc_setAssociatedObject(self, @selector(hmdViewWillAppearStartTime), hmdViewWillAppearStartTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)hmdViewDidAppearStartTime {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setHmdViewDidAppearStartTime:(NSNumber *)hmdViewDidAppearStartTime {
    objc_setAssociatedObject(self, @selector(hmdViewDidAppearStartTime), hmdViewDidAppearStartTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)hmdPageInitStartTime {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setHmdPageInitStartTime:(NSNumber *)hmdPageInitStartTime {
    objc_setAssociatedObject(self, @selector(hmdPageInitStartTime), hmdPageInitStartTime, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)hmdIsFirstOpen {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHmdIsFirstOpen:(NSNumber *)hmdIsFirstOpen {
    objc_setAssociatedObject(self, @selector(hmdIsFirstOpen), hmdIsFirstOpen, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
