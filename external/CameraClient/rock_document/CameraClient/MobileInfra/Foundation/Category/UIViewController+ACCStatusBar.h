//
//  UIViewController+ACCStatusBar.h
//  AWEBizUIComponent
//
//  Created by long.chen on 2019/11/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
 * force hide or show current view controller
 */
@interface UIViewController (ForceStatusBarShowOrHide)

- (BOOL)acc_forceHideStatusBar;
- (BOOL)acc_forceShowStatusBar;

+ (BOOL)acc_setStatusBarForceHide:(BOOL)hide;
+ (BOOL)acc_setStatusBarForceShow:(BOOL)show;

@end

NS_ASSUME_NONNULL_END
