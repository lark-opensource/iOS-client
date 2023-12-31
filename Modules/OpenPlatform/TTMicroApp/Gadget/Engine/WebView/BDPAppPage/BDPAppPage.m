//  Created by 王浩宇 on 2018/11/18.

#import "BDPAppPage.h"
#import "BDPAppLoadDefineHeader.h"
#import "BDPAppPageController.h"
#import "BDPAppPageFactory.h"
#import "BDPAppRouteManager.h"
#import <OPFoundation/BDPCommonManager.h>
#import "BDPComponentManager.h"
#import "BDPInterruptionManager.h"
#import <OPFoundation/BDPLifeCyclePluginDelegate.h>
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import "BDPTaskManager.h"
#import "BDPTimorClient+Business.h"
#import <OPFoundation/BDPTracingManager.h>
#import "BDPTracker+BDPLoadService.h"
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPTrackerEvent.h>
#import "BDPURLProtocolManager.h"
#import <OPFoundation/BDPUserAgent.h>
#import "BDPWebViewComponent.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPFoundation/OPAppTheme.h>
#import <ECOInfra/ECOCookieService.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import "BDPSubPackageManager.h"
#import "BDPGadgetLog.h"
#import "BDPMemoryMonitor.h"
#import <Heimdallr/HMDMemoryUsage.h>
#import "BDPWarmBootManager.h"
#import "BDPPerformanceProfileManager.h"
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPTracingManager+Gadget.h"
#import "BDPPkgFileBasicModel.h"

@interface BDPAppPage () <BDPWebViewInjectProtocol, UIScrollViewDelegate>

/** webview terminated的次数 */
@property (nonatomic, assign) int terminatedCount;
@property (nonatomic, assign, readwrite) int totalTerminatedCount; //与terminatedCount的区别在于：不清零，仅用于统计
@property (nonatomic, assign) BOOL didNotifyDOMReady;
@property (nonatomic, assign, readwrite) BOOL didLoadFrameScript;
@property (nonatomic, assign) BOOL didLoadPathScript;
/// 标识webView进程发生了崩溃
@property (nonatomic, assign) BOOL isWebViewTerminate;

/// 标识webView进程崩溃时，当前视图是否可见
@property (nonatomic, assign) BOOL isWebViewTerminatedVisible;
@property (nonatomic, assign) BOOL isLoadingPageFrame;
@property (nonatomic, assign) BOOL isLoadingPathFrame;
//  是否添加了小程序进入后台的监听
@property (nonatomic, assign) BOOL hasAddDidEnterBackgroundObserve;
//  是否添加了scrollView的监听
@property (nonatomic, assign) BOOL hasAddContentOffsetObserve;

@property (nonatomic, strong) NSNumber *isStartPage;

@property (nonatomic, copy) NSString *bap_pageFrameBasePath;//  可以放在.m
@property (nonatomic, copy) NSString *bap_loadErrorMsg;
/// 各种异步、各种等待path。最后直接简单粗暴上各个date节点。末尾时一次性监控上 T-T //  可以放在.m
@property (nonatomic, strong) NSDate *bap_webViewCreateBegin;//  可以放在.m
@property (nonatomic, strong) NSDate *bap_webViewCreateEnd;//  可以放在.m
@property (nonatomic, strong) NSDate *bap_loadHtmlEnd;//  可以放在.m
@property (nonatomic, strong) NSDate *bap_loadPageFrameBegin;//  可以放在.m
@property (nonatomic, strong) NSDate *bap_loadPageFrameEnd;//  可以放在.m
@property (nonatomic, strong) NSDate *bap_evalPageFrameEnd;//  可以放在.m
@property (nonatomic, strong) NSDate *bap_loadPathFrameBegin;//  可以放在.m
@property (nonatomic, strong) NSDate *bap_loadPathFrameEnd;//  可以放在.m
@property (nonatomic, strong) NSDate *bap_evalPathFrameEnd;//  可以放在.m
/// 小程序webview加载计时器
@property (nonatomic, strong) BDPTrackerTimingEvent *bap_loadTimingEvent;//  可以放在.m

@property (nonatomic, assign) BOOL overloadMonitorShouldFlushLater;
@property (nonatomic, assign) BOOL shouldReloadAfterPageAppear;
@property (nonatomic, strong) NSDictionary *overloadMonitorCategory;
@property (nonatomic, assign) BOOL isShownOverloadPage;

@property (nonatomic, assign) BOOL enableSchemeHandler;


@end

@implementation BDPAppPage

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithFrame:(CGRect)frame delegate:(id<BDPAppPageProtocol>)delegate enableSchemeHandler:(BOOL) enableHandler
{
    BDPMonitorEvent *loadStartEvent = BDPMonitorWithName(kEventName_mp_webview_load_start, self.uniqueID);
    NSDate *createBegin = [NSDate date];
    NSInteger webViewID = [[BDPComponentManager sharedManager] generateComponentID];
    WKWebViewConfiguration *config = [BDPAppPage userConfigWithWebViewID:webViewID];
    if(enableHandler) {
        [self registerSchemaHandler:config];
    }
    [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithStartKey:BDPPerformanceWebviewContainerLoad uniqueId:self.uniqueID
                                                                           extra:@{kBDPPerformanceWebviewId:@(webViewID)}];
    self = [super initWithFrame:frame config:config delegate:self bizType:LarkWebViewBizType.gadget advancedMonitorInfoEnable:NO];
    if (self) {
        !BDPAppPageManagerForEditor.shared.bdpAppPageInitBlock ?: BDPAppPageManagerForEditor.shared.bdpAppPageInitBlock((BDPAppPage *)self);
        // 优先创建tracing
        BDPTracing *trace = [BDPTracingManager.sharedInstance generateTracingByAppPage:(BDPAppPage *)self];
        loadStartEvent.bdpTracing(trace).flush();
        BDPMonitorWithName(kEventName_mp_webview_load_result, self.uniqueID).bdpTracing(trace).setResultType(kEventValue_success).flush();
        [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithEndKey:BDPPerformanceWebviewContainerLoad uniqueId:self.uniqueID
                                                                             extra:@{kBDPPerformanceWebviewId:@(webViewID)}];
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;

        self.appPageDelegate = delegate;
        self.appPageID = webViewID;
        self.isHasWebView = NO;
        _hasAddDidEnterBackgroundObserve = NO;
        _hasAddContentOffsetObserve = NO;
        _enableSchemeHandler = enableHandler;

        self.customUserAgent = [BDPUserAgent getUserAgentStringWithUniqueID:nil webviewID:@(webViewID).stringValue];

        // 初始化URLProtocol.预加载通用page-frame.html需要在这里提前开启URLProtocol拦截,而不能等到BaseContainerController中处理,否则读取不到JSSDK内的page-frame.html文件
        if(!enableHandler){
            [[BDPURLProtocolManager sharedManager] setInterceptionEnable:YES withWKWebview:self];
        }
        
        self.bap_pageFrameBasePath = [[BDPURLProtocolManager sharedManager] generateVirtualFolderPath];
        [self setupContent];
    } else {
        BDPTracing *trace = [BDPTracingManager.sharedInstance generateTracing];
        loadStartEvent.bdpTracing(trace).flush();
        BDPMonitorWithName(kEventName_mp_webview_load_result, self.uniqueID).bdpTracing(trace).setResultType(kEventValue_fail).setMonitorCode(GDMonitorCode.init_error).flush();
    }
    self.bap_webViewCreateBegin = createBegin;
    self.bap_webViewCreateEnd = [NSDate date];

    // 建立开放平台内存相关性能指标监控
    [OPObjectMonitorCenter setupMemoryMonitorWith:self];
    BDPGadgetLogInfo(@"BDPAppPage initWithFrame: with appPageID:%@, enableSchemeHandler:%@, for  uniqueID:%@", @(self.appPageID), @(enableHandler), self.uniqueID);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    return self;
}

