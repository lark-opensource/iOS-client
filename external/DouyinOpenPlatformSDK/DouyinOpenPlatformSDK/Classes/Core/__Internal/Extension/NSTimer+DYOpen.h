//
//  NSTimer+DYOpen.h
//  DouyinOpenPlatformSDK-ce36b184
//
//  Created by arvitwu on 2022/10/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (DYOpen)

+ (NSTimer *)dyopen_scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(NSTimer *timer))inBlock repeats:(BOOL)inRepeats;

+ (NSTimer *)dyopen_timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)(NSTimer *timer))inBlock repeats:(BOOL)inRepeats;

@end

NS_ASSUME_NONNULL_END
