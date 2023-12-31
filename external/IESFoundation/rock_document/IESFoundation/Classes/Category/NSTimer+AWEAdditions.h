//
//  NSTimer+AWEAdditions.h
//  Pods
//
//  Created by pretzei on 2019/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (AWEAdditions)

+ (NSTimer *)awe_scheduledTimerWithTimeInterval:(NSTimeInterval)ti
                                     weakTarget:(id)aTarget
                                       selector:(SEL)aSelector
                                       userInfo:(id)userInfo
                                        repeats:(BOOL)yesOrNo;

+ (NSTimer *)awe_timerWithTimeInterval:(NSTimeInterval)ti
                            weakTarget:(id)aTarget
                              selector:(SEL)aSelector
                              userInfo:(nullable id)userInfo
                               repeats:(BOOL)yesOrNo;

- (void)awe_pause;

- (void)awe_resume;

@end

NS_ASSUME_NONNULL_END
