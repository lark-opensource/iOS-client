//
//  NSTimer+TTNetworkBlockTimer.m
//  TTNetworkManager
//
//  Created by dongyangfan on 2020/11/8.
//

#import "NSTimer+TTNetworkBlockTimer.h"

@implementation NSTimer (TTNetworkBlockTimer)

+ (NSTimer *)ttnet_scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block repeats:(BOOL)repeats {
    NSTimer *timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(ttnet_blockSelector:) userInfo:[block copy] repeats:repeats];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    return timer;
}


+ (void)ttnet_blockSelector:(NSTimer *)timer {
    void(^block)(void) = timer.userInfo;
    if (block) {
        block();
    }
}

@end