- (void)registerSchemaHandler:(WKWebViewConfiguration *) configuration {
    
    [configuration setURLSchemeHandler:[[GadgetFileHandler alloc] init] forURLScheme:@"file"];
    [configuration setURLSchemeHandler:[[GadgetFileHandler alloc] init] forURLScheme:@"ttjssdk"];
    [configuration setURLSchemeHandler:[[GadgetFileHandler alloc] init] forURLScheme:@"ttfile"];
    
    [configuration setURLSchemeHandler:[[GadgetWebpHandler alloc] init] forURLScheme:@"ttwebp"];
    [configuration setURLSchemeHandler:[[GadgetWebpHandler alloc] init] forURLScheme:@"ttwebps"];
}


/// 检查webview 是否加载卡死，如果加载卡死，上报埋点
- (void)checkLoadPageFrameStuck {
    if(!self.isAppPageReady && self.bap_loadHtmlBegin && self.uniqueID) {
        double stuckThreshold = [GadgetSchemeHandlerUtil stuckThreshold];
        NSTimeInterval loadTime = [[NSDate date] timeIntervalSinceDate:self.bap_loadHtmlBegin];
        if(loadTime > stuckThreshold) {
            [self newMonitorEvent:@"gadget_webview_stuck"]
            .addCategoryValue(@"enableScheme", @(self.enableSchemeHandler))
            .addCategoryValue(@"loadTime", @(loadTime))
            .flush();
        }
    }
}

- (void)dealloc
{
    !BDPAppPageManagerForEditor.shared.bdpAppPageDeallocBlock ?: BDPAppPageManagerForEditor.shared.bdpAppPageDeallocBlock((BDPAppPage *)self);
    [[BDPURLProtocolManager sharedManager] unregisterFolderPath:self.bap_pageFrameBasePath];

    // 定时器未结束表示页面未加载完成
    if (self.bap_loadTimingEvent && self.bap_loadTimingEvent.isStart) {
        [self bap_eventPageLoadResult:BDPTrackerResultFail errorMsg:@"load error" uniqueID:self.uniqueID];
    }
    //  保证添加释放成对
    if (_hasAddDidEnterBackgroundObserve) {
        [BDPInterruptionManager.sharedManager removeObserver:self forKeyPath:NSStringFromSelector(@selector(didEnterBackground))];
        _hasAddDidEnterBackgroundObserve = NO;
    }
    if (_hasAddContentOffsetObserve) {
        [self.scrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))];
        _hasAddContentOffsetObserve = NO;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    BDPGadgetLogInfo(@"BDPAppPage dealloc: appPageID:%@", @(self.appPageID));
}

#pragma mark - BDPAppPage Load Content
/*-----------------------------------------------*/
//       BDPAppPage Load Content - 内容加载
/*-----------------------------------------------*/

- (void)setupAppPageWithUniqueID:(BDPUniqueID *)uniqueID
{
    // 注册下虚拟路径和ttpkg的匹配关系, 不然拦截不到资源加载
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    [[BDPURLProtocolManager sharedManager] registerFolderPath:self.bap_pageFrameBasePath forUniqueID:uniqueID pkgName:common.model.pkgName];
    [self setupWebViewWithUniqueID:uniqueID];
    
    BDPGadgetLogInfo(@"BDPAppPage - setupAppPageWithUniqueID:%@, appPageID:%@, bap_pageFrameBasePath:%@, enableSchemeHandler:%@", uniqueID, @(self.appPageID), self.bap_pageFrameBasePath, @(self.enableSchemeHandler));

    // AppPage被认领后, 就尝试加载内容
    [self tryLoadPageContent];
    if (self.bap_loadErrorMsg) { // 处理未处理的错误
        [self handleLoadErrorMsg:self.bap_loadErrorMsg];
    }

    self.customUserAgent = [BDPUserAgent getUserAgentStringWithUniqueID:uniqueID webviewID:@(self.appPageID).stringValue];

    if(GadgetSchemeHandlerUtil.enableStuckMonitor){
        [self checkLoadPageFrameStuck];
    }
}

- (void)setupContent
{
    [self loadPageFrameHTML];
}

-(void)setBap_path:(NSString *)bap_path
{
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    //说明当前是在（加载完首页主包/独立分包）的基础上，再加载一个（分包/主包页面）
    //分包场景下需要重新刷新虚拟路径
    if (common.isSubpackageEnable){
        //修正分包情况下资源映射的目录
        BDPPackageContext * packageContext = [[BDPSubPackageManager sharedManager] packageContextWithPath:bap_path
                                                                                                 uniqueID:self.uniqueID];
        if (packageContext) {
            [[BDPURLProtocolManager sharedManager] registerFolderPath:self.bap_pageFrameBasePath
                                                          forUniqueID:self.uniqueID
                                                              pkgName:packageContext.packageName];
        } else {
            BDPGadgetLogError(@"setBap_path in sub-pacakge, but packageContext is nil");
        }
    }
    _bap_path = bap_path;
}

#pragma mark - BDPAppPage Load Phase
/*-----------------------------------------------*/
//       BDPAppPage Load Phase - 加载事件相关
/*-----------------------------------------------*/
- (void)loadPageFrameHTML
{
    [self newMonitorEvent:kEventName_mp_webview_lib_load_start].flush();
    [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithStartKey:BDPPerformanceWebviewJSSDKLoad uniqueId:self.uniqueID extra:@{
        kBDPPerformanceWebviewId:@(self.appPageID)
    }];
    self.bap_loadHtmlBegin = [NSDate date];
    NSURL *url = nil;
    NSString *path = [self bap_pageFramePathWithFlag:YES];
    if (path.length && (url = [NSURL URLWithString:path])) {
        BOOL didLoad = NO;
        // tma下的所有文件默认可读
        NSString *tmaPath = [NSString stringWithFormat:@"file://%@", [[BDPGetResolvedModule(BDPStorageModuleProtocol, self.appType) sharedLocalFileManager] pathForType:BDPLocalFilePathTypeBase]];
        if (tmaPath) {
            [self loadFileURL:url allowingReadAccessToURL:[NSURL URLWithString:tmaPath]];
            didLoad = YES;
        }
        if (!didLoad) {
            NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0];
            [self loadRequest:request];
        }
    } else {
        [self newMonitorCodeEvent:GDMonitorCode.load_page_frame_html_error].setErrorMessage(@"path invalid").kv(@"html_file_path", path).flush();
    }
}

- (void)tryLoadPageContent {
    [self notifyDOMReadyIfNeeded];
    [self loadPageFrameScriptIfNeed];
    [self loadPathScriptIfNeed];
}

- (void)notifyDOMReadyIfNeeded {
    if (!self.isAppPageReady || (self.didNotifyDOMReady && self.isFireEventReady)) {
        return;
    }
    self.didNotifyDOMReady = YES;
    [BDPAppRouteManager postDocumentReadyNotifWithUniqueId:self.uniqueID appPageId:self.appPageID];
    BDPGadgetLogInfo(@"JSRuntime ready: %@", self.bap_path ?: @(self.appPageID));

    BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
    BDPGadgetLogTagInfo(@"BDPAppPage LifeCycle", @"bdp_onPageDomReady uniqueID:%@, bap_path:%@", self.uniqueID, self.bap_path);
    if ([lifeCyclePlugin respondsToSelector:@selector(bdp_onPageDomReady:page:)]) {
        [lifeCyclePlugin bdp_onPageDomReady:self.uniqueID page:self.appPageID];
    }
}

- (void)loadPageFrameScriptIfNeed {
        [self loadPageFrameScriptOldWayIfNeeded];
    [self tryMonitorWebviewTimelineEvent];
}

- (void)tryMonitorWebviewTimelineEvent {
    if (self.uniqueID && self.bap_loadHtmlEnd) {
        NSDictionary *param = @{
                                @"webview_id": @(self.appPageID)
                                };
        BDPMonitorLoadTimelineDate(@"create_webview_begin", param, self.bap_webViewCreateBegin, self.uniqueID);
        BDPMonitorLoadTimelineDate(@"create_webview_end", param, self.bap_webViewCreateEnd, self.uniqueID);
        BDPMonitorLoadTimelineDate(@"load_pageFrameHtml_begin", param, self.bap_loadHtmlBegin, self.uniqueID);
        BDPMonitorLoadTimelineDate(@"load_pageFrameHtml_end", param, self.bap_loadHtmlEnd, self.uniqueID);
        self.bap_loadHtmlBegin = nil;
        self.bap_loadHtmlEnd = nil;
        self.bap_webViewCreateBegin = nil;
        self.bap_webViewCreateEnd = nil;
    }
}

