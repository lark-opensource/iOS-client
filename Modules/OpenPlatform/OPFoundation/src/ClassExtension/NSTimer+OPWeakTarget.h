/*
  The MIT License (MIT)
 
 * (c) ShawnFoo on 16/6/14

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

//
//  NSTimer+FXWeakTimer.h
//  FXKit
//
//  Created by ShawnFoo on 16/6/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^op_timer_fire_block_t)(NSTimer *timer);


@interface NSTimer (OPWeakTarget)

/**
 *  返回一个已激活的NSTimer对象. 该对象会以NSRunLoopDefaultMode模式加入到当前的RunLoop中.
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)op_scheduledTimerWithInterval:(NSTimeInterval)interval
                                     target:(id)target
                                      block:(op_timer_fire_block_t)block;

/**
 *  返回一个已激活且会重复触发的NSTimer对象. 该对象会以NSRunLoopDefaultMode模式加入到当前的RunLoop中.
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)op_scheduledRepeatedTimerWithInterval:(NSTimeInterval)interval
                                             target:(id)target
                                              block:(op_timer_fire_block_t)block;

/**
 *  创建一个未激活的NSTimer对象
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)op_timerWithInterval:(NSTimeInterval)interval
                            target:(id)target
                             block:(op_timer_fire_block_t)block;

/**
 *  创建一个未激活会重复触发的NSTimer对象
 *
 *  @param interval 定时器两次触发的间隔
 *  @param target 关联目标对象. 当该对象被释放时, 若对应NSTimer依旧有效, 则会调用invlidate使其失效
 *  @param block 定时器触发时执行的Block, 还可以通过Block中的timer调用失效方法
 */
+ (NSTimer *)op_repeatedTimerWithInterval:(NSTimeInterval)interval
                                    target:(id)target
                                     block:(op_timer_fire_block_t)block;

@end

NS_ASSUME_NONNULL_END
