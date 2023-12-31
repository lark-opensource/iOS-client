//
//  CJPayTimer.m
//  Pods
//
//  Created by 王新华 on 2020/12/10.
//

#import "CJPayTimer.h"
#import "CJPayUIMacro.h"

@protocol CJPayTimerQueueBridgeProtocol <NSObject>

- (void)bridgeMethod;

@end

@interface CJPayTimerQueueBridge : NSObject

@property (nonatomic, weak) id<CJPayTimerQueueBridgeProtocol> delegate;

- (void)bridgeMethod;

@end

@implementation CJPayTimerQueueBridge

- (void)bridgeMethod {
    if (self.delegate && [self.delegate respondsToSelector:@selector(bridgeMethod)]) {
        [self.delegate performSelector:@selector(bridgeMethod)];
    }
}

@end

@interface CJPayTimer() <CJPayTimerQueueBridgeProtocol>

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign, readwrite) int curCount;
@property (nonatomic, strong) dispatch_queue_t timerQueue;
@property (nonatomic, strong) CJPayTimerQueueBridge *bridge;
@property (nonatomic, assign) BOOL needRefreshWhenEnterForeground;
@property (nonatomic, assign) CFTimeInterval startTime;
@property (nonatomic, assign) int startCount;

@end

@implementation CJPayTimer

- (instancetype)init{
    self = [super init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForground) name:UIApplicationWillEnterForegroundNotification object:nil];
    return self;
}

- (void)dealloc
{
    [self stopTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (dispatch_queue_t)timerQueue {
    if (!_timerQueue) {
        _timerQueue = dispatch_queue_create(("cjpay_count_time_queue"),DISPATCH_QUEUE_SERIAL);
    }
    return _timerQueue;
}

- (void)startTimerWithCountTime:(int) countTime{
    [self stopTimer];
    self.needRefreshWhenEnterForeground = YES;
    if (countTime < 1) {
        [self reset];
        return;
    }
    self.startCount = countTime;
    self.curCount = countTime;
    self.startTime = CFAbsoluteTimeGetCurrent();
    NSTimeInterval interval = 1.0;
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.timerQueue);
    dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), interval * NSEC_PER_SEC, 0);
    
    CJPayTimerQueueBridge *bridge = [CJPayTimerQueueBridge new];
    bridge.delegate = self;
    
    self.bridge = bridge;
    
    @CJWeakify(bridge)
    dispatch_source_set_event_handler(_timer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            @CJStrongify(bridge)
            [bridge bridgeMethod];
        });
    });
    dispatch_resume(_timer);
}

- (void)appEnterForground {
    if (self.needRefreshWhenEnterForeground && self.startCount > 0) {
        CFTimeInterval curTime = CFAbsoluteTimeGetCurrent();
        int delTime = curTime - self.startTime;
        self.curCount = MIN(self.startCount - delTime, self.curCount);
    }
}

- (void)setCurCount:(int)curCount {
    _curCount = curCount;
    
    [self currentCountChangeTo:self.curCount];
    if (self.curCount <= 0) {
        [self reset];
    }
}

- (void)stopTimer{
    self.needRefreshWhenEnterForeground = NO;
    self.bridge.delegate = nil;
    if (self.timer) {
        dispatch_source_cancel(self.timer);
    }
    self.timer = nil;
}


- (void)currentCountChangeTo:(int) value{
    if (self.delegate) {
        [self.delegate currentCountChangeTo:value];
    }
}

- (void)reset{
    _curCount = 0;
    [self stopTimer];
}

#pragma mark - CJPayTimerQueueBridgeProtocol
- (void)bridgeMethod {
    self.curCount = self.curCount - 1;
}

@end
