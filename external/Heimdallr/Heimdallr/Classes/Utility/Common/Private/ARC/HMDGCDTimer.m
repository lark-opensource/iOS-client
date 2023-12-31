//
//  HMDGCDTimer.m
//  Pods
//
//  Created by fengyadong on 2017/9/11.
//
//

#import "HMDGCDTimer.h"
#include "pthread_extended.h"

@interface HMDGCDTimer() {
    pthread_mutex_t _lock;
}

@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation HMDGCDTimer

#pragma mark - Public Method

- (instancetype)init {
    if (self = [super init]) {
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)scheduledDispatchTimerWithInterval:(NSTimeInterval)interval
                                     queue:(dispatch_queue_t)queue
                                   repeats:(BOOL)repeats
                                    action:(dispatch_block_t)action {
    if (!queue)
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    pthread_mutex_lock(&_lock);
    BOOL timerNeedInitialize = self.timer ? NO : YES;
    if (timerNeedInitialize) {
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        if (!self.timer) {
            pthread_mutex_unlock(&_lock);
            return;
        }
    }
        
    /* timer精度为1毫秒 */
    dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, NSEC_PER_MSEC);
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_source_set_event_handler(self.timer, ^{
        if (action) {
            action();
        }
        
        if (!repeats) {
            [weakSelf cancelTimer];
        }
    });
    
    // 在设置event_handler之前调用dispatch_resume()会产生asl日志，写入过程有可能会非常耗时，造成卡死
    if (timerNeedInitialize) {
        dispatch_resume(self.timer);
    }
    pthread_mutex_unlock(&_lock);
}

- (void)cancelTimer {
    pthread_mutex_lock(&_lock);
    dispatch_source_t timer = self.timer;
    
    if (!timer) {
        pthread_mutex_unlock(&_lock);
        return;
    }
    
    self.timer = nil;
    pthread_mutex_unlock(&_lock);
    dispatch_source_cancel(timer);
}

- (BOOL)existTimer {
    pthread_mutex_lock(&_lock);
    BOOL exist = self.timer ? YES : NO;
    pthread_mutex_unlock(&_lock);
    return exist;
}

@end