- (void)loadPageFrameScriptOldWayIfNeeded {
    if (!self.uniqueID || !self.isAppPageReady || self.isLoadingPageFrame || self.didLoadFrameScript) {
        return;
    }
    WeakSelf;
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    if (!common || !common.reader) {
        NSNotificationCenter * __weak center = [NSNotificationCenter defaultCenter];
        __block id token =
        [[NSNotificationCenter defaultCenter] addObserverForName:kBDPCommonReaderReadyNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            StrongSelfIfNilReturn
            [self
             loadPageFrameScriptOldWayIfNeeded];
            [center removeObserver:token];
        }];
        return;
    }
    
    // 在开始加载小程序代码之前要先初始化主题
    [self initTheme];
    
    [self newMonitorEvent:kEventName_mp_webview_app_load_start].kv(@"logic_version", @0).flush();
    [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithStartKey:BDPPerformancePageFrameJSRun uniqueId:self.uniqueID extra:@{
        kBDPPerformanceWebviewId:@(self.appPageID)}];
    self.bap_loadPageFrameBegin = [NSDate date];
    self.isLoadingPageFrame = YES;
    NSString *filePath = @"page-frame.js";
    int local_pkg = common.reader.createLoadStatus == BDPPkgFileLoadStatusDownloaded;
    //分包情况下的子路径，页面的page-frame在里面
    //一般情况下只有独立分包才会到这里，其他分包预加载时 page-frame.js 执行会出错（找不到文件），之后走补偿加载
    NSString * subPagePath = [common.reader basic].pagePath ?: @"";
    if (!BDPIsEmptyString(subPagePath)) {
        filePath = [subPagePath stringByAppendingPathComponent:filePath];
    }

    // 当预载开关打开且命中AB测试开关,则进行读取预载缓存内容
    if (BDPPreRunManager.sharedInstance.enablePreRun) {
        BDPPreRunCacheModel *preRunModel = [BDPPreRunManager.sharedInstance cacheModelFor:common.uniqueID];
        NSString *cachedScript = [preRunModel cachedJSString:filePath];
        if (!BDPIsEmptyString(cachedScript)) {
            // 有prerun缓存时, 这边要看一下是否命中ABTest开关
            if (BDPPreRunManager.sharedInstance.preRunABtestHit) {
                [self invokeBeforeLoadPageFrameJS];
                [self loadScript:cachedScript filePath:filePath isLocal:YES];
                [preRunModel addMonitorCachedFile:filePath];
                return;
            } else {
                [preRunModel addFailedReasonAndReport:@"abTest hit false"];
                [BDPPreRunManager.sharedInstance cleanAllCache];
            }
        }
    }

    [common.reader readDataWithFilePath:filePath syncIfDownloaded:YES dispatchQueue:nil completion:^(NSError * _Nullable error, NSString * _Nonnull pkgName, NSData * _Nullable data) {
        StrongSelfIfNilReturn;
        if (error != nil) {

            [self newMonitorEvent:kEventName_mp_webview_app_load_result]
            .setResultType(kEventValue_fail)
            .setMonitorCodeIfError(GDMonitorCode.load_page_frame_script_error)
            .kv(@"file_path", filePath)
            .setError(error)
            .flush();
            [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithEndKey:BDPPerformancePageFrameJSRun uniqueId:self.uniqueID extra:@{
                @"webviewId":@(self.appPageID)
              }];
            self.isLoadingPageFrame = NO;
            return;
        }

        [self invokeBeforeLoadPageFrameJS];
        NSString *pageFrameScript = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self loadScript:pageFrameScript filePath:filePath isLocal:local_pkg];
    }];
}

// 调用BDPLifeCyclePluginDelegate协议方法(原逻辑抽离封装)
- (void)invokeBeforeLoadPageFrameJS {
    BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
    BDPGadgetLogInfo(@"BDPAppPage LifeCycle, bdp_beforeLoadPageFrameJS uniqueID:%@ bap_path:%@", self.uniqueID, self.bap_path);
    if ([lifeCyclePlugin respondsToSelector:@selector(bdp_beforeLoadPageFrameJS:page:)]) {
        [lifeCyclePlugin bdp_beforeLoadPageFrameJS:self.uniqueID page:self.appPageID];
    }
    self.bap_loadPageFrameEnd = [NSDate date];
}

// 加载page-frame脚本任务(原逻辑抽离封装)
- (void)loadScript:(NSString *)pageFrameScript
          filePath:(NSString *)filePath
           isLocal:(BOOL)local_pkg {
    WeakSelf;
    [self bdp_evaluateJavaScript:pageFrameScript completion:^(id result, NSError *error) {
        StrongSelfIfNilReturn;
        [self newMonitorEvent:kEventName_mp_webview_app_load_result]
        .setResultType(error?kEventValue_fail:kEventValue_success)
        .setMonitorCodeIfError(GDMonitorCode.load_page_frame_script_error)
        .kv(@"file_path", filePath)
        .setError(error)
        .flush();
        [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithEndKey:BDPPerformancePageFrameJSRun uniqueId:self.uniqueID extra:@{
            @"webviewId":@(self.appPageID)
          }];
        if (!error) {
            self.bap_evalPageFrameEnd = [NSDate date];
            self.didLoadFrameScript = YES;
            self.isLoadingPageFrame = NO;
            [self loadPathScriptOldWayIfNeed];

            if ([self.appPageDelegate respondsToSelector:@selector(appPageShouldTrackPageFrameJSLoadTime)]
                && [self.appPageDelegate appPageShouldTrackPageFrameJSLoadTime]) {
                NSUInteger diff = ([self.bap_evalPageFrameEnd timeIntervalSince1970] - [self.bap_loadPageFrameEnd timeIntervalSince1970]) * 1000;

                [BDPTracker event:@"mp_load_time_page_frame"
                       attributes:@{
                                    @"duration": @(diff),
                                    @"local_pkg": @(local_pkg)
                                    }
             uniqueID:self.uniqueID];
            }
        } else {
            error = OPErrorWithError(GDMonitorCode.load_page_frame_script_error, error);
            // FG预计于4.6版本下掉
            [self handleBDPDataLoadErrorNotificationWith:error];
        }
    }];
}

- (void)loadPathScriptIfNeed {
    [self loadPathScriptOldWayIfNeed];
}

-(void)loadPathScriptOldWayIfNeedWhenUsingSubpackage
{
    if(self.didLoadPathScript) {
        BDPGadgetLogInfo(@"subpackage loadPathScriptOldWayIfNeedWhenUsingSubpackage return because path script had been loaded");
        return;
    }
    BDPGadgetLogInfo(@"subpackage loadPathScriptOldWayIfNeedWhenUsingSubpackage");
    self.didLoadFrameScript = YES;
    self.isLoadingPathFrame = NO;
    self.didLoadPathScript = NO;
    [self loadPathScriptOldWayIfNeed];
}

