//
//  NSTimer+FXWeakTimer.h
//  FXKit
//
//  Created by ShawnFoo on 16/6/14.
//  Copyright © 2016年 ShawnFoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSTimer+OPWeakTarget.h"
NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (OPWeakTarget_private)

+ (NSTimer *)op_timerWithInterval:(NSTimeInterval)interval
                            target:(id)target
                           repeats:(BOOL)repeats
                         scheduled:(BOOL)scheduled
                            block:(op_timer_fire_block_t)block;

@end

NS_ASSUME_NONNULL_END
