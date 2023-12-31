//
//  MinutesScrollView.m
//  Minutes
//
//  Created by chenlehui on 2021/12/28.
//

#import "MinutesScrollView.h"

@interface MinutesScrollView() <UIGestureRecognizerDelegate>
@end

@implementation MinutesScrollView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return _innerScrollView.panGestureRecognizer == otherGestureRecognizer;
}

// disable-lint: duplicated_code
- (void)setContentOffset:(CGPoint)contentOffset {
    if (!self.contentOffsetChanging) {
        super.contentOffset = contentOffset;
        return;
    }

    // API 调用
    if (!self.isDragging && !_innerScrollView.isDragging) {
        super.contentOffset = contentOffset;
        return;
    }

    // 手势 调用
    CGPoint oldOffset = [self contentOffset];
    CGPoint newOffset = contentOffset;
    if (CGPointEqualToPoint(oldOffset, newOffset)) {
        return;
    }
    super.contentOffset = newOffset;
    BOOL shouldChange = self.contentOffsetChanging(self, oldOffset, newOffset);
    if (shouldChange) {
        return;
    }

    // 禁止滑动，维持原来的位置
    // 纠偏
    CGFloat y = oldOffset.y;
    CGFloat max = self.contentSize.height - self.bounds.size.height;
    if (y > max) {
        y = max;
    }
    super.contentOffset = CGPointMake(oldOffset.x, y);
}
// enable-lint: duplicated_code



@end
