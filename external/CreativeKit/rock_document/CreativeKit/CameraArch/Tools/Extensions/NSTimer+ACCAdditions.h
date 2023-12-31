//
//  NSTimer+ACCAdditions.h
//  CameraClient
//
//  Created by ZhangYuanming on 2020/4/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (ACCAdditions)

/**
 Generate a new NSTimer object as a block

 @param seconds The interval of the callback
 @param block The block of the callback, the timer will force a reference to the block until the timer is invalid.
 @param repeats If YES, the callback will be repeated until the timer is invalidated, if NO, it will not be repeated
 @return Generate a new NSTimer object
 */
+ (nonnull NSTimer *)acc_scheduledTimerWithTimeInterval:(NSTimeInterval)seconds block:(nonnull void (^)(NSTimer * _Nonnull timer))block repeats:(BOOL)repeats;

/**
 Generate a new NSTimer object as a block, note that the generated timer object must be added to the run loop [runloop addTimer: forMode:]

 @param seconds The interval of the callback
 @param block The block of the callback, the timer will force a reference to the block until the timer is invalid.
 @param repeats If YES, the callback will be repeated until the timer is invalidated, if NO, it will not be repeated
 @return Generate a new NSTimer object
 */
+ (nonnull NSTimer *)acc_timerWithTimeInterval:(NSTimeInterval)seconds block:(nonnull void (^)(NSTimer * _Nonnull timer))block repeats:(BOOL)repeats;

@end

NS_ASSUME_NONNULL_END
