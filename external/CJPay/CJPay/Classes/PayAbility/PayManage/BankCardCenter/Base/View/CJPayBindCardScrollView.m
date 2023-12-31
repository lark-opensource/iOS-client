//
//  CJPayBindCardScrollView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/28.
//

#import "CJPayBindCardScrollView.h"

@implementation CJPayBindCardScrollView

- (BOOL)gestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UISwipeGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
