//
//  BDXPopupViewController+Gesture.m
//  BDXContainer
//
//  Created by xinwen tan on 2021/4/22.
//

#import "BDXPopupSchemaParam.h"
#import "BDXPopupViewController+Gesture.h"
#import "BDXPopupViewController+Private.h"
#import "BDXPopupViewController.h"
#import "BDXView.h"

@implementation BDXPopupViewController (Gesture)

- (void)initGesture
{
    self.dragInMaxHeight = NO;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOnContainer:)];
    if (@available(iOS 11.0, *)) {
        pan.name = @"BDXPopupGesture";
    }
    pan.delegate = self;
    [self.view addGestureRecognizer:pan];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        return NO;
    }
    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
    if (!self.config.closeByGesture && !self.config.dragByGesture) {
        return NO;
    }
    __auto_type container = self.viewContainer;
    if (!CGRectContainsPoint(container.bounds, [pan locationInView:container])) {
        return NO;
    }

    __auto_type popUpType = self.config.type;
    if (popUpType == BDXPopupTypeBottomIn) {
        __auto_type velocity = [pan velocityInView:self.view];
        if (ABS(velocity.x) >= ABS(velocity.y)) { // initial direction is horizontal
            return NO;
        }

        if (velocity.y < 0) { // initial direction is up
            if (self.config.dragByGesture && !self.dragInMaxHeight) {
                return YES;
            } else {
                return NO;
            }
        } else {
            if (self.config.closeByGesture || (self.dragInMaxHeight && self.config.dragBack)) {
                return YES;
            } else {
                return NO;
            }
        }
    } else if (popUpType == BDXPopupTypeRightIn || popUpType == BDXPopupTypeDialog) {
        if (!self.config.closeByGesture) {
            return NO;
        }

        __auto_type velocity = [pan velocityInView:self.view];
        if (ABS(velocity.y) >= ABS(velocity.x)) { // initial direction is vertical
            return NO;
        }

        if (velocity.x < 0) { // initial direction is left
            return NO;
        }
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        return NO;
    }
    if (![otherGestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        return NO;
    }

    __auto_type view = otherGestureRecognizer.view;
    if (![view isDescendantOfView:self.view]) {
        return YES;
    }
    if (![view isKindOfClass:UIScrollView.class]) {
        return NO;
    }
    __auto_type scrollView = (UIScrollView *)view;

    __auto_type panelType = self.config.type;
    if (panelType == BDXPopupTypeBottomIn) {
        if (scrollView.contentSize.width > CGRectGetWidth(scrollView.bounds)) {
            return NO;
        }

        if (self.config.dragByGesture && !self.dragInMaxHeight) {
            return YES;
        }

        if (scrollView.contentOffset.y > (-scrollView.contentInset.top)) {
            return NO;
        }

        return YES;
    } else if (panelType == BDXPopupTypeRightIn || panelType == BDXPopupTypeDialog) {
        if (scrollView.contentSize.height > CGRectGetHeight(scrollView.bounds)) {
            return NO;
        }

        if (scrollView.contentOffset.x > (-scrollView.contentInset.left)) {
            return NO;
        }

        return YES;
    } else {
        return NO;
    }
}

- (void)panOnContainer:(UIPanGestureRecognizer *)pan
{
    if (self.config.dragByGesture) {
        [self handleDragEvent:pan];
    } else {
        [self handleCloseEvent:pan];
    }
}

- (void)handleCloseEvent:(UIPanGestureRecognizer *)pan
{
    __auto_type type = self.config.type;
    __auto_type state = pan.state;
    __auto_type location = [pan locationInView:self.view];
    __auto_type offsetInX = location.x - self.panStartLocation.x;
    __auto_type offsetInY = location.y - self.panStartLocation.y;
    if (state == UIGestureRecognizerStateBegan) {
        self.panStartLocation = location;
        self.userInteractionEnabled = NO;
    } else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        if ([self checkCloseLimit:pan offsetX:offsetInX offsetY:offsetInY]) {
            NSDictionary *params = @{@"reason": @(BDXPopupCloseReasonByGesture)};
            [self close:params completion:^{
                self.userInteractionEnabled = YES;
            }];
        } else {
            if (type == BDXPopupTypeDialog) {
                self.userInteractionEnabled = YES;
            } else {
                [UIView animateWithDuration:.3 animations:^{
                    self.frame = self.finalFrame;
                } completion:^(BOOL finished) {
                    self.userInteractionEnabled = YES;
                }];
            }
        }
    } else if (state == UIGestureRecognizerStateChanged) {
        __auto_type targetFrame = self.finalFrame;
        if (type == BDXPopupTypeBottomIn) {
            targetFrame.origin.y += MAX(offsetInY, 0);
            self.frame = targetFrame;
        } else if (type == BDXPopupTypeRightIn) {
            targetFrame.origin.x += MAX(offsetInX, 0);
            self.frame = targetFrame;
        }
    }
}

