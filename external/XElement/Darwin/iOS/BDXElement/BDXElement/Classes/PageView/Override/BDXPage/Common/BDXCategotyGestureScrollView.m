//
//  BDXCategotyGestureScrollView.m
//  BDXElement
//
//  Created by hanzheng on 2021/2/24.
//

#import "BDXCategotyGestureScrollView.h"
#import <Lynx/LynxView.h>

@implementation BDXCategotyGestureScrollView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UILayoutContainerView")]) {
        if ((otherGestureRecognizer.state == UIGestureRecognizerStateBegan || otherGestureRecognizer.state == UIGestureRecognizerStatePossible)&& self.contentOffset.x <= 0) {
            return YES;
        }
    }
    return NO;
}

@end


@implementation BDXCategotyGestureCollectionView


- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (!self.horizonScrollEnable) {
        if ([panGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            CGPoint velocity = [(UIPanGestureRecognizer *)panGestureRecognizer velocityInView:self];
            if (fabs(velocity.y) < fabs(velocity.x)) {
                return NO;
            }
        }
    }
  
    if (self.gestureBeginOffset != 0 &&
        [panGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        ([panGestureRecognizer locationInView:self].x - self.contentOffset.x) < self.gestureBeginOffset) {
      return NO;
    }
  
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {

    if ([otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"UILayoutContainerView")]) {
        if ((otherGestureRecognizer.state == UIGestureRecognizerStateBegan || otherGestureRecognizer.state == UIGestureRecognizerStatePossible)&& self.contentOffset.x <= 0) {
            return YES;
        }
    }
  
  if (self.direction != BDXCategotyGestureScrollViewDirection_Default &&
      [otherGestureRecognizer.view isKindOfClass:UIScrollView.class] &&
      [otherGestureRecognizer isKindOfClass:UIPanGestureRecognizer.class] &&
      [self.lynxView isDescendantOfView:otherGestureRecognizer.view] &&
      (otherGestureRecognizer.state == UIGestureRecognizerStateBegan || otherGestureRecognizer.state == UIGestureRecognizerStatePossible) &&
      ((UIScrollView *)(otherGestureRecognizer.view)).contentSize.width > otherGestureRecognizer.view.bounds.size.width) {
    if (self.direction == BDXCategotyGestureScrollViewDirection_Left && self.contentOffset.x <= 0) {
      return YES;
    } else if (self.direction == BDXCategotyGestureScrollViewDirection_Right && self.contentOffset.x >= self.contentSize.width - self.bounds.size.width) {
      return YES;
    }  else if (self.direction == BDXCategotyGestureScrollViewDirection_Auto) {
      CGPoint velocity = [(UIPanGestureRecognizer *)otherGestureRecognizer velocityInView:self];
      if (velocity.x > 0 && self.contentOffset.x <= 0) {
        return YES;
      } else if (velocity.x < 0 && self.contentOffset.x >= self.contentSize.width - self.bounds.size.width) {
        return YES;
      }
    }
             
  }
    
    return NO;
}

@end
