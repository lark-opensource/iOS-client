//
//  NSTimer+FXWeakTimer.h
//  FXKit
//
//  Created by ShawnFoo on 16/6/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^bdp_timer_fire_block_t)(NSTimer *timer);


@interface NSTimer (BDPWeakTarget)

/**
 *  返回一个已激活的NSTimer对象. 该对象会以NSRunLoopDefaultMode模式加入到当前的RunLoop中.
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)bdp_scheduledTimerWithInterval:(NSTimeInterval)interval
                                     target:(id)target
                                      block:(bdp_timer_fire_block_t)block;

/**
 *  返回一个已激活且会重复触发的NSTimer对象. 该对象会以NSRunLoopDefaultMode模式加入到当前的RunLoop中.
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)bdp_scheduledRepeatedTimerWithInterval:(NSTimeInterval)interval
                                             target:(id)target
                                              block:(bdp_timer_fire_block_t)block;

/**
 *  创建一个未激活的NSTimer对象
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)bdp_timerWithInterval:(NSTimeInterval)interval
                            target:(id)target
                             block:(bdp_timer_fire_block_t)block;

/**
 *  创建一个未激活会重复触发的NSTimer对象
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)bdp_repeatedTimerWithInterval:(NSTimeInterval)interval
                                    target:(id)target
                                     block:(bdp_timer_fire_block_t)block;

@end

NS_ASSUME_NONNULL_END
