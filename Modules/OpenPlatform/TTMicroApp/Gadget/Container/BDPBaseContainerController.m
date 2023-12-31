//
//  BDPBaseContainerController.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/16.
//

#import "BDPBaseContainerController.h"
#import "BDPAPIInterruptionManager.h"
//#import "BDPAlertController.h"
#import "BDPAppController.h"
#import "BDPAppLoadDefineHeader.h"
#import "BDPAppLoadManager+Clean.h"
#import "BDPAppLoadManager+Load.h"
#import "BDPAppLoadManager+Util.h"
#import "BDPAppLoadURLInfo.h"
#import "BDPAppManagerTrackEvent.h"
#import "BDPAppPageController.h"
#import "BDPAppPageFactory.h"
#import <OPFoundation/BDPApplicationManager.h>
#import "BDPAudioControlManager.h"
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPContainerModuleProtocol.h"
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPDeviceManager.h>
#import <OPFoundation/BDPI18n.h>
#import "BDPJSRuntimePreloadManager.h"
#import "BDPLoadingView.h"
#import <OPFoundation/BDPMacroUtils.h>
#import "BDPMemoryMonitor.h"
#import <OPFoundation/BDPModel.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPMorePanelItem.h>
#import "BDPNavigationController.h"
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPNotification.h>
#import "BDPPermissionController.h"
#import <OPFoundation/BDPResponderHelper.h>
#import "BDPRootNavigationController.h"
#import <OPFoundation/BDPRouteMediator.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPSchema.h>
#import <OPFoundation/BDPSchemaCodec+Private.h>
#import "BDPSearchEventReporter.h"
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import "BDPStreamingAudioRecorder.h"
#import "BDPTask.h"
#import "BDPTaskManager.h"
#import <OPFoundation/BDPTimorClient+Private.h>
#import "BDPToolBarView.h"
#import "BDPTracker+BDPLoadService.h"
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPTrackerEvent.h>
#import "BDPTrackerHelper.h"
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPVersionManager.h>
#import "BDPWarmBootManager.h"
#import "BDPWebViewBlankScreenDetect.h"
#import <OPFoundation/EEFeatureGating.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/NSTimer+BDPWeakTarget.h>
#import "BDPDeprecateUtils.h"
#import <OPFoundation/TMACustomHelper.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <KVOController/KVOController.h>
#import <Masonry/Masonry.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPStorageManager.h"
#import "BDPAbilityNotSupportController.h"
#import <OPFoundation/BDPAppMetaUtils.h>
#import "BDPAppController+ExitMonitorStrategy.h"
#import "BDPPluginUpdateManager.h"

#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import "BDPJSSDKForceUpdateManager.h"
#import <OPFoundation/BDPModuleManager.h>
#import "BDPAppPagePrefetchManager.h"

#import <ECOInfra/EMAFeatureGating.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import "OPNoticeManager.h"
#import "BDPAppContainerController.h"
#import "BDPDirectionPanGestureRecognizer.h"
#import "BDPXScreenManager.h"

#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import "BDPTimorClient+Business.h"
#import "BDPSubPackageManager.h"
#import "BDPInterruptionManager.h"
#import <pthread.h>

#define CHECK_READY_DELAY 5.0

typedef NS_OPTIONS(int, BDPRemovePkgFrom) {
    /** 启动超时, 重置数据 */
    BDPRemovePkgFromTimeout = 1 << 0,
    /// 加载过程中有报错
    BDPRemovePkgFromError = 1 << 1,
    /// 下架移除
    BDPRemovePkgFromOffline = 1 << 2,
    /// versionState异常
    BDPRemovePkgFromVersionStateAbnormal = 1 << 3
};

@interface BDPBaseContainerController () <UIGestureRecognizerDelegate, BDPLoadingViewDelegate, BDPNavigationControllerRouteProtocol>

@property (nonatomic, strong) BDPUniqueID *uniqueID;
@property (nonatomic, strong) BDPLoadingView *loadingView;
@property (nonatomic, strong) BDPToolBarView *toolBarView;
@property (nonatomic, strong) BDPPkgFileReader appFileReader;
@property (nonatomic, strong) BDPNavigationController *subNavi;
@property (nonatomic, strong) BDPPresentAnimation *screenEdgePopAnimation;

@property (nonatomic, strong, readwrite) UIScreenEdgePanGestureRecognizer *popGesture;
@property (nonatomic, strong) UIAlertController *timeoutAlertController;

//@property (nonatomic, copy) BDPSchema *schema;
@property (nonatomic, copy) NSString *launchFrom;
@property (nonatomic, copy) NSString *exitType;
@property (nonatomic, copy) NSString *pkgName;
@property (nonatomic, strong, readwrite) BDPTimorLaunchParam *launchParam;

//@property (nonatomic, assign) BOOL backFromOtherMiniProgram;
@property (nonatomic, assign) BOOL isEnterBackground;
@property (nonatomic, assign) BOOL isAdaptingOrientation;
//这个属性在重启前需要标记为YES，在发送exit通知的时候会有使用, 主端的常用面板会有依赖这个属性
//@property (nonatomic, assign) BOOL willReboot;
/** 是否应该删除包缓存(包括meta) */
@property (nonatomic, assign) BDPRemovePkgFrom removePkgBitMask;
@property (nonatomic, assign) BDPContainerBootType bootType;
@property (nonatomic, strong, readwrite) OPMonitorCode *loadResultType;

// 记录导航栏/状态栏/屏幕方向原始状态
@property (nonatomic, assign) BOOL originIdleTimerDisabled;
@property (nonatomic, assign) BOOL originNavigationBarHidden;
@property (nonatomic, assign) BOOL originStatusBarHidden;
@property (nonatomic, assign) UIStatusBarStyle originStatusBarStyle;
@property (nonatomic, assign) UIInterfaceOrientation originInterfaceOrientation;
@property (nonatomic, weak) UINavigationController *originNavigationController; //这里加这个是因为抖音hook了UIViewController的getNavigationController方法，并创建了self的weak引用，导致dealloc中创建weak引用的crash。

/** 必须等task创建后执行的Blks! */
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *needAppTaskBlks;

// mp_load_result加载过程中切入后台则duration清零
// mp_launch duration只计算前台时间
@property (nonatomic, assign) BOOL loadDurationShouldClear;
@property (nonatomic, strong) BDPTrackerTimingEvent *loadTimingEvent;
@property (nonatomic, strong) BDPTrackerTimingEvent *launchTimingEvent;

@property (nonatomic, strong) BDPTrackerTimingEvent *usageTimingEvent; //用于记录每次前台使用时间

/// 小程序是否冷启动。如果是冷启动，则打开时是否存在缓存（内存），存在缓存的情况下打开几乎是无延迟的
@property (nonatomic, assign) BOOL isAppColdLaunch;
/// 页面首次出现
@property (nonatomic, assign) BOOL isFirstAppeared;
// 当前是否第一次disappear
@property (nonatomic, assign) BOOL isFirstDisappear;
/// 宿主block逻辑是否确认继续
@property (nonatomic, assign) BOOL blockLoadingContinue;
/// 被hold住的metaInfoModelCompletion事件
@property (nonatomic, copy) void (^metaInfoModelCompletionBlock)(void);
/// 被hold住的dataDownloadCompletion事件
@property (nonatomic, copy) void (^dataDownloadCompletionBlock)(void);
/// 因为宿主block逻辑导致的加载耗时增量
@property (nonatomic, strong) BDPTrackerTimingEvent *blockTimingEvent;

@property (nonatomic, readonly) BDPWarmBootCleaner rootVCCleaner;

@property (nonatomic, assign) NSTimeInterval launchTime;

// 搜索排序模型埋点上报类
@property (nonatomic, strong) BDPSearchEventReporter *searchReporter;

/// 启动的超时判定时间
@property (nonatomic, assign) NSTimeInterval launchTimeout;
/// 启动过程中的 Error 信息
@property (nonatomic, strong) NSError *launchError;
/// 启动结果是否已经上报
@property (nonatomic, assign) BOOL hasLaunchingReported;
/// VC 是否已经 delloc，此时应当避免 weak_self 的调用(会 crash)
@property (nonatomic, assign) BOOL deallocated;
/// 退出时的 code
@property (nonatomic, strong) OPMonitorCode *closeCode;
/// 启动时的 AppLoadContext，这里必须强引用持有，不然其存在提前释放的可能性从而导致无法接收回调
@property (nonatomic, strong) BDPAppLoadContext *appLoadContext;

@property (nonatomic, weak, nullable, readwrite) OPContainerContext *containerContext;

// 整个Lark是否Active
@property (nonatomic, assign) BOOL applicationIsActive;
// 当前的VC的view是否appear
@property (nonatomic, assign) BOOL containerControllerHasAppeared;

@property (nonatomic, strong) UIPanGestureRecognizer *directionGesture;

@end

@implementation BDPBaseContainerController

@synthesize hasLaunchingReported = _hasLaunchingReported;

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (BDPType)type
{
    return BDPTypeNativeApp;
}

- (instancetype)initWithLaunchParam:(BDPTimorLaunchParam *)launchParam
                   containerContext:(OPContainerContext *)containerContext
{
    BDPMonitorEvent *containerStartEvent = (BDPMonitorEvent *)BDPMonitorWithName(kEventName_mp_app_container_start, nil).timing();
    NSURL *url = launchParam.url;
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.containerContext = containerContext;
        self.hidesBottomBarWhenPushed = YES;
        NSDate *parseSchemaBegin = [NSDate date];
        // 解析schema
        NSError *schemaError = nil;
        _schema = [BDPSchemaCodec schemaFromURL:url appType:OPAppTypeGadget error:&schemaError];
        self.launchError = schemaError ?: self.launchError;
        NSDate *parseSchemaEnd = [NSDate date];
        
        // TODO: yinyuan 需要确认如何处理
        _bootType = BDPContainerBootTypeUnknown;
        _loadResultType = GDMonitorCodeLaunch.unknown_error;
        _uniqueID = containerContext.uniqueID ?: (_schema.uniqueID ?: [BDPUniqueID uniqueIDWithAppID:_schema.appID identifier:nil versionType:_schema.versionType appType:_schema.appType]);
        _launchFrom = [_schema launchFrom];
        _isEnterBackground = YES;
        _containerControllerHasAppeared = NO;
        _applicationIsActive = !BDPInterruptionManager.sharedManager.didEnterBackground;
        _isAdaptingOrientation = NO;
        _exitType = @"others";
        _launchParam = launchParam;
        _shouldOpenInTemporaryTab = NO;

        // TODO: yinyuan 需要确认如何处理
        // 音频增加活跃实例
        [[BDPAudioControlManager sharedManager] increaseActiveContainer];

        NSString *traceID = [BDPTracingManager.sharedInstance getTracingByUniqueID:self.uniqueID].traceId;
        if (BDPIsEmptyString(traceID)) {
            BDPLogInfo(@"generateTracing uniqueID:%@", self.uniqueID);
            [BDPTracingManager.sharedInstance clearTracingByUniqueID:self.uniqueID];
            traceID = [BDPTracingManager.sharedInstance generateTracingByUniqueID:self.uniqueID].traceId;
        }

        [self postEnterNotification];
        [self setupObserveNoification];
        [self setTrackerCommonParams:@{kEventKey_trace_id: traceID ?: @""}];
        [self eventSchemaInfoWithSchema:self.schema error:schemaError]; //schema的埋点需要放到commonParam创建之后
        
        BDPMonitorLoadTimelineDate(@"parse_schema_begin", nil, parseSchemaBegin, _uniqueID);
        BDPMonitorLoadTimelineDate(@"parse_schema_end", nil, parseSchemaEnd, _uniqueID);

        containerStartEvent.setUniqueID(_uniqueID);
        BDPMonitorWithName(kEventName_mp_app_container_loaded, self.uniqueID)
        .kv(@"launch_type", [NSNumber numberWithInt:(!!BDPTaskFromUniqueID(_uniqueID))])
        .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar)
        .flush();
        
        // 生命周期: 小程序UI容器创建加载完成
        BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
        if ([lifeCyclePlugin respondsToSelector:@selector(bdp_onContainerLoaded:container:)]) {
            [lifeCyclePlugin bdp_onContainerLoaded:self.uniqueID container:self];
        }
        BDPLogInfo(@"BDPBaseContainerController init, app=%@", self.uniqueID);
    }
    containerStartEvent.flush();
    return self;
}

