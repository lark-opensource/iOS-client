//
//  CJPayNavigationController.h
//  CJPay
//
//  Created by 王新华 on 9/19/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger ,CJPayDismissAnimatedType) {
    CJPayDismissAnimatedTypeFromBottom, //强制从上向下退出，默认值
    CJPayDismissAnimatedTypeFromRight, //强制从左向右退出
    CJPayDismissAnimatedTypeNone, // 强制无动画退出
};

extern NSInteger const gCJTransitionMaxX;

@class CJPayTransitionManager;
@interface CJPayNavigationController : UINavigationController<UIViewControllerTransitioningDelegate>

+ (CJPayNavigationController *)instanceForRootVC:(UIViewController *)rootVC;
+ (CJPayNavigationController *)customPushNavigationVC;

@property (nonatomic, strong) CJPayTransitionManager *transitionManager;
@property (nonatomic, assign) CGFloat cjpadPreferHeight;
@property (nonatomic, assign) CJPayDismissAnimatedType dismissAnimatedType;
@property (nonatomic, assign) BOOL useNewHalfPageTransAnimation; //半屏页面使用新转场动画

- (void)pushViewControllerSingleTop:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion;
- (BOOL)hasFullPageInNavi; // 判断导航栈中是否有全屏VC
@end

NS_ASSUME_NONNULL_END
