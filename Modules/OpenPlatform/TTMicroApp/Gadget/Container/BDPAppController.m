//
//  BDPAppController.m
//  Timor
//
//  Created by 王浩宇 on 2019/1/26.
//

#import "BDPAppController.h"
#import "BDPAppLoadDefineHeader.h"
#import "BDPAppPageController.h"
#import "BDPAppPageURL.h"
#import "BDPAppRouteManager.h"
#import <OPFoundation/BDPApplicationManager.h>
#import "BDPAudioControlManager.h"
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPInterruptionManager.h"
#import <OPFoundation/BDPMonitorHelper.h>
#import "BDPNavigationController.h"
#import <OPFoundation/BDPResponderHelper.h>
#import "BDPShareManager.h"
#import "BDPTabBarPageController.h"
#import "BDPTaskManager.h"
#import "BDPTimorClient+Business.h"
#import "BDPTracker+BDPLoadService.h"
#import <OPFoundation/BDPTracker.h>
#import "BDPTrackerHelper.h"
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/NSError+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPAppController+ExitMonitorStrategy.h"
#import <OPFoundation/BDPBlankDetectConfig.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPSDK/OPSDK-Swift.h>
#import "BDPXScreenManager.h"
#import "BDPXScreenAppProviderTipView.h"
#import "BDPPerformanceProfileManager.h"
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPPkgFileBasicModel.h"
#import "BDPSubPackageManager.h"
#import <OPPluginManagerAdapter/BDPJSBridgeCenter.h>

@interface BDPAppController ()<BDPXScreenAppProviderTipViewDelegate>

@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, strong) BDPAppPageURL *startPage;
@property (nonatomic, weak) UIButton *anchorShareButton;
@property (nonatomic, copy) NSDictionary *vdom;

/// 未成功启动监测策略
@property (nonatomic, strong) StrategyService *exitMonitorStrategy;
/// 未启动成功监测状态
@property (nonatomic, assign) NSInteger blankCount;

@property (nonatomic, weak, nullable) OPContainerContext *containerContext;

@property (nonatomic, assign) BOOL hasFlushNavigationBarItemMonitor;

@property (nonatomic, strong) BDPXScreenAppProviderTipView *XScreenTipView;

@property (nonatomic, strong) UIColor *originViewBackgroundColor;

@end

@implementation BDPAppController

#pragma mark - Initilize
/*-----------------------------------------------*/
//              Initilize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
                            page:(BDPAppPageURL *)page
                containerContext:(OPContainerContext *)containerContext
{
    return [self initWithUniqueID:uniqueID page:page vdom:nil containerContext:containerContext];
}

- (instancetype)initWithUniqueID:(BDPUniqueID *)uniqueID
                            page:(BDPAppPageURL *)page
                            vdom:(NSDictionary *)vdom
                containerContext:(OPContainerContext *)containerContext
{
    self = [super init];
    if (self) {
        self.containerContext = containerContext;
        _uniqueID = uniqueID;
        _startPage = page;
        _isPaused = YES;
        _vdom = [vdom copy];
        
        [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID].currentPage = page;
        if (BDPIsEmptyDictionary(vdom)) {
            [self loadAppContent];
        }
        BDPLogInfo(@"BDPAppController init, id=%@", self.uniqueID);
        [OPObjectMonitorCenter setupMemoryMonitorWith:self];
        [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedRetain for:self];
    }
    return self;
}

#pragma mark - View & Layout
/*-----------------------------------------------*/
//          View & Layout - 加载及布局相关
/*-----------------------------------------------*/
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupAppView];
    // BDPAppController使用VC自带的SubNavi，因此将BDPAppController的外层导航栏隐藏
    [self.navigationController setNavigationBarHidden:YES];

    // 当侧滑退出小程序时, 会接收到该通知, 此时需要处理一下appPageVC的页面方向
    if ([OPSDKFeatureGating fixGadgetOrientationByPreviewsGadgetGestureExit]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGadgetContainerDidHideByGesture:) name:@"kGadgetContainerDidHideByGesture" object:nil];
    }
}

