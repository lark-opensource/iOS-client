//
//  UINavigationController+ACCExpendCompletion.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/2/9.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationController (ACCExpendCompletion)

- (void)acc_pushViewController:(UIViewController *)viewController
                      animated:(BOOL)animated
                    completion:(dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