- (void)dealloc
{
    BDPLogInfo(@"BDPBaseContainerController dealloc, app=%@", self.uniqueID);
    self.deallocated = YES;
    [self postExitNotification];

    [BDPMemoryMonitor unregisterMemoryWarningTimerWithUniqueID:self.uniqueID];

    // 检查是否启动过程还未上报
    [self tryReportLoadResultIfNeeded];
}

- (NSString *)launchFrom
{
    return [_schema launchFrom];
}

/// 启动超时时间
- (NSTimeInterval)launchTimeout {
    if (_launchTimeout > 0) {
        return _launchTimeout;
    }
    _launchTimeout = [BDPSettingsManager.sharedManager s_integerValueForKey:kBDPLaunchTimeout] / 1000;
    if (_launchTimeout < 10) {
        _launchTimeout = 10; // 避免 settings 返回值异常导致启动异常，因此限定超时时间最小为 10s
        BDPLogWarn(@"launchTimeout should greater than 10s");
    }
    return _launchTimeout;
}

#pragma mark - View & Layout
/*-----------------------------------------------*/
//          View & Layout - 加载及布局相关
/*-----------------------------------------------*/
- (void)viewDidLoad
{
    int64_t beginTime = [[NSProcessInfo processInfo] systemUptime] * 1000.0;
    NSDate *beginDate = [NSDate date];
    [super viewDidLoad];
    
    // 支持 iPad 多 Scene，绑定 window
    self.uniqueID.window = self.view.window;
    
    self.isFirstAppeared = YES;
    self.isFirstDisappear = YES;
    
    // Init
    self.launchTimingEvent = [[BDPTrackerTimingEvent alloc] init];
    self.view.backgroundColor = UDOCColor.bgBase;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    // 记录导航栏/状态栏/屏幕方向原始状态
    _originNavigationController = self.navigationController;
    _originNavigationBarHidden = self.navigationController.isNavigationBarHidden;
    _originStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    _originStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    _originIdleTimerDisabled = [UIApplication sharedApplication].idleTimerDisabled;
    if ([OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
        // 这边设备横屏时进入, 会获取到其他方向的值. 如果这边不设置成竖屏, 则从横屏退出小程序时, 这边将不会恢复成竖屏.
        _originInterfaceOrientation = UIInterfaceOrientationPortrait;
    } else {
        _originInterfaceOrientation = [[[UIDevice currentDevice] valueForKey:@"orientation"] integerValue];
        if ([OPSDKFeatureGating gadgetUseStatusBarOrientation]) {
            // 这边使用UIApplication的statuBarOrientation替换UIDevice的方向
            // 小程序预期获取的是当前界面方向
            _originInterfaceOrientation = [OPGadgetRotationHelper currentDeviceOrientation];
        }
    }
    
    
    if ([BDPXScreenManager isXScreenFGConfigEnable]) {
        /*
         BDPDirectionPanGestureRecognizer手势内控制了只有在屏幕边缘开始的才会响应
         直接使用系统边缘手势会不响应，怀疑是手势冲突，但是没有采取移除原手势的实现方式，担心对原逻辑产生影响
         */
        BDPDirectionPanGestureRecognizer *directionGesture = [[BDPDirectionPanGestureRecognizer alloc] initWithTarget:self action:@selector(directionEdgePanGesture:)];
        directionGesture.delegate = self;
        directionGesture.maximumNumberOfTouches = 1;
        directionGesture.mode = kBDPDirectionPanGestureRecognizerModeScreenEdge;
        [self.view addGestureRecognizer:directionGesture];
        self.directionGesture = directionGesture;
    }
    
    // 开启了新的启动流程
    // 埋点还要保留
    BDPMonitorWithName(kEventName_mp_app_container_setuped, self.uniqueID).flush();
    [self eventMpEntranceClick];
}

- (void)viewWillAppear:(BOOL)animated
{
    BDPLogInfo(@"viewWillAppear, id=%@", self.uniqueID);
    [super viewWillAppear:animated];
    // 从一个小程序返回到小程序需要更新场景值
    if (self.backFromOtherMiniProgram) {
        // TODO: 检查新容器对于这种场景的支持
        BDPPlugin(applicationPlugin, BDPApplicationPluginDelegate);
        NSDictionary *sceneInfo = [applicationPlugin bdp_registerSceneInfo];
        NSString *scene = [sceneInfo bdp_stringValueForKey:@"back_mp"];
        [self.schema updateScene:scene];
        self.backFromOtherMiniProgram = NO;
    }
    // 隐藏默认导航栏(对于OPSDK架构子VC模式是不需要的)
    if (self.openType == BDPViewControllerOpenTypeChild) {
        // 不隐藏父导航栏
    } else {
        [TMACustomHelper configNavigationController:self innerNavigationController:self.originNavigationController barHidden:YES dragBack:NO];
    }
    
    if ([BDPXScreenManager isXScreenMode:self.uniqueID]) {
        self.view.backgroundColor = [UIColor clearColor];
    } else {
        self.view.backgroundColor = UDOCColor.bgBase;
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    BDPLogInfo(@"viewDidAppear, id=%@", self.uniqueID);
    [super viewDidAppear:animated];
    self.containerControllerHasAppeared = YES;
    [self applicationActiveChange:YES];
    self.isFirstAppeared = NO;  // 需要在 applicationActiveChange 后执行
    // 侧滑返回优化：防止进小程序二级页面有概率侧滑直接退出了小程序App
    if (self.openType == BDPViewControllerOpenTypePush && ![self.navigationController isKindOfClass:[BDPRootNavigationController class]]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
    }
    // 兜底逻辑，防止首次加载时viewDidLoad中设置uniqueID.window失效
    if (!self.uniqueID.window) {
        self.uniqueID.window = self.view.window;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    BDPLogInfo(@"viewWillDisappear, id=%@", self.uniqueID);
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    [self restoreOriginStatus];
    // 侧滑返回优化：防止进小程序二级页面有概率侧滑直接退出了小程序App
    if (self.openType == BDPViewControllerOpenTypePush && ![self.navigationController isKindOfClass:[BDPRootNavigationController class]]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = (id)self.navigationController;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    BDPLogInfo(@"viewDidDisappear, id=%@", self.uniqueID);
    [super viewDidDisappear:animated];
    self.containerControllerHasAppeared = NO;
    [self applicationActiveChange:NO];
    [self downgradeWorkerIfNeeded];
}

-(void)downgradeWorkerIfNeeded{
    if (!self.isFirstDisappear) {
        return ;
    }
    self.isFirstDisappear = NO;
    if(![EEFeatureGating boolValueForKey:@"gadget.worker.upgrade.priority"]){
        return ;
    }
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    if (!task || !task.context) {
        BDPLogInfo(@"[thread] task or worker is empty");
    }
    [task.context dispatchAsyncInJSContextThread:^{
        if (qos_class_self() == QOS_CLASS_USER_INTERACTIVE) {
            pthread_set_qos_class_self_np(QOS_CLASS_DEFAULT, 0);
            BDPLogInfo(@"[thread] worker downgrade to QOS_CLASS_DEFAULT");
        }
    }];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self layoutLoadingView];
    [self layoutToolBarView];

    // 转屏时如果内外ViewController屏幕方向不一致可能导致布局异常
    // 转屏时View.Size计算方式见：https://stackoverflow.com/questions/25731676/child-viewcontroller-height-zero-after-rotation-ios
    self.subNavi.view.frame = self.view.bounds;
}

#pragma mark - Foreground/Background
/*------------------------------------------*/
//     Foreground/Background - 前后台切换
/*------------------------------------------*/
- (void)applicationActiveChange:(BOOL)isActive
{
    // 进入后台
    BOOL canBeActive = [self canBeActive];
    BDPLogTagInfo(@"ContainerActive", @"applicationActiveChange, id=%@, isEnterBackground=%@, isActive=%@, canBeActive=%@", self.uniqueID, @(self.isEnterBackground), @(isActive), @(canBeActive));
    if (!self.isEnterBackground && !isActive) {
        BDPLogTagInfo(@"ContainerActive", @"onAppEnterBackground");
        [self onAppEnterBackground];
        self.isEnterBackground = YES;
        [self.launchTimingEvent stop];
        self.loadDurationShouldClear = YES;
        [self.schema updateRefererInfoDictionary:@{}];  // refererInfo表示当次启动时的跳转参数，从后台热启动时无跳转来源，应清空此字段
        
    // 进入前台
    } else if (self.isEnterBackground && isActive && canBeActive) {
        BDPLogTagInfo(@"ContainerActive", @"onAppEnterForeground");
        [self onAppEnterForeground];
        self.isEnterBackground = NO;
        [self.launchTimingEvent start];
        self.usageTimingEvent = [[BDPTrackerTimingEvent alloc] init];
    } else {
        BDPLogTagInfo(@"ContainerActive", @"applicationActiveChange but no action, id=%@, isEnterBackground=%@, isActive=%@, canBeActive=%@", self.uniqueID, @(self.isEnterBackground), @(isActive), @(canBeActive));
    }
}

/// 判断是否应当切回 active 状态的逻辑，逻辑不太好且命名不太好，逻辑不健壮，未充分考虑存在 present 情况，建议条件允许的情况下仔细梳理各种复杂场景下的处理
- (BOOL)canBeActive
{
    // 走新的简化的判断逻辑,直接判断当前Lark是否active以及当前小程序是否appeared
    BOOL isActive = self.containerControllerHasAppeared && self.applicationIsActive;
    BDPLogTagInfo(@"ContainerActive", @"canBeActiveFix %@", @(isActive));
    return isActive;
}

// 子类复写 - 小程序进入前台
- (void)onAppEnterForeground
{
    BDPLogInfo(@"onAppEnterForeground, id=%@", self.uniqueID);

    WeakSelf;
    [BDPMemoryMonitor registerMemoryWarningTimerWithUniqueID:self.uniqueID warningBlock:^{
        StrongSelfIfNilReturn
        [self memoryWarningAction];
    } killBlock:^{
        StrongSelfIfNilReturn
        [self memoryKillAction];
    }];
    
    BDPMonitorLoadTimelineDateTime(@"enter_foreground", nil, [NSDate date], [[NSProcessInfo processInfo] systemUptime] * 1000.0, self.uniqueID);
}

// 子类复写 - 小程序进入后台
- (void)onAppEnterBackground
{
    BDPMonitorLoadTimelineDateTime(@"enter_background", nil, [NSDate date], [[NSProcessInfo processInfo] systemUptime] * 1000.0, self.uniqueID);
}


#pragma mark - Cold Boot
/*------------------------------------------*/
//            Cold Boot - 冷启动
/*------------------------------------------*/

/// 尝试加载vdom数据,  返回YES 表示加载了Vdom， 返回 NO 表示没有加载Vdom
/// @param localModel 本地已经缓存的model， 已经缓存的vdom可以为空。
- (BOOL)loadVdomWithModel:(nullable BDPModel *)localModel
{
    // 如果有vdom，需要先加载一个vdom
    // 因为model 有可能异步返回，所以当common task subNavi已经创建的时候就不需要再加载vdom了。
    if (self.launchParam.vdom && !BDPCurrentCommon && !BDPCurrentTask && !self.subNavi) {
        // 如果本地没有缓存，或者本地的缓存和vdom的版本相等，再或者是local_dev的版本，那么就使用vdom加载
        if (!localModel || localModel.version_code == [self.launchParam.vdom bdp_intValueForKey:@"version_code"]) {
            // 先创建一个空的 common 和 task。
            BDPCommon *common = [[BDPCommon alloc] initWithSchema:self.schema uniqueID:self.uniqueID];
            [[BDPCommonManager sharedManager] addCommon:common uniqueID:self.uniqueID];
            
            BDPTask *task = [[BDPTask alloc] initWithSchema:self.schema
                                                   uniqueId:self.uniqueID
                                                containerVC:self
                                           containerContext:self.containerContext];
            [[BDPTaskManager sharedManager] addTask:task uniqueID:self.uniqueID];
            
            BDPNavigationController *subNavi = [[BDPNavigationController alloc] initWithRootViewController:[self childRootViewController] barBackgroundHidden:NO containerContext:self.containerContext];
            if ([self setupChildViewController:subNavi]) {
                self.subNavi = subNavi;
            }
            return YES;
        } else {
            self.launchParam.vdom = nil;
        }
    }
    return NO;
}

// 装载ChildViewController
- (BOOL)setupChildViewController:(UIViewController *)childVC
{
    BDPLogInfo(@"setupChildViewController, id=%@", self.uniqueID);
    if (!childVC) {
        BDPLogWarn(@"!childVC");
        return NO;
    }
    
    // 2019-6-28 测试版小游戏加载慢改为loading界面提示，小程序不改动。(监控BaseContainerController中subNavi的push和pop事件,以便处理存在"LoadingView"时的route处理)
    if ([childVC isKindOfClass:[BDPNavigationController class]]) {
        ((BDPNavigationController *)childVC).navigationRouteDelegate = self;
    }
    // 修复审批小程序过早调用getSystemInfo接口获取windowSize导致布局异常的问题
    if ([childVC isKindOfClass:[BDPNavigationController class]]) {
        BDPAppPageController *appVC = [BDPAppController currentAppPageController:childVC fixForPopover:false];
        [appVC updateViewControllerStyle:NO];
    }
    // tt.onWindowResize API 监听 windowSize 变化
    if ([childVC isKindOfClass:[BDPNavigationController class]]) {
        [self observeWindowResize:((BDPNavigationController *)childVC)];
    }

    [self addChildViewController:childVC];
    [self.view insertSubview:childVC.view atIndex:0];       // ChildViewController - ViewDidLoad
    [childVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    return YES;
}

// 子类复写 - 检测小程序model状态
- (BOOL)checkModelStatus:(BDPModel *)model isAsyncUpdate:(BOOL)isAsyncUpdate
{
    BDPLogInfo(@"checkModelStatus start, id=%@, model=%@", self.uniqueID, model);
    // 加载失败 - 小程序被下架
    if (model.state == BDPAppStatusDisable) {
        if (![OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
        [self eventMpLoadResult:GDMonitorCodeLaunch.offline
                         errMsg:@"This App has Offline."
                    extraParams:nil];
        self.loadResultType = GDMonitorCodeLaunch.offline;
        }
        self.removePkgBitMask |= BDPRemovePkgFromOffline; // 下线标记清除
        BDPLogInfo(@"checkModelStatus This App has Offline, id=%@, ", self.uniqueID);
        return NO;
    }
    
    //以下判定仅在正常加载的时候触发,异步更新不检查.
    if (isAsyncUpdate == NO) {
        // 加载失败 - 当前用户无权限访问小程序
        if (model.versionState == BDPAppVersionStatusNoPermission) {
            if (![OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
            [self eventMpLoadResult:GDMonitorCodeLaunch.no_permission
                             errMsg:@"No Access Permission for This App."
                        extraParams:nil];
            self.loadResultType = GDMonitorCodeLaunch.no_permission;
            }
            BDPLogInfo(@"checkModelStatus No Access Permission for This App, id=%@, ", self.uniqueID);
            return NO;
        }
        
        // 加载失败 - 小程序不支持当前宿主环境
        if (model.versionState == BDPAppVersionStatusIncompatible) {
            if (![OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
            [self eventMpLoadResult:GDMonitorCodeLaunch.incompatible
                             errMsg:@"This App Version Incompatible."
                        extraParams:nil];
            self.loadResultType = GDMonitorCodeLaunch.incompatible;
            }
            BDPLogInfo(@"checkModelStatus This App Version Incompatible, id=%@, ", self.uniqueID);
            return NO;
        }

        // 加载失败 - 预览版二维码已过期（二维码有效期1d）
        if (model.versionState == BDPAppVersionStatusPreviewExpired) {
            if (![OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
            [self eventMpLoadResult:GDMonitorCodeLaunch.preview_expired
                             errMsg:@"This qr code is expired."
                        extraParams:nil];
            self.loadResultType = GDMonitorCodeLaunch.preview_expired;
            }
            BDPLogInfo(@"checkModelStatus This qr code is expired, id=%@, ", self.uniqueID);
            return NO;
        }
    } else if (model.versionState == BDPAppVersionStatusNoPermission
               || model.versionState == BDPAppVersionStatusIncompatible
               || model.versionState == BDPAppVersionStatusPreviewExpired) {
        // 异步更新, 且versionState 非Normal的, 退出时移除缓存, 下次走正常加载流程, 重新请求meta
        self.removePkgBitMask |= BDPRemovePkgFromVersionStateAbnormal;
        BDPLogInfo(@"checkModelStatus BDPRemovePkgFromVersionStateAbnormal, id=%@, ", self.uniqueID);
        return NO;
    }

    if (!([BDPDeviceManager infoPlistSupportedInterfaceOrientationsMask] & UIInterfaceOrientationMaskPortrait)) {
        if (![OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
        [self eventMpLoadResult:GDMonitorCodeLaunch.orientation_portrait_unsupport
                         errMsg:@"App/Game orientation portrait is not supported"
                    extraParams:nil];
        self.loadResultType = GDMonitorCodeLaunch.orientation_portrait_unsupport;
        }
        BDPLogInfo(@"checkModelStatus App/Game orientation portrait is not supported, id=%@, ", self.uniqueID);
        return NO;
    }
    
    // 加载失败 - JSSDK版本过低
    if (![self isH5Version:model]) {
        if ([OPSDKFeatureGating gadgetCheckMinLarkVersion]
            && model.uniqueID.appType == OPAppTypeGadget
            && [BDPVersionManager isValidLarkVersion:model.minLarkVersion]
            && [BDPVersionManager isValidLocalLarkVersion]) {
            BDPLogInfo(@"[MinLarkVersion] check min lark version %@", model.minLarkVersion);
            // 加载失败 -lark应用版本过低
            if ([BDPVersionManager isLocalLarkVersionLowerThanVersion:model.minLarkVersion]) {
                BDPLogWarn(@"[MinLarkVersion] lark version lower than model: %@", model.minLarkVersion);
                return NO;
            }
        } else {
            if ([BDPVersionManager isLocalSdkLowerThanVersion:model.minJSsdkVersion]) {
                //阻塞当前线程，进行JSSDK强制更新，同时设置时时间，防止阻塞
                //ATTENTION：forceJSSDKUpdateWaitUntilCompeteOrTimeout 强制触发jssdk同步更新流程
                BOOL isSuccess = [[BDPJSSDKForceUpdateManager sharedInstance] forceJSSDKUpdateWaitUntilCompeteOrTimeout];
                //若更新完成且再次检查JSSDK版本时，仍小于minJSDKVersion，或同步强制更新结果返回超时
                //则继续走默认流程，记录报错信息
                if((isSuccess&&[BDPVersionManager isLocalSdkLowerThanVersion:model.minJSsdkVersion]) || !isSuccess){
                    if (![OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
                        [self eventMpLoadResult:GDMonitorCodeLaunch.jssdk_old
                                         errMsg:@"SDK Version is too old."
                                    extraParams:nil];
                        self.loadResultType = GDMonitorCodeLaunch.jssdk_old;
                    }
                    BDPLogInfo(@"checkModelStatus SDK Version is too old, id=%@, ", self.uniqueID);
                    return NO;
                }
            }
        }
    }
   BDPLogInfo(@"checkModelStatus success, id=%@, ", self.uniqueID);
    return YES;
}

// 子类复写 - 冷启动完毕时
- (void)excuteColdBootDone
{
    return;
}

// 子类复写 - 冷启动装载RootVC
- (UIViewController<BDPWarmBootCleanerProtocol> *)childRootViewController
{
    return nil;
}

// 子类复写 - 判断设备是否在黑名单
- (BOOL)checkDeviceAvailable
{
    return YES;
}

// 子类复写 - 检测环境是否可以正常加载小程序/小游戏
- (BOOL)checkEnvironmentAvailable
{
    return YES;
}

// 子类调用 - 准备完毕状态，由子VC向父类调用
// TODO: 即将删除的代码
- (void)becomeReadyStatus
{
}

- (void)firstFrameDidShow {
    if (![[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID].isReady) {
        return; // 双Ready与首帧分开后, 会先调用becomeReadyStatus再调用firstFrameDidShow. 如果becomeReadyStatus没Ok, 就不必走了
    }
    // BDPTask的重要事务开始处理, 开启性能监控、互跳小程序meta预请求
    [BDPTaskFromUniqueID(self.uniqueID) doImportantOperations];
    
    // 前台使用时间，剔除冷启动加载时长
    [self.usageTimingEvent reStart];
    
    [self eventDomReady];
    [self eventMPFirstContentSuccess];
    
    BDPType type = [self type];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [BDPTimorClient updatePreloadFrom:@"first_frame_did_show"];
        [[BDPJSRuntimePreloadManager sharedManager] preloadRuntimeIfNeed:type];
        [[BDPAppPageFactory sharedManager] tryPreloadAppPage];
        [[BDPAppPageFactory sharedManager] tryPreloadPrecessPool];
    });

    BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
    BDPLogTagInfo(@"LifeCycle", @"bdp_onFirstFrameRender %@", self.uniqueID);
    if ([lifeCyclePlugin respondsToSelector:@selector(bdp_onFirstFrameRender:)]) {
        [lifeCyclePlugin bdp_onFirstFrameRender:self.uniqueID];
    }
    //发送“应用内通知”的请求
    
    /*
    [[OPNoticeManager sharedManager] requsetNoticeModelForUniqueID:self.uniqueID];
        */
    // 仅做无逻辑改动的重构，使得OPNoticeManager和小程序解除耦合，使得Web可以复用
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    if(!common){
        BDPLogError(@"current common is nil, don't request for notice");
        return ;
    }
    WeakSelf;
    [OPNoticeManager.sharedManager requsetNoticeModelForAppID:self.uniqueID.appID context:common callback:^(OPNoticeModel * model) {
        StrongSelfIfNilReturn;
        BDPAppPageController *topVC = [self getTopAppPageControllerForUniqueID:self.uniqueID];
        if(!topVC){
            return ;
        }
        [topVC setupNoticeViewWithModel:model];
    }];


}
// code from chenmengqi
-(BDPAppPageController *)getTopAppPageControllerForUniqueID:(BDPUniqueID *)uniqueID{
    __weak BDPTask *task = BDPTaskFromUniqueID(uniqueID);
    __weak BDPAppContainerController *containerVC = (BDPAppContainerController *)task.containerVC;
    BDPAppPageController *appVC = [containerVC.appController currentAppPage];
    return appVC;
}

#pragma mark - Warm Boot
/*------------------------------------------*/
//            Warm Boot - 热启动
/*------------------------------------------*/
- (BOOL)excuteWarmBoot
{
    return NO;
}

// TODO: 即将删除的代码
/**
 从小游戏打开主端的界面，又从主端的界面打开这个小游戏，PM要求原路返回，回来的时候执行热启动。
 */
- (void)excuteWarmBootV2
{

}

// TODO: 即将删除的代码
// 子类复写 - 热启动完毕时
- (void)excuteWarmBootDone
{
}

// 子类复写 - Task准备完成时
- (void)setupTaskDone
{
}

- (void)updateSchema:(BDPSchema *)schema
{
}

// TODO: 即将删除的代码
- (void)loadDoneWithError:(NSError *)error
{
}

#pragma mark - onAppLaunch
/*-----------------------------------------------*/
//              onAppLaunch - 启动消息
/*-----------------------------------------------*/
- (void)onAppLaunch
{
}

#pragma mark - ContainerVC Update
/*-----------------------------------------------*/
//         ContainerVC Update - 容器更新
/*-----------------------------------------------*/
- (void)updateContainerVC
{
    [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID].containerVC = self;
}

#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
- (void)setupObserveNoification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:kBDPInterruptionNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLoadErrorNotification:)
                                                 name:kBDPDataLoadErrorNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hideLoadingViewFromNotification)
                                                 name:kBDPSnapshotRenderReadyNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSignificantTimeChangedNotif:)
                                                 name:NSSystemTimeZoneDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSignificantTimeChangedNotif:)
                                                 name:UIApplicationSignificantTimeChangeNotification
                                               object:nil];
    [self addTakeScreenShotObserverIfNeeded];
}

- (void)handleSignificantTimeChangedNotif:(NSNotification *)notif {
    NSNumber *reason = nil;
    if ([notif.name isEqualToString:NSSystemTimeZoneDidChangeNotification]) {
        reason = @1;
    }
    BDPMonitorLoadTimelineDateTime(@"throw_exception_log", @{@"reason": reason ?: @3}, [NSDate date], [[NSProcessInfo processInfo] systemUptime], self.uniqueID);
}

- (void)handleInterruption:(NSNotification *)notification
{
    // Get Audio Status
    BOOL isInterrupted = [notification.userInfo bdp_boolValueForKey:kBDPInterruptionStatusUserInfoKey];
    if (isInterrupted) {
        self.applicationIsActive = NO;
        [self applicationActiveChange:NO];
    } else {
        self.applicationIsActive = YES;
        [self applicationActiveChange:YES];
    }
}

- (void)handleLoadErrorNotification:(NSNotification *)note
{
}

- (void)postExitNotification
{
    BDPLogInfo(@"postExitNotification, id=%@", self.uniqueID);
    //Post Notification
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    NSString *mpType = BDPTrackerApp ;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:7];
    [dict setValue:common.uniqueID.appID forKey:@"mp_id"];
    [dict setValue:common.model.name forKey:@"mp_name"];
    [dict setValue:common.model.icon forKey:@"mp_icon"];
    [dict setValue:mpType forKey:@"mp_type"];
    [dict setValue:self.launchFrom forKey:kBDPExitBotificationLaunchFromKey];
    [dict setValue:@(self.willReboot) forKey:kBDPExitNotificationIsRebootKey];
    [dict setValue:self.uniqueID forKey:@"uniqueID"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDPExitNotification
                                                        object:nil
                                                      userInfo:[dict copy]];
}

- (void)postEnterNotification
{
    BDPLogInfo(@"postEnterNotification, id=%@", self.uniqueID);
    //Post Notification
    NSString *mpType = BDPTrackerApp;
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:4];
    [dict setValue:self.uniqueID.appID forKey:@"mp_id"];
    [dict setValue:mpType forKey:@"mp_type"];
    [dict setValue:self.launchFrom forKey:@"launch_from"];
    [dict setValue:self.uniqueID forKey:@"uniqueID"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kBDPEnterNotification
                                                        object:nil
                                                      userInfo:[dict copy]];
}

#pragma mark - Loading View
/*------------------------------------------*/
//          Loading View - 加载页面
/*------------------------------------------*/
// TODO: Loading 所有相关逻辑都要迁移
- (void)setupLoadingView:(BDPModel *)model
{
    BDPLogInfo(@"setupLoadingView, id=%@", self.uniqueID);
    if (!self.loadingView) {
        self.loadingView = [[BDPLoadingView alloc] initWithFrame:self.view.bounds type:[self type] delegate:self uniqueID:self.uniqueID];
        [self.loadingView checkIfNeedCustomLoadingStyleWithUniqueID:self.uniqueID];
        if (!model) {
            // 2019-3-17 Schema优化对齐Android对meta的使用
            model = [BDPModel fakeModelWithUniqueID:self.uniqueID name:nil icon:nil urls:nil];
        }
        [self updateLoadingViewModel:model];
    }
    [self startLoadingViewAnimation];
    [self.view insertSubview:self.loadingView belowSubview:self.toolBarView];
//    [self.view addSubview:self.loadingView];
}

- (void)hideLoadingViewFromNotification
{
    // 当vdom渲染好的时候，如果加载没有失败，就关闭loadingview
    // 如果加载已经失败了，则还是继续显示加载失败的loadingview，盖住vdom界面
//    if (self.loadResultType == GDMonitorCodeLaunch.unknown_error) {
    self.loadingView.hidden = YES;
    [self hideLoadingView:YES];
//    }
    // 释放self.launchParam 释放内存，后续也没有什么用了
//    self.launchParam.vdom = nil;
}

- (void)hideLoadingView:(BOOL)hideToolBar
{
    BDPLogInfo(@"hideLoadingView, id=%@", self.uniqueID);
    self.subNavi.view.alpha = 1.0;
    self.loadingView.alpha = 1.0;
    self.toolBarView.ready = YES;
    //因为toolBar的创建内移到了每个APPPageVC或GameVC自己创建，因此下线下架等loadFail的提示页不能隐藏掉BaseContainerVC的toolBar。
    
    BOOL needHideToolBar = (self.subNavi != nil);
    NSTimeInterval loadingViewDismissAnimationDuration = BDPTimorClient.sharedClient.appearanceConfg.loadingViewDismissAnimationDuration;
    [UIView animateWithDuration:loadingViewDismissAnimationDuration animations:^{
        self.loadingView.alpha = 0.0;
        if (hideToolBar && needHideToolBar) {
            self.toolBarView.alpha = 0.0;
        }
        self.subNavi.view.alpha = 1.0;
        [self.toolBarView setToolBarStyle:self.toolBarView.toolBarStyle];
    } completion:^(BOOL finished) {
        if (hideToolBar && needHideToolBar) {
            [self.toolBarView removeFromSuperview];
        }
        [self.loadingView removeFromSuperview];
        //        self.toolBarView = nil;  //这个暂时还不能清空，因为 getMenuButtonBoundingClientRect 接口还需要，这个稍后优化一下。
        [self stopLoadingViewAnimation];
    }];
}

- (void)startLoadingViewAnimation
{
    [self.loadingView startLoading];
    [self.loadingView setAlpha:1.0];
}

- (void)stopLoadingViewAnimation
{
    [self.loadingView stopLoading];
}

- (void)layoutLoadingView
{
    self.loadingView.frame = self.view.bounds;
    [self.loadingView setNeedsLayout];
    [self.loadingView layoutIfNeeded];
}

- (void)updateLoadingViewModel:(BDPModel *)model
{
    [self.loadingView updateAppModel:model];
}

- (void)updateLoadingViewPercent:(CGFloat)percent
{
    percent = fmax(0.f, fmin(percent, 1.f));
    BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
    if ([lifeCyclePlugin respondsToSelector:@selector(bdp_onLoading:progress:)]) {
        [lifeCyclePlugin bdp_onLoading:self.uniqueID progress:percent];
    }
    [self.loadingView updateLoadPercent:percent];
}

- (void)updateLoadingViewFailState:(BDPLoadingViewState)state withInfo:(NSString *)info
{
    if (state == BDPLoadingViewStateSlow || state == BDPLoadingViewStateSlowDebug) {
        // 加载过慢
        if (self.loadingView.state == BDPLoadingViewStateFail || self.loadingView.state == BDPLoadingViewStateFailReload) {
            return;
        }
        
        if (state == BDPLoadingViewStateSlowDebug) {
            BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
            BOOL isOpen = [[common.sandbox.privateStorage objectForKey:kBDPDebugVConsoleSwitchKey] boolValue];
            state = isOpen ? BDPLoadingViewStateSlow : BDPLoadingViewStateSlowDebug;
        }
        
        [self forcedEnableMoreMenu:YES];
        [self.loadingView changeToFailState:state withTipInfo:info];
    } else {
        [self forcedEnableMoreMenu:NO];
        [self.loadingView changeToFailState:state withTipInfo:info];
        
        if (BDPTimorClient.sharedClient.appearanceConfg.hideAppWhenLaunchError) {
            [self dismissSelf:GDMonitorCode.auto_dismiss_when_load_failed]; // Lark 定制：启动失败时直接退出小程序，并Toast提示
        }
    }
}

#pragma mark - BDPLoadingViewDelegate
// TODO: 即将删除的代码，需要再 Loading View 中补回
- (void)bdpLoadingViewReloadActionImmediately:(BOOL)immediately
{
    if (immediately) {
        [self forceReboot:GDMonitorCode.loading_view_reload];
    } else {
        [self dismissSelf:GDMonitorCode.loading_view_reload];
    }
}

// TODO: Loading View 需要处理
- (void)bdpLoadingViewDebugAction
{
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    BOOL isOpen = [[common.sandbox.privateStorage objectForKey:kBDPDebugVConsoleSwitchKey] boolValue];
    if (!isOpen) {
        [common.sandbox.privateStorage setObject:@(!isOpen) forKey:kBDPDebugVConsoleSwitchKey];
    }
    [self forceReboot:GDMonitorCode.loading_view_debug];
}

#pragma mark - BDPNavigationControllerRouteProtocol

- (void)navigation:(BDPNavigationController *)navigation didPushViewController:(UIViewController *)vc
{
}

- (void)navigation:(BDPNavigationController *)navigation didPopViewController:(NSArray<UIViewController *> *)vcs willShowViewController:(UIViewController *)vc
{
}


#pragma mark - ToolBar
/*-----------------------------------------------*/
//                ToolBar - 工具栏
/*-----------------------------------------------*/
- (void)setupToolBarView
{
    if (!self.toolBarView) {
        BDPToolBarView *toolBarView = [[BDPToolBarView alloc] initWithUniqueID:self.uniqueID];
        BDPPlugin(loadingViewPlugin, BDPLoadingViewPluginDelegate);
        NSMutableDictionary *config = NSMutableDictionary.dictionary;
        config[kBDPLoadingViewConfigUniqueID] = self.uniqueID;
        // 启动时的ToolBar样式，小程序由loadingViewPlugin决定
        if (self.schema.appType == BDPTypeNativeApp &&
            [loadingViewPlugin respondsToSelector:@selector(bdp_getLoadingViewWithConfig:)] &&
            [loadingViewPlugin bdp_getLoadingViewWithConfig:config]) {
        }
        self.toolBarView = toolBarView;
    }
    self.toolBarView.alpha = 1.0;
    [self.view addSubview:self.toolBarView];
    [self layoutToolBarView];
}

- (void)layoutToolBarView
{
    // iPad采取竖屏布局方式
    BOOL isLandscape = !([BDPDeviceHelper isPadDevice]) && UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]);

    if ([OPSDKFeatureGating gadgetUseStatusBarOrientation]) {
        // 这边使用UIApplication的statuBarOrientation替换UIDevice的方向
        // 小程序预期获取的是界面是否为横屏
        isLandscape = ![OPGadgetRotationHelper isPad] && [OPGadgetRotationHelper isLandscape];
    }

    CGFloat safeAreaTop = [BDPResponderHelper safeAreaInsets:self.view.window?:self.uniqueID.window].top;
    CGFloat adaptTop = isLandscape ? 15 : safeAreaTop == 0 ? 26 : safeAreaTop;
    
    self.toolBarView.frame = CGRectMake(self.view.bdp_width - self.toolBarView.bdp_width - 6, adaptTop, self.toolBarView.bdp_width, self.toolBarView.bdp_height);
    [self.toolBarView setNeedsLayout];
    [self.toolBarView layoutIfNeeded];
}

