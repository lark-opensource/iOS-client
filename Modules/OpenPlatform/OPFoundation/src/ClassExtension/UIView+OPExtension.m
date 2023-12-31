//
// Copyright 2009-2011 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "UIView+OPExtension.h"
#import <objc/runtime.h>
#import "UIColor+OPExtension.h"

const CGFloat OPCornerRadiusRatioNoExisted = -1;
const CGFloat OPCornerRadiusRatioAlwaysCircle = 0.5f;

@implementation UIView (BDPExtension)

#pragma mark - Factory

+ (instancetype)op_dimmingView
{
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor op_BlackColor4];
    return view;
}

#pragma mark - Style

- (CGFloat)op_left {
  return self.frame.origin.x;
}

- (void)setOp_left:(CGFloat)x {
  CGRect frame = self.frame;
  frame.origin.x = x;
  self.frame = frame;
}

- (CGFloat)op_top {
  return self.frame.origin.y;
}

- (void)setOp_top:(CGFloat)y {
  CGRect frame = self.frame;
  frame.origin.y = y;
  self.frame = frame;
}

- (CGFloat)op_right {
  return self.frame.origin.x + self.frame.size.width;
}

- (void)setOp_right:(CGFloat)right {
  CGRect frame = self.frame;
  frame.origin.x = right - frame.size.width;
  self.frame = frame;
}

- (CGFloat)op_bottom {
  return self.frame.origin.y + self.frame.size.height;
}

- (void)setOp_bottom:(CGFloat)bottom {
  CGRect frame = self.frame;
  frame.origin.y = bottom - frame.size.height;
  self.frame = frame;
}

- (CGFloat)op_centerX {
  return self.center.x;
}

- (void)setOp_centerX:(CGFloat)centerX {
  self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)op_centerY {
  return self.center.y;
}

- (void)setOp_centerY:(CGFloat)centerY {
  self.center = CGPointMake(self.center.x, centerY);
}

- (CGFloat)op_width {
  return self.frame.size.width;
}

- (void)setOp_width:(CGFloat)width {
  CGRect frame = self.frame;
  frame.size.width = width;
  self.frame = frame;
}

- (CGFloat)op_height {
  return self.frame.size.height;
}

- (void)setOp_height:(CGFloat)height {
  CGRect frame = self.frame;
  frame.size.height = height;
  self.frame = frame;
}

- (CGFloat)op_screenViewX {
  CGFloat x = 0.0f;
  for (UIView* view = self; view; view = view.superview) {
      x += view.op_left;

    if ([view isKindOfClass:[UIScrollView class]]) {
      UIScrollView* scrollView = (UIScrollView*)view;
      x -= scrollView.contentOffset.x;
    }
  }

  return x;
}

- (CGFloat)op_screenViewY {
  CGFloat y = 0;
  for (UIView* view = self; view; view = view.superview) {
    y += view.op_top;

    if ([view isKindOfClass:[UIScrollView class]]) {
      UIScrollView* scrollView = (UIScrollView*)view;
      y -= scrollView.contentOffset.y;
    }
  }
  return y;
}

- (CGRect)op_screenFrame {
  return CGRectMake(self.op_screenViewX, self.op_screenViewY, self.op_width, self.op_height);
}

- (CGPoint)op_origin {
  return self.frame.origin;
}

- (void)setOp_origin:(CGPoint)origin {
  CGRect frame = self.frame;
  frame.origin = origin;
  self.frame = frame;
}

- (CGSize)op_size {
  return self.frame.size;
}

- (void)setOp_size:(CGSize)size {
  CGRect frame = self.frame;
  frame.size = size;
  self.frame = frame;
}

- (CGRect)op_originalFrame {
    CGAffineTransform currentTransform = self.transform;
    self.transform = CGAffineTransformIdentity;
    CGRect originalFrame = self.frame;
    self.transform = currentTransform;
    
    return originalFrame;
}

- (UIViewController *)op_findFirstViewController
{
    for (UIView *next = self; next; next = next.superview) {
        UIResponder *nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)nextResponder;
        }
    }
    return nil;
}

- (BOOL)op_isVisible {
    return (self.window != nil && !self.window.hidden && !self.hidden && self.alpha > 0);
}

@end
