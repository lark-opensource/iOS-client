//
//  BDPAppContainerController.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/16.
//

#import "BDPAppContainerController.h"
#import "BDPAppController.h"
#import "BDPAppPageController.h"
#import "BDPAppPageURL.h"
#import "BDPAppRouteManager.h"
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPI18n.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPModel.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPMorePanelItem+Private.h>
#import <OPFoundation/BDPMorePanelItem.h>
#import "BDPNavigationController.h"
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import "BDPShareManager.h"
#import "BDPSocketConnectionTip.h"
#import "BDPTask.h"
#import "BDPTaskManager.h"
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUtils.h>
#import "BDPWebViewComponent.h"
#import "BDPDeprecateUtils.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/TMACustomHelper.h>
#import <OPFoundation/UIImage+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPSDK/OPSDK-Swift.h>
#import "BDPGadgetLog.h"
#import <OPFoundation/BDPSandBoxHelper.h>

static const NSInteger kContainerItemBaseInsertedIndex = 0;

@interface BDPAppContainerController () <BDPAppPageProtocol, BDPJSRuntimeDelegate, UIPopoverPresentationControllerDelegate, BDPSocketConnectionTipDelegate>

@property (nonatomic, strong) BDPAppController *appController;
@property (nonatomic, assign) BOOL didRecordDOMReady;

@property (nonatomic, strong) BDPSocketConnectionTip *socketTip;
@property (nonatomic, assign) BOOL enableSlideExitOnHitDebugPoint;

@end

@implementation BDPAppContainerController

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (BDPType)type
{
    return BDPTypeNativeApp;
}

- (instancetype)initWithLaunchParam:(BDPTimorLaunchParam *)launchParam containerContext:(OPContainerContext *)containerContext
{
    if (self = [super initWithLaunchParam:launchParam containerContext:containerContext]) {
        _startPage = [[BDPAppPageURL alloc] initWithURLString:[self.schema startPage]];
        _enableSlideExitOnHitDebugPoint = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetEnableSlideExitOnHitDebugPoint];
    }
    BDPGadgetLogInfo(@"BDPAppContainerController init, for uniqueID: %@, self: %@", self.uniqueID, self);
    return self;
}

- (void)dealloc
{
    BDPGadgetLogInfo(@"BDPAppContainerController dealloc, for uniqueID: %@, self: %@", self.uniqueID, self);
}

#pragma mark - View & Layout
/*-----------------------------------------------*/
//          View & Layout - 加载及布局相关
/*-----------------------------------------------*/
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

#pragma mark - BDPBaseContainer OverRide
/*-----------------------------------------------*/
//     BDPBaseContainer OverRide - 父类方法重写
/*-----------------------------------------------*/
- (void)onAppEnterForeground
{
    [super onAppEnterForeground];
    
    [self.appController onAppEnterForeground];
    [BDPTracker beginEvent:BDPTEEnter primaryKey:BDPTrackerPKEnter attributes:@{@"launch_type":self.schema.launchType ?: @""} uniqueID:self.uniqueID];
}

- (void)onAppEnterBackground
{
    [super onAppEnterBackground];
    
    [self.appController onAppEnterBackground];
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    NSMutableDictionary *param = [[NSMutableDictionary alloc] initWithCapacity:1];
    [param setValue:BDPSafeString(task.currentPage.path) forKey:@"page_path"];
    [param setValue:BDPSafeString(self.exitType) forKey:@"exit_type"];
    [param setValue:BDPSafeString(self.schema.launchType) forKey:@"launch_type"];
    if (self.schema.originEntrance.length) {
        NSDictionary *entranceInfo = [self.schema.originEntrance JSONValue];
        [param setValue:BDPSafeString([entranceInfo bdp_stringValueForKey:@"oe_launch_from"]) forKey:@"oe_launch_from"];
        [param setValue:BDPSafeString([entranceInfo bdp_stringValueForKey:@"oe_location"]) forKey:@"oe_location"];
    }
    [BDPTracker endEvent:BDPTEExit primaryKey:BDPTrackerPKEnter attributes:[param copy] uniqueID:self.uniqueID];
}

