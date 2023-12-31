//
//  CAKAlbumSlidingScrollView.m
//  CreativeAlbumKit_Example
//
//  Created by yuanchang on 2020/12/2.
//  Copyright © 2020 lixingdong. All rights reserved.
//

#import "CAKAlbumSlidingScrollView.h"

@implementation CAKAlbumSlidingScrollView

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self edgePan:gestureRecognizer]) {
        return NO;
    }
    return YES;
}

- (BOOL)edgePan:(UIGestureRecognizer *)gestureRecognizer
{
#if TARGET_iOS
    if (gestureRecognizer == self.panGestureRecognizer) {
        UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
        CGPoint point = [pan translationInView:self];
        UIGestureRecognizerState state = gestureRecognizer.state;
        if (UIGestureRecognizerStateBegan == state || UIGestureRecognizerStatePossible == state) {
            CGPoint location = [gestureRecognizer locationInView:self];
            if (point.x > 0 && location.x <= [UIApplication sharedApplication].keyWindow.bounds.size.width && self.contentOffset.x <= 0) {
                return YES;
            } else if (point.x < 0 && self.contentOffset.x >= self.contentSize.width - self.bounds.size.width) {
                return YES;
            }
        }
    }
    return NO;
#else
    return NO;
#endif
}


@end
