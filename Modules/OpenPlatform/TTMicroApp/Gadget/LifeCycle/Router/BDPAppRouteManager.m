//
//  BDPAppRouteManager.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/26.
//

#import "BDPAppRouteManager.h"
#import "BDPTask.h"
#import <OPFoundation/BDPUtils.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import <OPFoundation/BDPUniqueID.h>
#import "BDPAppPageURL.h"
#import "BDPTaskManager.h"
#import <OPFoundation/BDPNotification.h>
#import "BDPAppController.h"
#import <OPFoundation/BDPCommonManager.h>
#import "BDPWebViewComponent.h"
#import "BDPAppPageController.h"
#import "BDPTabBarPageController.h"
#import "BDPNavigationController.h"
#import "BDPDeprecateUtils.h"
#import <OPFoundation/EEFeatureGating.h>
#import "BDPSubPackageManager.h"
#import "BDPPackageStreamingFileHandle.h"
#import <OPPluginManagerAdapter/BDPJSBridgeCenter.h>

#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/BDPI18n.h>

#import <TTMicroApp/TTMicroApp-Swift.h>
#import <TTMicroApp/OPAPIDefine.h>

#import <OPSDK/OPSDK-Swift.h>


@interface BDPAppRouteManager () <UITabBarControllerDelegate, BDPNavigationControllerRouteProtocol, BDPNavigationControllerBarProtocol>

@property (nonatomic, strong) BDPUniqueID *uniqueID;
//@property (nonatomic, weak) BDPNavigationController *subNavi;
@property (nonatomic, weak) BDPAppController *appController;

@property (nonatomic, weak, nullable) OPContainerContext *containerContext;

@end

@implementation BDPAppRouteManager

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithAppController:(BDPAppController *)appController
                     containerContext:(OPContainerContext *)containerContext
{
    self = [super init];
    if (self) {
        self.containerContext = containerContext;
        _appController = appController;
        _uniqueID = appController.uniqueID;

        [self setupPlugins];
        [self setupDelegate];
    }
    return self;
}

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
+ (void)postDocumentReadyNotifWithUniqueId:(BDPUniqueID *)uniqueId appPageId:(NSInteger)appPageId {
    if (!uniqueId) {
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDPAppDocumentReadyNotification
                                                        object:nil
                                                      userInfo:@{
                                                                 kBDPAppPageIDUserInfoKey: @(appPageId),
                                                                 kBDPUniqueIDUserInfoKey: uniqueId
                                                                 }];
}

#pragma mark - Route Plugin
/*------------------------------------------*/
//         Route Plugin - 路由插件支持
/*------------------------------------------*/
- (void)setupPlugins
{
    WeakSelf;
    
    // navigateTo
    __weak BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    [BDPJSBridgeCenter registerContextMethod:@"navigateTo" isSynchronize:NO isOnMainThread:YES engine:task.context type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        [self navigateTo:params callback:callback];
    }];
    
    // navigateBack
    [BDPJSBridgeCenter registerContextMethod:@"navigateBack" isSynchronize:NO isOnMainThread:YES engine:task.context type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        [self navigateBack:params callback:callback];
    }];
    
    // reLaunch
    [BDPJSBridgeCenter registerContextMethod:@"reLaunch" isSynchronize:NO isOnMainThread:YES engine:task.context type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        [self reLaunch:params callback:callback];
    }];
    
    // redirectTo
    [BDPJSBridgeCenter registerContextMethod:@"redirectTo" isSynchronize:NO isOnMainThread:YES engine:task.context type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        [self redirectTo:params callback:callback];
    }];
    
    // switchTab
    [BDPJSBridgeCenter registerContextMethod:@"switchTab" isSynchronize:NO isOnMainThread:YES engine:task.context type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        [self switchTab:params callback:callback];
    }];
}