- (BOOL)checkCloseLimit:(UIPanGestureRecognizer *)pan offsetX:(CGFloat)x offsetY:(CGFloat)y
{
    if (self.config.type == BDXPopupTypeBottomIn) {
        __auto_type limit = ceil(CGRectGetHeight(self.view.bounds) * 0.2);
        __auto_type velocity = [pan velocityInView:nil];
        return y > limit || velocity.y > 600;
    } else {
        __auto_type limit = ceil(CGRectGetWidth(self.view.bounds) * 0.2);
        return x > limit;
    }
}

- (void)handleDragEvent:(UIPanGestureRecognizer *)pan
{
    __auto_type state = pan.state;
    __auto_type location = [pan locationInView:self.view];
    __auto_type offsetInY = location.y - self.panStartLocation.y;
    if (state == UIGestureRecognizerStateBegan) {
        self.panStartLocation = location;
        self.panStartFrame = self.viewContainer.frame;
        self.userInteractionEnabled = NO;
        self.handleTouchFinish = NO;
    } else if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
        if (self.dragInMaxHeight && self.config.dragBack) {
            [self handleDragBack];
        } else {
            [self handleDragEnd:pan offsetY:offsetInY];
        }
    } else if (state == UIGestureRecognizerStateChanged) {
        [self handleDragChanged:offsetInY];
    }
}

- (void)handleDragBack
{
    __auto_type curHeight = self.viewContainer.frame.size.height;
    if (curHeight >= self.dragHeightFrame.size.height) {
        // nothing to do
    } else if (curHeight > self.finalFrame.size.height) {
        [self resizeWithAnimation:self.dragHeightFrame completion:^{
            self.userInteractionEnabled = YES;
        }];
    } else if (curHeight > self.finalFrame.size.height * 0.8) {
        [self resizeWithAnimation:self.finalFrame completion:^{
            self.userInteractionEnabled = YES;
            self.dragInMaxHeight = NO;
        }];
    } else {
        if (self.config.closeByGesture) {
            NSDictionary *params = @{@"reason": @(BDXPopupCloseReasonByGesture)};
            [self close:params completion:^{
                self.userInteractionEnabled = YES;
            }];
        } else {
            [self resizeWithAnimation:self.finalFrame completion:^{
                self.userInteractionEnabled = YES;
                self.dragInMaxHeight = NO;
            }];
        }
    }
}

- (void)handleDragEnd:(UIPanGestureRecognizer *)pan offsetY:(CGFloat)y
{
    if (self.handleTouchFinish) {
        return;
    }
    BOOL gestureUp = y < 0;
    CGFloat limitRatio = gestureUp ? 0.1 : 0.2;
    __auto_type limit = ceil(CGRectGetHeight(self.view.bounds) * limitRatio);
    __auto_type limitVelocityY = gestureUp ? 100 : 400;
    __auto_type velocity = [pan velocityInView:nil];

    if (ABS(y) > limit || velocity.y > limitVelocityY) {
        if (gestureUp) {
            [self resizeWithAnimation:self.dragHeightFrame completion:^{
                self.userInteractionEnabled = YES;
                self.dragInMaxHeight = YES;
            }];
        } else {
            NSDictionary *params = @{@"reason": @(BDXPopupCloseReasonByGesture)};
            [self close:params completion:^{
                self.userInteractionEnabled = YES;
            }];
        }
    } else {
        if (gestureUp) {
            // 上滑回弹的时候，view会突然变小，导致下面有空白，所以暂时不加动画
            [self resize:self.panStartFrame];
            self.userInteractionEnabled = YES;
        } else {
            [self resizeWithAnimation:self.panStartFrame completion:^{
                self.userInteractionEnabled = YES;
            }];
        }
    }
}

- (void)handleDragChanged:(CGFloat)y
{
    // TODO: webview再拖动的时候，使用fixed吸底组件会抖动
    if (self.handleTouchFinish) {
        return;
    }
    // 初始状态不跟手的情况，只要检测到向上的手势，就变成最大高度
    if (!self.config.dragFollowGesture && !self.dragInMaxHeight && y < 0) {
        [self resizeWithAnimation:self.dragHeightFrame completion:^{
            self.userInteractionEnabled = YES;
            self.dragInMaxHeight = YES;
        }];
        self.handleTouchFinish = YES;
        return;
    }

    __auto_type targetFrame = self.panStartFrame;
    targetFrame.origin.y += y;
    targetFrame.size.height -= y;
    if (targetFrame.size.height > self.dragHeightFrame.size.height) {
        targetFrame = self.dragHeightFrame;
    }
    [self resize:targetFrame];
}

@end
