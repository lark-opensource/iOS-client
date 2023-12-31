//
//  NSTimer+FXWeakTimer.m
//  FXKit
//
//  Created by ShawnFoo on 16/6/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import "NSTimer+BDPWeakTarget.h"
#import <objc/runtime.h>
#import "NSTimer+OPWeakTarget.h"
#import "NSTimer+OPWeakTarget_private.h"

#pragma mark - NSTimer + FXWeakTarget
@implementation NSTimer (BDPWeakTarget)

+ (NSTimer *)bdp_scheduledTimerWithInterval:(NSTimeInterval)interval
                                     target:(id)target
                                      block:(bdp_timer_fire_block_t)block {
    return [NSTimer op_scheduledTimerWithInterval:interval
                                           target:target
                                            block:block];
}

+ (NSTimer *)bdp_scheduledRepeatedTimerWithInterval:(NSTimeInterval)interval
                                             target:(id)target
                                              block:(bdp_timer_fire_block_t)block {
    return [NSTimer op_scheduledRepeatedTimerWithInterval:interval
                                                   target:target
                                                    block:block];
}

+ (NSTimer *)bdp_timerWithInterval:(NSTimeInterval)interval
                            target:(id)target
                             block:(bdp_timer_fire_block_t)block {
    return [NSTimer op_timerWithInterval:interval
                                  target:target
                                   block:block];
}

+ (NSTimer *)bdp_repeatedTimerWithInterval:(NSTimeInterval)interval
                                    target:(id)target
                                     block:(bdp_timer_fire_block_t)block {
    return [self bdp_timerWithInterval:interval
                                target:target
                               repeats:YES
                             scheduled:NO
                                 block:block];
}

+ (NSTimer *)bdp_timerWithInterval:(NSTimeInterval)interval
                            target:(id)target
                           repeats:(BOOL)repeats
                         scheduled:(BOOL)scheduled
                             block:(bdp_timer_fire_block_t)block {

    return  [NSTimer op_timerWithInterval:interval
                                   target:target
                                  repeats:repeats
                                scheduled:scheduled
                                    block:block];
}

@end
