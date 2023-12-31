//
//  NSTimer+FXWeakTimer.m
//  FXKit
//
//  Created by ShawnFoo on 16/6/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "NSTimer+OPWeakTarget.h"
#import <objc/runtime.h>
#import "NSTimer+OPWeakTarget_private.h"

#pragma mark - FXTimerTargetDeallocMonitor Interface
@interface OPTimerTargetMonitor : NSObject

@property (nonatomic, copy) void (^deallocBlock)(void);

+ (void)addMonitorToTarget:(id)target forKey:(id)key withDeallocBlock:(void (^)(void))deallocBlock;
+ (void)removeMonitorFromTarget:(id)target ofKey:(id)key;

@end


#pragma mark - FXTimerTargetProxy Interface
@interface OPTimerTargetProxy : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, copy) op_timer_fire_block_t fireBlock;
@property (nonatomic, weak) NSTimer *timer;

+ (instancetype)proxyWithTarget:(id)target fireBlock:(op_timer_fire_block_t)block;
- (void)fireBlockInvoker:(NSTimer *)timer;
- (void)invalidateTimer;

@end


#pragma mark - NSTimer + FXWeakTarget
@implementation NSTimer (BDPWeakTarget)

+ (NSTimer *)op_scheduledTimerWithInterval:(NSTimeInterval)interval
                                     target:(id)target
                                      block:(op_timer_fire_block_t)block {
    return [self op_timerWithInterval:interval
                                target:target
                               repeats:NO
                             scheduled:YES
                                 block:block];
}

+ (NSTimer *)op_scheduledRepeatedTimerWithInterval:(NSTimeInterval)interval
                                             target:(id)target
                                              block:(op_timer_fire_block_t)block {
    return [self op_timerWithInterval:interval
                                target:target
                               repeats:YES
                             scheduled:YES
                                 block:block];
}

+ (NSTimer *)op_timerWithInterval:(NSTimeInterval)interval
                            target:(id)target
                             block:(op_timer_fire_block_t)block {
    return [self op_timerWithInterval:interval
                                target:target
                               repeats:NO
                             scheduled:NO
                                 block:block];
}

+ (NSTimer *)op_repeatedTimerWithInterval:(NSTimeInterval)interval
                                    target:(id)target
                                     block:(op_timer_fire_block_t)block {
    return [self op_timerWithInterval:interval
                                target:target
                               repeats:YES
                             scheduled:NO
                                 block:block];
}

+ (NSTimer *)op_timerWithInterval:(NSTimeInterval)interval
                            target:(id)target
                           repeats:(BOOL)repeats
                         scheduled:(BOOL)scheduled
                             block:(op_timer_fire_block_t)block {
    OPTimerTargetProxy *targetProxy = [[OPTimerTargetProxy alloc] init];
    targetProxy.target = target;
    targetProxy.fireBlock = block;
    
    [OPTimerTargetMonitor addMonitorToTarget:target forKey:targetProxy withDeallocBlock:^{
        [targetProxy invalidateTimer];
    }];
    
    NSTimer *timer = nil;
    if (scheduled) {
        timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                 target:targetProxy
                                               selector:@selector(fireBlockInvoker:)
                                               userInfo:nil
                                                repeats:repeats];
    } else {
        timer = [NSTimer timerWithTimeInterval:interval
                                        target:targetProxy
                                      selector:@selector(fireBlockInvoker:)
                                      userInfo:nil
                                       repeats:repeats];
    }
    targetProxy.timer = timer;
    
    // 如果外部手动释放了timer, 但target又不释放(比如传入个单例或类对象的情况), 就得把monitor移除掉, 避免内存泄漏
    __weak typeof(target) weakTarget = target;
    [OPTimerTargetMonitor addMonitorToTarget:timer forKey:targetProxy withDeallocBlock:^{
        __strong typeof(weakTarget) target = weakTarget;
        [OPTimerTargetMonitor removeMonitorFromTarget:target ofKey:targetProxy];
    }];
    return timer;
}

@end


#pragma mark - FXTimerTargetDeallocMonitor IMP
@implementation OPTimerTargetMonitor

+ (void)addMonitorToTarget:(id)target forKey:(id)key withDeallocBlock:(void (^)(void))deallocBlock {
    if (!target || !key) {
        return;
    }
    OPTimerTargetMonitor *monitor = [[OPTimerTargetMonitor alloc] init];
    monitor.deallocBlock = deallocBlock;
    objc_setAssociatedObject(target,
                             (__bridge const void *)(key),
                             monitor,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void)removeMonitorFromTarget:(id)target ofKey:(id)key {
    if (!target || !key) {
        return;
    }
    objc_setAssociatedObject(target, (__bridge const void *)(key), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc {
    if (!_deallocBlock) {
        return;
    }
    if ([NSThread isMainThread]) {
        _deallocBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), _deallocBlock);
    }
    _deallocBlock = nil;
}

@end


#pragma mark - FXTimerTargetProxy IMP
@implementation OPTimerTargetProxy

+ (instancetype)proxyWithTarget:(id)target fireBlock:(op_timer_fire_block_t)block {
    OPTimerTargetProxy *proxy = [[OPTimerTargetProxy alloc] init];
    proxy.target = target;
    proxy.fireBlock = block;
    return proxy;
}

- (void)fireBlockInvoker:(NSTimer *)timer {
    if (timer.valid) {
        id strongTarget = self.target;
        if (strongTarget) {
            [self invokeFireBlock];
        }
        else {
            [self invalidateTimer];
        }
    }
}

- (void)invokeFireBlock {
    if (self.fireBlock) {
        self.fireBlock(self.timer);
    }
}

- (void)invalidateTimer {
    self.fireBlock = nil;
    [self.timer invalidate];
}

@end