-(void)dealloc{
    BDPLogInfo(@"BDPAppController dealloc, id=%@", self.uniqueID);
    [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedDestroy for:self.currentAppPage];

    if ([OPSDKFeatureGating fixGadgetOrientationByPreviewsGadgetGestureExit]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kGadgetContainerDidHideByGesture" object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // ⚠️Native 小程序的 onAppEnterForeground 需要在 [viewWillAppear:] 里执行
    // 由于 onAppEnterForeground 事件对应前端的 App.onShow，时机需保证先与上一个 VC 的 App.onHide
    [self onAppEnterForeground];
    
    // BDPAppController使用VC自带的SubNavi，因此将BDPAppController的外层导航栏隐藏
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    [self resetViewStatus];
    [self relayoutXScreenProviderTipView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    // 作用是统计小程序的内存占用情况，由于 小程序A 进入 小程序B，B再退出，调用顺序是 A的viewWillAppear -> B的viewDidDisappear -> A的viewDidAppear，
    // 因此为了保证 每次设置的appID正确，则需要添加新didAppear的通知
    [BDPInterruptionManager postDidEnterForegroundNotification:BDPTypeNativeApp uniqueID:self.uniqueID];

    // 埋导航栏按钮埋点上报
    [self monitorNavigationBarItems];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self onAppEnterBackground];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    // 系统会修改VC.view的frame, 这边tabbar切换界面.解/锁屏切换时,self.view的size会被改为与superView一致.
    // 这个在小程序横屏下是不符合预期的.因此这边需要进行调整;
    [self layoutAutorateFrame];
    // 转屏时如果内外ViewController屏幕方向不一致可能导致布局异常
    // 转屏时View.Size计算方式见：https://stackoverflow.com/questions/25731676/child-viewcontroller-height-zero-after-rotation-ios
    self.contentVC.view.frame = self.view.bounds;
}

- (void)layoutAutorateFrame {
    if (![OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
        return;
    }

    BOOL isLandscape = [OPGadgetRotationHelper isLandscape];
    if (isLandscape) {
        NSAssert(self.view.superview != nil, @"BDPAppViewController superView is nil");
        CGFloat widthInset = [OPGadgetRotationHelper opHorizontalSafeArea].left + [OPGadgetRotationHelper opHorizontalSafeArea].right;
        CGRect expectFrame = CGRectMake([OPGadgetRotationHelper opHorizontalSafeArea].left, 0, self.view.superview.bdp_width - widthInset, self.view.superview.bdp_height);
        if (!CGRectEqualToRect(self.view.frame, expectFrame)) {
            self.view.frame = expectFrame;
        }
    } else {
        self.view.frame = self.view.superview.bounds;
    }
}
#pragma mark - Foreground/Background
/*------------------------------------------*/
//     Foreground/Background - 前后台切换
/*------------------------------------------*/
- (BOOL)canBeActive
{
    // 顶层VC为小游戏时设置isActive才会生效
    BOOL isTopAppVC = (self.navigationController.topViewController == self);
    if (isTopAppVC) {
        return YES;
    }
    return NO;
}

- (void)onAppEnterForeground
{
    BOOL canBeActive = [self canBeActive];
    if (self.isPaused && canBeActive) {
        [self setAppActive:YES];
        [self setAppViewPause:NO];
        self.isPaused = NO;
    }
}

- (void)onAppEnterBackground
{
    if (!self.isPaused) {
        [self setAppViewPause:YES];
        [self setAppActive:NO];
        self.isPaused = YES;
    }
}

- (void)forceStopRunning {
    [self setAppViewPause:YES];
    [self setAppActive:NO];
    self.isPaused = YES;
}

#pragma mark - AppView
/*-----------------------------------------------*/
//               AppView - 程序视图
/*-----------------------------------------------*/
// 装载ChildViewController
- (void)setupAppView
{
    self.originViewBackgroundColor = self.view.backgroundColor;
    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        self.view.backgroundColor = [UIColor clearColor];
    }
    
    [self updateContentVC:[self contentController:self.startPage]];
    self.routeManager = [[BDPAppRouteManager alloc] initWithAppController:self containerContext:self.containerContext];
    [self.routeManager showGoHomeButtonIfNeed];
    [self setupBottomBarIfNeed];
    [self setupXScreenProviderTipView];
}

- (void)updateContentVC:(UIViewController *)content
{
    BDPLogInfo(@"[BDPlatform-App] update contentvc, enter dismiss present vc");
    // apppage 将要移除时，如果有presentvc  不会dealloc，只有dismiss 之后才能真正移除
    [self.contentVC.presentedViewController dismissViewControllerAnimated:NO completion:nil];

    [self.contentVC removeFromParentViewController];
    [self.contentVC.view removeFromSuperview];
    [self addChildViewController:content];
    [self.view insertSubview:content.view atIndex:0];
    self.contentVC = content;
}

/// 初始化 bottomBar。
- (void)setupBottomBarIfNeed
{
    __weak BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    __weak BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];

    BDPAppPageController *currentPage = [BDPAppController currentAppPageController:self.contentVC fixForPopover:false];
    NSDictionary *bottomBarDic = [[common.schema.originQueryParams objectForKey:@"bottom_bar"] JSONValue];
    
    // 如果在初始化的时候有gid。就需要添加 底bar了。
    if (!BDPIsEmptyDictionary(bottomBarDic) && [currentPage isKindOfClass:[BDPAppPageController class]]) {
    } else if (currentPage.bottomBar) {
        [currentPage.bottomBar removeFromSuperview];
        [currentPage.view setNeedsLayout];
        currentPage.bottomBar = nil;
    }
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        UITouch *touch = [touches anyObject];
        CGPoint currentLoaction = [touch locationInView:self.view];
        // 点击了蒙层区域，关闭小程序
        if (currentLoaction.y < [BDPXScreenManager XScreenAppropriateMaskHeight:self.uniqueID]) {
            [[OPApplicationService.current getContainerWithUniuqeID:self.uniqueID] unmountWithMonitorCode:GDMonitorCode.mask_tap_dismiss];
        }
    }
}