- (void)navigateTo:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
        OP_API_RESPONSE(OPAPIResponse)
        
        NSString *url = [params bdp_stringValueForKey:@"url"];
        BDPAppPageURL *page = [[BDPAppPageURL alloc] initWithURLString:url];
        
        OP_INVOKE_GUARD_NEW([task.config isTabPage:page.path], [response callbackWithErrno:1400001 errString:@"Only support redirection to non-Tab pages" legacyErrorCode:NavigateToAPICodeNavigateTabPage], @"只能跳到非Tab页面");
        OP_INVOKE_GUARD_NEW(![task.config containsPage:page.path], [response callbackWithErrno:1400002 errString:@"Page does not exist" legacyErrorCode:NavigateToAPICodePageNotExist], BDPI18n.jump_page_not_exist);
        OP_INVOKE_GUARD_NEW([self.appController.currentAppPage.navigationController.viewControllers count] >= 10, [response callbackWithErrno:1400003 errString:@"Page redirections exceed the limit" legacyErrorCode:NavigateToAPICodeOverPageCountLimit], @"页面跳转超过10个");
        
        WeakSelf;
        BDPExecuteOnMainQueue(^{
            StrongSelfIfNilReturn;
            BDPAppPageController *controller = [[BDPAppPageController alloc] initWithUniqueID:self.uniqueID page:page containerContext:self.containerContext];
            controller.hidesBottomBarWhenPushed = YES;
            ((BDPNavigationController *)self.appController.currentAppPage.navigationController).navigationRouteDelegate = self;
            ((BDPNavigationController *)self.appController.currentAppPage.navigationController).navigationBarDelegate = self;
            [self.appController.currentAppPage.navigationController pushViewController:controller animated:YES];
            [self updateTaskCurrentPage:page];
        });
        [response callback:OPGeneralAPICodeOk];
}

- (void)navigateBack:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback {
        OP_API_RESPONSE(OPAPIResponse)
        
        UINavigationController *navi = self.appController.currentAppPage.navigationController;

        NSInteger delta = MAX(0, [params integerValueForKey:@"delta" defaultValue:1]);
        NSInteger count = navi.viewControllers.count;
        NSInteger index = delta < count ? count - 1 - delta : 0;
        [navi popToViewController:navi.viewControllers[index] animated:YES];
        [self updateCurrentVC:navi.viewControllers[index]];
        [response callback:OPGeneralAPICodeOk];
}

- (void)reLaunch:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback {
        OP_API_RESPONSE(OPAPIResponse)
        
        NSString *url = [params bdp_stringValueForKey:@"url"];
        OP_INVOKE_GUARD_NEW(BDPIsEmptyString(url), [response callbackWithErrno:104 errString:@"Parameter error. url cannot be empty" legacyErrorCode:OPGeneralAPICodeParam], @"url不能为空");
        [self reLaunch:url];
        [response callback:OPGeneralAPICodeOk];
}

- (void)redirectTo:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
        OP_API_RESPONSE(OPAPIResponse)
        
        NSString *url = [params bdp_stringValueForKey:@"url"];
        BDPAppPageURL *page = [[BDPAppPageURL alloc] initWithURLString:url];
        OP_INVOKE_GUARD_NEW([task.config isTabPage:page.path], [response callbackWithErrno:1400001 errString:@"Only support redirection to non-Tab pages" legacyErrorCode:RedirectToAPICodeRedirectTabPage], @"只能跳到非Tab页面");
        
        WeakSelf;
        BDPExecuteOnMainQueue(^{
            StrongSelfIfNilReturn;
            BDPAppPageController *dest = [[BDPAppPageController alloc] initWithUniqueID:self.uniqueID page:page containerContext:self.containerContext];
            UINavigationController *navi = self.appController.currentAppPage.navigationController;
            NSMutableArray *currentVCs = [navi.viewControllers mutableCopy];
            dest.hidesBottomBarWhenPushed = ((UIViewController *)[currentVCs lastObject]).hidesBottomBarWhenPushed;
            [currentVCs removeLastObject];
            [currentVCs addObject:dest];
            [navi setViewControllers:[currentVCs copy]];
            [self updateCurrentVC:dest];
            [dest onAppRoute:@"redirectTo"];
            if (currentVCs.count == 1 && !OPSDKFeatureGating.disableShowGoHomeRedirectTo) {
                [self showGoHomeButtonIfNeed];
            }
        });
        [response callback:OPGeneralAPICodeOk];
}

