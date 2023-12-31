// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxScrollView.h"

@implementation LynxScrollView

- (BOOL)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
        (UISwipeGestureRecognizer *)otherGestureRecognizer {
  if (nil != self.parentScrollView &&
      [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]] && self.enableNested) {
    return YES;
  }

  if ([otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UILayoutContainerView")]) {
    if ((otherGestureRecognizer.state == UIGestureRecognizerStateBegan ||
         otherGestureRecognizer.state == UIGestureRecognizerStatePossible)) {
      if (!self.scrollY && !self.bounces) {
        if (!self.isRTL && self.contentOffset.x <= 0) {
          return YES;
        }
        if (self.scrollY &&
            self.contentOffset.x >= self.contentSize.width - self.frame.size.width) {
          return YES;
        }
      }
    }
  }

  return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldBeRequiredToFailByGestureRecognizer:
        (nonnull UIGestureRecognizer *)otherGestureRecognizer {
  if (_forceCanScroll && [otherGestureRecognizer.view isKindOfClass:_blockGestureClass] &&
      otherGestureRecognizer.view.tag == _recognizedViewTag) {
    return YES;
  }
  return NO;
}

@end  // LynxScrollView