- (void)resetViewStatus {
    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        self.view.backgroundColor = [UIColor clearColor];
    } else {
        self.view.backgroundColor = self.originViewBackgroundColor;
    }
}

- (void)setupXScreenProviderTipView {
    // 开关在整个App生命周期内只可能是一个值，不会存在状态切换，可以使用开关限制组件加载，并且在切换状态(半屏/全屏)时不缺少组件
    if (![BDPXScreenManager isXScreenFGConfigEnable]) {
        return;
    }
    
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    
    BDPXScreenAppProviderTipView *tipView = [[BDPXScreenAppProviderTipView alloc] initWithFrame:CGRectZero];
    tipView.delegate = self;
    [self.view addSubview:tipView];
    self.XScreenTipView = tipView;
    self.XScreenTipView.hidden = NO;
    
    [self.XScreenTipView updateAppName:common.model.name iconURL:common.model.icon];
    
}

- (void)relayoutXScreenProviderTipView {
    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        CGFloat topOffset = [BDPXScreenManager XScreenAppropriateMaskHeight:self.uniqueID];
        CGFloat tipViewHeight = 40.f;
        
        self.XScreenTipView.frame = CGRectMake(0, topOffset - tipViewHeight, self.view.bdp_width, tipViewHeight);
        
        self.XScreenTipView.hidden = NO;
    } else {
        self.XScreenTipView.hidden = YES;
    }
    
}

- (UIViewController *)contentController:(BDPAppPageURL *)pageURL
{
    // Tab页，创建TabBarPageController
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    if ([task.config isTabPage:pageURL.path]) {
        BDPTabBarPageController *controller = [[BDPTabBarPageController alloc] initWithUniqueID:self.uniqueID
                                                                                           page:pageURL
                                                                                       delegate:self.routeManager containerContext:self.containerContext];
        return controller;
        
    // 普通页面，创建BDPAppPageController
    } else if (self.vdom) {
        BDPAppPageController *controller = [[BDPAppPageController alloc] initWithUniqueID:self.uniqueID
                                                                                     page:pageURL
                                                                                     vdom:self.vdom
                                                                         containerContext:self.containerContext];
        BDPNavigationController *navi = [[BDPNavigationController alloc] initWithRootViewController:controller
                                                                                barBackgroundHidden:YES containerContext:self.containerContext];
        [navi useCustomAnimation];
        return navi;
    } else {
        BDPAppPageController *controller = [[BDPAppPageController alloc] initWithUniqueID:self.uniqueID
                                                                                     page:pageURL
                                                                         containerContext:self.containerContext];
        BDPNavigationController *navi = [[BDPNavigationController alloc] initWithRootViewController:controller
                                                                                barBackgroundHidden:YES containerContext:self.containerContext];
        [navi useCustomAnimation];
        return navi;
    }
}

