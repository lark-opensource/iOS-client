//
//  HMDGCDTimer.m
//  Pods
//
//  Created by fengyadong on 2017/9/11.
//
//

#import <Foundation/Foundation.h>

@interface HMDGCDTimer : NSObject

/**
 启动一个timer，默认精度为1毫秒
 
 @param interval        执行的时间间隔。
 @param queue           timer将被放入的队列，也就是最终action执行的队列。传入nil将自动放到一个子线程队列中。
 @param repeats         timer是否循环调用。
 @param action          时间间隔到点时执行的block。
 */
- (void)scheduledDispatchTimerWithInterval:(NSTimeInterval)interval
                                     queue:(dispatch_queue_t)queue
                                   repeats:(BOOL)repeats
                                    action:(dispatch_block_t)action;

/**
 撤销timer。
  */
- (void)cancelTimer;


/**
 *  是否存在timer。
 *
 *  @return YES表示存在，反之。
 */
- (BOOL)existTimer;

@end