- (void)forcedEnableMoreMenu:(BOOL)enable
{
    if (self.toolBarView) {
        [self.toolBarView setForcedMoreEnable:enable];
    }
}

// 子类复写 - 工具栏“更多”菜单增加自定义选项
- (void)setToolBarMoreButtonCustomMenu:(NSMutableArray<BDPMorePanelItem *> *)items;
{
    return;
}

#pragma mark - Loading Result Process
/*------------------------------------------*/
//   Loading Result Process - 加载结果处理
/*------------------------------------------*/
- (void)setLoadResultType:(OPMonitorCode *)loadResultType
{
}

// TODO: 处理启动失败的逻辑全部要迁移
// 这块代码太乱了，还要需要进一步再整一整
- (void)handleLoadFailedWithCode:(OPMonitorCode *)code error:(NSError *)error useAlert:(BOOL)useAlert {
}

#pragma mark - White Board
/*------------------------------------------*/
//          White Board - 提示白板
/*------------------------------------------*/
// TODO: 全部合入 Loading 模块
- (void)showWhiteBoard:(OPMonitorCode *)loadResultType
{
}

#pragma mark - StatusBar
/*------------------------------------------*/
//            StatusBar - 状态栏
/*------------------------------------------*/
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.subNavi preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    // 由于状态栏隐藏容易导致布局Bug，因此将状态栏控制方式改为KVC形式设置透明度，动画及效果比较完美，曲线救国😂
    // 每个子VC的[prefersStatusBarHidden]都会被BDPNavigationController触发并根据返回值设置状态栏透明度
    // 为保证上述过程不受外部影响，此处必须返回NO
    // 状态栏隐藏/显示
    BOOL isVCBaseStatusBar = NO;
    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"]) {
        isVCBaseStatusBar = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] boolValue];
    }
    
    if (!isVCBaseStatusBar && [BDPDeviceHelper OSVersionNumber] < 13.f) {
        return NO;
    }
    
    return [self.subNavi prefersStatusBarHidden];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.subNavi preferredStatusBarUpdateAnimation];
}

