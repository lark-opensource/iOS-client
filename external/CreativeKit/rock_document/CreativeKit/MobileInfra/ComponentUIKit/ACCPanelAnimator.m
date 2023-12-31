//
//  ACCPanelAnimator.m
//  CameraClient
//
//  Created by wishes on 2020/2/28.
//
#import "ACCPanelAnimator.h"

@interface ACCPanelSlideDownAnimator ()

@end

@implementation ACCPanelSlideDownAnimator

@synthesize animationDidEnd,animationWillStart,targetView,type,containerView;

- (void)animate {
    self.type = ACCPanelAnimationDismiss;
    if (self.animationWillStart) {
        self.animationWillStart(self);
    }

    [UIView animateWithDuration:self.duration delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.targetView.frame = CGRectMake(0, self.containerView.bounds.size.height, self.containerView.bounds.size.width, self.targetAnimationHeight);
    } completion:^(BOOL finished) {
        self.targetView.frame = CGRectMake(0, self.containerView.bounds.size.height, self.containerView.bounds.size.width, self.targetAnimationHeight);
        if (self.animationDidEnd) {
            self.animationDidEnd(self);
        }
    }];
}


@end

@interface ACCPanelSlideUpAnimator ()

@end

@implementation ACCPanelSlideUpAnimator

@synthesize animationDidEnd,animationWillStart,targetView,type,containerView;

- (void)animate {
    self.type = ACCPanelAnimationShow;
    if (self.animationWillStart) {
       self.animationWillStart(self);
    }
    self.targetView.frame = CGRectMake(0, self.containerView.bounds.size.height, self.containerView.bounds.size.width, self.targetAnimationHeight);
    [UIView animateWithDuration:self.duration delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.targetView.frame = CGRectMake(0, self.containerView.bounds.size.height - self.targetAnimationHeight, self.containerView.bounds.size.width, self.targetAnimationHeight);
    } completion:^(BOOL finished) {
        self.targetView.frame = CGRectMake(0, self.containerView.bounds.size.height - self.targetAnimationHeight, self.containerView.bounds.size.width, self.targetAnimationHeight);
        if (self.animationDidEnd) {
            self.animationDidEnd(self);
        }
    }];
}

@end
