//
//  BDPBaseViewController.h
//  Timor
//
//  Created by 王浩宇 on 2019/1/27.
//

#import <UIKit/UIKit.h>

@interface BDPBaseViewController : UIViewController

// 初始化导航栏。
- (void)setupNavigationBar;
// 更新导航栏样式。
- (void)updateNavigationBarStyle:(BOOL)animated;
// 更新状态栏。
- (void)updateStatusBarStyle:(BOOL)animated;
/// 是否隐藏导航栏 default:NO
- (BOOL)navigationBarHidden;
/// 是否启用手势返回 default:YES
- (BOOL)popGestureEnable;
/// 更新view controller style，包括导航栏样式，是否启用手势返回
- (void)updateViewControllerStyle:(BOOL)animated;

@end
