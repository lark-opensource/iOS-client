//
//  CJPayTimerView.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/19.
//

#import "CJPayTimerView.h"
#import "CJPayTimer.h"
#import "CJPaySDKMacro.h"

@interface CJPayTimerView ()<CJPayTimerProtocol>

@property (nonatomic, strong) CJPayTimer *timer;
@property (nonatomic, assign, readwrite) int curCount;

@end

@implementation CJPayTimerView

- (CJPayTimer *)timer {
    if (!_timer) {
        _timer = [CJPayTimer new];
        _timer.delegate = self;
    }
    return _timer;
}

- (void)startTimerWithCountTime:(int) countTime{
    [self.timer startTimerWithCountTime:countTime];
    self.enabled = NO;
}

- (void)reset{
    [self.timer reset];
    self.enabled = YES;
}

#pragma mark - CJPayTimerView
- (void)currentCountChangeTo:(int) value{
    if (value <= 0) {
        [self reset];
    }
}

- (int)curCount {
    return self.timer.curCount;
}

@end
