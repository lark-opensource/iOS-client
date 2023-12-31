//
//  BDPResponderHelper.h
//  Timor
//
//  Created by CsoWhy on 2018/9/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPResponderHelper : NSObject

// window的大小（兼容iOS7）
+ (CGSize)windowSize:(UIWindow *_Nullable)window;

// UIScreen大小（兼容iOS7）
+ (CGSize)screenSize;

// 安全区域
+ (UIEdgeInsets)safeAreaInsets:(UIWindow *_Nullable)window;

/**
 获取指定UIResponder的响应链下游第一个UIViewController对象，注意有可能返回childViewController
 如果想取parentViewController，就用correctTopViewControllerFor:
 如果想取view所在的ViewController，直接使用view.viewController(在SSViewControllerBase中)
 @warning 当responder是UINavigationController或者UITabBarController时，会查找其childViewController而非parentViewController
 @param responder responder
 @return UIViewController
 */
+ (nullable UIViewController *)topViewControllerFor:(UIResponder *_Nullable)responder;

/** 获取指定UIResponder的响应链下游第一个UINavigationController对象，使用topViewControllerFor: */
+ (nullable UINavigationController *)topNavigationControllerFor:(UIResponder *_Nullable)responder;

/** 获取最顶层UIViewController*/
+ (nullable UIViewController *)topViewControllerForController:(UIViewController *)rootViewController fixForPopover:(BOOL)fixForPopover;

/** 获取指定类型的ParentViewController(逐层查找) */
+ (id)findParentViewControllerFor:(UIViewController *)viewController class:(Class)clz;

/** 获取windows.rootVC最上游的UIView对象，使用topViewControllerForController: */
+ (nullable UIView*)topmostView:(UIWindow *_Nullable)window;

/** 获取当前应用响应链最上游的UIViewController对象，使用topViewControllerFor: */
+ (nullable UIViewController *)topmostViewController:(UIWindow *_Nullable)window;

@end

NS_ASSUME_NONNULL_END
