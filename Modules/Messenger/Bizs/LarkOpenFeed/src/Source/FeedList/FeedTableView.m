//
//  FeedTableView.m
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/10.
//

#import "FeedTableView.h"

@interface FeedTableView() <UIGestureRecognizerDelegate>
@end

@implementation FeedTableView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return _outerScrollView.panGestureRecognizer == otherGestureRecognizer;
}

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
    CGFloat min = 0;
    if (y < min) {
        y = min;
    }
    super.contentOffset = CGPointMake(oldOffset.x, y);
}

@end

