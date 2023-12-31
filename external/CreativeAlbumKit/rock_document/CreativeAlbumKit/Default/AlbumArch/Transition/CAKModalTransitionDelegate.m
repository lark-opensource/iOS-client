//
//  CAKModalTransitionDelegate.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/9.
//

#import "CAKModalTransitionDelegate.h"
#import "CAKBouncePresentAnimationController.h"
#import "CAKBounceDismissAnimationController.h"

@interface CAKModalTransitionDelegate ()

@end

@implementation CAKModalTransitionDelegate

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    return [[CAKBouncePresentAnimationController alloc] init];
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    
    return [CAKBounceDismissAnimationController new];
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
    
    return self.swipeInteractionController.interactionInProgress ? self.swipeInteractionController : nil;
}

- (CAKSwipeInteractionController *)swipeInteractionController {
    
    if (!_swipeInteractionController) {
        _swipeInteractionController = [[CAKSwipeInteractionController alloc] init];
    }
    return _swipeInteractionController;
}

@end
