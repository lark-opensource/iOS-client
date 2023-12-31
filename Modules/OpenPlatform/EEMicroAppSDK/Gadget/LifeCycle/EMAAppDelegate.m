//
//  EMAAppDelegate.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/12/2.
//

#import "EMAAppDelegate.h"
#import "BDPPluginLoadingViewCustomImpl.h"
#import "EMAAppEngine.h"
#import <ECOInfra/EMAConfigManager.h>
#import <OPFoundation/EMADebugUtil.h>
#import "EMALibVersionManager.h"
#import "EMAComponentsVersionManager.h"
#import "EMALifeCycleManager.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <LarkOPInterface/LarkOPInterface-Swift.h>
#import <ECOProbe/OPMonitorServiceConfig.h>
#import <TTMicroApp/BDPAppPageFactory.h>
#import <TTMicroApp/BDPBaseContainerController.h>
#import <TTMicroApp/BDPCPUMonitor.h>
#import <OPFoundation/BDPCommonManager.h>
#import <TTMicroApp/BDPJSRuntimePreloadManager.h>
#import <TTMicroApp/BDPTaskManager.h>
#import <TTMicroApp/BDPTimorClient+Business.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPVersionManager.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <LKLoadable/Loadable.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/OPFoundation-Swift.h>

@interface EMAAppDelegate () <EMALifeCycleListener, BDPJSRuntimeDelegate, EMAConfigManagerDelegate>

@property (nonatomic, strong) OPMonitorEvent *launchEvent;     // 启动全流程埋点（https://bytedance.feishu.cn/docs/doccnTZVa3Fl1C9LbnpMvMW0thb#）
@property (nonatomic, assign) NSTimeInterval startTime;

@end

static NSTimeInterval gAppLaunchTime;

LoadableMainFuncBegin(EMAAppDelegateGetAppLaunchTime)
gAppLaunchTime = NSDate.date.timeIntervalSince1970;
LoadableMainFuncEnd(EMAAppDelegateGetAppLaunchTime)

@implementation EMAAppDelegate

+ (NSTimeInterval)appLaunchTime {
    return gAppLaunchTime;
}

- (NSInteger)durationToStartTimeInMS {
    if (self.startTime) {
        return (NSInteger)((NSDate.date.timeIntervalSince1970 - self.startTime) * 1000);
    } else {
        return 0;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(forceJSSDKUpdate:)
                                                     name:BDPJSSDKSyncForceUpdateBeginNoti
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)forceJSSDKUpdate:(NSNotification *)notification
{
    [EMAAppEngine.currentEngine.configManager updateConfig];
}


- (void)onContainerLoaded:(BDPUniqueID *)uniqueID container:(UIViewController *)container {
    // 适配Lark，标记小程序的主容器，避免小程序内部导航被 Lark 主端探测并用于 push 其他 VC
    [EENavigatorBridge setSupportNavigatorWithViewController:container supportNavigator:NO];
}

// 小程序开始加载
- (void)onStart:(nonnull BDPUniqueID *)uniqueID {
    if (EMAAppEngine.currentEngine.onlineConfig.enableAppLaunchDetailEvent) {
        [self flushAppLaunchDetailEvent:NO];

        self.startTime = NSDate.date.timeIntervalSince1970;
        self.launchEvent = BDPMonitorWithName(kEventName_mp_app_launch_detail, uniqueID).enableThreadSafe().timing()
        .kv(@"time_to_lark_launch", @((NSInteger)((self.startTime - gAppLaunchTime) * 1000)))
        .kv(@"cpu_max", (NSInteger)BDPCPUMonitor.cpuUsage);

        id preloadpJSContextApp = BDPJSRuntimePreloadManager.sharedManager.preloadRuntimeApp;
        NSInteger jscorePreload = preloadpJSContextApp?1:0;
        self.launchEvent.kv(@"jscore_preload", jscorePreload);

        id preloadpAppPage = BDPAppPageFactory.sharedManager.preloadAppPage;
        NSInteger appPagePreload = preloadpAppPage?1:0;
        self.launchEvent.kv(@"webview_preload", appPagePreload);

        WeakSelf;
        __weak typeof(self.launchEvent) wLaunchEvent = self.launchEvent;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            __strong typeof(wLaunchEvent) launchEvent = wLaunchEvent;
            if (!launchEvent) {
                return;
            }
            [self flushAppLaunchDetailEvent:YES];
        });
    }

    // 小程序每次启动前，设置小程序的 loading 页面隐藏动画时间
    NSTimeInterval duration = [EMAAppEngine.currentEngine.onlineConfig loadingDismissScaleAnimationDurationForUniqueID:uniqueID];
    if (duration > 0) {
        BDPAppearanceConfiguration *config = BDPTimorClient.sharedClient.appearanceConfg;
        config.loadingViewDismissAnimationDuration = duration;
    }
}

