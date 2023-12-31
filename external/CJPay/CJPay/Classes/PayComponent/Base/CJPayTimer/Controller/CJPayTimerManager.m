//
//  CJPayTimerManager.m
//  Pods
//
//  Created by 易培淮 on 2021/8/17.
//

#import "CJPayTimerManager.h"
#import <ByteDanceKit/BTDWeakProxy.h>
#import "CJPaySDKMacro.h"

@interface CJPayTimerManager ()

@property (nonatomic, strong) NSTimer *timer;

@end


@implementation CJPayTimerManager

- (void)startTimer:(NSTimeInterval)time {
    if (self.timer == nil) {
        [self createTimer:time];
    } else {//重置计时器
        [self detoryTimer];
        [self createTimer:time];
    }
}

- (void)stopTimer {
    [self detoryTimer];
}

- (void)createTimer:(NSTimeInterval)time {
    self.timer = [NSTimer timerWithTimeInterval:time target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(p_timeout) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)detoryTimer {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (BOOL)isTimerValid {
    return self.timer ? YES : NO;
}

- (void)appendTimeoutBlock:(void (^)(void))appendBlock {
    if (!appendBlock) {
        return;
    }
    
    void (^originalBlock)(void) = [self.timeOutBlock copy];
    void (^resultBlock)(void) = ^{
        CJ_CALL_BLOCK(originalBlock);
        CJ_CALL_BLOCK(appendBlock);
    };
    
    self.timeOutBlock = resultBlock;
}

- (void)p_timeout {
    CJ_CALL_BLOCK(self.timeOutBlock);
}

@end