- (void)loadPathScriptOldWayIfNeed {
    if (!self.uniqueID || !self.bap_path || !self.isAppPageReady || !self.didLoadFrameScript || self.didLoadPathScript || self.isLoadingPathFrame) {
        if (self.didLoadPathScript &&
            !self.isSubPageFrameReady) {
            BDPGadgetLogError(@"subpackage whitescreen will happed, sub page frame is not ready with appPage:%@, %@", self, self.uniqueID);
        }
        return;
    }
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    //如果子页面的subPageFrame没有加载，则需要先加载
    if(common.isSubpackageEnable&&!self.isSubPageFrameReady){
        WeakSelf;
        [[BDPSubPackageManager sharedManager] prepareSubPackagesForPage:self.bap_path
                                                           withUniqueID:self.uniqueID
                                                               isWorker:NO
                                                      jsExecuteCallback:^(BDPSubPackageExtraJSLoadStep loadStep, NSError * _Nullable error) {
            StrongSelfIfNilReturn;
            if(loadStep == BDPSubPackageLoadPageFrameEnd) {
                [self loadPathScriptOldWayIfNeed];
            }
        }];
        return;
    }
    
    BDPPkgFileReader fileReader = [[BDPSubPackageManager sharedManager] getFileReaderWithPagePath:self.bap_path uniqueID:self.uniqueID] ?: common.reader;
    if (!common || ! fileReader) {
        BDPGadgetLogTagWarn(BDPTag.gadget, @"common unavailable");
        return;
    }
    //说明当前是在（加载完首页主包/独立分包）的基础上，再加载一个（分包/主包页面）
    if (common.isSubpackageEnable &&
        //分包场景，需要按顺序补偿执行 page-frame.js
        common.reader != fileReader) {
        //分包场景，需要再检查 分包下的 page-frame.js 是否执行成功
        if (!self.isSubPageFrameReady) {
            BDPGadgetLogTagInfo(@"SubPackage", @"loadPathScriptOldWayIfNeed and isSubPageFrameReady is false");
            return;
        }
    } else {
        BDPGadgetLogTagInfo(@"SubPackage", @"loadPathScriptOldWayIfNeed uniqueID:%@ bap_path:%@, readerMatch", self.uniqueID, self.bap_path);
    }
    
    [self newMonitorEvent:kEventName_mp_webview_page_load_start].flush();
    self.isLoadingPathFrame = YES;
    self.bap_loadPathFrameBegin = [NSDate date];
    WeakSelf;
    NSString *filePath = [self.bap_path stringByAppendingString:@"-frame.js"];
    [fileReader readDataInOrder:NO withFilePath:filePath dispatchQueue:nil completion:^(NSError * _Nullable error, NSString * _Nonnull pkgName, NSData * _Nullable data) {
        StrongSelfIfNilReturn;
        if (error != nil) {

            [self newMonitorEvent:kEventName_mp_webview_page_load_result]
            .setResultType(kEventValue_fail)
            .setMonitorCodeIfError(GDMonitorCode.load_path_frame_script_error)
            .kv(@"file_path", filePath)
            .setError(error)
            .flush();

            self.isLoadingPathFrame = NO;
            return;
        }
        BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
        BDPGadgetLogTagInfo(@"BDPAppPage LifeCycle", @"bdp_beforeLoadPageJS uniqueID:%@ bap_path:%@", self.uniqueID, self.bap_path);
        if ([lifeCyclePlugin respondsToSelector:@selector(bdp_beforeLoadPageJS:page:)]) {
            [lifeCyclePlugin bdp_beforeLoadPageJS:self.uniqueID page:self.appPageID];
        }
        self.bap_loadPathFrameEnd = [NSDate date];
        NSString *pathScript = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self bdp_evaluateJavaScript:pathScript completion:^(id result, NSError *error) {
            StrongSelfIfNilReturn;

            [self newMonitorEvent:kEventName_mp_webview_page_load_result]
            .setResultType(error?kEventValue_fail:kEventValue_success)
            .setMonitorCodeIfError(GDMonitorCode.load_path_frame_script_error)
            .setError(error)
            .kv(@"file_path", filePath)
            .flush();

            if (!error) {
                self.bap_evalPathFrameEnd = [NSDate date];
                self.didLoadPathScript = YES;
                self.isLoadingPathFrame = NO;

                // OnPageReload When WebView Terminated
                if (self.isWebViewTerminate) {
                    BDPGadgetLogError(@"AppView OnPageReload appPageID: %ld bap_Path: %@", (long)self.appPageID, self.bap_path);
                    self.isWebViewTerminate = NO;
                    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
                    [task.context bdp_fireEvent:@"onPageReload" sourceID:self.appPageID data:@{@"webviewId": @(self.appPageID)}];
                }
                NSUInteger diff = ([self.bap_evalPathFrameEnd timeIntervalSince1970] - [self.bap_loadPageFrameEnd timeIntervalSince1970]) * 1000;

                [BDPTracker event:@"mp_load_time_path_frame"
                       attributes:@{@"path": self.bap_path ?: @"",
                                    @"duration": @(diff),
                                    @"local_pkg": @(fileReader.createLoadStatus == BDPPkgFileLoadStatusDownloaded ? 1 : 0)}
             uniqueID:self.uniqueID];

                BDPMonitorLoadTimelineDate(@"get_file_content_from_ttpkg_begin", (@{ @"file_path": @"page-frame.js", @"page_path": self.bap_path ?: @"" }), self.bap_loadPageFrameBegin, self.uniqueID);
                BDPMonitorLoadTimelineDate(@"get_file_content_from_ttpkg_end", (@{ @"file_path": @"page-frame.js", @"page_path": self.bap_path ?: @"" }), self.bap_loadPageFrameEnd, self.uniqueID);
                BDPMonitorLoadTimelineDate(@"webview_evaluateJavascript_begin", (@{ @"file_path": @"page-frame.js", @"page_path": self.bap_path ?: @"" }), self.bap_loadPageFrameEnd, self.uniqueID);
                BDPMonitorLoadTimelineDate(@"webview_evaluateJavascript_end", (@{ @"file_path": @"page-frame.js", @"page_path": self.bap_path ?: @"" }), self.bap_evalPageFrameEnd, self.uniqueID);
                BDPMonitorLoadTimelineDate(@"get_file_content_from_ttpkg_begin", (@{ @"file_path": filePath?:@"", @"page_path": self.bap_path ?: @"" }), self.bap_loadPathFrameBegin, self.uniqueID);
                BDPMonitorLoadTimelineDate(@"get_file_content_from_ttpkg_end", (@{ @"file_path": filePath?:@"", @"page_path": self.bap_path ?: @"" }), self.bap_loadPathFrameEnd, self.uniqueID);
                BDPMonitorLoadTimelineDate(@"webview_evaluateJavascript_begin", (@{ @"file_path": filePath?:@"", @"page_path": self.bap_path ?: @"" }), self.bap_loadPathFrameEnd, self.uniqueID);
                BDPMonitorLoadTimelineDate(@"webview_evaluateJavascript_end", (@{ @"file_path": filePath?:@"", @"page_path": self.bap_path ?: @"" }), self.bap_evalPathFrameEnd, self.uniqueID);
                self.bap_loadPageFrameBegin = nil;
                self.bap_loadPageFrameEnd = nil;
                self.bap_evalPageFrameEnd = nil;
                self.bap_loadPathFrameBegin = nil;
                self.bap_loadPathFrameEnd = nil;
                self.bap_evalPathFrameEnd = nil;
            } else {
                error = OPErrorWithError(GDMonitorCode.load_path_frame_script_error, error);
                // FG预计于4.6版本下掉
                [self handleBDPDataLoadErrorNotificationWith:error];
            }
        }];
    }];
}

- (void)appPageViewDidLoad {
    BDPTracing *tracing = [BDPTracingManager.sharedInstance getTracingByAppPage:(BDPAppPage *)self];
    [tracing clientDurationTagStart:kEventName_mp_lifecycle_page_start];
    [self newMonitorEvent:kEventName_mp_lifecycle_page_start].flush();

    // appPage被装载了, 尝试加载path-frame.js
    [self loadPathScriptIfNeed];
    // 若DOMReady发生在addAppPage之前, 找到不到AppPage, 导致Event没有Ready, 那eventQueue就不会执行, 尝试fire一下。不然前端收不到消息白屏
    [self notifyDOMReadyIfNeeded];

    self.bap_loadTimingEvent = [BDPTrackerTimingEvent new];
    [self eventPageLoadStartWithUniqueID:self.uniqueID];
}

