//
//  UIViewController+CJPay.m
//  AFNetworking
//
//  Created by wangxinhua on 2018/8/17.
//

#import "UIViewController+CJPay.h"

#import <objc/runtime.h>
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayDataSecurityModel.h"
#import "CJPaySettingsManager.h"
#import "CJPayUIMacro.h"

@implementation UIViewController (CJPay)

- (void(^)(void))cjBackBlock {
    return objc_getAssociatedObject(self, @selector(cjBackBlock));
}

- (void)setCjBackBlock:(nullable void(^)(void))cjBackBlock {
    objc_setAssociatedObject(self, @selector(cjBackBlock), cjBackBlock, OBJC_ASSOCIATION_COPY);
}

- (UIWindow *)cj_window {
    return self.view.window;
}

+ (UIViewController *)cj_topViewController {
    __block UIViewController *resultVC;
//    CJPayLogAssert(CJ_Pad, @"在iPad场景，不应该直接调用该方法");
    resultVC = [self _cjvisibleTopViewController:[[self cj_mainWindow] rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _cjvisibleTopViewController:resultVC.presentedViewController];
    }
//    if ([resultVC isKindOfClass:[CJPayHalfLoadingItem class]]) {//loadingVC应忽略
//        CJPayHalfLoadingItem *item = (CJPayHalfLoadingItem *)resultVC;
//        if (item.originNavigationController) {
//            return [item.originNavigationController.viewControllers lastObject];
//        } else if (item.topVc) {
//            return item.topVc;
//        } else {
//            return item;
//        }
//    }
    UIViewController *customTopVC = [resultVC cj_customTopVC];
    if (customTopVC) {
        return customTopVC;
    }
    CJPayLogInfo(@"get top vc: %@", resultVC);
    return resultVC;
}

- (UIViewController *)cj_customTopVC { //提供覆写topVC能力
    return nil;
}

+ (BOOL)isTopVcBelongHalfVc {
    __block UIViewController *resultVC;
    resultVC = [self _cjvisibleTopViewController:[[self cj_mainWindow] rootViewController]];
    while (resultVC.presentedViewController) { 
        resultVC = [self _cjvisibleTopViewController:resultVC.presentedViewController];
    }
    if ([resultVC isKindOfClass:[CJPayHalfPageBaseViewController class]]) {
        return YES;
    }
    return NO;
}

+ (UIViewController *)cj_foundTopViewControllerFrom:(nullable UIViewController *)fromVC {
    if (!CJ_Pad) {
        return [self cj_topViewController];
    }
    if (CJ_Pad_Support_Multi_Window && !fromVC) {
        [CJMonitor trackService:@"wallet_found_topvc_exception" extra:@{@"topvc": CJString(fromVC.description)}];
    }
    if (![fromVC isKindOfClass:UIViewController.class]) {
        CJPayLogAssert(NO, @"传入的fromVC类型不正确");
        return [UIViewController cj_topViewController];
    }
    UIViewController *sourceVC = fromVC;
    if (fromVC.isViewLoaded) {
        sourceVC = fromVC.view.window.rootViewController ?: fromVC.navigationController ?: fromVC;
    } else {
        sourceVC = [self cj_mainWindow].rootViewController;
    }
    UIViewController *resultVC = [self _cjvisibleTopViewController:sourceVC];
    while (resultVC.presentedViewController) {
        resultVC = [self _cjvisibleTopViewController:resultVC.presentedViewController];
    }
    UIViewController *customTopVC = [resultVC cj_customTopVC];
    if (customTopVC) {
        return customTopVC;
    }
//    if ([resultVC isKindOfClass:[CJPayHalfLoadingItem class]]) {//loadingVC应忽略
//        CJPayHalfLoadingItem *item = (CJPayHalfLoadingItem *)resultVC;
//        if (item.originNavigationController) {
//            return [item.originNavigationController.viewControllers lastObject];
//        } else if (item.topVc) {
//            return item.topVc;
//        } else {
//            return item;
//        }
//    }
    return resultVC;
}