- (void)onModelFetchedForUniqueID:(BDPUniqueID *)uniqueID isSilenceFetched:(BOOL)isSilenceFetched isModelCached:(BOOL)isModelCached appModel:(BDPModel *)appModel error:(NSError *)error {
    if (!isSilenceFetched) {
        if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
            if (appModel) {
                NSInteger durationMS = self.durationToStartTimeInMS;
                NSString *pkgUrl = appModel.urls.firstObject.absoluteString;
                NSInteger packageCache = isModelCached?1:0;
                self.launchEvent
                .kv(@"meta_duration", durationMS)
                .kv(@"meta_cache", packageCache)
                .kv(@"pkg_url", pkgUrl);
            } else if(error) {
                self.launchEvent.setError(error);
            }
        }
    } else {
        BDPTask *task = BDPTaskFromUniqueID(uniqueID);
        BDPCommon *common = BDPCommonFromUniqueID(uniqueID);

        BDPModel *curModel = common.model;
        
        BOOL hasUpdate = [appModel isNewerThanAppModel:curModel];
        BDPBaseContainerController *baseVC = (BDPBaseContainerController *)task.containerVC;
        if ([baseVC isKindOfClass:BDPBaseContainerController.class]) {
            if (![baseVC checkModelStatus:curModel isAsyncUpdate:YES]) {
                hasUpdate = NO;
            }
        }
        BDPMonitorWithName(kEventName_mp_launch_package_result, uniqueID)
        .kv(kEventKey_result_type, hasUpdate?@"checked_new":@"cached_new")
        .flush();
    }
}

- (void)onPkgFetched:(BDPUniqueID *)uniqueID error:(NSError *)error {
    if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
        if (error) {
            self.launchEvent.setError(error);
        } else {
            NSInteger durationMS = self.durationToStartTimeInMS;
            self.launchEvent.kv(@"package_duration", durationMS);
        }
    }
}

- (void)beforeLaunch:(BDPUniqueID *)uniqueID {
    if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
        [task.context.otherDelegates removeDelegate:self];
        [task.context.otherDelegates addDelegate:self];

        BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
        NSInteger packageCache = common.reader.createLoadStatus < BDPPkgFileLoadStatusDownloaded ? 0: 1;
        NSInteger durationMS = self.durationToStartTimeInMS;
        self.launchEvent.kv(@"app_launch_duration", durationMS)
        .kv(@"start_page_path", common.coldBootSchema.startPagePath)
        .kv(@"schema", common.coldBootSchema.originURL.absoluteString)
        .kv(@"package_cache", packageCache);

        if (EMADebugUtil.sharedInstance.enable) {
            [EMADebugUtil.sharedInstance debugConfigForID:kEMADebugConfigIDRecentOpenURL].stringValue = common.coldBootSchema.originURL.absoluteString;
        }

        if (!packageCache) {
            BDPMonitorWithName(kEventName_mp_launch_package_result, uniqueID)
            .kv(kEventKey_result_type, @"download_just_now")
            .flush();
        }
    }
}

- (void)onLaunch:(BDPUniqueID *)uniqueID {
    BDPPlugin(loadingViewPlugin, BDPLoadingViewPluginDelegate);
    if ([loadingViewPlugin isKindOfClass:BDPPluginLoadingViewCustomImpl.class] && [loadingViewPlugin respondsToSelector:@selector(hideLoadingView)]) {
        BDPPluginLoadingViewCustomImpl *impl = (BDPPluginLoadingViewCustomImpl *)loadingViewPlugin;
        [impl hideLoadingView];
    }

    if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
        NSInteger durationMS = self.durationToStartTimeInMS;
        self.launchEvent.kv(kEventKey_result_type, kEventValue_success).kv(@"dom_ready_duration", durationMS);
    }
}

