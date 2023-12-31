//
//  BDPNavigationController.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class BDPNavigationController;
@class OPContainerContext;

/* ------------- 导航路由代理 ------------- */
@protocol BDPNavigationControllerRouteProtocol <NSObject>

@optional
- (void)navigation:(BDPNavigationController *)navigation didPushViewController:(UIViewController *)vc;
- (void)navigation:(BDPNavigationController *)navigation didPopViewController:(NSArray<UIViewController *> *)vcs willShowViewController:(UIViewController *)vc;

@end

/* ------------- 自定义导航栏组件 ------------- */
@protocol BDPNavigationControllerItemProtocol <NSObject>

@optional
- (NSArray<UIBarButtonItem *> *)navigationLeftItems:(BDPNavigationController *)navigation;
- (NSArray<UIBarButtonItem *> *)navigationRightItems:(BDPNavigationController *)navigation;

@end

/* ------------- 导航栏Bar代理 ------------- */
@protocol BDPNavigationControllerBarProtocol <NSObject>

@optional
- (void)navigationBackBarClicked:(BDPNavigationController *)navigation;

@end

@interface BDPNavigationController : UINavigationController

@property (nonatomic, weak) id<BDPNavigationControllerRouteProtocol> navigationRouteDelegate;
@property (nonatomic, weak) id<BDPNavigationControllerBarProtocol> navigationBarDelegate;
@property (nonatomic, assign) BOOL barBackgroundHidden;
@property (nonatomic, assign) CGSize windowSize;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
                       barBackgroundHidden:(BOOL)barBackgroundHidden
                          containerContext:(OPContainerContext *)containerContext;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController NS_UNAVAILABLE;

/// 使用自定义的动画。 app page之间的跳转使用自定义动画，containerVC的subNavi使用系统的动画。
- (void)useCustomAnimation;

/* ------------- StatusBar Style ------------- */
- (void)updateStatusBarStyle:(BOOL)animated;
- (void)updateStatusBarHidden:(BOOL)animated;

/* ------------- NavigationBar Style ------------- */
- (void)setNavigationBarBackgroundColor:(UIColor *)color;
- (void)setNavigationBarTitleTextAttributes:(NSDictionary<NSAttributedStringKey, id> *)titleTextAttributes viewController:(UIViewController *)viewController;
- (void)setNavigationItemTitle:(NSString *)title viewController:(UIViewController *)viewController;
- (void)setNavigationItemTintColor:(UIColor *)color viewController:(UIViewController *)viewController;
- (void)setNavigationPopGestureEnabled:(BOOL)enabled;

/// 初始化自定义的导航栏titleView
- (void)initNavigationTitleView:(UIViewController *)viewController;
/// 显示或隐藏导航栏的菊花载入动画，默认隐藏
- (void)setNavigationBarLoading:(BOOL)showed viewController:(UIViewController *)viewController;

/// 强制需要发送AppRoute的pop方法
- (UIViewController *)popViewControllerWithAppRouteAnimated:(BOOL)animated;
/// 强制需要发送AppRoute的push方法
- (void)pushViewControllerWithAppRoute:(UIViewController *)viewController animated:(BOOL)animated;

/// 更新导航栏右侧组件
- (void)updateRightItems:(NSArray<UIBarButtonItem *> *)rightItemsv viewController:(UIViewController *)viewController;

@end

@interface BDPNavigationController (Private)

- (UIViewController *)origin_popViewControllerAnimated:(BOOL)animated;
- (void)origin_pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

// 自定义的导航栏标题Label，因为部分宿主hook了导航栏UILabel的setText方法
@interface BDPNavigationTitleLabel : UIView

@property (nonatomic, copy) NSAttributedString *attributedText;

/// 根据attributedText调整UIView大小
- (void)adjustLabelSize:(CGFloat)maxWidth;

@end

NS_ASSUME_NONNULL_END