- (void)switchTab:(nullable NSDictionary *)params callback:(BDPJSBridgeCallback)callback {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
        OP_API_RESPONSE(OPAPIResponse)
        
        NSString *url = [params bdp_stringValueForKey:@"url"];
        BDPAppPageURL *page = [[BDPAppPageURL alloc] initWithURLString:url];
        
        OP_INVOKE_GUARD_NEW(![task.config isTabPage:page.path], [response callbackWithErrno:1400004 errString:@"Only support redirection to Tab pages" legacyErrorCode:SwitchTabAPICodeSwitchNonTab], BDPI18n.target_page_not_tab);
        NSInteger index = [task.config tabBarIndexOfPath:page.path];
        OP_INVOKE_GUARD_NEW(index == NSNotFound, [response callbackWithErrno:102 errString:@"Internal error" legacyErrorCode:SwitchTabAPICodePageNotExist], BDPI18n.target_page_index_no_exsit);
        
        WeakSelf;
        BDPExecuteOnMainQueue(^{
            StrongSelfIfNilReturn;
            // 如果最底层VC是TabVC，直接展示TabVC并切换至指定Tab页的Index
            [self updateTaskCurrentPage:page];
            UIViewController *content = self.appController.contentVC;
            if ([content isKindOfClass:[BDPTabBarPageController class]]) {
                BDPNavigationController *selectedNavi = (BDPNavigationController *)(((UITabBarController *)content).selectedViewController);
                [selectedNavi popToRootViewControllerAnimated:NO];
                ((BDPTabBarPageController *)content).selectedIndex = index;
                
                // 这个是一个track的修改方法，因为tabbar的UITransitionView的height莫名其妙的被修改了，
                // 暂时先这么解决，后期需要找到真正修改UITransitionView的height的地方。
                UIView *view = [[((BDPTabBarPageController *)content).view subviews] objectAtIndex:0];
                view.bdp_size = view.superview.bdp_size;
            } else {   // 没有Tab页面，重新创建TabVC
                BDPTabBarPageController *controller = [[BDPTabBarPageController alloc] initWithUniqueID:self.uniqueID page:page delegate:self containerContext:self.containerContext];
                [self.appController updateContentVC:controller];
            }
            
            [self.appController.currentAppPage onAppRoute:@"switchTab"];
        });
        
        [response callback:OPGeneralAPICodeOk];
}

- (void)setupDelegate
{
    if ([self.appController.contentVC isKindOfClass:[UITabBarController class]]) {
        ((UITabBarController *)self.appController.contentVC).delegate = self;
    }
}

- (UIViewController *)resetPageToURL:(NSString *)url
{
    BDPAppPageURL *page = [[BDPAppPageURL alloc] initWithURLString:url];
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    
    // currentPage在[BDPAppPageController viewDidLoad]前不会被设置，导致reLaunch时currentPage为空，需提前赋值
    [self updateTaskCurrentPage:page];
    
    // BDPTabBarPageController
    if ([task.config isTabPage:page.path]) {
        BDPTabBarPageController *tabBarVC = [[BDPTabBarPageController alloc] initWithUniqueID:self.uniqueID
                                                                                         page:page
                                                                                     delegate:self
                                                                             containerContext:self.containerContext];
        [self.appController updateContentVC:tabBarVC];
        return tabBarVC;
    } else { // BDPAppPageController
        BDPAppPageController *controller = [[BDPAppPageController alloc] initWithUniqueID:self.uniqueID
                                                                                     page:page
                                                                         containerContext:self.containerContext];
        BDPNavigationController *navi = [[BDPNavigationController alloc] initWithRootViewController:controller
                                                                                barBackgroundHidden:YES containerContext:self.containerContext];
        [navi useCustomAnimation];
        [self.appController updateContentVC:navi];
        return controller;
    }
    return nil;
}