- (void)onCancel:(BDPUniqueID *)uniqueID {
    if (self.launchEvent && !self.launchEvent.flushed) {
        NSInteger durationMS = self.durationToStartTimeInMS;
        self.launchEvent.kv(kEventKey_result_type, @"cancel").kv(@"cancel_duration", durationMS);
        [self flushAppLaunchDetailEvent:NO];
    }
}

- (void)onFailure:(BDPUniqueID *)uniqueID code:(EMALifeCycleErrorCode)code msg:(NSString *)msg {
    if (self.launchEvent && !self.launchEvent.flushed) {
        NSInteger durationMS = self.durationToStartTimeInMS;
        self.launchEvent.kv(kEventKey_result_type, msg).kv(kEventKey_error_code, code).kv(kEventKey_error_msg, msg).kv(@"fail_duration", durationMS);
        [self flushAppLaunchDetailEvent:NO];
    }
}

- (void)beforeLoadAppServiceJS:(BDPUniqueID *)uniqueID {
    if (self.launchEvent && !self.launchEvent.flushed) {
        BDPTask *task = BDPTaskFromUniqueID(uniqueID);

        NSInteger durationMS = self.durationToStartTimeInMS;
        self.launchEvent.kv(@"first_page_start_duration", durationMS);

        BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
        WeakSelf;
        [common.reader getFileSizeInPkg:@"app-service.js" withCompletion:^(int64_t size) {
            StrongSelfIfNilReturn;
            if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
                self.launchEvent.kv(@"app_service_js_size", size);
            }
        }];
        [common.reader getFileSizeInPkg:@"page-frame.js" withCompletion:^(int64_t size) {
            StrongSelfIfNilReturn;
            if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
                self.launchEvent.kv(@"page_frame_js_size", size);
            }
        }];
        NSString *currentPage = task.currentPage.path;
        if (!BDPIsEmptyString(currentPage)) {
            NSString *firstPagefilePath = [currentPage stringByAppendingString:@"-service.js"];
            [common.reader getFileSizeInPkg:firstPagefilePath withCompletion:^(int64_t size) {
                StrongSelfIfNilReturn;
                if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
                    self.launchEvent.kv(@"first_page_js_size", size);
                }
            }];
            NSString *firstPageFramefilePath = [currentPage stringByAppendingString:@"-frame.js"];
            [common.reader getFileSizeInPkg:firstPageFramefilePath withCompletion:^(int64_t size) {
                StrongSelfIfNilReturn;
                if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
                    self.launchEvent.kv(@"first_page_frame_js_size", size);
                }
            }];
        }
    }
}

- (void)beforeLoadPageFrameJS:(BDPUniqueID *)uniqueID page:(NSInteger)appPageId {
    if (self.launchEvent && !self.launchEvent.flushed) {
        BDPTask *task = BDPTaskFromUniqueID(uniqueID);
        BDPAppPage *page = [task.pageManager appPageWithID:appPageId];
        if ([page.bap_path isEqualToString:task.currentPage.path]) {
            NSInteger durationMS = self.durationToStartTimeInMS;
            self.launchEvent.kv(@"page_frame_start_duration", durationMS);
        }
    }
}

- (void)beforeLoadPageJS:(BDPUniqueID *)uniqueID page:(NSInteger)appPageId {
    if (self.launchEvent && !self.launchEvent.flushed) {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
        BDPAppPage *page = [task.pageManager appPageWithID:appPageId];
        if ([page.bap_path isEqualToString:task.currentPage.path]) {
            NSInteger durationMS = self.durationToStartTimeInMS;
            self.launchEvent.kv(@"first_page_frame_start_duration", durationMS);
        }
    }
}

- (void)onPageDomReady:(BDPUniqueID *)uniqueID page:(NSInteger)appPageId {
    if (self.launchEvent && !self.launchEvent.flushed) {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
        BDPAppPage *page = [task.pageManager appPageWithID:appPageId];
        if ([page.bap_path isEqualToString:task.currentPage.path]) {
            NSInteger durationMS = self.durationToStartTimeInMS;
            self.launchEvent.kv(@"first_page_frame_dom_ready_duration", durationMS);
        }
    }
}

