//
//  ACCThrottle.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/24.
//

#import "ACCThrottle.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCThrottle ()

@property (nonatomic, strong) NSDictionary *userInfo;
@property (nonatomic, assign, readwrite) BOOL isIdle;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL needExecuteWhenTimerInvoke;

@end

@implementation ACCThrottle

- (instancetype)init
{
    if (self = [super init]) {
        _isIdle = YES;
    }
    return self;
}

+ (instancetype)throttleWithTimeInterval:(NSTimeInterval)timeInterval executor:(ACCThrottleExecutor)executor
{
    ACCThrottle *throttle = [[ACCThrottle alloc] init];
    throttle.timeInterval = timeInterval;
    throttle.executor = executor;
    return throttle;
}

- (void)dealloc
{
    [self p_invalidateTimer];
}

#pragma mark - public
- (void)tryExecuteWithUserInfo:(NSDictionary *)userInfo
{
    if (self.isIdle || self.timeInterval <= ACC_FLOAT_ZERO) {
        // 当前空闲 立即执行
        ACCBLOCK_INVOKE(self.executor, userInfo);
        self.needExecuteWhenTimerInvoke = NO;
    } else {
        // 非空闲则延后在执行
        self.userInfo = userInfo;
        self.needExecuteWhenTimerInvoke = YES;
    }
    // 重新计时
    [self p_reschedule];
}

- (void)cancelExecute
{
    [self p_resetToIdel];
}

#pragma mark - timer
- (void)p_invalidateTimer
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)p_onTimerHandler
{
    if (self.needExecuteWhenTimerInvoke) {
        ACCBLOCK_INVOKE(self.executor, self.userInfo);
    }
    
    [self p_resetToIdel];
}

#pragma mark - schedule
- (void)p_resetToIdel
{
    [self p_invalidateTimer];
    self.isIdle = YES;
    self.userInfo = nil;
    self.needExecuteWhenTimerInvoke = NO;
}

- (void)p_reschedule
{
    [self p_invalidateTimer];
    if (self.timeInterval > ACC_FLOAT_ZERO) {
        self.isIdle = NO;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeInterval target:self selector:@selector(p_onTimerHandler) userInfo:nil repeats:NO];
    } else {
        [self p_resetToIdel];
    }
}

@end
