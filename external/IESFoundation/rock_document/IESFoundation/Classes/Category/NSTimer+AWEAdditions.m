//
//  NSTimer+AWEAdditions.m
//  Pods
//
//  Created by pretzei on 2019/7/26.
//

#import <objc/runtime.h>
#import "NSTimer+AWEAdditions.h"

@interface AWEWeakTimerTarget : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;

- (nonnull instancetype)initWithTarget:(nonnull id)target selector:(nonnull SEL)sel;
- (void)timerDidFire:(nonnull NSTimer *)timer;

@end

@implementation AWEWeakTimerTarget

- (instancetype)initWithTarget:(id)target selector:(nonnull SEL)sel
{
    self = [super init];
    if (self) {
        self.target = target;
        self.selector = sel;
    }
    return self;
}

- (void)timerDidFire:(NSTimer *)timer
{
    if (self.target) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.selector withObject:timer];
#pragma clang diagnostic pop
    } else {
        [timer invalidate];
    }
}

@end

@interface NSTimer ()

@property (nonatomic, strong) NSDate *awe_pausedDate;

@property (nonatomic, strong) NSDate *awe_nextFireDate;

@end

@implementation NSTimer (AWEAdditions)

+ (NSTimer *)awe_scheduledTimerWithTimeInterval:(NSTimeInterval)ti
                                     weakTarget:(id)aTarget
                                       selector:(SEL)aSelector
                                       userInfo:(id)userInfo
                                        repeats:(BOOL)yesOrNo
{
    AWEWeakTimerTarget *target = [[AWEWeakTimerTarget alloc] initWithTarget:aTarget selector:aSelector];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:ti target:target selector:@selector(timerDidFire:) userInfo:userInfo repeats:yesOrNo];
    return timer;
}

+ (NSTimer *)awe_timerWithTimeInterval:(NSTimeInterval)ti
                            weakTarget:(id)aTarget
                              selector:(SEL)aSelector
                              userInfo:(nullable id)userInfo
                               repeats:(BOOL)yesOrNo
{
    AWEWeakTimerTarget *target = [[AWEWeakTimerTarget alloc] initWithTarget:aTarget selector:aSelector];
    NSTimer *timer = [NSTimer timerWithTimeInterval:ti target:target selector:@selector(timerDidFire:) userInfo:userInfo repeats:yesOrNo];
    return timer;
}

- (void)awe_pause
{
    if (self.awe_pausedDate || self.awe_nextFireDate) {
        return;
    }
    
    self.awe_pausedDate = [NSDate date];
    self.awe_nextFireDate = [self fireDate];
    
    [self setFireDate:[NSDate distantFuture]];
}

- (void)awe_resume
{
    if (!self.awe_pausedDate || !self.awe_nextFireDate) {
        return;
    }
    
    float pauseTime = -1 * [self.awe_pausedDate timeIntervalSinceNow];
    [self setFireDate:[self.awe_nextFireDate initWithTimeInterval:pauseTime sinceDate:self.awe_nextFireDate]];
    
    self.awe_pausedDate = nil;
    self.awe_nextFireDate = nil;
}

- (NSDate *)awe_pausedDate
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAwe_pausedDate:(NSDate *)awe_pausedDate
{
    objc_setAssociatedObject(self, @selector(awe_pausedDate), awe_pausedDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDate *)awe_nextFireDate
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAwe_nextFireDate:(NSDate *)awe_nextFireDate
{
    objc_setAssociatedObject(self, @selector(awe_nextFireDate), awe_nextFireDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