#pragma mark - Orientation & WindowResize
/*------------------------------------------*/
//    Orientation - 屏幕旋转 & WindowResize
/*------------------------------------------*/
- (BOOL)shouldAutorotate
{
    return [self.subNavi shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (self.isAdaptingOrientation) {
        return UIInterfaceOrientationMaskPortrait;
    }
    if (self.subNavi) {
        return [self.subNavi supportedInterfaceOrientations];
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)observeWindowResize:(BDPNavigationController *)subNavi {
    BDPUniqueID *uniqueID = self.uniqueID;
    [subNavi.KVOController unobserve:subNavi.view keyPath:@"frame"];
    __weak typeof(subNavi) weakSubNavi = subNavi;
    WeakSelf;
    [subNavi.KVOController observe:subNavi.view
                           keyPath:@"frame"
                           options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                             block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        __strong typeof(weakSubNavi) subNavi = weakSubNavi;
        BDPResolveModule(container, BDPContainerModuleProtocol, BDPTypeNativeApp)
        if (CGSizeEqualToSize(subNavi.windowSize, CGSizeZero)) {
            subNavi.windowSize = [container containerSize:subNavi type:BDPTypeNativeApp uniqueID:uniqueID];   // 初始化 windowSize
            return;
        }
        NSValue *oldFrameValue = change[NSKeyValueChangeOldKey];
        NSValue *newFrameValue = change[NSKeyValueChangeNewKey];
        CGSize oldSize = oldFrameValue.CGRectValue.size;
        CGSize newSize = newFrameValue.CGRectValue.size;
        if (!CGSizeEqualToSize(oldSize, newSize)) {
            CGSize windowSize = [container containerSize:subNavi type:BDPTypeNativeApp uniqueID:uniqueID];
            if (!CGSizeEqualToSize(subNavi.windowSize, windowSize)) {
                subNavi.windowSize = windowSize;
                BDPJSBridgeEngine engine = nil;
                BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
                StrongSelfIfNilReturn;
                if ([self isH5Version:common.model]) {
                } else {
                    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
                    engine = task.context;
                }
                if ([engine respondsToSelector:@selector(bdp_fireEvent:sourceID:data:)]) {
                    if ([OPGadgetRotationHelper enableGadgdetRotation:self.uniqueID]) {
                        BDPAppPageController *pageController = [self getTopAppPageControllerForUniqueID:self.uniqueID];
                        CGSize screenSize = UIScreen.mainScreen.bounds.size;
                        NSDictionary *data = @{
                            @"size" : @{
                                @"windowWidth" : @(windowSize.width),
                                @"windowHeight": @(windowSize.height),
                                @"screenWidth" : @(screenSize.width),
                                @"screenHeight": @(screenSize.height)
                            },
                            @"pageOrientation" : [OPGadgetRotationHelper configPageInterfaceResponse:pageController.pageInterfaceOrientation]
                        };

                        [engine bdp_fireEvent:@"onWindowResize"
                                     sourceID:NSNotFound
                                         data:data];
                    } else {
                        CGSize screenSize = UIScreen.mainScreen.bounds.size;
                        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithDictionary:@{
                            @"size" : @{
                                @"windowWidth" : @(windowSize.width),
                                @"windowHeight": @(windowSize.height),
                                @"screenWidth" : @(screenSize.width),
                                @"screenHeight": @(screenSize.height)
                            },
                            @"pageOrientation" : @"portrait"
                        }];

                        // iPad上方向的定义与iPhone有所不同.因为iPad支持左右拖动.因此这个字段在iPad上不返回.
                        if (OPGadgetRotationHelper.isPad) {
                            [data removeObjectForKey:@"pageOrientation"];
                        }

                        [engine bdp_fireEvent:@"onWindowResize"
                                     sourceID:NSNotFound
                                         data:data];
                    }
                }

            }
        }
    }];
}