+ (UIViewController *)_cjvisibleTopViewController:(UIViewController *)vc
{
    NSString *useTopVCV2 = [CJPaySettingsManager shared].currentSettings.topVCV2;
    //优先取presentedViewController，解决tabbarController presentVC后topvc的问题
    if ([useTopVCV2 isEqualToString:@"1"]) {
        if (vc.presentedViewController) {
            return [self _cjvisibleTopViewController:vc.presentedViewController];
        } else if ([vc isKindOfClass:[UINavigationController class]]) {
            return [self _cjvisibleTopViewController:[(UINavigationController *)vc visibleViewController]];
        } else if ([vc isKindOfClass:[UITabBarController class]]) {
            return [self _cjvisibleTopViewController:[(UITabBarController *)vc selectedViewController]];
        } else {
            return vc;
        }
    } else {
        if ([vc isKindOfClass:[UINavigationController class]]) {
            return [self _cjvisibleTopViewController:[(UINavigationController *)vc visibleViewController]];
        } else if ([vc isKindOfClass:[UITabBarController class]]) {
            return [self _cjvisibleTopViewController:[(UITabBarController *)vc selectedViewController]];
        } else if (vc.presentedViewController) {
            return [self _cjvisibleTopViewController:vc.presentedViewController];
        } else {
            return vc;
        }
    }
}

+ (UIWindow *)cj_mainWindow {
    UIWindow * window = nil;
    if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        window = [[UIApplication sharedApplication].delegate window];
    }
    if (![window isKindOfClass:[UIView class]]) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    if (!window) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    return window;
}

- (void)cj_presentWithNewNavVC {
    CJPayNavigationController *navVC = [CJPayNavigationController instanceForRootVC:self];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIViewController cj_foundTopViewControllerFrom:self.cjpay_referViewController] presentViewController:navVC animated:YES completion:nil];
    });
}

- (NSString *)cj_performanceMonitorName {
    return NSStringFromClass([self class]);
}


- (BOOL)isCJPayViewController {
    return [self isKindOfClass:CJPayBaseViewController.class];
}

- (NSString *)cj_trackerName {
    return [NSString stringWithFormat:@"%@", self];
}

- (void)cj_presentViewController:(UIViewController *)viewControllerToPresent
                        animated:(BOOL)flag
                      completion:(nullable void (^)(void))completion {
    if (self.presentedViewController) {
        NSString *fromVCStr = NSStringFromClass([self class]);
        NSString *toVCStr = NSStringFromClass([viewControllerToPresent class]);
        [CJMonitor trackService:@"wallet_rd_present_exception"
                       category:@{@"from_vc": CJString(fromVCStr),
                                  @"to_vc": CJString(toVCStr)}
                          extra:@{}];
        
        [self p_trackerPresentWithVC:viewControllerToPresent];
        CJPayLogInfo(@"presentedVC不为空：%@",[self.presentedViewController cj_trackerName]);
        [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ //延时作用：确保presented dismiss成功，避免present失败
            [self presentViewController:viewControllerToPresent animated:flag completion:^{
                CJPayLogInfo(@"present动作成功");
                CJ_CALL_BLOCK(completion);
            }];
        });
    } else {
        [self presentViewController:viewControllerToPresent animated:flag completion:completion];
    }
}

- (void)p_trackerPresentWithVC:(UIViewController *)viewControllerToPresent {
    NSMutableArray *vcs = [NSMutableArray array];
    if ([self.presentedViewController isKindOfClass:CJPayNavigationController.class]) {
        CJPayNavigationController *presentNavi = (CJPayNavigationController *)self.presentedViewController;
        [presentNavi.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [vcs addObject:CJString([obj cj_trackerName])];
        }];
    }
    [CJTracker event:@"cjpay_present" params:@{
        @"presentedVC": [self.presentedViewController cj_trackerName],
        @"selfVC": [self cj_trackerName],
        @"presentedVCs": vcs
    }];
}

@end

@implementation UINavigationController(CJPay)

- (void)cj_popViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        CJ_CALL_BLOCK(completion);
    }];
    [self popViewControllerAnimated:animated];
    [CATransaction commit];
}

@end
