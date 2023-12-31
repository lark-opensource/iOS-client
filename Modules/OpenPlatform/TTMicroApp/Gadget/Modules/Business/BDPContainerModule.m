//
//  BDPContainerModule.m
//  Timor
//
//  Created by houjihu on 2020/3/30.
//

#import "BDPAppContainerController.h"
#import "BDPAppController.h"
#import "BDPAppPageController.h"
#import <OPFoundation/BDPCommonManager.h>
#import "BDPContainerModule.h"
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPRouteMediator.h>
#import "BDPTaskManager.h"
#import <OPFoundation/UIColor+BDPExtension.h>
#import <LarkOPInterface/LarkOPInterface-Swift.h>
#import <UIKit/UIKit.h>
#import "BDPTaskManager.h"
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPFoundation/BDPMonitorEvent.h>

@implementation BDPContainerModule

- (BOOL)setNavigationBarTitle:(NSString * _Nonnull)title context:(BDPPluginContext)context {
    if (context.engine.uniqueID.appType == BDPTypeWebApp) {
        // 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 评审要求，去除导致KA问题「最大之错误」的API在网页调用，没有修改任何其他逻辑
        return NO;
    }
    if ([context.engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:((id<BDPJSBridgeEngineProtocol>)context.engine).uniqueID];
        BDPAppContainerController *container = (BDPAppContainerController *)task.containerVC;
        BDPAppPageController *pageVC = container.appController.currentAppPage;
        //2019-3-25 侧滑返回停留到中途的时候触发设置title(假设bVC->aVC中途,bVC已经被从导航栈中移除,topPage为aVC)需要找到正确的bVC.
        if (pageVC.transitionCoordinator.isInteractive) {
            UIViewController *fromVC = [pageVC.transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
            if ([fromVC isKindOfClass:[BDPAppPageController class]]) {
                pageVC = (BDPAppPageController *)fromVC;
            }
        }
        if (!pageVC) {
            return NO;
        }
        [pageVC setCustomNavigationBarTitle:title];
        //这里也同步一份titleText到originWindow里
        pageVC.pageConfig.originWindow.navigationBarTitleText = title;
        BDPNavigationController *subNavi = (BDPNavigationController *)pageVC.navigationController;
        if ([subNavi isKindOfClass:[BDPNavigationController class]]) {
            [subNavi setNavigationItemTitle:title viewController:pageVC];
        } else {
            pageVC.navigationItem.title = title;
        }
        return YES;
    }
    return NO;
}

- (BOOL)setNavigationBarColorWithFrontColor:(NSString * _Nonnull)frontColor
                            backgroundColor:(NSString * _Nonnull)backgroundColor
                                    context:(BDPPluginContext)context {
    if (context.engine.uniqueID.appType == BDPTypeWebApp) {
        // 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 评审要求，去除导致KA问题「最大之错误」的API在网页调用，没有修改任何其他逻辑
        return NO;
    }
    if ([context.engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        BDPAppPageController *appVC = [BDPAppController currentAppPageController:context.controller fixForPopover:false];;
        if (![appVC isKindOfClass:[BDPAppPageController class]]) {
            BDPLogError(@"current appVC(%@) is not %@, setNavigationBarColor failed",
                        NSStringFromClass([appVC class]), NSStringFromClass([BDPAppPageController class]))
            return NO;
        }
        //  导航栏背景颜色
        [appVC.pageConfig.window setNavigationBarBackgroundColorByAPI:backgroundColor];
        //  标题颜色 item颜色 toolbar颜色 状态栏颜色
        [appVC.pageConfig.window setNavigationBarTextStyleByAPI:([frontColor isEqualToString:@"#ffffff"]?@"white":@"black")];
        [appVC updateViewControllerStyle:NO];
        [appVC updateStatusBarStyle:NO];
        [appVC setNeedsStatusBarAppearanceUpdate];
        return YES;
    }
    BDPLogError(@"the type of engine is illegal, setNavigationBarColor failed")
    return NO;
}

- (CGSize)containerSizeWithContext:(BDPPluginContext)context {
    //  这里是之前迁移API的时候把之前同事在handler强行ifelse的地方迁移了过来，维持了原有逻辑，但是逻辑不好，需要APIowner进行review重构
    if (context.engine.uniqueID.appType == BDPTypeWebApp) {
        return [BDPResponderHelper windowSize:context.controller.view.window];
    }
    if ([context.engine conformsToProtocol:@protocol(BDPJSBridgeEngineProtocol)]) {
        return [self containerSize:context.controller type:context.engine.uniqueID.appType uniqueID:((BDPJSBridgeEngine)context.engine).uniqueID];
    }
    return CGSizeZero;
}

- (CGSize)containerSize:(nullable UIViewController *)vc type:(BDPType)type uniqueID:(BDPUniqueID *)uniqueID {
    CGFloat height = 0.f;
    CGFloat width = 0.f;
    BDPAppPageController *appPageVC = [BDPAppController currentAppPageController:vc fixForPopover:false];
    //  这里是之前迁移API的时候把之前同事在handler强行ifelse的地方迁移了过来，维持了原有逻辑，但是逻辑不好，需要APIowner进行review重构
    if (type == BDPTypeNativeApp) {
        // 如果获取的太早， 是没有currentAppPageController的，所以当没有的时候返回vc自己的height。
        height = appPageVC.view.frame.size.height ?: vc.view.frame.size.height;
        width = appPageVC.view.frame.size.width ?: vc.view.frame.size.width;
    } else { ///预加载JSC时,type=0,这里返回一个兜底值
        height = [UIScreen mainScreen].bounds.size.height;
        width = [UIScreen mainScreen].bounds.size.width;
    }
    //  这里是之前迁移API的时候把之前同事在handler强行ifelse的地方迁移了过来，维持了原有逻辑，但是逻辑不好，需要APIowner进行review重构
    /// fix: [SUITE-50142]解决OKR页面顶部按钮被状态栏遮挡的问题，等小程序修改后再返回全屏高度
    BOOL fix = BDPRouteMediator.sharedManager.getSystemInfoHeightInWhiteListForUniqueID(uniqueID);
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat safeTop = 0;
    UIWindow *windowKey = uniqueID.window ?: OPWindowHelper.fincMainSceneWindow;
    safeTop = windowKey.safeAreaInsets.top;
    // 如果安全区域为0 则设置安全区域顶部高为电池状态栏的高度
    if (safeTop == 0) {
        safeTop = statusBarHeight;
    }
    // 判断使用自定义导航栏时，才减去状态栏高度
    if (appPageVC && !(!appPageVC.navigationController.navigationBarHidden && !appPageVC.navigationController.navigationBar.translucent)) {
        if (!fix) {
            height -= safeTop;
        }

        BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
        BDPMonitorWithName(kEventName_mp_custom_navigation_bar, common.uniqueID).kv(@"app_name", common.model.name).flush();
    }
    return CGSizeMake(width, height);
}


- (BOOL)isVCInForgoundContext:(BDPPluginContext)context {
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return NO;
    }
    if (context.engine.uniqueID.appType == BDPTypeWebApp) {
        return YES;
    }
    BDPJSBridgeEngine engine = (BDPJSBridgeEngine)context.engine;
    if (!engine) {
        return NO;
    }
    BDPCommon *common = BDPCommonFromUniqueID(engine.uniqueID);
    if (common.isActive == NO) {
        return NO;
    }

    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:engine.uniqueID];
    UIViewController *containerVC = task.containerVC;
    if (!containerVC) {
        return NO;
    }
    if (![containerVC isKindOfClass:[BDPBaseContainerController class]]) {
        return NO;
    }
    if ([containerVC.navigationController isBeingDismissed] || [containerVC.navigationController isMovingFromParentViewController] || [containerVC isBeingDismissed] || [containerVC isMovingFromParentViewController]) {
        return NO;
    }
    if (containerVC.navigationController == nil && containerVC.parentViewController == nil && containerVC.presentingViewController == nil) {
        return NO;
    }

    return YES;
}

- (BOOL)isVCActiveContext:(BDPPluginContext)context {
    if (context.engine.uniqueID.appType == BDPTypeWebApp) {
        // 小程序处于后台时，不通知截屏事件
        return YES;
    } else {
        BDPJSBridgeEngine gadgetEngine = (BDPJSBridgeEngine)context.engine;
        if (gadgetEngine && BDPCommonFromUniqueID(gadgetEngine.uniqueID).isActive) {
            return YES;
        }
    }
    return NO;
}

@end