- (void)forceStopRunning {
    BDPGadgetLogInfo(@"forceStopRunning, id=%@", self.uniqueID);
    [self.appController forceStopRunning];
    [super forceStopRunning];
}

- (BOOL)checkDeviceAvailable
{
    if ([super checkDeviceAvailable] == NO) {
        return NO;
    }
    return ![BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSBlackListDeviceTma];
}

- (BOOL)checkEnvironmentAvailable
{
    [super checkEnvironmentAvailable];
    return YES;
}

- (void)setToolBarMoreButtonCustomMenu:(NSMutableArray<BDPMorePanelItem *> *)items
{
    [super setToolBarMoreButtonCustomMenu:items];

    WeakSelf;
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    BDPCommon *common = BDPCommonFromUniqueID(self.uniqueID);
    
    NSMutableArray<BDPMorePanelItem *> *containerItems = [NSMutableArray array];
    // “返回首页”
    if (task.showGoHomeButton) {
        BDPMorePanelItem *item = [BDPMorePanelItem itemWithType:BDPMorePanelItemTypeHome name:BDPI18n.back_home icon:[UIImage bdp_imageNamed:@"icon_more_panel_back_home"] action:^(BDPMorePanelItem * _Nonnull item) {
            StrongSelfIfNilReturn;
            // H5 返回首页 - 发送 Subscribe 消息
            if (!BDPIsEmptyString(common.model.webURL)) {
            } else {
                // 非 H5 返回首页 - 正常处理
                [self.appController.routeManager goHome];
            }
            
            [BDPTracker event:@"mp_home_btn_click" attributes:nil uniqueID:self.uniqueID];
            task.showGoHomeButton = NO;
        }];
        item.priority = BDPMorePanelItemPriorityRequire;
        [containerItems addObject:item];
    }
    
    // “分享”
    BOOL hideShareMenu = NO;
    BDPPageConfig *pageConfig = nil;
    if (task.currentPage.path && (pageConfig = [task.config getPageConfigByPath:task.currentPage.path])) {
        hideShareMenu = pageConfig.isHideShareMenu;
    }
    
    BDPPlugin(sharePlugin, BDPSharePluginDelegate);
    if (sharePlugin && hideShareMenu == NO) {
        // Get Page & Engine
        NSString *path = @"";
        WKWebView *page = nil;
        BDPJSBridgeEngine engine = task.context;
        page = [task.pageManager appPageWithPath:task.currentPage.path];
        path = [task.pageManager appPageWithPath:task.currentPage.path].bap_path;
        
        // Get Path & WebViewURL
        NSString *webViewUrlStr = @"";
        for (UIView *view in page.subviews) {
            if ([view isKindOfClass:[BDPWebViewComponent class]] && !view.hidden) {
                webViewUrlStr = [(BDPWebViewComponent *)view bwc_openInOuterBrowserURL].absoluteString;
                break;
            }
        }
        
        // Generate
        NSMutableDictionary *fireParams = [NSMutableDictionary dictionary];
        [fireParams setValue:BDPSafeString(path) forKey:@"path"];
        [fireParams setValue:BDPSafeString(webViewUrlStr) forKey:@"webViewUrl"];
        [BDPShareManager sharedManager].engine = engine;
        [BDPShareManager sharedManager].shareChannelParams = fireParams;

        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
        BOOL hideShareMenu = (common.model.shareLevel == BDPAppShareLevelBlack);
        if (!hideShareMenu) {
            // “分享”
            BDPMorePanelItem *item = [BDPMorePanelItem itemWithType:BDPMorePanelItemTypeShare name:BDPI18n.share icon:[UIImage bdp_imageNamed:@"icon_more_panel_share"] action:^(BDPMorePanelItem * _Nonnull item) {
                StrongSelfIfNilReturn;
                [[BDPShareManager sharedManager] setShareEntry:BDPShareEntryTypeToolBar];
                [[BDPShareManager sharedManager].engine bdp_fireEvent:@"onShareAppMessage" sourceID:NSNotFound data:fireParams];
            }];
            [containerItems addObject:item];
        }
    }
    
    NSInteger insertedIndex = MIN(items.count, kContainerItemBaseInsertedIndex);
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(insertedIndex, containerItems.count)];
    [items insertObjects:containerItems atIndexes:indexSet];
}