- (void)handleLoadErrorMsg:(NSString *)errorMsg {
    if (errorMsg) {
        if (self.uniqueID) {
            NSError *error = OPErrorWithMsg(GDMonitorCodeAppLoad.pkg_data_failed, @"page(%@) load failed: %@", self.bap_path ?: @"preload unused", errorMsg);
            // FG预计于4.6版本下掉
            [self handleBDPDataLoadErrorNotificationWith:error];
            
            self.bap_loadErrorMsg = nil;

            [self newMonitorEvent:kEventName_mp_webview_load_exception]
            .setMonitorCode(GDMonitorCode.webview_load_exception)
            .setError(error)
            .flush();

        } else {
            self.bap_loadErrorMsg = errorMsg;

            [self newMonitorEvent:kEventName_mp_webview_load_exception]
            .setMonitorCode(GDMonitorCode.webview_load_exception)
            .setErrorMessage(errorMsg)
            .flush();

        }
    }
}

- (void)tryLoadVdom
{
    if (self.isAppPageReady && self.bap_vdom && !self.didLoadFrameScript && self.bap_loadPageFrameEnd == nil) {
        [self bdp_fireEvent:@"onRenderSnapshot"
                   sourceID:self.appPageID
                       data:self.bap_vdom];
        BDPGadgetLogInfo(@"onRenderSnapshot");
        self.bap_vdom = nil;
    }
}

#pragma mark - BDPWebViewInjectProtocol
/*-----------------------------------------------*/
//  BDPWebViewInjectProtocol - WebViewEngine配置
/*-----------------------------------------------*/
- (void)webViewOnDocumentReady
{
    if (self.isAppPageReady) { // 会有两次, 只要首次预加载的DOMReady
        [self tryLoadVdom]; // 如果有vdom的话，就直接发送.
        return;
    }
    [self newMonitorEvent:kEventName_mp_webview_lib_load_result].setResultType(kEventValue_success).flush();
    [self newMonitorEvent:kEventName_mp_webview_load_dom_ready].flush();
    [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithEndKey:BDPPerformanceWebviewJSSDKLoad uniqueId:self.uniqueID extra:@{
        kBDPPerformanceWebviewId:@(self.appPageID)
                                                                                                                    }];
    self.bap_loadHtmlEnd = [NSDate date];
    self.isAppPageReady = YES;
    [self tryLoadVdom]; // 如果有vdom的话，就直接发送.
    [self tryLoadPageContent];
    [self loadDynamicComponentIfNeed];
    BDPGadgetLogInfo(@"BDPAppPage - webViewOnDocumentReady pageID:%@", @(self.appPageID));
}

- (void)webViewInvokeMethod:(NSString *)event param:(NSDictionary *)param
{
    if ([event isEqualToString:@"reportTimeline"]) {
        if ([param[@"phase"] isEqualToString:@"DOMReady"]) {
            [self handleReportTimelineDomReady];
        }
    } else if ([event isEqualToString:@"postErrors"]) { // 加载过程中出现的错误
        // 在 EEFeatureGatingKeyBDPPiperRegisterOptDisable FG关闭时, 不再允许调用到
        [self handleLoadErrorMsg:[param JSONRepresentation]];
    }
}

- (void)handleReportTimelineDomReady {
    if ([self.appPageDelegate respondsToSelector:@selector(handleReportTimelineDomReady)]) {
        [self.appPageDelegate handleReportTimelineDomReady];
    }
    [self.bap_loadTimingEvent stop];
    [self bap_eventPageLoadResult:BDPTrackerResultSucc errorMsg:nil uniqueID:self.uniqueID];
    BDPTracing *tracing = [BDPTracingManager.sharedInstance getTracingByAppPage:(BDPAppPage *)self];
    [self newMonitorEvent:kEventName_mp_lifecycle_page_onready monitorCode:GDMonitorCodeLifecycle.page_onready]
    .setPlatform(OPMonitorReportPlatformSlardar|OPMonitorReportPlatformTea)
    .kv(@"from_page_start_duration", @([tracing clientDurationTagEnd:kEventName_mp_lifecycle_page_start]))
    .flush();
}

- (void)webViewPublishMessage:(NSString *)event param:(NSDictionary *)param
{
    if ([self.appPageDelegate respondsToSelector:@selector(appPagePublishMessage:event:param:)]) {
        [self.appPageDelegate appPagePublishMessage:(BDPAppPage *)self event:event param:param];
    }
    /** code from houzhiyou
    检测是否是__DOMReady事件来表明页面渲染是否完成，并判断页面发生白屏后做白屏恢复成功的打点
    之前的initReady和onAppRouteDone事件已移除
     {
         event: custom_event_PAGE_EVENT,
         paramsString:{
            data: {
                eventName: "__DOMReady"
            }
         }
     }
    */
    if ([event isEqualToString:@"custom_event_PAGE_EVENT"]) {
        NSString *eventName = [[param bdp_dictionaryValueForKey:@"data"] bdp_stringValueForKey:@"eventName"];
        BDPGadgetLogInfo(@"custom_event_PAGE_EVENT eventName : %@ , appPageID:%@", eventName, @(self.appPageID));
        if ([eventName isEqualToString:@"__DOMReady"]) {

            // 页面白屏恢复成功打点
            BOOL isCrashed = self.isWebViewTerminate;
            if (isCrashed) {
                //线上未查询到这个点位数据，且domready 不代表恢复成功，目前无合适方案来确认是否业务意义上恢复成功。 5.17 暂不修改该埋点字段https://data.bytedance.net/aeolus#/dataQuery?appId=555164&id=1886149227&sid=1184167
                BOOL visible = self.isWebViewTerminatedVisible;
                NSString *crashType = visible ? @"recover_visible" : @"recover_invisible";
                [self newMonitorEvent:kEventName_mp_page_crash].kv(@"crash_status", crashType).flush();
                self.isWebViewTerminate = NO;
            }
        }
    }
}

- (UIViewController *)webViewController
{
    return [self bdp_findFirstViewController];
}

#pragma mark - UIScrollViewDelegate
/*-----------------------------------------------*/
//       UIScrollViewDelegate - 页面滚动代理
/*-----------------------------------------------*/
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self endEditing:YES];
}

#pragma mark - AppPage Config
+ (WKWebViewConfiguration *)userConfigWithWebViewID:(NSInteger)webViewID {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    [config.preferences setValue:@YES forKey:[@[@"allow", @"File", @"AccessF", @"romFileURLs"] componentsJoinedByString:@""]];
    config.userContentController = [[WKUserContentController alloc] init];

    /// 获取小程序容器的 datastore，FG 开启时为 noPersistent
    config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
    return config;
}

