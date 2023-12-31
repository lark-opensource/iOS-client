//
//  TTVideoEnginePerformanceCollector.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/7/12.
//

#import "TTVideoEnginePerformanceCollector.h"
#import "TTVideoEngineUtil.h"
#import "NSTimer+TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"

static const NSInteger s_kCPUTimeInterval = 3;
static const NSInteger s_kMemTimeInterval = 6;
static NSInteger s_timer_count = 0;

@interface _TTVideoEngineAppPerformance : NSObject
@property (nonatomic, strong) NSHashTable *observers;
@property (nonatomic, strong) NSTimer *scheduledTimer;
@end

@implementation _TTVideoEngineAppPerformance {
    dispatch_queue_t _collectorQueue;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_scheduledTimer) {
        [_scheduledTimer invalidate];
        _scheduledTimer = nil;
    }
}

- (instancetype)init {
    if (self = [super init]) {
        _observers = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory capacity:0];
        _collectorQueue = dispatch_queue_create("vclould.engine.performance.queue", DISPATCH_QUEUE_SERIAL);
        [self _resetScheduledTimer];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_willEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_didEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static _TTVideoEngineAppPerformance *s_instance = nil;
    dispatch_once(&onceToken, ^{
        s_instance = [[self alloc] init];
    });
    return s_instance;
}

- (void)_resetScheduledTimer {
    [self _tryToStopScheduledTimer];
    
    _scheduledTimer = [NSTimer ttvideoengine_scheduledNoRetainTimerWithTimeInterval:3.0
                                                                             target:self
                                                                           selector:@selector(_scheduledTimerEvent)
                                                                           userInfo:nil
                                                                            repeats:YES];
}

- (void)_tryToStartScheduledTimer {
    if (![_scheduledTimer isValid]) {
        [self _resetScheduledTimer];
    }
}

- (void)_tryToStopScheduledTimer {
    if ([_scheduledTimer isValid]) {
        [_scheduledTimer invalidate];
    }
}

- (void)_scheduledTimerEvent {
    dispatch_async(_collectorQueue, ^{
        
        CGFloat mem = -1.0f;
        if (s_timer_count % 2 == 0) {
            mem = TTVideoEngineAppMemoryUsage();
        }
        CGFloat cpu = TTVideoEngineAppCpuUsage();
        s_timer_count++;
        if (s_timer_count >= NSIntegerMax - 1) {
            s_timer_count = 0;
        }
        
        TTVideoRunOnMainQueue(^{
            if (self.observers.anyObject == nil) {
                return;
            }
            
            NSEnumerator *enumerator = self.observers.objectEnumerator;
            id<TTVideoEnginePerformancePoint> obj = enumerator.nextObject;
            
            while (obj) {
                if (mem >= 0.0f) {
                    [obj addMemUsagesPoint:mem];
                }
                [obj addCpuUsagesPoint:cpu];
                
                obj = enumerator.nextObject;
            }
        }, NO);
    });
}

- (void)_willEnterForeground {
    [self _resetScheduledTimer];
}

- (void)_didEnterBackground {
    [self _tryToStopScheduledTimer];
}

- (void)addObserver:(id)observer {
    TTVideoRunOnMainQueue(^{
        [self.observers addObject:observer];
        
        [self _tryToStartScheduledTimer];
    }, NO);
}

- (void)removeObserver:(id)observer {
    TTVideoRunOnMainQueue(^{
        [self.observers removeObject:observer];
        
        if (self.observers.anyObject == nil) {
            [self _tryToStopScheduledTimer];
        }
    }, NO);
}

@end

@implementation TTVideoEnginePerformanceCollector

+ (void)addObserver:(id<TTVideoEnginePerformancePoint>)observer {
    if (observer
        && [observer respondsToSelector:@selector(addCpuUsagesPoint:)]
        && [observer respondsToSelector:@selector(addMemUsagesPoint:)]) {
        [[_TTVideoEngineAppPerformance shareInstance] addObserver:observer];
    }
}

+ (void)removeObserver:(id<TTVideoEnginePerformancePoint>)observer {
    if (!observer) {
        return;
    }
    
    [[_TTVideoEngineAppPerformance shareInstance] removeObserver:observer];
}

@end