#pragma mark - Event Track
/*-----------------------------------------------*/
//             Event Track - 埋点相关
/*-----------------------------------------------*/
- (void)setTrackerCommonParams:(NSDictionary *)extraParams
{
    NSDictionary *params = [self buildTrackerParams:extraParams];
    [BDPTracker setCommonParams:params forUniqueID:self.uniqueID];
}

- (NSDictionary *)buildTrackerParams:(NSDictionary *)extraParams
{
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    
    NSString *specialParam = BDPTrackerApp;
    NSString *localLibVersion = [BDPVersionManager localLibVersionString];
    NSString *localSDKVersion = [BDPVersionManager localSDKVersionString];
    NSString *localLibGreyHash = [BDPVersionManager localLibGreyHash];
//    NSString *mpName = common.model.name ?: [[self.schema name] copy];
//    NSString *bdpLog = [self.schema.bdpLog copy];
    NSDictionary *sceneParams = [BDPApplicationManager getOnAppEnterForegroundParams:self.schema];
    NSString *scene = [sceneParams bdp_stringValueForKey:@"scene"];
    NSString *subScene = [sceneParams bdp_stringValueForKey:@"subScene"];
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    //2019-3-27这里做一下优化，将RecommendParams设置时机提前，防止包含同名埋点时SDK本身的埋点信息被覆盖掉
    [self addRecommendParamsIfNeeded:params];
    
    [params setValue:self.uniqueID.appID forKey:BDPTrackerAppIDKey];
    [params setValue:self.uniqueID.appID forKey:BDPTrackerApplicationIDKey]; // Lark埋点公参治理，新增key： https://bytedance.feishu.cn/wiki/wikcnYAaVu1taJMtZmqS954fPjh?sheet=qNDYFb
    [params setValue:OPAppTypeToString(self.uniqueID.appType) forKey:BDPTrackerAppTypeKey];
    [params setValue:OPAppVersionTypeToString(self.uniqueID.versionType) forKey:BDPTrackerVersionTypeKey];
    [params setValue:self.uniqueID.identifier forKey:BDPTrackerIdentifierKey];
    
    [params setValue:self.launchFrom forKey:BDPTrackerLaunchFromKey];
    [params setValue:specialParam forKey:BDPTrackerParamSpecialKey];
    [params setValue:localLibVersion forKey:BDPTrackerLibVersionKey];
    [params setValue:localLibGreyHash forKey:BDPTrackerLibGreyHashKey];
    [params setValue:@"" forKey:BDPTrackerJSEngineVersion];
    [params setValue:localSDKVersion forKey:BDPTrackerSDKVersionKey];
    [params setValue:@"none" forKey:BDPTrackerSolutionIdKey];
//    [params setValue:mpName forKey:BDPTrackerMPNameKey];
//    [params setValue:self.schema.location forKey:BDPTrackerLocationKey];
//    [params setValue:self.schema.bizLocation forKey:BDPTrackerBizLocationKey];
    if (([self.launchFrom isEqualToString:@"in_mp"] || [self.launchFrom isEqualToString:@"back_mp"])) {
        id refererInfoObject = self.schema.refererInfoDictionary;
        if ([refererInfoObject isKindOfClass:[NSDictionary class]]) {
            NSString *referAppId = refererInfoObject[@"appId"];
            BDPIsEmptyString(referAppId)? : [params setValue:referAppId forKey:BDPTrackerBizLocationKey];
        }
    }
//    [params setValue:bdpLog forKey:BDPTrackerBDPLogKey];
    [params setValue:scene forKey:BDPTrackerSceneKey];
    [params setValue:scene forKey:BDPTrackerSceneTypeKey];  // Lark埋点公参治理，新增key： https://bytedance.feishu.cn/wiki/wikcnYAaVu1taJMtZmqS954fPjh?sheet=qNDYFb
    [params setValue:subScene forKey:BDPTrackerSubSceneKey];
    
    if (!BDPIsEmptyDictionary(extraParams)) {
        [params addEntriesFromDictionary:extraParams];
    }
    return params;
}

- (NSMutableDictionary *)addRecommendParamsIfNeeded:(NSMutableDictionary *)params
{
//    NSString *mp_gid = [self.schema ttid];
//    [params setValue:mp_gid forKey:BDPTrackerMPGIDKey];
    NSDictionary *eventExtra = [self.schema dictionaryValueFromExtraForKey:@"event_extra"];
    if (!BDPIsEmptyDictionary(eventExtra)) {
        [params addEntriesFromDictionary:eventExtra];
    }
    return params;
}