#pragma mark - Inner WebView Component
/*-----------------------------------------------*/
//    Inner WebView Component - 内置WebView组件
/*-----------------------------------------------*/
- (void)setIsHasWebView:(BOOL)isHasWebView
{
    _isHasWebView = isHasWebView;
    if (_isHasWebView) {
        self.scrollView.bounces = NO;
    } else {
        BDPPageConfig *pageConfig = [self.bap_config getPageConfigByPath:self.bap_path];
        self.scrollView.bounces = [pageConfig.window.enablePullDownRefresh boolValue];
    }
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/
- (BDPAppPageController * _Nullable)parentController
{
    UIViewController *controller = [self webViewController];
    if ([controller isKindOfClass:[BDPAppPageController class]]) {
        if (((BDPAppPageController *)controller).appPage.appPageID == self.appPageID) {
            return (BDPAppPageController *)controller;
        }
    }
    return nil;
}

- (void)publishEvent:(NSString *)event param:(NSDictionary *)param
{
    if ([self.appPageDelegate respondsToSelector:@selector(appPagePublishMessage:event:param:)]) {
        [self.appPageDelegate appPagePublishMessage:(BDPAppPage *)self event:event param:param];
    }
}

#pragma mark - WKNavigationDelegate
/*-----------------------------------------------*/
//       WKNavigationDelegate - 网页路由协议
/*-----------------------------------------------*/
- (WKNavigation *)reload
{
    WKNavigation *wkNavi = [super reload];

    // 重置状态
    self.isAppPageReady = NO;
    // MEEGO：https://bits.bytedance.net/meego/larksuite/issue/detail/1783944#detail
    // AppPage在触发crash尝试reload时没有将isFireEventReady重新置为NO，有几率在该段时间内收到fireEvent导致reload失败
    self.isFireEventReady = NO;
    self.isNeedRoute = NO;

    self.didNotifyDOMReady = NO;
    self.didLoadFrameScript = NO;
    self.didLoadPathScript = NO;
    self.isWebViewTerminate = YES;
    self.isLoadingPageFrame = NO;
    self.isLoadingPathFrame = NO;

    self.bap_loadHtmlBegin = nil;
    self.bap_loadHtmlEnd = nil;
    self.bap_loadPageFrameBegin = nil;
    self.bap_loadPageFrameEnd = nil;
    self.bap_evalPageFrameEnd = nil;
    self.bap_loadPathFrameBegin = nil;
    self.bap_loadPathFrameEnd = nil;
    self.bap_evalPathFrameEnd = nil;

    [self setupContent];

    return wkNavi;
}

/// 重新加载webView
- (void)reloadWithWebView:(WKWebView *)webView {
    self.totalTerminatedCount ++;
    if ([self isPreload]) {
        // 没被使用的预加载WebView释放掉
        [[NSNotificationCenter defaultCenter]
         postNotificationName:kBDPAppPageTerminatedNotification
         object:nil
         userInfo:@{kBDPAppPageTerminatedUserInfoTypeKey:self}];
        BDPGadgetLogTagInfo(BDPTag.gadget, @"release preload webview");
        return ;
    }
    // 被页面认领过的, 有path的, 直接reload
    if (self.terminatedCount++ < BDPMemoryManager.sharedInstance.maxReloadCount) {
        BDPGadgetLogTagWarn(BDPTag.gadget, @"reload app page for %@, path %@ , current times %d,total times %d ",self.uniqueID, self.bap_path, self.terminatedCount ,self.totalTerminatedCount);
        [super webViewWebContentProcessDidTerminate:webView];
    } else {
        NSString *errorMessage = @"reload app page reach max count";
        BDPGadgetLogTagWarn(BDPTag.gadget, errorMessage);
        OPError* error = OPErrorWithMsg(GDMonitorCode.webview_crash_overload, errorMessage);
        [self showCrashOverloadSceneWithErrorMsg:errorMessage];

        if(self.bdp_isVisible){
            self.overloadMonitorShouldFlushLater = false;
            [self newMonitorEvent:kEventName_mp_page_crash_overload]
            .setMonitorCode(GDMonitorCode.webview_crash_overload)
            .setError(error)
            .addMap([self overloadMonitorParams])
            .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar)
            .flush();
            BDPLogError(@"overreload crash visbile %@",self.uniqueID)
        } else {
            self.overloadMonitorShouldFlushLater = true;
            self.overloadMonitorCategory = [self overloadMonitorParams];
            BDPLogError(@"overreload invisible visbile %@",self.uniqueID)
        }
    }
}

-(void)showCrashOverloadSceneWithErrorMsg:(NSString *)errorMessage{
    self.isShownOverloadPage = true;
    OPError* error = OPErrorWithMsg(GDMonitorCode.webview_crash_overload, errorMessage);
    [OPSDKRecoveryEntrance handleErrorWithUniqueID:self.uniqueID with:error recoveryScene:RecoveryScene.gadgetPageCrashOverload contextUpdater:^(RecoveryContext * _Nonnull context) {
        // 以弱引用的方式将当前发生崩溃的page放到recoveryContext的userInfo中去
        [context setUserInfoWithValue:self key:NSStringFromClass([self class]) weakReference:true];
    }];
}

-(BOOL)isPreload{
    return (!self.bap_path || !self.uniqueID);
}

-(BOOL)shouldCleanForPreload{
    ///如果是预加载页面 且 会配置了 render_crash场景下的预加载回收，则埋点，直接走回收逻辑
    return [self isPreload] && [BDPMemoryManager.sharedInstance shouldTriggerPreloadRenderMemoryCleanWithUniqueId:self.uniqueID];
}

-(BOOL)shouldCleanForBackgroundGadget{
        ///如果不是预加载，且 小程序在后台 且不是主导航小程序， 且 配置了 render_crash下后台小程序清理，则埋点，直接清理， 不再处理后续的reload 等逻辑，减少内存占用和同时触发reload后的卡顿
    return ![self isPreload] && [self gadget_is_background] && ![self isTabGadget] && [BDPMemoryManager.sharedInstance shouldTriggerBackgroundGadgetMemoryCleanWithUniqueId:self.uniqueID] && ![BDPWarmBootManager.sharedManager.uniqueIdInFront containsObject:self.uniqueID];
}

-(BOOL)shouldReloadAfterAppear{
    ///当前不可见 且 settings配置了该appid
    return ![self isPreload] && !self.bdp_isVisible && ![BDPInterruptionManager sharedManager].didEnterBackground && ![self isTabGadget] && [BDPMemoryManager.sharedInstance shouldReloadAfterCrashWithAppID:self.uniqueID.appID];
}

-(BOOL)shouldForceReloadTabGadget{
    return [self isTabGadget] && BDPMemoryManager.sharedInstance.tabReloadEnable && self.isShownOverloadPage;
}


-(BOOL)gadget_is_background{
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    return !common.isForeground;
}

-(BOOL)isCurrentPageVisible{
    return self.bdp_isVisible && ![BDPInterruptionManager sharedManager].didEnterBackground;
}

-(BOOL)isTabGadget{
    OPContainerContext *context = [OPApplicationService.current getContainerWithUniuqeID:self.uniqueID].containerContext;
    OPAppScene scene = context.firstMountData.scene;
    return  (scene == OPAppSceneMainTab || scene == OPAppSceneConvenientTab);
}

-(NSDictionary *)overloadMonitorParams{
    NSString *crashType = [self isCurrentPageVisible] ? @"crash_visible" : @"crash_invisible";
    BOOL is_lark_background = [BDPInterruptionManager sharedManager].didEnterBackground; // 飞书是否后台
    BOOL is_background = [self gadget_is_background];
    BOOL is_tab_gadget = [self isTabGadget];
    return @{@"crash_status": crashType,
             @"is_background":@(is_background),
             @"is_lark_background": @(is_lark_background),
             @"is_tab_gadget": @(is_tab_gadget)};
}

 /// 重新加载当前webview，并将之前已经自动重置过的次数进行清零
 - (void)reloadAndRefreshTerminateState {
     /// toolBar在crashView出现的时候颜色会置为iconN1，点击重试之后刷新appPage，需要重新设定一次toolBar的颜色
     if (self.parentController.toolBarView) {
         [self.parentController.toolBarView setToolBarStyle:self.parentController.toolBarView.toolBarStyle];
     }
     self.terminatedCount = 0;
     self.isShownOverloadPage = false;
     [self reloadWithWebView:self];
     self.parentController.failedRefreshViewIsOn = false;
 }

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    BDPGadgetLogTagWarn(BDPTag.gadget, @"webViewWebContentProcessDidTerminate mp_page_crash %@", self.uniqueID);
    if([self shouldCleanForPreload]){
        [self monitorForPageCrash];
        [BDPMemoryManager.sharedInstance triggerMemoryCleanByRenderCrash];
        return ;
    }
    
    if ([self shouldCleanForBackgroundGadget]) {
        //仅作保险，显示错误页，避免未被回收，但是又没自动reload的情况。理论上不应该看到
        [self showCrashOverloadSceneWithErrorMsg:@"show error scene for clean gadget"] ;
        ///后台小程序触发清理逻辑后，只埋一次
        if(BDPTaskFromUniqueID(self.uniqueID)){
            [self monitorForPageCrash];
            [BDPMemoryManager.sharedInstance triggerMemoryCleanByRenderCrash];
            BDPGadgetLogTagWarn(BDPTag.gadget, @"triggerBackgroundGadgetMemoryClean %@ is cleaned", self.uniqueID);
        } else {
            BDPGadgetLogTagWarn(BDPTag.gadget, @"triggerBackgroundGadgetMemoryClean %@ is cleaning", self.uniqueID);
        }
        return ;
    }
    
    if([self shouldReloadAfterAppear]){
        BDPGadgetLogTagInfo(BDPTag.gadget, @"shouldReloadAfterAppear %@ page_path %@", self.uniqueID, self.bap_path?:@"");
        ///不直接reload，等页面进入可见范围后再reload
        self.shouldReloadAfterPageAppear = true;
        [self monitorForPageCrash];
        [self triggerLifeCycleAfterPageCrash];
        return ;
    }
    
    // 进入后台时, 如果发生Terminate, 不要触发reload
    if ([BDPInterruptionManager sharedManager].didEnterBackground) {
        //  预防重复添加
        if (self.hasAddDidEnterBackgroundObserve) {
            return;
        }
        //  如果是小程序在后台 webview crash，添加一个一次性监听，回到前台 reload 一下
        [BDPInterruptionManager.sharedManager addObserver:self forKeyPath:NSStringFromSelector(@selector(didEnterBackground)) options:NSKeyValueObservingOptionNew context:nil];
        self.hasAddDidEnterBackgroundObserve = YES;
    } else {
        [self reloadWithWebView:webView];
    }
    [self monitorForPageCrash];
    [self triggerLifeCycleAfterPageCrash];
}

