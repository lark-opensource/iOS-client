//
//  UINavigationController+ACCExpendCompletion.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/2/9.
//

#import "UINavigationController+ACCExpendCompletion.h"

@implementation UINavigationController (ACCExpendCompletion)

- (void)acc_pushViewController:(UIViewController *)viewController
                      animated:(BOOL)animated
                    completion:(dispatch_block_t)completion
{
    [self pushViewController:viewController animated:animated];
    if (animated && self.transitionCoordinator) {
        [self.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            !completion ? : completion();
        }];
    } else {
        !completion ? : completion();
    }
}



@end