- (void)onFirstFrameRender:(BDPUniqueID *)uniqueID {
    if (self.launchEvent && !self.launchEvent.flushed) {
        NSInteger durationMS = self.durationToStartTimeInMS;
        self.launchEvent.kv(@"first_render_duration", durationMS);
        [self flushAppLaunchDetailEvent:NO];
    }
}

- (void)onPageCrashed:(BDPUniqueID *)uniqueID page:(NSInteger)appPageId visible:(BOOL)visible {
    if (self.launchEvent && !self.launchEvent.flushed) {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID];
        BDPAppPage *page = [task.pageManager appPageWithID:appPageId];
        if ([page.bap_path isEqualToString:task.currentPage.path]) {
            self.launchEvent.kv(@"first_page_webview_crash", 1);
        }
    }
}

- (void)flushAppLaunchDetailEvent:(BOOL)timeout {
    if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
        if (timeout) {
            NSInteger durationMS = self.durationToStartTimeInMS;
            self.launchEvent.kv(@"timeout_duration", durationMS);
        }
        self.launchEvent.timing().flush();
        self.startTime = 0;
    }
}

#pragma mark - BDPJSRuntimeDelegate
- (void)onJSRuntimeLogException:(JSValue *)exception {
    if (exception) {
        JSValue *line = [exception valueForProperty:@"line"];
        JSValue *file = [exception valueForProperty:@"sourceURL"];
        NSString *message = [NSString stringWithFormat:@"%@ \n at %@:%@", [exception toString], [file toString], [line toString]];

        if (self.launchEvent && !self.launchEvent.flushed) {
            self.launchEvent.kv(@"jscore_js_exception", 1);
            self.launchEvent.kv(@"jscore_js_exception_info", message);
        }
    }
}

- (void)jsRuntimeOnDocumentReady {
    if (self.launchEvent && !self.launchEvent.flushed && self.startTime) {
        NSInteger durationMS = self.durationToStartTimeInMS;
        self.launchEvent.kv(@"app_service_dom_ready_duration", durationMS);
    }
}

#pragma mark - EMAConfigManagerDelegate
- (void)configDidUpdate:(ECOConfig *)config error:(NSError * _Nullable)error {
    if (!error) {
        [EMAAppEngine.currentEngine.onlineConfig checkTMASwitch];
        [EMAAppEngine.currentEngine.onlineConfig registerBackgroundAppSettings];
        [EMAAppEngine.currentEngine.onlineConfig updateJSSDKConfig];
    }

    // 在迁移过程中（4.5～）由settings覆盖mina配置，迁移完成后统一走settings配置下发逻辑
    [OPMonitorServiceConfig.globalRemoteConfig buildConfigWithConfig:EMAAppEngine.currentEngine.onlineConfig.monitorConfig];

    // 配置中心配置更新
    [EMADebugUtil.sharedInstance updateDebug];

    [EMAAppEngine.currentEngine.libVersionManager updateLibIfNeed];
    if ([OPVersionDirHandler sharedInstance].enableFixBlockCopyBundleIssue) {
        [BDPVersionManager setupBundleVersionIfNeed:OPAppTypeBlock];
    }
    [EMAAppEngine.currentEngine.libVersionManager updateBlockLibIfNeed]; // 更新block js sdk

    // 更新消息卡片jssdk
    if([OPSDKFeatureGating enableMsgCardJSSDKUpdate]){
        [EMAAppEngine.currentEngine.libVersionManager updateCardMsgLibIfNeedWithComplete:nil];
    }
    // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
    [EMAAppEngine.currentEngine.componentsVersionManager updateComponentsIfNeeded];

    // 评论组件worker更新. 搜索[COMMENT]可以找到相关信息
    if ([EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWorkerCheckOnLaunchEnable]) {
        [EMAAppEngine.currentEngine.commnentVersionManager updateAllCommentComponetsIfNeeded];
    }
//    if ([OPSDKFeatureGating isWebappOfflineEnable]) {
//        [EMAAppEngine.currentEngine.componentResourceManager updateAllComponetsIfNeeded];
//    }
    [EMAAppEngine.currentEngine.componentResourceManager updateAllComponetsIfNeeded];
}

@end