- (UIViewController *)reLaunch:(NSString *)url
{
    UIViewController *controller = [self resetPageToURL:url];
    [[self fixed_currentPageController:controller] onAppRoute:@"reLaunch"];
    // reLaunch之后，JS和客户端均仅保留当前页面
    // 此时需要检查是否展示"返回首页"，这是跳出reLaunch页面的唯一出口
    [self showGoHomeButtonIfNeed];
    
    return controller;
}

- (UIViewController *)goHome
{
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    UIViewController *controller = [self resetPageToURL:task.config.entryPagePath];
    [[self fixed_currentPageController:controller] onAppRoute:@"reLaunch"];
    return controller;
}

- (void)showGoHomeButtonIfNeed
{
    // 返回首页状态检测(与首页不同时展示"返回首页")
    // 经与PM确认，判断返回首页仅判断path不判断query
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    NSString *entryPagePath = task.config.entryPagePath;
    NSString *currentPagePath = task.currentPage.path;
    task.showGoHomeButton = (entryPagePath && currentPagePath && ![entryPagePath isEqualToString:currentPagePath]);
}

#pragma mark - UITabBarControllerDelegate
/*------------------------------------------*/
//  UITabBarControllerDelegate - TabVC代理
/*------------------------------------------*/
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    if (viewController == tabBarController.selectedViewController) {
        return YES;
    }
    BDPAppPageController *topVC = [BDPAppController currentAppPageController:viewController fixForPopover:false];
    [self updateTaskCurrentPage:topVC.page];
    [topVC onAppRoute:@"switchTab"];
    return YES;
}

#pragma mark - BDPNavigationControllerProtocol
/*------------------------------------------*/
// BDPNavigationControllerProtocol - Nav代理
/*------------------------------------------*/
- (void)navigation:(BDPNavigationController *)navigation didPushViewController:(UIViewController *)vc
{
    [self updateCurrentVC:vc];
    [[self fixed_currentPageController:vc] onAppRoute:@"navigateTo"];
}

- (void)navigation:(BDPNavigationController *)navigation didPopViewController:(NSArray<UIViewController *> *)vcs willShowViewController:(UIViewController *)vc
{
    [self updateCurrentVC:vc];
    [[self fixed_currentPageController:vc] onAppRoute:@"navigateBack"];
}

- (void)navigationBackBarClicked:(BDPNavigationController *)navigation
{
    // 如果有WebView组件，优先返回WebView组件的上一级
    BDPAppPageController *appVC = self.appController.currentAppPage;
    if (appVC) {
        for (UIView *view in appVC.appPage.subviews) {
            if ([view isKindOfClass:[BDPWebViewComponent class]] && [(BDPWebViewComponent *)view canGoBack]) {
                [(BDPWebViewComponent *)view goBack];
                return;
            }
        }
    }
    
    // AppController页面返回
    [appVC.navigationController popViewControllerAnimated:YES];
    
    UIViewController *topVC = appVC.navigationController.topViewController;
    [self updateCurrentVC:topVC];
}

#pragma mark - Common
/*------------------------------------------*/
//            Common - 通用公共方法
/*------------------------------------------*/
- (void)updateCurrentVC:(UIViewController *)vc
{
    if ([vc isKindOfClass:[BDPAppPageController class]]) {
        BDPAppPageController *appPage = (BDPAppPageController *)vc;
        [self updateTaskCurrentPage:appPage.page];
    }
}

- (void)updateTaskCurrentPage:(BDPAppPageURL *)page
{
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    task.currentPage = page;
}

#pragma mark - helper

/// 用于解决iPad的上路由时找不到AppPageVC，增加兜底查询
/// - Parameters:
///   - vc: 用于寻找
///   - iPadOnly: 作用范围是否仅iPad
- (nullable BDPAppPageController *)fixed_currentPageController:(UIViewController *)vc{
    BDPAppPageController *topAppPageVC = [BDPAppController currentAppPageController:vc fixForPopover:true];
    if(topAppPageVC) {
        return topAppPageVC;
    } else {
        if([BDPDeviceHelper isPadDevice]) {
            return [self.appController currentAppPage];
        }
    }
    return nil;
}

@end
