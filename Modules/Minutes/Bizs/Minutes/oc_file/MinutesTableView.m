//
//  MinutesTableView.m
//  Minutes
//
//  Created by chenlehui on 2021/12/28.
//

#import "MinutesTableView.h"

@interface MinutesTableView() <UIGestureRecognizerDelegate>
@end

@implementation MinutesTableView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return _outerScrollView.panGestureRecognizer == otherGestureRecognizer;
}
// disable-lint: duplicated_code
- (void)setContentOffset:(CGPoint)contentOffset {
    if (!self.contentOffsetChanging) {
        super.contentOffset = contentOffset;
        return;
    }

    // API 调用
    if (!self.isDragging && !_outerScrollView.isDragging) {
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
    CGFloat min = -self.adjustedContentInset.top;
    if (y < min) {
        y = min;
    }
    super.contentOffset = CGPointMake(oldOffset.x, y);
}
// enable-lint: duplicated_code


@end
