//
//  NSTimer.h
//  Pods
//
//  Created by guikunzhi on 16/12/13.
//
//

#import <Foundation/Foundation.h>

@interface NSTimer (TTVideoEngine)

+ (instancetype)ttvideoengine_scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval queue:(dispatch_queue_t)queue block:(void (^)())inBlock repeats:(BOOL)inRepeats;


+ (NSTimer *)ttvideoengine_scheduledNoRetainTimerWithTimeInterval:(NSTimeInterval)ti
                                                           target:(id)aTarget
                                                         selector:(SEL)aSelector
                                                         userInfo:(id)userInfo
                                                          repeats:(BOOL)yesOrNo;

@end
