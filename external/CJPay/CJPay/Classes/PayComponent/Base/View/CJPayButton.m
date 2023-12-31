//
//  CJPayButton.m
//  CJPay
//
//  Created by 王新华 on 2018/12/10.
//

#import "CJPayButton.h"
#import "CJPayUIMacro.h"
#import "CJPayPerformanceTracker.h"

@implementation CJPayButton

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cjEventInterval = 1;
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    if (self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.1) {
        return nil;
    }
    CGSize size = CGSizeMake(44, 44);
    CGFloat extWidth = fmax(size.width - self.cj_width, 0);
    CGFloat extHeight = fmax(size.height - self.cj_height, 0);
    CGRect largeRect = CGRectInset(self.bounds, -extWidth / 2, -extHeight / 2);
    if (CGRectContainsPoint(largeRect, point)) {
        return self;
    }
    return nil;
}

- (void)sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    if (!self.cjEventUnavailable || self.cjEventUnavailable.intValue == 0) {
        self.cjEventUnavailable = @(1);
        [super sendAction:action to:target forEvent:event];
        [self performSelector:@selector(setCjEventUnavailable:) withObject:@(0) afterDelay:self.cjEventInterval];
        
        [CJPayPerformanceMonitor trackBtnActionWithBtn:self target:target extra:@{}];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if (_disableHightlightState) {
        [super setHighlighted:NO];
    } else {
        [super setHighlighted:highlighted];
    }
}

@end