#pragma mark - AppContent
/*-----------------------------------------------*/
//            AppContent - 页面内容加载
/*-----------------------------------------------*/
- (void)loadAppContent
{
    WeakSelf;
    NSDate *loadBegin = [NSDate date];
    NSString *appPath = @"app-service.js";
    __weak BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    __weak BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    [self.routeManager setupPlugins];

    // 真机调试的appcontent都在IDE里面，无需加载app-service.js
    if (!BDPIsEmptyString(common.realMachineDebugAddress)) {
        return;
    }

    BDPMonitorWithName(kEventName_mp_jscore_app_load_start, self.uniqueID).flush();
    [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithStartKey:BDPPerformanceAppServiceJSRun uniqueId:self.uniqueID extra:nil];
    NSString * pagePath = [[[common reader] basic] pagePath] ?: nil;
    appPath = pagePath ? [pagePath stringByAppendingPathComponent:@"app-service.js"] : appPath;

    // 当预载开关打开且命中AB测试开关,则进行读取预载缓存内容
    if (BDPPreRunManager.sharedInstance.enablePreRun) {
        BDPPreRunCacheModel *preRunModel = [BDPPreRunManager.sharedInstance cacheModelFor:common.uniqueID];
        NSString *cachedScript = [preRunModel cachedJSString:appPath];
        if (!BDPIsEmptyString(cachedScript)) {
            // 有prerun缓存时, 这边要看一下是否命中ABTest开关
            if (BDPPreRunManager.sharedInstance.preRunABtestHit) {
                [self invokeBeforeLoadAppServiceJS];
                NSDate *loadEnd = [NSDate date];
                [self loadScriptAndMonitorReport:task common:common script:cachedScript filePath:appPath loadBeginTime:loadBegin loadEndTime:loadEnd];
                [preRunModel addMonitorCachedFile:appPath];
                return;
            } else {
                [preRunModel addFailedReasonAndReport:@"abTest hit false"];
                [BDPPreRunManager.sharedInstance cleanAllCache];
            }
        }
    }

    [common.reader readDataInOrder:NO
                      withFilePath:appPath
                     dispatchQueue:dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)
                        completion:^(NSError * _Nullable error, NSString * _Nonnull pkgName, NSData * _Nullable data) {
        StrongSelfIfNilReturn;
        if (error) {
            error = OPErrorWithError(GDMonitorCode.load_app_service_script_error, error);
            BDP_PKG_LOAD_LOG(@"app-service.js not found!!!: %@", error);
            [OPSDKRecoveryEntrance handleErrorWithUniqueID:self.uniqueID with:error recoveryScene:RecoveryScene.gadgetRuntimeFail contextUpdater:nil];
            return;
        }
        [self invokeBeforeLoadAppServiceJS];
        
        NSDate *loadEnd = [NSDate date];
        
        NSString *script = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (!BDPIsEmptyString(script)) {
            [self loadScriptAndMonitorReport:task common:common script:script filePath:appPath loadBeginTime:loadBegin loadEndTime:loadEnd];
        } else {
            if (!error) {
                error = OPErrorWithErrorAndMsg(GDMonitorCodeAppLoad.pkg_data_parse_failed, error, @"data(%@) in pkg parse failed: %@", self.uniqueID, appPath);
            }
            BDPMonitorWithName(kEventName_mp_jscore_app_load_result, self.uniqueID).setResultType(kEventValue_fail).setError(error).flush();
            [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithEndKey:BDPPerformanceAppServiceJSRun uniqueId:self.uniqueID extra:nil];
            // 抛出通知让container知晓弹窗报错弹窗, 并退出
            [OPSDKRecoveryEntrance handleErrorWithUniqueID:self.uniqueID with:error recoveryScene:RecoveryScene.gadgetRuntimeFail contextUpdater:nil];
        }
    }];
}

- (void)invokeBeforeLoadAppServiceJS {
    BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
    BDPLogTagInfo(@"LifeCycle", @"bdp_beforeLoadAppServiceJS %@", self.uniqueID);
    if ([lifeCyclePlugin respondsToSelector:@selector(bdp_beforeLoadAppServiceJS:)]) {
        [lifeCyclePlugin bdp_beforeLoadAppServiceJS:self.uniqueID];
    }
}

