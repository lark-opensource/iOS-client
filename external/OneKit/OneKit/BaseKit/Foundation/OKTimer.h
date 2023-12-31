//
//  OKTimer.h
//  OneKit
//
//  Created by bob on 2020/4/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OKTimer : NSObject

/**
 @param interval        interval in millisecond, not second
 */
+ (OKTimer *)timerWithInterval:(long long)interval
                       repeats:(BOOL)repeats
                         queue:(dispatch_queue_t)queue
                        action:(dispatch_block_t)action;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
