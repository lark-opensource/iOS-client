//
//  UIViewController+TMATrack.m
//  Timor
//
//  Created by CsoWhy on 2018/8/31.
//

#import "UIViewController+TMATrack.h"
#import "NSObject+BDPExtension.h"
//#import "BDPBootstrapHeader.h"
#import <LKLoadable/Loadable.h>

#if __has_feature(modules)
@import ObjectiveC;
#else
#import <objc/runtime.h>
#endif

#pragma GCC diagnostic ignored "-Wundeclared-selector"

LoadableRunloopIdleFuncBegin(UIViewControllerTMATrackSwizzle)
[UIViewController performSelector:@selector(bdp_viewController_TMATrack_swizzle)];
LoadableRunloopIdleFuncEnd(UIViewControllerTMATrackSwizzle)

@implementation UIViewController (TMATrack)
+ (void)bdp_viewController_TMATrack_swizzle {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self bdp_swizzleOriginInstanceMethod:@selector(viewWillDisappear:) withHookInstanceMethod:@selector(tma_track_viewWillDisappear:)];
    });
}


- (void)tma_track_viewWillAppear:(BOOL)animated
{
    NSMutableDictionary *willShowViewControllerItem = [[NSMutableDictionary alloc] init];
    [willShowViewControllerItem setValue:[NSString stringWithFormat:@"%@_enter", NSStringFromClass([self class])] forKey:@"viewControllerName"];

    [willShowViewControllerItem setValue:@([[NSDate date] timeIntervalSince1970]) forKey:@"timestamp"];

    [self tma_track_viewWillAppear:animated];

    if (self.tmaTrackStayEnable) {
        if ([self tma_hadObservedNotification] == NO) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(tma_ApplicationDidEnterBackground)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(tma_ApplicationWillEnterForeground)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];
            [self tma_setHadObservedNotification:YES];
        }

        [self tma_startTrack];
    }
}

- (void)tma_track_viewWillDisappear:(BOOL)animated
{
    NSMutableDictionary *willHideViewControllerItem = [[NSMutableDictionary alloc] init];
    //    NSString * className = NSStringFromClass([self class]);
    [willHideViewControllerItem setValue:[NSString stringWithFormat:@"%@_leave", NSStringFromClass([self class])] forKey:@"viewControllerName"];
    [willHideViewControllerItem setValue:@([[NSDate date] timeIntervalSince1970]) forKey:@"timestamp"];
    [self tma_track_viewWillDisappear:animated];

    if (self.tmaTrackStayEnable) {
        [self tma_endTrack];
        if ([self tma_hadObservedNotification] == YES) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
            [self tma_setHadObservedNotification:NO];
        }
    }
}

- (void)tma_ApplicationDidEnterBackground
{
    if (self.tmaTrackStayEnable) {
        [self tma_endTrack];

        if ([self respondsToSelector:@selector(trackEndedByAppWillEnterBackground)]) {
            [self trackEndedByAppWillEnterBackground];
        }
    }
}

- (void)tma_ApplicationWillEnterForeground
{
    if (self.tmaTrackStayEnable) {
        [self tma_startTrack];

        if ([self respondsToSelector:@selector(trackStartedByAppWillEnterForground)]) {
            [self trackStartedByAppWillEnterForground];
        }
    }
}

- (void)tma_startTrack
{
    self.tmaTrackStartTime = [[NSDate date] timeIntervalSince1970];
}

- (void)tma_endTrack
{
    self.tmaTrackStayTime += [[NSDate date] timeIntervalSince1970] - self.tmaTrackStartTime;
}

- (void)tma_resetStayTime
{
    self.tmaTrackStayTime = 0;
}

#pragma mark Properties

- (NSTimeInterval)tmaTrackStayTime
{
    return (NSTimeInterval)[objc_getAssociatedObject(self, @selector(tmaTrackStayTime)) doubleValue];
}

- (void)setTmaTrackStayTime:(NSTimeInterval)tmaTrackStayTime
{
    objc_setAssociatedObject(self, @selector(tmaTrackStayTime), @(tmaTrackStayTime), OBJC_ASSOCIATION_RETAIN);
}

- (NSTimeInterval)tmaTrackStartTime
{
    return (NSTimeInterval)[objc_getAssociatedObject(self, @selector(tmaTrackStartTime)) doubleValue];
}

- (void)setTmaTrackStartTime:(NSTimeInterval)tmaTrackStartTime
{
    objc_setAssociatedObject(self, @selector(tmaTrackStartTime), @(tmaTrackStartTime), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)tmaTrackStayEnable
{
    return (BOOL)[objc_getAssociatedObject(self, @selector(tmaTrackStayEnable)) boolValue];
}

- (void)setTmaTrackStayEnable:(BOOL)tmaTrackStayEnable
{
    objc_setAssociatedObject(self, @selector(tmaTrackStayEnable), @(tmaTrackStayEnable), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)tma_hadObservedNotification
{
    return (BOOL)[objc_getAssociatedObject(self, @selector(tma_hadObservedNotification)) boolValue];
}

- (void)tma_setHadObservedNotification:(BOOL)hadSet
{
    objc_setAssociatedObject(self, @selector(tma_hadObservedNotification), @(hadSet), OBJC_ASSOCIATION_RETAIN);
}

@end
