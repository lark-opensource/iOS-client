//
//  OKTimer.m
//  OneKit
//
//  Created by bob on 2020/4/26.
//

#import "OKTimer.h"

@interface OKTimer ()

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) BOOL repeat;
@property (nonatomic, strong) dispatch_block_t action;

@end

@implementation OKTimer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timer = nil;
    }
    
    return self;
}

- (void)cancel {
    dispatch_source_t timer = self.timer;
    if (timer != nil) {
        dispatch_source_cancel(timer);
    }
    
    self.timer = nil;
}

+ (OKTimer *)timerWithInterval:(long long)interval
                       repeats:(BOOL)repeats
                         queue:(dispatch_queue_t)queue
                        action:(dispatch_block_t)action {
    NSCAssert(interval > 0, @"interval must > 0");
    NSCAssert(action != nil, @"action must not be nil");
    
    
    if (!queue)
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    OKTimer *okTimer = [OKTimer new];
    okTimer.action = action;
    okTimer.repeat = repeats;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_MSEC), interval * NSEC_PER_MSEC, 0);
    okTimer.timer = timer;
    dispatch_source_set_event_handler(timer, ^{
        dispatch_block_t block = okTimer.action;
        if (action) {
            action();
        }
        if (!okTimer.repeat) {
            [okTimer cancel];
        }
    });
    
    return okTimer;
}

@end
