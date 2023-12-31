//
//  NSTimer.m
//  Pods
//
//  Created by guikunzhi on 16/12/13.
//
//

#import "NSTimer+TTVideoEngine.h"

@interface _TTVideoEngineTimerTarget : NSObject
@property (nonatomic, weak) id wTarget;
@end

@implementation _TTVideoEngineTimerTarget

- (instancetype)initWithTarget:(id)target {
    self = [super init];
    if (self) {
        self.wTarget = target;
    }
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.wTarget;
}

@end

@implementation NSTimer (TTVideoEngine)

+(instancetype)ttvideoengine_scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval queue:(dispatch_queue_t)queue block:(void (^)())inBlock repeats:(BOOL)inRepeats {
    void (^block)() = ^() {
        dispatch_queue_t taskQueue = queue;
        if (!taskQueue) {
            taskQueue = dispatch_get_main_queue();
        }
        dispatch_async(taskQueue, ^{
            if (inBlock) {
                inBlock();
            }
        });
    };
    id ret = [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(excuteBlock:) userInfo:block repeats:inRepeats];
    [[NSRunLoop currentRunLoop] addTimer:ret forMode:NSRunLoopCommonModes];
    return ret;
}

+ (void)excuteBlock:(NSTimer *)inTimer {
    if([inTimer userInfo]) {
        void (^block)() = (void (^)())[inTimer userInfo];
        block();
    }
}

+ (NSTimer *)ttvideoengine_scheduledNoRetainTimerWithTimeInterval:(NSTimeInterval)ti
                                                           target:(id)aTarget
                                                         selector:(SEL)aSelector
                                                         userInfo:(id)userInfo
                                                          repeats:(BOOL)yesOrNo {
    _TTVideoEngineTimerTarget * timerTarget = [[_TTVideoEngineTimerTarget alloc] initWithTarget:aTarget];
    return [self scheduledTimerWithTimeInterval:ti target:timerTarget selector:aSelector userInfo:userInfo repeats:yesOrNo];
}



@end