- (UIViewController<BDPWarmBootCleanerProtocol> *)childRootViewController
{
    [super childRootViewController];
    
    // 如果有startPage时使用，没有则使用配置文件中的首页
    // startPage在[self setupTaskDone]时已经检测完成，无效则变成首页
    
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    BDPAppPageURL *page = self.startPage ?: [[BDPAppPageURL alloc] initWithURLString:task.config.entryPagePath];
    if (self.launchParam.vdom) {
        // 如果有vdom的情况
        self.appController = [[BDPAppController alloc] initWithUniqueID:self.uniqueID
                                                                   page:page
                                                                   vdom:self.launchParam.vdom
                                                       containerContext:self.containerContext];
    } else {
        self.appController = [[BDPAppController alloc] initWithUniqueID:self.uniqueID
                                                                   page:page
                                                       containerContext:self.containerContext];
    }
    return self.appController;
}

- (void)excuteColdBootDone
{
    [super excuteColdBootDone];
    if (self.launchParam.vdom) {
        // 如果是有vdom的情况，需要加载App content;
        [self.appController loadAppContent];
    }
}

#pragma mark - BDPJSContextInjectProtocol
/*-----------------------------------------------*/
//  BDPJSContextInjectProtocol - JSContext注入协议
/*-----------------------------------------------*/
- (void)jsRuntimePublishMessage:(NSString *)event param:(NSDictionary *)param appPageIDs:(NSArray<NSNumber *> *)appPageIDs
{
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    NSArray<BDPAppPage *> *appPages = [task.pageManager appPagesWithIDs:appPageIDs];
    // 在AppPage注册前就调用JSC的方法, 比如onAppRoute或者RedictTo等, 可能导致丢消息
    if (![appPageIDs.firstObject isKindOfClass:[NSNull class]] && appPageIDs.count > 0 && appPages.count == 0) {
        // 此处简单处理延时0.5s执行
        BDPGadgetLogWarn(@"can find apppage to handle publish msg!")
        WeakSelf;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            NSArray<BDPAppPage *> *appPages = [BDPTaskFromUniqueID(self.uniqueID).pageManager appPagesWithIDs:appPageIDs];
            for (BDPAppPage *appPage in appPages) {
                [appPage bdp_fireEvent:event sourceID:appPage.appPageID data:param];
            }
        });
    } else {
        for (BDPAppPage *appPage in appPages) {
            [appPage bdp_fireEvent:event sourceID:appPage.appPageID data:param];
        }
    }
}

- (UIViewController *)jsRuntimeController
{
    return self.subNavi.topViewController;
}

- (void)jsRuntimeOnDocumentReady
{
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    BDPAppPage *appPage = [task.pageManager appPageWithPath:task.currentPage.path];
    [BDPAppRouteManager postDocumentReadyNotifWithUniqueId:self.uniqueID appPageId:appPage.appPageID];
    BDPGadgetLogInfo(@"JSRuntime ready: %@", @(appPage.appPageID));
}

