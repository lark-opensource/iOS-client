//
//  CJPayStyleTimerButton.m
//  Pods
//
//  Created by 王新华 on 2020/12/10.
//

#import "CJPayStyleTimerButton.h"
#import "CJPayTimer.h"
#import "CJPaySDKMacro.h"

@interface CJPayStyleTimerButton()<CJPayTimerProtocol>

@property (nonatomic, strong) CJPayTimer *timer;
@property (nonatomic, copy) NSString *originalTitle;

@end

@implementation CJPayStyleTimerButton

- (CJPayTimer *)timer {
    if (!_timer) {
        _timer = [CJPayTimer new];
        _timer.delegate = self;
    }
    return _timer;
}

- (void)startTimer:(int)value {
    if (value > 0) {
        self.enabled = NO;
    }
    self.originalTitle = self.titleLabel.text;
    [self.timer startTimerWithCountTime:value];
}

- (void)currentCountChangeTo:(int)value {
    if (value > 0) {
        [self setTitle:[NSString stringWithFormat:@"%@(%ds)", self.originalTitle, value] forState:UIControlStateNormal];
    } else {
        [self setTitle:self.originalTitle forState:UIControlStateNormal];
        self.enabled = YES;
    }
}

@end