- (void)eventMpLoadStart
{
    [BDPTracker beginEvent:BDPTELoadStart primaryKey:BDPTrackerPKLoad attributes:@{@"launch_type":self.schema.launchType?:@""} uniqueID:self.uniqueID];
    [BDPTracker beginEvent:BDPTELaunchStart primaryKey:BDPTrackerPKLaunch attributes:nil reportStart:NO uniqueID:self.uniqueID];
    NSDictionary *initTrackParams = @{
                                      BDPTrackerResultTypeKey: BDPTrackerResultSucc,
                                      BDPTrackerErrorMsgKey: @""
                                      };
    [BDPTracker endEvent:@"mp_init_result" primaryKey:BDPTrackerPKInit attributes:initTrackParams uniqueID:self.uniqueID];
    self.launchTime = CFAbsoluteTimeGetCurrent();
    [BDPTrackerHelper setLoadState:BDPTrackerLSMetaRequesting forUniqueID:self.uniqueID];
}

// TODO: 即将删除，待迁移
- (void)eventMpLoadResult:(OPMonitorCode *)loadResultType errMsg:(NSString *)errMsg extraParams:(NSDictionary *)extraParams
{
}

- (BOOL)hasLaunchingReported {
    // 判断是否已经完成了上报。Container 的生命周期与 Task 的生命周期不完全一致。
    // 存在三种情况：
    // 1. 有Container没Task 2.有Container有Task 3.无Container有Task
    // 因而这里需要有维护两个上报状态才能完成完整记录应用生命周期的监控，好的方案可以是设计一种纯抽象的Task能够完整表达应用的完整生命周期，建议放在小程序架构演进项目中一起考虑重构
    if (_hasLaunchingReported) {
        return YES;
    }
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    return task.hasLaunchingReported;
}

- (void)setHasLaunchingReported:(BOOL)hasLaunchingReported {
    _hasLaunchingReported = hasLaunchingReported;
    BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
    task.hasLaunchingReported = hasLaunchingReported;
}

/// 如果还没有完成启动过程上报，则进行上报
- (void)tryReportLoadResultIfNeeded {

}

- (void)eventMPStartFirstContent
{
    [self performSelector:@selector(eventMPEndFirstContentTimeout:) withObject:@(YES) afterDelay:5.0];

    // 新容器暂时保留这两个埋点(产品用到)
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    NSMutableDictionary *renderParams = [NSMutableDictionary new];
    [renderParams setValue:BDPTrackerResultSucc forKey:BDPTrackerResultTypeKey];
    [renderParams setValue:@"" forKey:BDPTrackerErrorMsgKey];
    // 埋点 - mp_preload_result，小程序渲染第一帧
    [renderParams setValue:task.currentPage.path ?: @"" forKey:BDPTrackerPagePathKey];
    [BDPTracker endEvent:@"mp_preload_result" primaryKey:BDPTrackerPKWebViewRender attributes:renderParams uniqueID:self.uniqueID];

    // 埋点 - mp_launch，启动成功, mp_load_result，加载成功
    NSMutableDictionary *param = [[NSMutableDictionary alloc] initWithCapacity:1];
    [param setValue:@(self.loadTimingEvent.duration) forKey:BDPTrackerDurationKey];
    if (self.schema.originEntrance.length) {
        NSDictionary *entranceInfo = [self.schema.originEntrance JSONValue];
        [param setValue:BDPSafeString([entranceInfo bdp_stringValueForKey:@"oe_launch_from"]) forKey:@"oe_launch_from"];
        [param setValue:BDPSafeString([entranceInfo bdp_stringValueForKey:@"oe_location"]) forKey:@"oe_location"];
    }
    [BDPTracker endEvent:BDPTELaunchEnd primaryKey:BDPTrackerPKLaunch attributes:[param copy] uniqueID:self.uniqueID];
}

- (void)eventMPFirstContentSuccess
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self eventMPEndFirstContentTimeout:@(NO)];
}

- (void)eventMPEndFirstContentTimeout:(NSNumber *)timeout
{
    BOOL isTimeout = [timeout boolValue];
    NSDictionary *params = @{
        @"first_content_result" : isTimeout ? @"timeout" : @"success"
    };
    [BDPTracker event:BDPTELoadFirstContent attributes:params uniqueID:self.uniqueID];
}

- (void)eventMpEntranceClick
{
    [BDPTrackerHelper setLoadState:BDPTrackerLSLoadInit forUniqueID:self.uniqueID];
    self.loadTimingEvent = [[BDPTrackerTimingEvent alloc] init];
    // 埋点 - mp_entrance_click
    [BDPTracker event:@"mp_entrance_click" attributes:nil uniqueID:self.uniqueID];
    
    // 埋点 - mp_click
    if ([self.launchFrom hasPrefix:@"share_"]) {
        [BDPTracker event:@"mp_click" attributes:@{@"position": @"mp_list_special"} uniqueID:self.uniqueID];
    }
    
    // 埋点 - mp_init_result 开始计时
    [BDPTracker beginEvent:@"mp_init_start" primaryKey:BDPTrackerPKInit attributes:nil reportStart:NO uniqueID:self.uniqueID];
    
    self.searchReporter = [BDPSearchEventReporter reporterWithCommonParams:self.schema.gdExtDictionary
                                                                launchFrom:self.launchFrom
                                                                     isApp:self.type == BDPTypeNativeApp];
}

- (void)eventSchemaInfoWithSchema:(BDPSchema *)schema error:(NSError *)error
{
    if (BDPIsEmptyString(schema.originURL.absoluteString)) {
        return;
    }
    
    // 埋点统计schame信息(没有放到BDPSchame内部的原因是考虑BDPSchame可以作为通用工具类使用,只有使用BDPSchame启动小程序时才上报)
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setValue:schema.originURL.absoluteString forKey:@"schema_string"];
    //与Android对齐不上报ErrMsg
//    if (error != nil) {
//        NSString *errorString = [NSString stringWithFormat:@"code:{%ld};userInfo:{%@};", (long)error.code, error.userInfo];
//        [attributes setValue:errorString forKey:BDPTrackerErrorMsgKey];
//    }
    
    if (!BDPIsEmptyDictionary(schema.schemaCodecTrackInfo)) {
        [attributes setValue:[schema.schemaCodecTrackInfo bdp_stringValueForKey:@"launch_from_check"] forKey:@"launch_from_check"];
        [attributes setValue:[schema.schemaCodecTrackInfo bdp_stringValueForKey:@"ttid_check"] forKey:@"ttid_check"];
        [attributes setValue:[schema.schemaCodecTrackInfo bdp_stringValueForKey:@"scene_check"] forKey:@"scene_check"];
        [attributes setValue:[schema.schemaCodecTrackInfo bdp_stringValueForKey:@"bdpsum_check"] forKey:@"bdpsum_check"];
    }
    
    if (!BDPIsEmptyDictionary(attributes)) {
        [BDPTracker event:@"mp_schema_assess" attributes:attributes uniqueID:self.uniqueID];
    }
}

- (void)eventDomReady
{
    BDPTracing *trace = [BDPTracingManager.sharedInstance getTracingByUniqueID:self.uniqueID];
    NSDictionary *params = @{
                             BDPTrackerResultTypeKey: BDPTrackerResultSucc,
                             BDPTrackerErrorMsgKey: @"",
                             BDPTrackerDurationKey: self.loadDurationShouldClear ? @(0) : @(self.launchTimingEvent.duration),
                             BDPTrackerFromAppLaunchStartDurationKey: @([trace clientDurationTagEnd:kEventName_mp_app_launch_start])
    };
    [BDPTracker event:BDPTELoadDomReadyEnd
           attributes:params
 uniqueID:self.uniqueID];
}

#pragma mark - Memory Warning
/*------------------------------------------*/
//          Memory Warning - 内存警告
/*------------------------------------------*/
- (void)memoryKillAction
{
    /// 暂时不kill app。 观察mp_memorywarning_report的log以及数据，与OOM的关系，数据支撑后续的推进。
    BDPLogTagWarn(BDPTag.gadget, @"memoryKillAction. id=%@", self.uniqueID);
    
//    BDPAlertController *alert = [BDPAlertController themedAlertControllerWithTitle:BDPI18n.memory_warning message:BDPI18n.insufficient_remaining_memory preferredStyle:BDPAlertControllerStyleAlert];
//    WeakSelf;
//    [alert addAction:[BDPAlertAction actionWithTitle:BDPI18n.determine style:BDPAlertActionStyleConfirm handler:^(BDPAlertAction * _Nonnull action) {
//        StrongSelfIfNilReturn;
//        BDPLogTagWarn(BDPTag.gadget, @"memoryKillAction forceClose. id=%@", self.uniqueID);
//        [self forceClose:GDMonitorCode.memory_warning_kill];
//    }]];
//    [self presentViewController:alert animated:YES completion:nil];
}

- (void)memoryWarningAction
{
    BDPLogTagWarn(BDPTag.gadget, @"memoryWarningAction. id=%@", self.uniqueID);
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    [task.context bdp_fireEvent:@"onMemoryWarning" sourceID:NSNotFound data:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    BDPLogTagWarn(BDPTag.gadget, @"didReceiveMemoryWarning. id=%@", self.uniqueID);
    [BDPMemoryMonitor didReceiveMemoryWarning];
}

#pragma mark - Force Reboot
/*------------------------------------------*/
//          Force Reboot - 强制重启
/*------------------------------------------*/
- (void)forceReboot:(OPMonitorCode *)code
{
    BDPLogInfo(@"forceReboot, id=%@, code=%@", self.uniqueID, code);
    if ([OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
        [[OPApplicationService.current getContainerWithUniuqeID:self.uniqueID] reloadWithMonitorCode:code?:GDMonitorCode.about_restart];
    } else {
    [self closeAndReboot:YES cleanWarmCache:NO code:code];
    }
}

- (void)forceClose:(OPMonitorCode *)code {
    BDPLogTagInfo(BDPTag.gadget, @"forceClose, id=%@, code=%@", self.uniqueID, code);
    if ([OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
        [[OPApplicationService.current getContainerWithUniuqeID:self.uniqueID] destroyWithMonitorCode:code?:GDMonitorCode.unknown_error];
    } else {
    [self closeAndReboot:NO cleanWarmCache:YES code:code];
    }
}

- (void)forceStopRunning {
    BDPLogTagWarn(BDPTag.gadget, @"forceStopRunning, id=%@", self.uniqueID);
    [self onApplicationExitWithRestoreStatus:YES];
}

- (void)closeAndReboot:(BOOL)reboot cleanWarmCache:(BOOL)cleanWarmCache code:(OPMonitorCode *)code
{
}

// TODO: 没有被用到需要删除
- (void)closeAndClosePresentedVC
{
}

- (void)onApplicationExitWithRestoreStatus:(BOOL)restoreStatus
{
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    common.isActive = NO;
    common.readerOff = YES;
    common.isForeground = NO; // 需设下标志位，防止不能清理热启缓存而重启失败。
    
    [TMACustomHelper hideCustomLoadingToast:self.uniqueID.window];
    [[BDPAudioControlManager sharedManager] decreaseActiveContainer]; // 音频删除活跃实例
    [[BDPStreamingAudioRecorder shareInstance] forceStopRecorder];
    
    [common.reader appContainerWillBeClosed];
    if(OPSDKFeatureGating.enableToCancelAllReadDataCompletionBlks){
        [common.reader cancelAllReadDataCompletionBlks];
    }
    if (restoreStatus) {
        [self restoreOriginStatus];
    }
    [[BDPTracker sharedInstance] flushLoadTimelineWithUniqueId:self.uniqueID];
    
    // 2019-7-12 小程序 or 小游戏 退出的时候预创建下一个JSRuntime
    [self prepareForTheNextApp];
}

- (void)prepareForTheNextApp {
    [BDPTimorClient updatePreloadFrom:@"prepare_next_app"];
    [[BDPJSRuntimePreloadManager sharedManager] preloadRuntimeIfNeed:[self type]];
    [[BDPAppPageFactory sharedManager] tryPreloadAppPage];
    [[BDPAppPageFactory sharedManager] tryPreloadPrecessPool];
    // Settings尝试更新下
    [BDPSettingsManager.sharedManager updateSettingsByForce:nil];
}

- (void)restoreOriginStatus
{
    // 恢复NavigationBar原始状态
    [BDPDeviceManager deviceInterfaceOrientationAdaptTo:self.originInterfaceOrientation];
    
    // 恢复StatusBar原始状态
    [[UIApplication sharedApplication] setIdleTimerDisabled:self.originIdleTimerDisabled];
    [[UIApplication sharedApplication] setStatusBarStyle:self.originStatusBarStyle animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:self.originStatusBarHidden withAnimation:UIStatusBarAnimationFade];
    
    // 针对 iOS13 以下存在的动画问题，使用 Alpha 模式设置状态栏隐藏
    // UIViewControllerBasedStatusBarAppearance 为 YES 时自动使用 prefersStatus，不做下述处理
    BOOL isVCBaseStatusBar = NO;
    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"]) {
        isVCBaseStatusBar = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] boolValue];
    }
    
    if (!isVCBaseStatusBar && [BDPDeviceHelper OSVersionNumber] < 13.f) {
        [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
            [[[UIApplication sharedApplication] valueForKey:@"statusBar"] setAlpha:!self.originStatusBarHidden];
        }];
    }
}