// 建立真机调试连接，展示“已连接”
- (void)onSocketDebugConnected
{
    if (self.socketTip) {
        self.socketTip.hidden = NO;
    } else {
        self.socketTip = [BDPSocketConnectionTip new];
        [self.view addSubview:self.socketTip];
        self.socketTip.translatesAutoresizingMaskIntoConstraints = NO;
        [self.socketTip.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
        [self.socketTip.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
        [self.socketTip.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [self.socketTip.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
        [self.socketTip setSocketDebugType:BDPSocketDebugTypeRealDevice];
        self.socketTip.delegate = self;
        [self.socketTip setStatus:BDPSocketDebugTipStatusConnected];
    }
}

// 真机调试连接断开，弹窗提示退出
- (void)onSocketDebugDisconnected
{
    [self realDeviceDebugMaskVisibleChangedTo:NO];//意外断开的情况下，可能还在断点命中状态，除了隐藏提示，还需要调用此方法使能侧滑
    self.socketTip.hidden = YES;
    BDPPlugin(alertPlugin, BDPAlertPluginDelegate);
    if ([alertPlugin respondsToSelector:@selector(bdp_showAlertWithTitle:content:confirm:fromController:confirmCallback:showCancel:)]) {
        WeakSelf;
        NSString *content = BDPI18n.OpenPlatform_RealdeviceDebug_exitinfo;
                NSString *appName = BDPSandBoxHelper.appDisplayName;
                content = [content stringByReplacingOccurrencesOfString:@"{{APP_DISPLAY_NAME}}" withString:appName];
        [alertPlugin bdp_showAlertWithTitle:BDPI18n.OpenPlatform_RealdeviceDebug_endinfo content:content confirm:BDPI18n.determine fromController:self.appController confirmCallback:^{
            StrongSelfIfNilReturn;
            [self forceClose:GDMonitorCode.debug_exit];
        } showCancel:NO];
    } else {
        [self forceClose:GDMonitorCode.debug_exit];
    }
}

// 真机调试连接失败，弹窗提示退出
- (void)onSocketDebugConnectFailed
{
    [self realDeviceDebugMaskVisibleChangedTo:NO];// 意外断开的情况下，可能还在断点命中状态，除了隐藏提示，还需要调用此方法使能侧滑
    self.socketTip.hidden = YES;
    BDPPlugin(alertPlugin, BDPAlertPluginDelegate);
    if ([alertPlugin respondsToSelector:@selector(bdp_showAlertWithTitle:content:confirm:fromController:confirmCallback:showCancel:)]) {
        WeakSelf;
        NSString *content = BDPI18n.OpenPlatform_RealdeviceDebug_wificonfirm;
        NSString *appName = BDPSandBoxHelper.appDisplayName;
        content = [content stringByReplacingOccurrencesOfString:@"{{APP_DISPLAY_NAME}}" withString:appName];
        [alertPlugin bdp_showAlertWithTitle:BDPI18n.OpenPlatform_RealdeviceDebug_hints content:content confirm:BDPI18n.determine fromController:self.appController confirmCallback:^{
            StrongSelfIfNilReturn;
            [self forceClose:GDMonitorCode.debug_exit];
        } showCancel:NO];
    } else {
        [self forceClose:GDMonitorCode.debug_exit];
    }
}


// 命中断点
- (void)onSocketDebugPauseInspector
{
    [self.socketTip setStatus:BDPSocketDebugTipStatusHitDebugPoint];
}

// 断点继续, 回到已连接状态
- (void)onSocketDebugResumeInspector
{
    [self.socketTip setStatus:BDPSocketDebugTipStatusConnected];
}

#pragma mark - BDPPerformanceProfileProtocol

-(void)onSocketPerformanceConnected{
    [self onSocketDebugConnected];
    [self.socketTip setSocketDebugType:BDPSocketDebugTypePerformanceProfile];
}

-(void)onSocketPerformanceDisconnected{
    [self realDeviceDebugMaskVisibleChangedTo:NO];//意外断开的情况下，可能还在断点命中状态，除了隐藏提示，还需要调用此方法使能侧滑
    self.socketTip.hidden = YES;
    BDPPlugin(alertPlugin, BDPAlertPluginDelegate);
    if ([alertPlugin respondsToSelector:@selector(bdp_showAlertWithTitle:content:confirm:fromController:confirmCallback:showCancel:)]) {
        WeakSelf;
        NSString *appName = BDPSandBoxHelper.appDisplayName;
        NSString *description = BDPI18n.OpenPlatform_GadgetAnalytics_RecExitedDesc;

        [alertPlugin bdp_showAlertWithTitle:BDPI18n.OpenPlatform_GadgetAnalytics_RecExitedTtl content:description confirm:BDPI18n.determine fromController:self.appController confirmCallback:^{
            StrongSelfIfNilReturn;
            [self forceClose:GDMonitorCode.debug_exit];
        } showCancel:NO];
    } else {
        [self forceClose:GDMonitorCode.debug_exit];
    }
}

-(void)onSocketPerformanceConnectFailed{
    [self realDeviceDebugMaskVisibleChangedTo:NO];// 意外断开的情况下，可能还在断点命中状态，除了隐藏提示，还需要调用此方法使能侧滑
    self.socketTip.hidden = YES;
    BDPPlugin(alertPlugin, BDPAlertPluginDelegate);
    if ([alertPlugin respondsToSelector:@selector(bdp_showAlertWithTitle:content:confirm:fromController:confirmCallback:showCancel:)]) {
        WeakSelf;
        NSString *content = BDPI18n.OpenPlatform_RealdeviceDebug_wificonfirm;
        NSString *appName = BDPSandBoxHelper.appDisplayName;
        content = [content stringByReplacingOccurrencesOfString:@"{{APP_DISPLAY_NAME}}" withString:appName];
        [alertPlugin bdp_showAlertWithTitle:BDPI18n.OpenPlatform_GadgetAnalytics_RecExitedTtl content:content confirm:BDPI18n.determine fromController:self.appController confirmCallback:^{
            StrongSelfIfNilReturn;
            [self forceClose:GDMonitorCode.debug_exit];
        } showCancel:NO];
    } else {
        [self forceClose:GDMonitorCode.debug_exit];
    }
}

#pragma mark - BDPAppPageProtocol
/*-----------------------------------------------*/
//      BDPAppPageProtocol - AppPage代理协议
/*-----------------------------------------------*/

- (void)appPagePublishMessage:(BDPAppPage *)appPage event:(NSString *)event param:(NSDictionary *)param
{
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    [task.context bdp_fireEvent:event sourceID:appPage.appPageID data:param];
}

- (BOOL)appPageShouldTrackPageFrameJSLoadTime {
    return !self.didRecordDOMReady;
}

- (void)handleReportTimelineDomReady {
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    if (!self.didRecordDOMReady && self.launchTime > 0) {
        self.didRecordDOMReady = YES;
        NSUInteger diff = (CFAbsoluteTimeGetCurrent() - self.launchTime) * 1000;
        [self firstFrameDidShow]; // 标记首帧渲染
        [BDPTracker event:@"mp_load_time_ttpkg2"
               attributes:@{@"duration": @(diff),
                            @"local_pkg": @(common.reader.createLoadStatus == BDPPkgFileLoadStatusDownloaded)}
     uniqueID:self.uniqueID];
    }
}

#pragma mark -
- (void)firstFrameDidShow {
    [super firstFrameDidShow];
    
    // 首个界面渲染完成后, 才去预加载下个界面的Webview..
    [BDPTaskFromUniqueID(self.uniqueID).pageManager setAutoCreateAppPageEnable:YES];
}

#pragma mark - BDPlatformContainerProtocol
/*------------------------------------------*/
//  BDPlatformContainerProtocol - 基础VC方法
/*------------------------------------------*/
- (UIView *)topView
{
    return self.appController.currentAppPage.appPage;
}

#pragma mark - BDPSocketConnectionTipDelegate
- (void) exitAndFinishDebug {
    [self realDeviceDebugMaskVisibleChangedTo:NO];// 任何情况下退出页面，为防止流程异常调用此方法，使能侧滑，防止影响飞书侧滑
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    id<OPMicroAppJSRuntimeProtocol> runtime = task.context;
    if([runtime respondsToSelector:@selector(isSocketDebug)] && [runtime respondsToSelector:@selector(finishDebug)] && runtime.isSocketDebug) {
        [runtime finishDebug];
    } else {
        BDPMonitorWithCode(RealmachineDebug.realmachine_client_finish_debug, self.uniqueID)
        .setResultTypeFail()
        .setErrorMessage(@"runtime not response to finishDebug")
        .flush();
    }
    [self forceClose:GDMonitorCode.debug_exit];
    BDPGadgetLogInfo(@"RealMachineDebug exitAndFinishDebug");
    BDPMonitorWithCode(RealmachineDebug.realmachine_client_finish_debug, self.uniqueID).flush();
}

-(void)exitAndFinishProfile{
    [self realDeviceDebugMaskVisibleChangedTo:NO];// 任何情况下退出页面，为防止流程异常调用此方法，使能侧滑，防止影响飞书侧滑
    [BDPPerformanceProfileManager.sharedInstance endConnection];
    [self forceClose:GDMonitorCode.debug_exit];
    BDPGadgetLogInfo(@"BDPPerformanceProfileManager exitAndFinishProfile");
}

- (void)finishDebugButtonPressedWithType:(BDPSocketDebugType)type{
    switch (type) {
        case BDPSocketDebugTypeRealDevice:
            [self finishDebugButtonPressedForRealDevice];
            break;
        case BDPSocketDebugTypePerformanceProfile:
            [self finishDebugButtonPressedForPerformanceProfile];
        default:
            break;
    }
}

-(void)finishDebugButtonPressedForRealDevice{
    BDPGadgetLogInfo(@"RealMachineDebug finishDebugButtonPressed");
    BDPPlugin(alertPlugin, BDPAlertPluginDelegate);
    if ([alertPlugin respondsToSelector:@selector(bdp_showAlertWithTitle:content:confirm:fromController:confirmCallback:showCancel:)]) {
        WeakSelf;
        [alertPlugin bdp_showAlertWithTitle:BDPI18n.OpenPlatform_RealdeviceDebug_hints content:BDPI18n.OpenPlatform_RealdeviceDebug_endconfirm confirm:BDPI18n.OpenPlatform_RealdeviceDebug_endsession fromController:self.appController confirmCallback:^{
            StrongSelfIfNilReturn
            [self exitAndFinishDebug];
        } showCancel:YES];
    } else {
        BDPGadgetLogWarn(@"RealMachineDebug finishDebugButtonPressed show Alert Failed!");
        [self exitAndFinishDebug];
    }
}

-(void)finishDebugButtonPressedForPerformanceProfile{
    BDPGadgetLogInfo(@"RealMachineDebug finishDebugButtonPressed PerformanceProfile");
    BDPPlugin(alertPlugin, BDPAlertPluginDelegate);
    if ([alertPlugin respondsToSelector:@selector(bdp_showAlertWithTitle:content:confirm:fromController:confirmCallback:showCancel:)]) {
        WeakSelf;
        [alertPlugin bdp_showAlertWithTitle:BDPI18n.OpenPlatform_RealdeviceDebug_hints content:BDPI18n.OpenPlatform_GadgetAnalytics_StopRecConfirmDesc confirm:BDPI18n.OpenPlatform_RealdeviceDebug_endsession fromController:self.appController confirmCallback:^{
            StrongSelfIfNilReturn
            [BDPPerformanceProfileManager.sharedInstance endProfileAfterFinishDebugButtonPressed];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self exitAndFinishProfile];
            });
        } showCancel:YES];
    } else {
        BDPGadgetLogWarn(@"RealMachineDebug finishDebugButtonPressed PerformanceProfile show Alert Failed!");
        [self exitAndFinishProfile];
    }
}

- (void)realDeviceDebugMaskVisibleChangedTo:(BOOL) visible {
    BOOL enableGesture = !visible; // 断点命中遮罩显示的情况下，禁止侧滑返回
    if (self.enableSlideExitOnHitDebugPoint) {
        // v4.2 发现飞书导航栏异常，使能后，侧滑依然无效，这里使用 FG 控制，打开的情况下，不禁止侧滑退出。
        UINavigationController *navi =  self.appController.navigationController;
            if ([navi isKindOfClass:[BDPNavigationController class]]) {
                navi.interactivePopGestureRecognizer.enabled = enableGesture;
                BDPGadgetLogInfo(@"update navigationController: %@,interactivePopGestureRecognizer.enabled %d",
                            [navi class], navi.interactivePopGestureRecognizer.enabled);
            }
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = enableGesture;
        BDPGadgetLogInfo(@"update navigationController: %@,interactivePopGestureRecognizer.enabled %d",
                    [self.navigationController class], self.navigationController.interactivePopGestureRecognizer.enabled);
    }
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}
@end