-(void)monitorForPageCrash{
    // 判断当前页面是否正在显示
    BOOL visible = [self isCurrentPageVisible];
    self.isWebViewTerminatedVisible = visible;

    NSString *gadget_state = [self isPreload] ? @"preload" : @"running";
    NSMutableDictionary *pageCrashParams = [[NSMutableDictionary alloc] initWithDictionary:[self overloadMonitorParams]];
    [pageCrashParams addEntriesFromDictionary:@{@"gadget_state":gadget_state,
                                                @"reload_count": @(self.totalTerminatedCount),
                                                @"page_path":self.bap_path?:@""
                                              }];
    [self newMonitorEvent:kEventName_mp_page_crash]
    .addMap([pageCrashParams copy])
    .setMonitorCode(GDMonitorCode.webview_crash)
    .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar)
    .flush();
}

-(void)triggerLifeCycleAfterPageCrash{
    BOOL visible = [self isCurrentPageVisible];
    BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
    BDPGadgetLogTagInfo(@"LifeCycle", @"bdp_onPageCrashed %@ %@", self.uniqueID, self.bap_path);
    if ([lifeCyclePlugin respondsToSelector:@selector(bdp_onPageCrashed:page:)]) {
        [lifeCyclePlugin bdp_onPageCrashed:self.uniqueID page:self.appPageID visible:visible];
    }
}

-(void)pageDidAppear{
    if([self shouldForceReloadTabGadget]){
        ///如果 shouldForceReloadTabGadget tab有强制多刷一次的逻辑，则不用上报overload的埋点，多一次强制刷新
        [self forceReloadTabPage];
        self.overloadMonitorShouldFlushLater = false;
    }else if(self.overloadMonitorShouldFlushLater){
        [self flushOverloadMonitorIfNeeded];
        [self reloadWithWebView:self];
        self.shouldReloadAfterPageAppear = false;
    }
}

-(void)flushOverloadMonitorIfNeeded{
    NSString *errorMessage = @"reload app page reach max count";
    BDPGadgetLogTagWarn(BDPTag.gadget, errorMessage);
    OPError* error = OPErrorWithMsg(GDMonitorCode.webview_crash_overload, errorMessage);
    [self newMonitorEvent:kEventName_mp_page_crash_overload]
    .setMonitorCode(GDMonitorCode.webview_crash_overload)
    .setError(error)
    .addMap(self.overloadMonitorCategory?:@{})
    .setPlatform(OPMonitorReportPlatformTea|OPMonitorReportPlatformSlardar)
    .flush();
    BDPLogError(@"mp_page_crash_overload appear %@",self.uniqueID)
    self.overloadMonitorCategory = nil;
    self.overloadMonitorShouldFlushLater = NO;
}

-(void)forceReloadTabPage{
    BDPLogInfo(@"force reloadTabPage after pageDidAppear");
    [self.parentController updateCrashOverloadViewWithShow:false tipText:@""];
    [self reloadAndRefreshTerminateState];
}

-(void)applicationWillEnterForeground{
    if(![self shouldForceReloadTabGadget]){
        return ;
    }
    ///如果 shouldForceReloadTabGadget tab有强制多刷一次的逻辑，则不用上报overload的埋点，多一次强制刷新
    [self forceReloadTabPage];
}

-(void)applicationDidEnterBackground{
    if(!BDPMemoryManager.sharedInstance.backgroundCleanCountEnable){
        return ;
    }
    ///KAR等 会把小程序放在主导航栏上，如果反复飞书切后台，后台webview被kill后，因为主导航栏上的小程序不会被回收，所以增加配置，在切入后台的时候 重置次数
    self.terminatedCount = 0;
}

 - (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
     error = OPErrorWithErrorAndMsg(GDMonitorCode.navigation_delegate_did_fail, error, @"apppage did file didFailProvisionalNavigation with error(%@)", error);
    [self handleBDPDataLoadErrorNotificationWith:error];
 }

 - (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
     error = OPErrorWithErrorAndMsg(GDMonitorCode.navigation_delegate_did_fail, error, @"apppage didFailNavigation with error(%@)", error);
    [self handleBDPDataLoadErrorNotificationWith:error];
 }

#pragma mark - Access

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(didEnterBackground))]) {
        BOOL didEnterBackground = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
        if (didEnterBackground) {
            //  小程序后台不要reload
            return;
        }
        [self reloadWithWebView:self];
        if (!self.hasAddDidEnterBackgroundObserve) {
            return;
        }
        [BDPInterruptionManager.sharedManager removeObserver:self forKeyPath:NSStringFromSelector(@selector(didEnterBackground))];
        self.hasAddDidEnterBackgroundObserve = NO;
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
    } else { // 其他
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSNumber *)isStartPage {
    if (!_isStartPage) {
        if (!self.uniqueID || BDPIsEmptyString(self.bap_path)) {
            return nil;
        }

        BDPCommon *common = BDPCommonFromUniqueID(self.uniqueID);
        if (!common) {
            return nil;
        }
        NSString *startPagePath = common.schema.startPage;
        if (BDPIsEmptyString(startPagePath)) {
            BDPTask *task = BDPTaskFromUniqueID(self.uniqueID);
            startPagePath = task.config.entryPagePath;
            if (BDPIsEmptyString(startPagePath)) {
                return nil;
            }
        }
        _isStartPage = [NSNumber numberWithInt:[self.bap_path isEqualToString:startPagePath]];
    }
    return _isStartPage;
}

#pragma mark - Monitor
- (BDPMonitorEvent *)newMonitorEvent:(NSString *)eventName {
    return [self newMonitorEvent:eventName monitorCode:nil];
}

- (BDPMonitorEvent *)newMonitorEvent:(NSString *)eventName monitorCode:(OPMonitorCode * _Nullable) monitorCode {
    return (BDPMonitorEvent *)BDPMonitorWithNameAndCode(eventName, monitorCode, self.uniqueID)
    .bdpTracing([BDPTracingManager.sharedInstance getTracingByAppPage:(BDPAppPage *)self])
    .kv(@"page_path", self.bap_path)
    .kv(@"first_launch_page", self.isStartPage);
}

- (BDPMonitorEvent *)newMonitorCodeEvent:(OPMonitorCode *)monitorCode {
    return (BDPMonitorEvent *)[self newMonitorEvent:nil].setMonitorCode(monitorCode);
}

#pragma mark - ActionMenu
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (self.bap_pageConfig.window.disableDefaultPopupMenu && self.bap_pageConfig.window.disableDefaultPopupMenu.boolValue) {
        // 禁用页面默认的弹出菜单
        return NO;
    }
    return [super canPerformAction:action withSender:sender];
}

