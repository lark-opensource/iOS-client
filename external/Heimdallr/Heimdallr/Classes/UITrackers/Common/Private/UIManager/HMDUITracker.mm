//
//  HMDUITracker.m
//  HMDUITrackerRecreate
//
//  Created by sunrunwang on 2021/12/2.
//

#include <stdatomic.h>
#import "HMDMacro.h"
#import "HMDUITracker.h"
#import "HMDUITracker+Private.h"
#import "UIControl+HMDUITracker.h"
#import "UIGestureRecognizer+HMDUITracker.h"
#import "UINavigationController+HMDUITracker.h"
#import "UITabBarController+HMDUITracker.h"
#import "UIViewController+HMDUITracker.h"

static NSString *const HMDApplicationTrackName = @"appliction";

static inline NSString *HMDUIEventNameWithEvent(HMDUITrackableEvents event);

@implementation HMDUITracker {
    atomic_bool _isRuning;
    NSMutableSet *_liveContexts;
}

#pragma mark - Intialization 单例的生成

+ (instancetype)sharedInstance {
    static HMDUITracker *tracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tracker = [[HMDUITracker alloc] init];
    });
    return tracker;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _liveContexts = [NSMutableSet set];
        atomic_init(&_isRuning, false);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResignActive:)
                                                     name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

#pragma mark - Open & Close 开启和关闭

- (void)start {
    DEBUG_ASSERT(!NSThread.isMainThread);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIControl              hmd_startSwizzle];
        [UIGestureRecognizer    hmd_startSwizzle];
        [UINavigationController hmd_startSwizzle];
        [UITabBarController     hmd_startSwizzle];
        [UIViewController       hmd_startSwizzle];
    });
    atomic_store_explicit(&_isRuning, true, memory_order_release);
}

- (void)stop {
    DEBUG_ASSERT(!NSThread.isMainThread);
    
    atomic_store_explicit(&_isRuning, false, memory_order_release);
}


#pragma mark - NSNotification Application Status 变化回调 (在 init 内注册)

- (void)willResignActive:(NSNotification *)notification {
    [self trackWithName:HMDApplicationTrackName event:@"will_resign_active" parameters:nil];
}

- (void)didBecomeActive:(NSNotification *)notification {
    [self trackWithName:HMDApplicationTrackName event:@"did_become_active" parameters:nil];
}

- (void)willEnterForeground:(NSNotification *)notification {
    [self trackWithName:HMDApplicationTrackName event:@"will_enter_foreground" parameters:nil];
}

- (void)didEnterBackground:(NSNotification *)notification {
    [self trackWithName:HMDApplicationTrackName event:@"did_enter_background" parameters:nil];
}

#pragma mark - Private Callback Method 这是各个模块给 UITracker 回调的接口, 我们将信息传给 delegate

- (void)trackableContextDidStart:(HMDUITrackableContext *)context {
    DEBUG_ASSERT(NSThread.isMainThread);
    
    [_liveContexts addObject:context];
}

- (void)trackableContextDidEnd:(HMDUITrackableContext *)context {
    DEBUG_ASSERT(NSThread.isMainThread);
    
    [_liveContexts removeObject:context];
}

- (void)trackableContext:(HMDUITrackableContext *)context didTriggerEvent:(HMDUITrackableEvents)event {
    DEBUG_ASSERT(NSThread.isMainThread);
    
    [self trackableContext:context didTriggerEvent:event parameters:nil];
}

- (void)trackableContext:(HMDUITrackableContext *)context didTriggerEvent:(HMDUITrackableEvents)event parameters:(NSDictionary *)parameters {
    DEBUG_ASSERT(NSThread.isMainThread);
    
    [self trackableContext:context eventWithName:HMDUIEventNameWithEvent(event) parameters:parameters];
}

- (void)trackableContext:(HMDUITrackableContext *)context
           eventWithName:(NSString *)event
              parameters:(NSDictionary *)parameters {
    DEBUG_ASSERT(NSThread.isMainThread);
    
    if (atomic_load_explicit(&_isRuning, memory_order_acquire)) {
        if ([(id)self.delegate respondsToSelector:@selector(hmdTrackableContext:eventWithName:parameters:)]) {
            [self.delegate hmdTrackableContext:context eventWithName:event parameters:parameters];
        }
    }
}

- (void)trackWithName:(NSString *)name
                event:(NSString *)event
           parameters:(NSDictionary *)parameters {
    DEBUG_ASSERT(NSThread.isMainThread);
    
    if (atomic_load_explicit(&_isRuning, memory_order_acquire)) {
        if ([(id)self.delegate respondsToSelector:@selector(hmdTrackWithName:event:parameters:)]) {
            [self.delegate hmdTrackWithName:name event:event parameters:parameters];
        }
    }
}

@end

static inline NSString *HMDUIEventNameWithEvent(HMDUITrackableEvents event) {
    switch (event) {
        case HMDUITrackableEventLoad:       return @"load";
        case HMDUITrackableEventAppear:     return @"appear";
        case HMDUITrackableEventDisappear:  return @"disappear";
        case HMDUITrackableEventTrigger:    return @"trigger";
        case HMDUITrackableEventSelectItem: return @"selectItem";
        default:                            return @"custom";
    }
}
