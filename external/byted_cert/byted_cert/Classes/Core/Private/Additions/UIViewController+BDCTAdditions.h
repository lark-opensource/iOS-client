//
//  UIViewController+BDCTAdditions.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface UIWindow (BDCTAdditions)

+ (UIWindow *)bdct_keyWindow;

@end


@interface UIViewController (BDCTAdditions)

- (void)bdct_showViewController:(UIViewController *)viewController;

- (void)bdct_dismiss;
- (void)bdct_dismissWithComplation:(nullable void (^)(void))completion;

+ (UIViewController *)bdct_topViewController;

@end


@interface UIAlertController (BDCTAdditions)

- (void)bdct_showFromViewController:(UIViewController *)fromViewController;

@end

NS_ASSUME_NONNULL_END
