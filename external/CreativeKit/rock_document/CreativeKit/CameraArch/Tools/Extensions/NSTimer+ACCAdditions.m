//
//  NSTimer+ACCAdditions.m
//  CameraClient
//
//  Created by ZhangYuanming on 2020/4/1.
//

#import "NSTimer+ACCAdditions.h"

@implementation NSTimer (ACCAdditions)

+ (void)acc_execBlock:(NSTimer *)timer
{
    if ([timer userInfo]) {
        void (^block)(NSTimer *timer) = (void (^)(NSTimer *timer))[timer userInfo];
        if (block) {
            block(timer);
        }
    }
}

+ (NSTimer *)acc_scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats
{
    return [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(acc_execBlock:) userInfo:[block copy] repeats:repeats];
}

+ (NSTimer *)acc_timerWithTimeInterval:(NSTimeInterval)seconds block:(void (^)(NSTimer *timer))block repeats:(BOOL)repeats
{
    return [NSTimer timerWithTimeInterval:seconds target:self selector:@selector(acc_execBlock:) userInfo:[block copy] repeats:repeats];
}

@end