- (void)loadScriptAndMonitorReport:(BDPTask *)task
                            common:(BDPCommon *)common
                            script:(NSString *)script
                          filePath:(NSString *)appPath
                     loadBeginTime:(NSDate *)loadBegin
                       loadEndTime:(NSDate *)loadEnd {
    if (!task || !common) {
        return;
    }
    // 修复该https://slardar.bytedance.net/node/app_detail/?aid=1161&os=iOS&region=cn&lang=zh#/abnormal/detail/watch_dog/1161_3c6f184496c380c805c05f494d1d9e19WatchDog?params=%7B%22token%22%3A%22%22%2C%22token_type%22%3A0%2C%22crash_time_type%22%3A%22insert_time%22%2C%22start_time%22%3A1649820120%2C%22end_time%22%3A1650424920%2C%22granularity%22%3A86400%2C%22filters_conditions%22%3A%7B%22type%22%3A%22and%22%2C%22sub_conditions%22%3A%5B%5D%7D%2C%22event_index%22%3A1%7D
    // callbackIsMainThread传入NO，callback为不派发到主线程，callbackIsMainThread传NO
    // 问题原因是：eventCpJsLoadResult的[BDPTracker buildJSContextParams:]内获取JS exception卡死
    WeakSelf;
    [task.context loadScript:script withFileSource:appPath callbackIsMainThread:NO completion:^{
        StrongSelfIfNilReturn;
        NSDate *evalEnd = [NSDate date];
        NSUInteger diff = ([evalEnd timeIntervalSince1970] - [loadEnd timeIntervalSince1970]) * 1000;

        [BDPTracker event:@"mp_load_time_app_service"
               attributes:@{@"duration": @(diff),
                            @"local_pkg": @(common.reader.createLoadStatus == BDPPkgFileLoadStatusDownloaded)}
     uniqueID:self.uniqueID];

        [self eventCpJsLoadResult];

        BDPMonitorLoadTimelineDate(@"get_file_content_from_ttpkg_begin", @{ @"file_path": @"app-service.js"}, loadBegin, self.uniqueID);
        BDPMonitorLoadTimelineDate(@"get_file_content_from_ttpkg_end", @{ @"file_path": @"app-service.js"}, loadEnd, self.uniqueID);
        BDPMonitorLoadTimelineDate(@"jsc_eval_js_begin", @{ @"file_path": @"app-service.js"}, loadEnd, self.uniqueID);
        BDPMonitorLoadTimelineDate(@"jsc_eval_js_end", @{ @"file_path": @"app-service.js"}, evalEnd, self.uniqueID);
        BDPLogInfo(@"[BDPlatform-App] Loading app-service.js");

        BDPMonitorWithName(kEventName_mp_jscore_app_load_result, self.uniqueID).setResultType(kEventValue_success).flush();
        [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithEndKey:BDPPerformanceAppServiceJSRun uniqueId:self.uniqueID extra:nil];
    }];
    [self eventCpJsLoadStart];
    [self eventMpRenderStart];
}

#pragma mark - AppControl
/*-----------------------------------------------*/
//            AppControl - 游戏状态控制
/*-----------------------------------------------*/
- (void)setAppActive:(BOOL)isActive
{
    [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID].isActive = isActive;
}

- (void)setAppViewPause:(BOOL)isPause
{
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    if (isPause) {
        BDPLogInfo(@"[BDPlatform-App] EnterBackground");
        
        // Audio Pause
        [task.context bdp_fireEvent:@"audioInterruptionBegin" sourceID:NSNotFound data:nil];
        [[BDPAudioControlManager sharedManager] beginInterruption:self.uniqueID];
        
        // App Pause
        [BDPInterruptionManager postEnterBackgroundNotification:BDPTypeNativeApp uniqueID:self.uniqueID];
        [task.context handleInvokeInterruptionWithStatus:GeneralJSRuntimeRenderStatusOnAppEnterBackground data:nil];
        
    } else {
        // App Restore
        [task.context handleInvokeInterruptionWithStatus:GeneralJSRuntimeRenderStatusOnAppEnterForeground data:[self getOnAppEnterForegroundParams]];
        [BDPInterruptionManager postEnterForegroundNotification:BDPTypeNativeApp uniqueID:self.uniqueID];
        
        // Audio Restore
        [[BDPAudioControlManager sharedManager] endInterruption:self.uniqueID];
        [task.context bdp_fireEvent:@"audioInterruptionEnd" sourceID:NSNotFound data:nil];
        
        BDPLogInfo(@"[BDPlatform-App] EnterForeground");
    }
}

#pragma mark - Event
/*------------------------------------------*/
//             Event - 埋点上报
/*------------------------------------------*/
- (void)eventCpJsLoadStart
{
    // 埋点 - mp_cpjs_load_start, 开始计时
    [BDPTracker beginEvent:BDPTECPJSLoadStart primaryKey:BDPTrackerPKCPJSLoad attributes:nil reportStart:NO uniqueID:self.uniqueID];
    [BDPTrackerHelper setLoadState:BDPTrackerLSCPJSLoading forUniqueID:self.uniqueID];
}

- (void)eventCpJsLoadResult
{
    // 埋点 - mp_cpjs_load_start, 加载结果
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    NSMutableDictionary *params = [BDPTracker buildJSContextParams:task.context.jsContext];
    [BDPTracker endEvent:BDPTECPJSLoadResult primaryKey:BDPTrackerPKCPJSLoad attributes:params uniqueID:self.uniqueID];
}