#pragma mark - Download Manager
/*------------------------------------------*/
//         Download Manager - 下载管理
/*------------------------------------------*/

// Meta异步拉取完成回调
- (void)getUpdatedMetaInfoModelCompletion:(NSError *)error model:(BDPModel *)model
{
    WeakSelf;
    if (!self || [self isH5Version:model]) {
        return; // h5兜底不处理
    }

    BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
    if ([lifeCyclePlugin respondsToSelector:@selector(bdp_onModelFetchedForUniqueID:isSilenceFetched:isModelCached:appModel:error:)]) {
        [lifeCyclePlugin bdp_onModelFetchedForUniqueID:self.uniqueID isSilenceFetched:YES isModelCached:NO appModel:model error:error];
    }
    
    if (self.containerContext && self.containerContext.apprearenceConfig.forbidUpdateWhenRunning) {
        return; // 新容器中不允许运行时更新
    }
    
    // 启动后用户关闭窗口，ContainerVC被释放，task需要通过appId去热启动缓存中获取
    BDPUniqueID *uniqueID = self.uniqueID;
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
    
    dispatch_block_t checkUpdateBlk = ^{
        StrongSelfIfNilReturn;
        if (!error && model) {
            // 重新读一次
            BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
            BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
            
            BDPModel *curModel = common.model;
            [curModel mergeNewestInfoFromModel:model];
            
            BOOL hasUpdate = [model isNewerThanAppModel:curModel];
            if (self && ![self checkModelStatus:curModel isAsyncUpdate:YES]) {
                hasUpdate = NO;
            }
            
            if (hasUpdate) {
                [task.context bdp_fireEvent:BDPCallbackEventOnCheckForUpdate
                                   sourceID:NSNotFound
                                       data:@{BDPCallbackParamHasUpdate:@(hasUpdate)}];
            }
        }
    };
    
    if (task) {
        checkUpdateBlk();
    } else if (self) { // 因为流式异步加载, 可能task还没创建, 但self是有的. 先记录下来, 延迟执行
        [self.needAppTaskBlks addObject:checkUpdateBlk];
    }
}

// TTPKG 数据包异步下载完成回调
- (void)getUpdatedPkgCompletion:(NSError *)error model:(BDPModel *)model
{
    if (!self || [self isH5Version:model]) {
        return; // h5兜底不处理
    }
    
    if (self.containerContext && self.containerContext.apprearenceConfig.forbidUpdateWhenRunning) {
        return; // 新容器中不允许运行时更新
    }
    
    if (error) {
        BDPLogError(@"onUpdateFailed: %@", error.localizedDescription);
    }

    // 启动后用户关闭窗口，ContainerVC被释放，task需要通过appId去热启动缓存中获取
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    [task.context sendOnUpdateReadyEventFromAsyncStartupWithError:error];
}

#pragma mark - H5 Version

- (BOOL)isH5Version:(BDPModel *)model
{
//    model.webURL = @"http://10.95.136.61:18242/__dist__/";
    BOOL isReleaseCandidateMode = [BDPAppMetaUtils metaIsReleaseCandidateModeForVersionType:model.uniqueID.versionType];
    return !BDPIsEmptyString(model.webURL) && isReleaseCandidateMode;
}

#pragma mark - BDPlatformContainerProtocol
/*------------------------------------------*/
//  BDPlatformContainerProtocol - 基础VC方法
/*------------------------------------------*/
// TODO: 该方法即将删除，被 unmount 替代
- (void)dismissSelf:(OPMonitorCode *)code
{
    if ([OPSDKFeatureGating isGadgetContainerRemoveCode:self.uniqueID]) {
        [[OPApplicationService.current getContainerWithUniuqeID:self.uniqueID] unmountWithMonitorCode:code?:GDMonitorCode.unknown_error];
    }
}

- (void)detectBlankWebview:(void (^)(BOOL, NSError * _Nullable))complete {
    if (!complete) {
        BDPLogError(@"complete is nil");
        return;
    }
    NSDate *beginTime = [NSDate date];
    // 白屏检测
    UIViewController *topVc = [BDPResponderHelper topViewControllerForController:self.subNavi fixForPopover:false];
    BDPAppPage *detectWebView = nil;
    BDPAppController *appController = nil;
    if ([topVc isKindOfClass:[BDPAppController class]]) {
        appController = (BDPAppController *)topVc;
        detectWebView = appController.currentAppPage.appPage;
    }
    if (!detectWebView || !appController) {
        BDPLogInfo(@"appController or detect webview is nil");
        complete(NO, nil);
        return;
    }
    // 没有配置时，不做监测
    if (!appController.exitMonitorStrategy) {
        BDPLogWarn(@"detect config is null");
        BDPMonitorWithName(kEventName_mp_blank_screen_detect, self.uniqueID)
        .setPlatform(OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea)
        .addMap(@{@"result_type": @"fail"})
        .flush();

        complete(NO, nil);
        return;
    }
    WeakSelf;
    [BDPWebViewBlankScreenDetect detectBlankWebView:detectWebView complete:^(BDPBlankDetectModel *detectResult, NSError * _Nullable error) {
        StrongSelfIfNilReturn;
        NSDate *endTime = [NSDate date];
        NSInteger duration = ([endTime timeIntervalSince1970] - [beginTime timeIntervalSince1970]) * 1000.0;
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
        if (error) {
            BDPLogWarn(@"detect blank webview fail, error=%@", error);
            [BDPTracker monitorService:kEventName_mp_blank_screen_detect
                                metric:@{OPMonitorEventKey.duration: @(duration)}
                              category:@{
                                  @"isUniteDetect": @(YES),
                                  @"result_type": @"fail",
                                  @"is_subpackage_mode":@([common isSubpackageEnable]),
                                  ExitMonitorStrategyConsts.blankRate: @(detectResult.blankPixelsRate),
                                  ExitMonitorStrategyConsts.lucency: @(detectResult.lucencyPixelsRate),
                                  ExitMonitorStrategyConsts.maxPureColor : detectResult.maxPureColor?:@"default",
                                  ExitMonitorStrategyConsts.maxPureColorRate:@(detectResult.maxPureColorRate),
                                  @"error": error,
                                  @"reload_count": @(detectWebView.totalTerminatedCount)
                              }
                                 extra:@{@"pagePath": BDPSafeString(task.currentPage.path)}
                  uniqueID:self.uniqueID];
            
            ///暂时保留2份，2022.5后删除上方旧埋点
            BDPMonitorWithName(kEventName_mp_blank_screen_detect, self.uniqueID)
            .setPlatform(OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea)
            .addMap(@{
                @"isUniteDetect": @(YES),
                @"result_type": @"fail",
                @"is_subpackage_mode": @([common isSubpackageEnable]),
                ExitMonitorStrategyConsts.blankRate: @(detectResult.blankPixelsRate),
                ExitMonitorStrategyConsts.lucency: @(detectResult.lucencyPixelsRate),
                ExitMonitorStrategyConsts.maxPureColor : detectResult.maxPureColor?:@"default",
                ExitMonitorStrategyConsts.maxPureColorRate:@(detectResult.maxPureColorRate),
                @"reload_count": @(detectWebView.totalTerminatedCount),
                @"error": error
            })
            .flush();

            complete(NO, error);
            return;
        }
        
        if([self enablePureColorDetect]){
            NSInteger strategy = [self pureColorDetectStragdety];
            if(strategy == 1){
                //策略1: 用纯色百分比 替换 背景色占比
                detectResult.blankPixelsRate = detectResult.maxPureColorRate;
            } else if(strategy == 2){
                //策略2: 用纯色+透明度百分比 替换 背景色占比 （优先本方案）
                if (![detectResult.maxPureColor isEqualToString:@"r0g0b0a0"]) {
                    //透明度超过50%这个场景出现了bad case，所以在当前最大色值是透明的情况下，不继续累加。具体分析见 https://bytedance.feishu.cn/wiki/wikcnaS1zXADPqT0fe9aYxfubZu
                    detectResult.blankPixelsRate = detectResult.maxPureColorRate + detectResult.lucencyPixelsRate;
                }
            }
        }
        
        NSArray *param = [self buildExitStrategyParamWithDuration:duration detect:detectResult blankCount:appController.blankCount];
        NSError *strategError = nil;
        BOOL cleanWarmCache = [appController isCleanWarmCache:param withError:&strategError];
        complete(cleanWarmCache, strategError);
    }];
}


- (NSArray<StrategyParam *> *)buildExitStrategyParamWithDuration:(NSInteger)duration
                                                          detect:(BDPBlankDetectModel *)detectResult
                                                      blankCount:(NSInteger)blankCount {
    NSMutableArray <StrategyParam *> *param = [NSMutableArray array];
    [param addObject:[StrategyParam buildParam:OPMonitorEventKey.duration intValue:duration]];
    [param addObject:[StrategyParam buildParam:ExitMonitorStrategyConsts.blankRate floatValue:detectResult.blankPixelsRate]];
    [param addObject:[StrategyParam buildParam:ExitMonitorStrategyConsts.lucency floatValue:detectResult.lucencyPixelsRate]];
    [param addObject:[StrategyParam buildParam:ExitMonitorStrategyConsts.closeCount intValue:blankCount]];
    [param addObject:[StrategyParam buildParam:ExitMonitorStrategyConsts.maxPureColor strValue:detectResult.maxPureColor]];
    [param addObject:[StrategyParam buildParam:ExitMonitorStrategyConsts.maxPureColorRate floatValue:detectResult.maxPureColorRate]];

    return [param copy];
}

