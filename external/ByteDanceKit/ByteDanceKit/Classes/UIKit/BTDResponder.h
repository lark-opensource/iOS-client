//
//  BTDResponder.h
//
//  Created by Quan Quan on 15/11/5.
//  Copyright © 2015年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface BTDResponder : NSObject

/**
 * @brief 寻找responder的NavigationController
 *
 * @param responder View或者ViewController
 */
+ (nullable UINavigationController *)topNavigationControllerForResponder:(nullable UIResponder *)responder;

/**
 * @brief 当前ViewController栈上，寻找top rootViewController
 */
+ (nullable UIViewController *)topViewController;

/**
 * @brief 指定的viewController是不是topmostViewController
   @param viewController 指定的viewController
 */
+ (BOOL)isTopViewController:(nonnull UIViewController *)viewController;

/**
 * @brief 当前ViewController栈上，寻找top rootViewController，返回其root view
 */
+ (nullable UIView *)topView;

/**
 * @brief 从指定ViewController开始的ViewController栈上，寻找top rootViewController
 *
 * @param rootViewController 寻找的起点ViewController
 */
+ (nullable UIViewController *)topViewControllerForController:(nonnull UIViewController *)rootViewController;

/**
 * @brief 从指定View开始的ViewController栈上，寻找top rootViewController
 *
 * @param view 寻找的起点View
 */
+ (nullable UIViewController *)topViewControllerForView:(nonnull UIView *)view;

/**
 * @brief 从指定responder开始的ViewController栈上，寻找top rootViewController
 *
 * @param responder View或者ViewController
 */
+ (nullable UIViewController *)topViewControllerForResponder:(nonnull UIResponder *)responder;

/**
 * @brief 关闭top rootViewController
 *
 * @param animated 是否有动画
 */
+ (void)closeTopViewControllerWithAnimated:(BOOL)animated;

@end

///////////////////////////////////////////////////////////////////////////////////

@interface UIViewController (BTD_Close)

/**
 * @brief 关闭自己
 *
 * @param animated 是否有动画
 */
- (void)closeWithAnimated:(BOOL)animated;

@end