- (void)eventMpRenderStart
{
    // 埋点 - mp_preload_start, 开始计时，对应小游戏mp_render_start，start埋点只记录时间戳，不上报
    [BDPTracker beginEvent:@"mp_preload_start" primaryKey:BDPTrackerPKWebViewRender attributes:nil reportStart:NO uniqueID:self.uniqueID];
    [BDPTrackerHelper setLoadState:BDPTrackerLSRendering forUniqueID:self.uniqueID];
}

#pragma mark - StatusBar
/*------------------------------------------*/
//            StatusBar - 状态栏
/*------------------------------------------*/
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.contentVC preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    return [self.contentVC prefersStatusBarHidden];
}

#pragma mark - Orientation
/*------------------------------------------*/
//          Orientation - 屏幕旋转
/*------------------------------------------*/
- (BOOL)shouldAutorotate
{
    return [self.contentVC shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.contentVC supportedInterfaceOrientations];
}

- (void)handleGadgetContainerDidHideByGesture:(NSNotification *)noti {
    if (self.isPaused) {
        BDPLogInfo(@"no need handle, gadget is paused %@", self.uniqueID.appID);
        return;
    }

    NSObject *appVC = [noti object];
    if ([appVC isMemberOfClass:[self class]] && self != appVC) {
        BDPLogInfo(@"handle other gadget container notification %@", self.uniqueID.appID)
        BDPAppPageController *pageVC = [self currentAppPage];
        [pageVC adjustInterfaceOrientation];
    } else {
        BDPLogInfo(@"no need handle Self gadget container notification %@", self.uniqueID.appID);
    }
}
#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
- (NSDictionary *)getOnAppEnterForegroundParams
{
    // Generate Scene Params
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    NSDictionary *onShowParams = [BDPApplicationManager getOnAppEnterForegroundParams:common.schema];
    return onShowParams;
}

/// 寻找当前VC中最上层的VC，这是一个针对iPad设备，且当BDPAppPageController弹出了一个popover时才生效的补丁
/// 因为原方法在这种情况下，根据现在的查找机制会找到popover弹出的VC，并错误的返回nil，这是不正确的
/// 于是在这里加上一个判断方法，让他返回正确的VC, fixForPopover为true则会走补丁逻辑
+ (BDPAppPageController *)currentAppPageController:(UIViewController *)viewController fixForPopover:(BOOL)fixForPopover
{
    if ([viewController isKindOfClass:[BDPAppController class]]) {
        return [(BDPAppController *)viewController currentAppPage];
    }
    UIViewController *topVC = [BDPResponderHelper topViewControllerForController:viewController fixForPopover:fixForPopover];
    if ([topVC isKindOfClass:[BDPAppPageController class]]) {
        return (BDPAppPageController *)topVC;
    }
    return nil;
}

- (BDPAppPageController *)currentAppPage
{
//    UIViewController *topVC = [BDPResponderHelper topViewControllerForController:self.contentVC fixForPopover:false];
//    NSAssert([topVC isKindOfClass:[BDPAppPageController class]], @"BDPAppController topVC 必须是 BDPAppPageController类型的");
    
    // 不用BDPResponderdHelper的原因是因为他还计算了presented的VC，其实并不是真正计算当前的appPage。
    UIViewController *topVC = nil;
    if ([self.contentVC isKindOfClass:[BDPNavigationController class]]) {
        topVC = [((BDPNavigationController *)self.contentVC).viewControllers lastObject];
    } else if ([self.contentVC isKindOfClass:[BDPTabBarPageController class]]) {
        BDPNavigationController *selectedVC = (BDPNavigationController *)((BDPTabBarPageController *)(self.contentVC)).selectedViewController;
        topVC = [selectedVC.viewControllers lastObject];
    }
    if ([topVC isKindOfClass:[BDPAppPageController class]]) {
        return (BDPAppPageController *)topVC;
    }
    return nil;
}

#pragma mark - BDPXScreenAppProviderTipViewDelegate
- (void)didClickAppProviderTipView:(BDPXScreenAppProviderTipView *)appProviderTipView {
    // 暂时使用上层SDK的能力打开关于
    BDPPlugin(routerPlugin, BDPRouterPluginDelegate);
    [routerPlugin aboutHandlerForUniqueID:self.uniqueID];
}

#pragma mark - BDPWarmBootCleanerProtocol
/*-----------------------------------------------*/
//   BDPWarmBootCleanerProtocol - 热启动清理协议
/*-----------------------------------------------*/
- (void)warmBootManagerWillEvictCache
{
    self.routeManager = nil;
    
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    
    common.isDestroyed = YES;
    if (!task || !task.context) {
        BDPLogWarn(@"empty call.task is %@, context is %@, uniqueID is %@",task, task.context, self.uniqueID);
    } else {
        [task.context enableAcceptAsyncDispatch:NO];
        [task.context cancelAllPendingAsyncDispatch];
    }
    
    [BDPJSBridgeCenter clearContextMethod:self.uniqueID];
    [[BDPTracker sharedInstance] flushLoadTimelineWithUniqueId:self.uniqueID];
}