#pragma mark - appType
- (OPAppType)appType {
    return self.uniqueID ? self.uniqueID.appType : OPAppTypeGadget;
}

//原封不动的换了个位置，没有做任何逻辑修改
- (NSString *)bap_pageFramePathWithFlag:(BOOL)isInJSSDK
{
    NSString *path = [self.bap_pageFrameBasePath stringByAppendingFormat:@"/%@", BDP_PAGE_FREAM_NAME]; // page-frame路径
    return isInJSSDK ? [[BDPURLProtocolManager sharedManager] addJSSDKFolderMaskForPath:path] : path;
}

- (void)bap_eventPageLoadResult:(NSString *)resultType errorMsg:(NSString *)errorMsg uniqueID:(OPAppUniqueID *)uniqueID
{
    NSDictionary *trackerParams = @{BDPTrackerResultTypeKey: resultType ?: BDPTrackerResultSucc,
                                    BDPTrackerDurationKey: @(self.bap_loadTimingEvent.duration),
                                    BDPTrackerErrorMsgKey: errorMsg ?: @"",
                                    BDPTrackerPagePathKey: self.bap_path ?: @"",
                                    BDPTrackerPageDarkMode: @(OPIsDarkMode()),
                                    BDPTrackerPageDisableSetDark : @(self.disableSetDarkColorInInit)
    };
    [BDPTracker event:BDPTEPageLoadResult attributes:trackerParams uniqueID:uniqueID];
}

- (void)eventPageLoadStartWithUniqueID:(OPAppUniqueID *)uniqueID
{
    NSDictionary *trackerParams = @{BDPTrackerPagePathKey: self.bap_path ?: @""};
    [BDPTracker event:BDPTEPageLoadStart attributes:trackerParams uniqueID:uniqueID];
}

#pragma mark - 错误自动恢复框架相关方法

/// 重写dataLoadErrorHandleDelegate属性的set方法，一遍在设置代理时能够及时将AppPage中发生的错误传递给delegate
- (void)setDataLoadErrorHandleDelegate:(id<BDPAppPageDataLoadErrorHandleDelegate>)dataLoadErrorHandleDelegate {
    if (_dataLoadErrorHandleDelegate != dataLoadErrorHandleDelegate) {
        _dataLoadErrorHandleDelegate = dataLoadErrorHandleDelegate;
    }
    // 当代理设置进来时，如果代理和待处理的错误都存在，就将待处理的错误交给代理处理
    if (self.dataLoadErrorHandleDelegate && self.pendingDataLoadError) {
        [self.dataLoadErrorHandleDelegate appPage:self didTriggerDataLoadError:self.pendingDataLoadError];
        self.pendingDataLoadError = nil;
    }
}

/// 处理BDPAppPage中发生的数据加载异常
- (void)handleBDPDataLoadErrorNotificationWith:(NSError *)error {
    // 1. 有dataLoadErrorHandleDelegate代理，直接将错误传给代理处理
    // 2. 没有代理，将错误暂存进pendingDataLoadError(存在多个错误时仅记录第一个发生的错误)
    if (self.dataLoadErrorHandleDelegate) {
        [self.dataLoadErrorHandleDelegate appPage:self didTriggerDataLoadError:error];
    } else {
        self.pendingDataLoadError = self.pendingDataLoadError ?: error;
    }
}

#pragma mark - DarkMode

- (void)initTheme {
    if (!self.uniqueID.isAppSupportDarkMode) {
        // 小程序不支持 DarkMode 则强制为 Light
        if(OPSDKFeatureGating.shouldDisableAppPageDefaultDarkMode) {
            if (@available(iOS 13.0, *)) {
                //make sure api which related about UI always manipulated in main thread.
                if(BDPIsMainQueue()){
                    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
                    });
                }
            }
        }
    }
    // 不管小程序是否支持 DarkMode，都要执行这个逻辑
    BOOL darkMode = self.uniqueID.isAppDarkMode;
    [self bdp_fireEvent:OPThemeEventOnThemeInit sourceID:self.appPageID data:@{
        OPThemeKey: darkMode ? OPThemeValueDark : OPThemeValueLight
    }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        BDPGadgetLogInfo(@"traitCollectionDidChange. previous:%@, current:%@", @(previousTraitCollection.userInterfaceStyle), @(self.traitCollection.userInterfaceStyle));
        if (!self.uniqueID.isAppSupportDarkMode) {
            // 不支持 DarkMode
            BDPGadgetLogInfo(@"%@ not support dark mode", self.uniqueID);
            return;
        }
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            BOOL darkMode = self.uniqueID.isAppDarkMode;
            [self bdp_fireEvent:OPThemeEventOnThemeChange sourceID:self.appPageID data:@{
                OPThemeKey: darkMode ? OPThemeValueDark : OPThemeValueLight
            }];
        }
    }
}

@end

extern BOOL IsGadgetWebView(id object) {
    return ([object isKindOfClass:BDPAppPage.class]);
}

@implementation BDPAppPage (DynamicCompnent)
- (void)appendEvaluateDynamicComponentJSCallback:(EvaluateDynamicCompentJSCallback)callback {
    if (![OPDynamicComponentHelper enableDynamicComponent:self.uniqueID]) {
        BDPLogInfo(@"[Load Dynamic Script] settings enable is false");
        return;
    }

    if (!callback) {
        BDPLogInfo(@"[Load Dynamic Script] EvaluateDynamicCompentJSCallback is nil");
        return;
    }

    BDPExecuteOnMainQueue(^{
        if (!self.evaluateDynamicCompentCallbackArray) {
            self.evaluateDynamicCompentCallbackArray = [NSMutableArray array];
        }
        
        if ([self.evaluateDynamicCompentCallbackArray containsObject:callback]) {
            BDPLogInfo(@"[Load Dynamic Script] callback is already exsit");
            return;
        }
        
        [self.evaluateDynamicCompentCallbackArray addObject:callback];
    });
}

- (void)loadDynamicComponentIfNeed {
    if (![OPDynamicComponentHelper enableDynamicComponent:self.uniqueID]) {
        BDPLogInfo(@"[Load Dynamic Script] settings enable is false");
        return;
    }

    BDPExecuteOnMainQueue(^{
        // 没有evaluateDynamicCompentCallbackArray数组,代表loadPlugin并没有往数组中添加执行JS代码的callback方法
        if (!self.evaluateDynamicCompentCallbackArray) {
            BDPLogInfo(@"[Load Dynamic Script] evaluateDynamicCompentCallbackArray is not init");
            return;
        }

        BDPLogInfo(@"[Dynamic Component] start load dynamic component,  uniqueID: %@ webviewId:%zd, path: %@", BDPSafeString(self.uniqueID.appID), self.appPageID, BDPSafeString(self.bap_path));
        NSMutableArray *array = self.evaluateDynamicCompentCallbackArray;
        NSInteger callbackCount = [array count];
        if (callbackCount > 0) {
            BDPLogInfo(@"[Dynamic Component] start callback from evaluateDynamicCompentCallbackArray: %zd uniqueID: %@ webviewId:%zd, path: %@", callbackCount, BDPSafeString(self.uniqueID.appID), self.appPageID, BDPSafeString(self.bap_path));
            for (EvaluateDynamicCompentJSCallback callback in array) {
                if (!callback) { continue; }
                callback();
            }
            [array removeAllObjects];
        } else {
            BDPLogInfo(@"[Dynamic Component] evaluateDynamicCompentCallbackArray count is 0, uniqueID: %@ webviewId:%zd, path: %@", BDPSafeString(self.uniqueID.appID), self.appPageID, BDPSafeString(self.bap_path));
        }
    });
}

- (NSMutableArray *)evaluateDynamicCompentCallbackArray {
    return objc_getAssociatedObject(self, @selector(setEvaluateDynamicCompentCallbackArray:));
}

- (void)setEvaluateDynamicCompentCallbackArray:(NSMutableArray *)evaluateDynamicCompentCallbackArray {
    objc_setAssociatedObject(self, _cmd, evaluateDynamicCompentCallbackArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