-(BOOL)enablePureColorDetect{
    id<ECOConfigService> service = [ECOConfig service];
    NSDictionary<NSString *, id> *config = BDPSafeDictionary([service getDictionaryValueForKey:@"ecosystem_pure_color_detect"]);
    if (!config) {
        return false;
    }
    return config[@"enable"];
}

-(BOOL)enableScreenshotObserve{
    id<ECOConfigService> service = [ECOConfig service];
    NSDictionary<NSString *, id> *config = BDPSafeDictionary([service getDictionaryValueForKey:@"ecosystem_pure_color_detect"]);
    if (!config) {
        return false;
    }
    return [config bdp_boolValueForKey2:@"enableScreenshot"];
}


-(NSInteger)pureColorDetectStragdety{
    id<ECOConfigService> service = [ECOConfig service];
    NSDictionary<NSString *, id> *config = BDPSafeDictionary([service getDictionaryValueForKey:@"ecosystem_pure_color_detect"]);
    return [config bdp_integerValueForKey:@"strategy"];
}


-(void)addTakeScreenShotObserverIfNeeded{
    if(![self enablePureColorDetect] || ![self enableScreenshotObserve]){
        return ;
    }
    
    ///增加白屏检测的诊断时机，用于线上诊断白屏效果，看是否是关闭后页面跳动造成的数据不正确 还是 检测方法本身的问题。
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(triggerDetectBlankwebview:) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
}

- (void)triggerDetectBlankwebview:(NSNotification *)notification{
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    if (!common.isForeground) {
        //只前台的小程序响应，避免堆栈内太多截屏同时触发
        return ;
    }
    [self detectBlankWebview:^(BOOL cleanWarmCache, NSError * _Nullable error) {
        if (error) {
            BDPLogError(@"detect blank screen error do nothing, error=%@", error);
            return;
        }
        BDPLogInfo(@"detect successly trigger by user did takeScreenshot");
    }];
}

// TODO: 没有被调用的函数，需要删除
- (void)dismissSelfAndClosePresentedVC:(NSString *)exitType
{

}

// 获取左上角胶囊组件位置，小游戏脱敏状态下，用于获取右边"更多"按钮位置
- (CGRect)getToolBarRect
{
    // 暂时 Trick，重构后解决
    UIView *toolbar = self.toolBarView;
    if ([self.subNavi.topViewController respondsToSelector:@selector(toolBarView)]) {
        toolbar = [self.subNavi.topViewController performSelector:@selector(toolBarView)];
    }
    return toolbar.frame;
}

// 小游戏脱敏API，用于获取左边"退出"按钮的位置
- (CGRect)getLeftToolBarRect
{
    return CGRectZero;
}

- (UIView *)topView
{
    return self.subNavi.topViewController.view;
}

// TODO: 即将删除
- (BOOL)applyUpdateIfNeed
{
    return NO;
}

- (void)startAdaptOrientation
{
    self.isAdaptingOrientation = YES;
    [BDPDeviceManager deviceInterfaceOrientationAdaptTo:UIInterfaceOrientationPortrait];
}

- (void)endAdaptOrientation
{
    self.isAdaptingOrientation = NO;
    [BDPDeviceManager deviceInterfaceOrientationAdaptToMask:[self supportedInterfaceOrientations]];
}

#pragma mark - Pop Gesture
/*------------------------------------------*/
//           Pop Gesture - 手势动画操作
/*------------------------------------------*/
- (void)edgePanGesture:(UIScreenEdgePanGestureRecognizer *)gesture
{
    CGFloat progress = [gesture translationInView:self.view].x / self.view.bounds.size.width;
    progress = MIN(1.0, MAX(0.0, progress));//把这个百分比限制在0~1之间
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            if ([self.navigationController isKindOfClass:[BDPRootNavigationController class]]) {
                self.screenEdgePopAnimation = [(BDPRootNavigationController *)(self.navigationController) animation];                
            }
            self.screenEdgePopAnimation.screenEdgePopMode = YES;

            self.screenEdgePopAnimation.style = ([self type] == BDPTypeNativeApp) ? BDPPresentAnimationStypeRightLeft : BDPPresentAnimationStypeUpDown;

            // TODO: 确认与 closeAndReboot 实现的等效性
            [[OPApplicationService.current getContainerWithUniuqeID:self.uniqueID] unmountWithMonitorCode:GDMonitorCode.edge_gesture_dismiss];
        
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            [self.screenEdgePopAnimation.interactive updateInteractiveTransition:progress];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGFloat velocity = [gesture velocityInView:self.view].x;
            if (progress > 0.25 || velocity >= 80) {
                _exitType = @"slide";
                [self.screenEdgePopAnimation.interactive finishInteractiveTransition];
                
                [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID].isActive = NO;
                [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID].isForeground = NO;
                [[BDPWarmBootManager sharedManager] startTimerToReleaseViewWithUniqueID:self.uniqueID];
            } else {
                _exitType = @"others";
                [self.screenEdgePopAnimation.interactive cancelInteractiveTransition];
            }
        }
        default:
            break;
    }
}

- (void)directionEdgePanGesture:(UIScreenEdgePanGestureRecognizer *)gesture
{
    CGFloat progress = [gesture translationInView:self.view].x / self.view.bounds.size.width;
    progress = MIN(1.0, MAX(0.0, progress));//把这个百分比限制在0~1之间
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
        {
            // 暂时什么都不处理
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            self.subNavi.view.bdp_top = [UIScreen mainScreen].bounds.size.height * progress;
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGFloat velocity = [gesture velocityInView:self.view].x;
            if (progress > 0.25 || velocity >= 80) {
                _exitType = @"slide";
                
                [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID].isActive = NO;
                [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID].isForeground = NO;
                [[BDPWarmBootManager sharedManager] startTimerToReleaseViewWithUniqueID:self.uniqueID];

                [[OPApplicationService.current getContainerWithUniuqeID:self.uniqueID] unmountWithMonitorCode:GDMonitorCode.edge_gesture_dismiss];
            } else {
                _exitType = @"others";
                self.subNavi.view.bdp_top = 0;
            }
        }
        default:
            break;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (![BDPXScreenManager isXScreenMode:self.uniqueID] && gestureRecognizer == self.directionGesture) {
        return NO;
    }
    
    if (self.subNavi.viewControllers.count > 1) {
        return NO;
    }
    
    UIViewController *topVC = self.subNavi.topViewController;
    if ([topVC isKindOfClass:[BDPAppController class]]) {
        BDPAppController *appVC = (BDPAppController *)topVC;
        UINavigationController *navi ;
        if ([appVC.contentVC isKindOfClass:[UITabBarController class]]) {
            navi = (UINavigationController *)((UITabBarController *)(appVC.contentVC)).selectedViewController;
        } else if ([appVC.contentVC isKindOfClass:[UINavigationController class]]) {
            navi = (UINavigationController *)appVC.contentVC;
        }
        return navi.viewControllers.count <= 1;
        
    }
    
    if (gestureRecognizer == self.directionGesture) {
        return [BDPXScreenManager isXScreenMode:self.uniqueID];
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer == self.popGesture && ![otherGestureRecognizer isKindOfClass:[UIScreenEdgePanGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer
{
    UIView *superView = otherGestureRecognizer.view.superview;
    while (superView) {
        if ([superView isKindOfClass:[WKWebView class]]) {
            static NSString *className = nil;
            if (!className) {
                // private class UIWebTouchEventsGestureRecognizer
                className = @"UIWebTouchEventsGestureRecognizer"; //[NSString bdp_stringFromBase64String:@"VUlXZWJUb3VjaEV2ZW50c0dlc3R1cmVSZWNvZ25pemVy"];
            }
            if ([NSStringFromClass(otherGestureRecognizer.class) isEqualToString:className]) {
                return YES;
            }
            break;
        }
        superView = superView.superview;
    }

    return NO;
}

- (BDPWarmBootCleaner)rootVCCleaner {
    return self.subNavi ? self.subNavi.viewControllers.firstObject : nil;
}

- (NSMutableArray<dispatch_block_t> *)needAppTaskBlks {
    if (!_needAppTaskBlks) {
        _needAppTaskBlks = [[NSMutableArray<dispatch_block_t> alloc] init];
    }
    return _needAppTaskBlks;
}

#pragma mark - Check App has some ability
- (void)checkAppHasSepcifyAbility:(NSString *)abilityName {
    BDPLogInfo(@"checkAppHasSepcifyAbility :%@", abilityName);
    BDPCommon *common = BDPCommonFromUniqueID(self.uniqueID);
    if(common.model == nil) {
        BDPLogError(@"checkAppHasSepcifyAbility %@ common is nil", abilityName)
        return;
    }
    if([abilityName isEqualToString:kBDPSchemaKeyAbilityMessageAction] && !common.model.abilityForMessageAction) {
        /// 声明有Message Action，但是没有对应权限
        [self showNeedUpdateGadgetApp];
    }
    
    if([abilityName isEqualToString:kBDPSchemaKeyAbilityChatAction] && !common.model.abilityForChatAction) {
        /// 声明有Message Action，但是没有对应权限
        [self showNeedUpdateGadgetApp];
    }
}

- (void)showNeedUpdateGadgetApp {
    BDPLogInfo(@"showNeedUpdateGadgetApp");
    BDPAbilityNotSupportController *vc = [[BDPAbilityNotSupportController alloc] init];
    vc.uniqueID = self.uniqueID;
    BDPRootNavigationController *nav = [[BDPRootNavigationController alloc] initWithRootViewController:vc];
    UIViewController *topVC = [BDPResponderHelper topViewControllerFor:[BDPResponderHelper topmostView:self.view.window?:self.uniqueID.window]];
    [topVC presentViewController:nav animated:YES completion:^{
        BDPLogInfo(@"showNeedUpdateGadgetApp end");
    }];
}

#pragma mark - ⚠️TODO: 下方是支持重构迁移的临时代码⚠️

- (void)invokeAppTaskBlks {
    for (dispatch_block_t blk in self.needAppTaskBlks) {
        blk(); // 需要Task的延迟Blk
    }
    self.needAppTaskBlks = nil;
}

- (void)bindSubNavi:(BDPNavigationController *)subNavi {
    self.subNavi = subNavi;
    
    // TODO: 这里一行代码用于检测最大后台运行应用数量并进行清楚，需要优化逻辑
    [BDPWarmBootManager.sharedManager cacheSubNavi:subNavi uniqueID:self.uniqueID cleaner:self.rootVCCleaner];
}

- (void)newContainerDidFirstContentReady {
    [self eventMPStartFirstContent];
    // 需要设置状态为 success，因为部分老的逻辑还依赖了该状态
    self.loadResultType = GDMonitorCodeLaunch.success;
}

#pragma mark - ⚠️TODO: 上方是支持重构迁移的临时代码⚠️

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        BDPLogInfo(@"traitCollectionDidChange. previous:%@, current:%@", @(previousTraitCollection.userInterfaceStyle), @(self.traitCollection.userInterfaceStyle));
        if (!self.uniqueID.isAppSupportDarkMode) {
            // 不支持 DarkMode
            BDPLogInfo(@"%@ not support dark mode", self.uniqueID);
            return;
        }
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
            BOOL darkMode = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
            // 首先先更新小程序配置
            [task.config applyDarkMode:darkMode];
            
            // 向 JSRuntime 发送通知
            [task.context bdp_fireEvent:OPThemeEventOnThemeChange sourceID:NSNotFound data:@{
                OPThemeKey: (darkMode ? OPThemeValueDark : OPThemeValueLight)
            }];
        }
    }
}

@end
