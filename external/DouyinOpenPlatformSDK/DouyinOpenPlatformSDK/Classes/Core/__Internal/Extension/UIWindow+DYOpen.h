//
//  UIWindow+DYOpen.h
//  DouyinOpenPlatformSDK-ad006023
//
//  Created by arvitwu on 2022/10/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (DYOpen)

/// 获取 key window
+ (nullable UIWindow *)dyopen_keyWindow;

/// 获取 topVC
+ (UIViewController *)dyopen_topViewController;

@end

NS_ASSUME_NONNULL_END
