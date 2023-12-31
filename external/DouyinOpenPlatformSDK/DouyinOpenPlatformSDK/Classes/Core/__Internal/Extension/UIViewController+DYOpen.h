//
//  UIViewController+DYOpen.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/9/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (DYOpen)

/// 添加 childVC
/// @param childVC 待添加的 child vc
/// @param atView 将 childVC.view 添加到指定的 view 上，为 nil 时添加到父 vc 的 self.view 上
- (void)dyopen_addChildVC:(nonnull UIViewController *)childVC atView:(nullable UIView *)atView;

/// 移除 childVC
/// @param childVC 待移除的 child vc
- (void)dyopen_removeChildVC:(nonnull UIViewController *)childVC;

@end

NS_ASSUME_NONNULL_END
