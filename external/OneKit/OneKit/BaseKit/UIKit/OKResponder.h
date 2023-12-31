//
//  OKResponder.h
//
//  Created by Quan Quan on 15/11/5.
//  Copyright © 2015 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface OKResponder : NSObject

/**
 * @brief Find the responder's NavigationController.
 *
 * @param responder A View or a ViewController.
 */
+ (nullable UINavigationController *)topNavigationControllerForResponder:(nullable UIResponder *)responder;

/**
 * @brief Return the top rootViewController of the current ViewControllers' stack.
 */
+ (nullable UIViewController *)topViewController;

/**
 * @brief Is viewController the  topViewController?
   @param viewController A ViewController.
 */
+ (BOOL)isTopViewController:(nonnull UIViewController *)viewController;

/**
 * @brief Return the root view of the top rootViewController in the current ViewControllers' stack.
 */
+ (nullable UIView *)topView;

/**
 * @brief Find the top rootViewController from the rootViewController in it's ViewControllers' stack.
 *
 * @param rootViewController A UIViewController.
 */
+ (nullable UIViewController *)topViewControllerForController:(nonnull UIViewController *)rootViewController;

/**
 * @brief Find the top rootViewController from the view in it's ViewControllers' stack.
 *
 * @param view A UIView.
 */
+ (nullable UIViewController *)topViewControllerForView:(nonnull UIView *)view;

/**
 * @brief Find the top rootViewController from the responder in it's ViewControllers' stack.
 *
 * @param responder A UIResponder.
 */
+ (nullable UIViewController *)topViewControllerForResponder:(nonnull UIResponder *)responder;

/**
 * @brief Close the top rootViewController.
 *
 * @param animated  `YES` if the change should be animated, `NO` if the change should happen immediately.
 */
+ (void)closeTopViewControllerWithAnimated:(BOOL)animated;

@end

///////////////////////////////////////////////////////////////////////////////////

@interface UIViewController (OK_Close)

/**
 * @brief Close self.
 *
 * @param animated  `YES` if the change should be animated, `NO` if the change should happen immediately.
 */
- (void)closeWithAnimated:(BOOL)animated;

@end