- (void)layoutAnchorShareButton {
    [BDPShareManager sharedManager].engine = BDPCurrentTask.context;
    if (!self.anchorShareButton) {
        UIButton *button = [[UIButton alloc] init];
        self.anchorShareButton = button;
        [button addTarget:self action:@selector(anchorShareButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
        UIImage *image = image = [UIImage imageNamed:@"anchor_add" inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil];;
        [button setImage:image forState:UIControlStateNormal];
        button.adjustsImageWhenHighlighted = NO;
        button.titleLabel.font = [UIFont systemFontOfSize:15];
        
        CGFloat height = 54;
        CGFloat toBottom = 78;
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 24, 0, 24);
        
        button.layer.cornerRadius = height / 2;
        button.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2].CGColor;
        button.layer.shadowOffset = CGSizeMake(0, 10);
        button.layer.shadowRadius = 16;
        button.layer.shadowOpacity = 1;
        
        button.translatesAutoresizingMaskIntoConstraints = NO;
        NSLayoutConstraint *c2 = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.f constant:height];
        NSLayoutConstraint *c3 = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f];
        NSLayoutConstraint *c4 = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.f constant:-toBottom];
        [self.view addConstraints:@[c2, c3, c4]];
        button.hidden = YES;
    }
    
    self.anchorShareButton.hidden = YES;
}

- (void)anchorShareButtonDidClick:(id)sender {
    [[BDPShareManager sharedManager] setShareEntry:BDPShareEntryTypeAnchor];
}


/// 上报当前appPageVC上的导航栏按钮(code定义见链接)
/// https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
- (void)monitorNavigationBarItems {
    // 每个小程序生命周期只上报一次
    if (!self.hasFlushNavigationBarItemMonitor) {
        BDPMonitorEvent *monitor = BDPMonitorWithName(@"openplatform_mp_container_view", self.uniqueID);
        monitor.addCategoryValue(@"application_id", BDPSafeString(self.uniqueID.appID));
        monitor.setPlatform(OPMonitorReportPlatformTea);
        BDPAppPageController *currentPage = [self currentAppPage];

        NSMutableArray *buttonIdArray = [NSMutableArray array];
        for (UIBarButtonItem *item in currentPage.navigationItem.leftBarButtonItems) {
            if ([item.accessibilityIdentifier isEqualToString:OPNavigationBarItemConsts.backButtonKey]) {
                [buttonIdArray addObject:OPNavigationBarItemMonitorCodeBridge.backButton];
            }
            if ([item.accessibilityIdentifier isEqualToString:OPNavigationBarItemConsts.homeButtonKey]) {
                [buttonIdArray addObject:OPNavigationBarItemMonitorCodeBridge.homeButton];
            }
        }

        BDPToolBarView *toolbar = [self currentAppPage].toolBarView;
        if (toolbar.moreButton && !toolbar.moreButton.isHidden && [toolbar.moreButton.accessibilityIdentifier isEqualToString:OPNavigationBarItemConsts.moreButtonKey]) {
            [buttonIdArray addObject:OPNavigationBarItemMonitorCodeBridge.moreButton];
        }

        if (toolbar.closeButton && !toolbar.closeButton.isHidden && [toolbar.closeButton.accessibilityIdentifier isEqualToString:OPNavigationBarItemConsts.closeButtonKey]) {
            [buttonIdArray addObject:OPNavigationBarItemMonitorCodeBridge.closeButton];
        }

        NSString *buttonListString = [buttonIdArray componentsJoinedByString:@","];
        monitor.addCategoryValue(@"button_list", BDPSafeString(buttonListString)).flush();
        self.hasFlushNavigationBarItemMonitor = YES;
    }
}
@end

@implementation BDPAppController(ExitMonitorStrategy)

- (BOOL)isCleanWarmCache:(NSArray<StrategyParam *> *)param withError:(NSError *__autoreleasing  _Nullable *)error {
    /// 根据配置策略进行探测，共有3个command: blank, not_blank, close
    __block BOOL cleanWarmCache = NO;
    CommandBlockWrap *closeCommand = [CommandBlockWrap buildWithCommand:^(NSDictionary<NSString *,StrategyParam *> * _Nonnull param) {
        cleanWarmCache = YES;
        NSMutableDictionary *category = [self buildExitMonitorCategory:param];
        [BDPTracker monitorService:kEventName_mp_blank_screen_close metric:nil category:category extra:nil uniqueID:self.uniqueID];
    }];
    *error = [self.exitMonitorStrategy strategyWithCommand:@{BDPBlankDetectCommandClose: closeCommand} with:param];
    return cleanWarmCache;
}

