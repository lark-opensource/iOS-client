//
//  TMATimer.m
//  Timor
//
//  Created by muhuai on 2017/12/6.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "TMATimer.h"
//#import "BDPUtils.h"
#import <ECOInfra/OPMacroUtils.h>
@interface TMATimer()

// block 类型的timer
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, dispatch_block_t> *timeout;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, dispatch_source_t> *interval;

// NSTimer 类型的timer
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSTimer*> *timeoutNT;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSTimer*> *intervalNT;
@end

@implementation TMATimer

- (void)dealloc {
    [self clearAllTimeout];
    [self clearAllInterval];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _timeout = [[NSMutableDictionary alloc] init];
        _interval = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setTimeout:(NSInteger)functionID time:(NSInteger)time callbackMainThread:(void(^)(void))callback {
    [self setTimeout:functionID time:time callbackQueue:dispatch_get_main_queue() callback:callback];
}

- (void)setTimeout:(NSInteger)functionID time:(NSInteger)time callbackQueue:(dispatch_queue_t)queue callback:(void(^)(void))callback
{
    WeakSelf;
//    __weak typeof(self) wself = self;
    dispatch_block_t block = dispatch_block_create(0, ^{
//        __strong typeof(wself) sself = wself;
//        if (!sself) {
//            return;
//        }
        StrongSelfIfNilReturn;
        if (callback) {
            callback();
        }
        [self.timeout removeObjectForKey:@(functionID)];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_MSEC)), queue, block);
}

- (void)_timerInnerFireFunction:(NSTimer*)timer
{
    NSDictionary* dict = timer.userInfo;
    NSInteger functionID = ((NSNumber*)dict[@"id"]).integerValue;
    void (^callback)(void) = dict[@"callback"];
    if (callback) {
        callback();
    }
    
    NSTimer* timerNT = self.timeoutNT[@(functionID)];
    if (timerNT) {
        [self.timeoutNT removeObjectForKey:@(functionID)];
    }
}

- (void)setTimeout:(NSInteger)functionID time:(NSInteger)time inRunLoop:(NSRunLoop*)runloop callback:(void(^)(void))callback
{
    if (runloop) {
        NSTimeInterval interval = ((NSTimeInterval)time) / 1000.f;
        NSDictionary* paramDict = @{
                                    @"id":@(functionID),
                                    @"callback":callback
                                    };
        NSTimer* timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(_timerInnerFireFunction:) userInfo:paramDict repeats:NO];
        [runloop addTimer:timer forMode:NSDefaultRunLoopMode];
        self.timeoutNT[@(functionID)] = timer;
    }
}

- (void)clearTimeout:(NSInteger)functionID {
    dispatch_block_t block = self.timeout[@(functionID)];
    if (block) {
        [self.timeout removeObjectForKey:@(functionID)];
        dispatch_block_cancel(block);
    }
    
    NSTimer* timerNT = self.timeoutNT[@(functionID)];
    if (timerNT) {
        [self.timeoutNT removeObjectForKey:@(functionID)];
        [timerNT invalidate];
    }
}

- (void)clearAllTimeout {
    [self.timeout enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, dispatch_block_t  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj) {
            dispatch_block_cancel(obj);
        }
    }];

    [self.timeout removeAllObjects];
    
    [self.timeoutNT enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSTimer*  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj) {
            [obj invalidate];
        }
    }];
    
    [self.timeoutNT removeAllObjects];
}

- (void)setInterval:(NSInteger)functionID time:(NSInteger)time callbackMainThread:(void(^)(void))callback {
    [self setInterval:functionID time:time callbackQueue:dispatch_get_main_queue() callback:callback];
}

- (void)setInterval:(NSInteger)functionID time:(NSInteger)time callbackQueue:(dispatch_queue_t)queue callback:(void(^)(void))callback
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, time * NSEC_PER_MSEC, 50 * NSEC_PER_MSEC);
    dispatch_source_set_event_handler(timer, ^{
        if (callback) {
            callback();
        }
    });
    dispatch_resume(timer);
    
    self.interval[@(functionID)] = timer;
}

- (void)setInterval:(NSInteger)functionID time:(NSInteger)time inRunLoop:(NSRunLoop*)runloop callback:(void(^)(void))callback
{
    if (runloop) {
        NSTimeInterval interval = ((NSTimeInterval)time) / 1000.f;
        NSDictionary* paramDict = @{
                                    @"id":@(functionID),
                                    @"callback":callback
                                    };
        NSTimer* timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(_timerInnerFireFunction:) userInfo:paramDict repeats:YES];
        [runloop addTimer:timer forMode:NSDefaultRunLoopMode];
        self.intervalNT[@(functionID)] = timer;
    }
}

- (void)clearInterval:(NSInteger)functionID {
    dispatch_source_t timer = self.interval[@(functionID)];
    
    if (timer) {
        [self.interval removeObjectForKey:@(functionID)];
        dispatch_source_cancel(timer);
    }
    
    NSTimer* timerNT = self.intervalNT[@(functionID)];
    
    if (timerNT) {
        [self.intervalNT removeObjectForKey:@(functionID)];
        [timerNT invalidate];
    }
}

- (void)clearAllInterval {
    [self.interval enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, dispatch_source_t  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj) {
            dispatch_source_cancel(obj);
        }
    }];
    
    [self.interval removeAllObjects];
    
    [self.intervalNT enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSTimer*  _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj) {
            [obj invalidate];
        }
    }];
    
    [self.intervalNT removeAllObjects];
}
@end
