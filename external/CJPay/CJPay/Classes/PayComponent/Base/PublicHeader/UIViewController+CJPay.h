//
//  UIViewController+CJPay.h
//  AFNetworking
//
//  Created by wangxinhua on 2018/8/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (CJPay)

+ (UIViewController *_Nullable)cj_topViewController;
+ (BOOL)isTopVcBelongHalfVc;
+ (UIViewController *_Nullable)cj_foundTopViewControllerFrom:(nullable UIViewController *)fromVC;
- (void)cj_presentWithNewNavVC;
- (BOOL)isCJPayViewController;
- (void)cj_presentViewController:(UIViewController *)viewControllerToPresent
                        animated:(BOOL)flag
                      completion:(nullable void (^)(void))completion;

- (NSString *)cj_performanceMonitorName;
- (NSString *)cj_trackerName;
- (UIViewController *)cj_customTopVC;

@property (nonatomic, copy) void(^ _Nullable cjBackBlock)(void);
@property (nonatomic,readonly,strong) UIWindow *cj_window;

@end

@interface UINavigationController(CJPay)

- (void)cj_popViewControllerAnimated:(BOOL)animated completion:(void (^ __nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