- (StrategyService *)exitMonitorStrategy {
    if (!_exitMonitorStrategy) {
        BDPPlugin(webviewPlugin, BDPWebviewPluginDelegate);
        if (![webviewPlugin respondsToSelector:@selector(bdp_getWebviewDetectConfig)]) {
            BDPLogError(@"can not find get config method")
            return nil;
        }
        BDPBlankDetectConfig *config = [webviewPlugin bdp_getWebviewDetectConfig];
        if (!config) {
            BDPLogInfo(@"exit monitor strategy is nil")
            return nil;
        }
        _exitMonitorStrategy = [[StrategyService alloc] initWithConfigJSON:config.strategy commonParams:nil];
        WeakSelf;
        __weak BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
        [_exitMonitorStrategy registerWithName:BDPBlankDetectCommandBlank with:^(NSDictionary<NSString *,StrategyParam *> * _Nonnull param) {
            StrongSelfIfNilReturn;
            self.blankCount += 1;
            NSMutableDictionary *category = [self buildExitMonitorCategory:param];
            NSString *page_path = self.currentAppPage.page.path ?:@"";
            BDPTracing *trace = [BDPTracingManager.sharedInstance getTracingByUniqueID:self.uniqueID];
            NSInteger from_app_launch_start_duration = trace ? [trace clientDurationFor:kEventName_mp_app_launch_start] : NSIntegerMax;
            category[@"page_path"] = page_path;
            category[@"isBlank"] = @(YES);
            category[@"reload_count"] = @(self.currentAppPage.appPage.totalTerminatedCount);
            category[@"from_app_launch_start_duration"] = @(from_app_launch_start_duration);
            category[@"is_subpackage_mode"] = @([common isSubpackageEnable]);
            BDPMonitorWithName(kEventName_mp_blank_screen_detect, self.uniqueID)
            .setPlatform(OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea)
            .addMap([category copy])
            .flush();
        }];
        [_exitMonitorStrategy registerWithName:BDPBlankDetectCommandNotBlank with:^(NSDictionary<NSString *,StrategyParam *> * _Nonnull param) {
            StrongSelfIfNilReturn;
            self.blankCount = 0;
            BDPTracing *trace = [BDPTracingManager.sharedInstance getTracingByUniqueID:self.uniqueID];
            NSInteger from_app_launch_start_duration = trace ? [trace clientDurationFor:kEventName_mp_app_launch_start] : NSIntegerMax;
            NSMutableDictionary *category = [self buildExitMonitorCategory:param];
            NSString *page_path = self.currentAppPage.page.path ?:@"";
            category[@"page_path"] = page_path;
            category[@"isBlank"] = @(NO);
            category[@"reload_count"] = @(self.currentAppPage.appPage.totalTerminatedCount);
            category[@"from_app_launch_start_duration"] = @(from_app_launch_start_duration);
            category[@"is_subpackage_mode"] = @([common isSubpackageEnable]);
            BDPMonitorWithName(kEventName_mp_blank_screen_detect, self.uniqueID)
            .setPlatform(OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea)
            .addMap([category copy])
            .flush();
        }];
    }
    return _exitMonitorStrategy;
}

- (NSMutableDictionary *)buildExitMonitorCategory: (NSDictionary<NSString *,StrategyParam *> *)param {
    NSMutableDictionary *category = [NSMutableDictionary dictionary];
    category[OPMonitorEventKey.duration] = @([param[OPMonitorEventKey.duration] getIntValue]);
    category[ExitMonitorStrategyConsts.blankRate] = @([param[ExitMonitorStrategyConsts.blankRate] getFloatValue]);
    category[ExitMonitorStrategyConsts.lucency] = @([param[ExitMonitorStrategyConsts.lucency] getFloatValue]);
    category[ExitMonitorStrategyConsts.closeCount] = @([param[ExitMonitorStrategyConsts.closeCount] getIntValue]);
    category[ExitMonitorStrategyConsts.maxPureColor] =  [param[ExitMonitorStrategyConsts.maxPureColor] getStrValue];
    category[ExitMonitorStrategyConsts.maxPureColorRate] = @([param[ExitMonitorStrategyConsts.maxPureColorRate] getFloatValue]);
    return category;
}

@end
