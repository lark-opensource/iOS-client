//
//  BDPAppPageFactory.m
//  Timor
//
//  Created by liubo on 2019/5/14.
//

#import "BDPAppPageFactory.h"
#import "BDPAppPage.h"
#import <OPFoundation/BDPCommon.h>
#import "BDPInterruptionManager.h"
#import <OPFoundation/BDPMacroUtils.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPNotification.h>
#import <OPFoundation/BDPResponderHelper.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import "BDPGadgetLog.h"
#import "BDPAppLoadManager.h"
#import "BDPTracingManager+Gadget.h"
#import <OPFoundation/BDPMonitorEvent.h>

@interface BDPAppPageFactory ()

@property (nonatomic, strong, readwrite) BDPAppPage *preloadAppPage;
@property (nonatomic, strong) WKProcessPool *preloadProcessPool;
@property (nonatomic, weak) id token;
@property (nonatomic, weak) id activeBgToken;
@property (nonatomic, strong) NSString * releaseReason;
@property (nonatomic, assign) BOOL isPreloadingPage;
@property (nonatomic, strong) NSString * preGadgetAppId;
@property (nonatomic, strong) NSString * preGadgetStartPath;
@property (nonatomic, assign) NSTimeInterval preGadgetStartTime;
@property (nonatomic, assign) NSInteger indexForOpenGadget;
@property (nonatomic, copy) NSString *preloadFrom;
@property (nonatomic, assign) NSTimeInterval activeBgPreloadTime;
@property (nonatomic, assign) NSTimeInterval preActiveBgTime; //上次后台切前台时间

@end

@implementation BDPAppPageFactory

#pragma mark - Init

+ (instancetype)sharedManager {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDPAppPageFactory alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _indexForOpenGadget = 1;
        _activeBgPreloadTime = -1;
        _preActiveBgTime = -1;
        [self buildAppPageFactory];
    }
    return self;
}

- (void)dealloc {
    id strongToken = self.token;
    if (strongToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:strongToken];
    }

    id strongActiveToken = self.activeBgToken;
    if (strongActiveToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:strongActiveToken];
    }
}

- (void)buildAppPageFactory {
    WeakSelf;
    self.token =
    [[NSNotificationCenter defaultCenter] addObserverForName:kBDPAppPageTerminatedNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        StrongSelfIfNilReturn;
        [self releaseTerminatedPreloadAppPage:note.userInfo[kBDPAppPageTerminatedUserInfoTypeKey]];
    }];

    self.activeBgToken =[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        StrongSelfIfNilReturn;
        self.preActiveBgTime = [[NSDate date] timeIntervalSince1970];
        if (OPSDKFeatureGating.enableWebViewPreloadFromActivebg) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self checkPreloadActiveFromBackground];
            });
        }
    }];
}

#pragma mark - Preload webView from background

- (void)checkPreloadActiveFromBackground {
    BDPExecuteOnMainQueue(^{
        if (self.preloadAppPage || self.isPreloadingPage || [BDPInterruptionManager sharedManager].didEnterBackground) {
            return;
        }
        // 如果距上次预加载时间间隔小于5s，就不进行预加载，控制一下频率
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        if (self.activeBgPreloadTime > 0 && (currentTime - self.activeBgPreloadTime) < 5) {
            return;
        }
        self.activeBgPreloadTime = currentTime;
        self.preloadFrom = @"active_from_background";
        [self tryPreloadAppPage];
    });
}


/// 重写preLoadAppPage属性的setter，将objectState变更为预期状态
- (void)setPreloadAppPage:(BDPAppPage *)preloadAppPage {
    if (preloadAppPage != _preloadAppPage) {
        // 旧page变为预期销毁状态，新page取代旧page变为预期持有状态
        [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedDestroy for:_preloadAppPage];
        [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedRetain for:preloadAppPage];
        _preloadAppPage = preloadAppPage;
        BDPGadgetLogInfo(@"BDPAppPageFactory - setPreLoadAppPage preloadAppPageID: %@", @(preloadAppPage.appPageID));
        // 重新预加载，重置释放状态
        if (preloadAppPage) {
            _releaseReason = nil;
            _preloadAppPage.finishedInitTime = [[NSDate date] timeIntervalSince1970];
        }
    }
}
#pragma mark - Interface

- (BDPAppPage *)appPageWithUniqueID:(BDPUniqueID *)uniqueID {
    if (!uniqueID) {
        return nil;
    }
    
    __block BDPAppPage *resultAppPage = nil;
    if ([[NSThread currentThread] isMainThread]) {
        resultAppPage = [self getPreloadAppPageWithUniqueID:uniqueID];
    } else {
        WeakSelf;
        dispatch_sync(dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            resultAppPage = [self getPreloadAppPageWithUniqueID:uniqueID];
        });
    }
    [[BDPTracingManager.sharedInstance getTracingByUniqueID:uniqueID] linkTracing:[BDPTracingManager.sharedInstance getTracingByAppPage:resultAppPage]];
    return resultAppPage;
}

- (void)releaseTerminatedPreloadAppPage:(BDPAppPage *)page {
    BDPExecuteOnMainQueue(^{
        if (page == self.preloadAppPage) {
            self.releaseReason = @"render_terminate";
            self.preloadAppPage = nil;
            BDPGadgetLogInfo(@"BDPAppPageFactory - releaseTerminatedPreloadAppPage self.preloadAppPageID: %@", @(self.preloadAppPage.appPageID));
        }
    });
}

- (void)reloadPreloadedAppPage {
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        // 判断是否需要禁止预加载，提升预加载使用率
        if([self checkDisablePreloadIfNeed]){
            return;
        }

        BOOL needNotification = NO;
        if (self.preloadAppPage != nil) {
            needNotification = YES;
        }
        
        self.preloadAppPage = nil;
        self.preloadAppPage = [self createAppPage];
        self.preloadAppPage.preloadFrom = self.preloadFrom;
        // webview 预加载埋点，用于统计预加载量级
        [BDPWebViewRuntimePreloadManager monitorEvent:@"render_start" params:@{@"from":OPSafeString([self.preloadFrom copy])}];
        self.preloadFrom = nil;

        BDPGadgetLogInfo(@"BDPAppPageFactory - reloadPreLoadAppPage self.preloadAppPageID: %@", @(self.preloadAppPage.appPageID));

        if (needNotification) { // 通知所有小程序需要重新创建预加载的webview
            [[NSNotificationCenter defaultCenter] postNotificationName:kBDPAppPageFactoryReloadNotification object:nil];
        }
    });
}

- (void)releaseAllPreloadedAppPage {
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn
        self.preloadAppPage = nil;
    });
    BDPGadgetLogInfo(@"BDPAppPageFactory - releaseAllPreloadedAppPage AppPageID:%@", @(self.preloadAppPage.appPageID));
}

+ (void)releaseAllPreloadedAppPageWithReason:(NSString * _Nonnull)reason {
    BDPExecuteOnMainQueue(^{
        BDPAppPageFactory *pageManager = [BDPAppPageFactory sharedManager];
        if (pageManager.preloadAppPage) {
            pageManager.releaseReason = [reason copy];
            [pageManager releaseAllPreloadedAppPage];
        }
    });
}

- (void)tryPreloadAppPage {
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn
        if (!self.preloadAppPage) {
            // 判断是否需要禁止预加载，提升预加载使用率
            if([self checkDisablePreloadIfNeed]){
                return;
            }

            self.preloadAppPage = [self createAppPage];
            // webview 预加载埋点，用于统计预加载量级
            [BDPWebViewRuntimePreloadManager monitorEvent:@"render_start" params:@{@"from":OPSafeString([self.preloadFrom copy])}];
            self.preloadAppPage.preloadFrom = self.preloadFrom;
            self.preloadFrom = nil;
        }
    });
}

#pragma mark - App Page

- (BDPAppPage *)createAppPage {
    // 原本逻辑为取mainscreen的bounds, 适配iPad，统一换成用[BDPResponderHelper windowSize]取window的bounds
    // TODO: 预加载的 AppPage 还不能确定在哪个 window 加载，在真实加载后还需要重新layout
    self.isPreloadingPage = YES;
    BOOL enableAllHandle = [GadgetSchemeHandlerUtil enableAllHandle];
    BDPAppPage *appPage = [[BDPAppPage alloc] initWithFrame:CGRectMake(0, 0,
                                                                       [BDPResponderHelper windowSize:OPWindowHelper.fincMainSceneWindow].width,
                                                                       [BDPResponderHelper windowSize:OPWindowHelper.fincMainSceneWindow].height)
                                                                       delegate:nil enableSchemeHandler:enableAllHandle];
    self.isPreloadingPage = NO;
    return appPage;
}


- (BDPAppPage *)createAppPageFromSchemaHandler {
    // 原本逻辑为取mainscreen的bounds, 适配iPad，统一换成用[BDPResponderHelper windowSize]取window的bounds
    // TODO: 预加载的 AppPage 还不能确定在哪个 window 加载，在真实加载后还需要重新layout
    BDPAppPage *appPage = [[BDPAppPage alloc] initWithFrame:CGRectMake(0, 0,
                                                                       [BDPResponderHelper windowSize:OPWindowHelper.fincMainSceneWindow].width,
                                                                       [BDPResponderHelper windowSize:OPWindowHelper.fincMainSceneWindow].height)
                                                                       delegate:nil enableSchemeHandler:YES];
    return appPage;
}


- (BDPAppPage *)getPreloadAppPageWithUniqueID:(BDPUniqueID *)uniqueID {
    BDPAppPage *resultAppPage = nil;
    BDPMonitorEvent *monitor = BDPMonitorWithCode(EPMClientOpenPlatformGadgetLaunchRenderCode.render_load_result, uniqueID).timing();
    
    NSString *preloadReason = nil;
    NSString *appIds = BDPSafeString(uniqueID.appID);
    // schema handler 仅白名单生效，每次页面打开或者获取appPage都创建新的开关，并且打开schema handler
    if(![GadgetSchemeHandlerUtil enableAllHandle] && [GadgetSchemeHandlerUtil enableHandleWithAppId:appIds]) {
        monitor.addMetricValue(@"is_preloaded",0);
        resultAppPage = [self createAppPageFromSchemaHandler];
        preloadReason = @"enable_scheme_handler";
    }else {
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        if([BDPPerformanceProfileManager.sharedInstance enableProfileForCommon:common] && !BDPPerformanceProfileManager.sharedInstance.isDomready){
            resultAppPage = [self createAppPage];
            ///使用的是metric，目的是 bytest 可配置相应的指标，方便查看是否是预加载
            monitor.addMetricValue(@"is_preloaded",0);
            preloadReason = @"pre_preload_empty";
        } else if (self.preloadAppPage) {
            resultAppPage = self.preloadAppPage;
            self.preloadAppPage = nil;
            ///使用的是metric，目的是 bytest 可配置相应的指标，方便查看是否是预加载
            monitor.addMetricValue(@"is_preloaded",1);
            // 记录被消费，同时2s 后会触发预加载，需要保存预加载来源
            self.releaseReason = @"consumed";
            preloadReason = @"consumed";
        } else {
            resultAppPage = [self createAppPage];
            ///使用的是metric，目的是 bytest 可配置相应的指标，方便查看是否是预加载
            monitor.addMetricValue(@"is_preloaded",0);
            preloadReason = @"pre_preload_empty";
        }
    }
    //更新BDPAppPage
    [resultAppPage setupAppPageWithUniqueID:uniqueID];

    WeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        StrongSelfIfNilReturn;
        if (!self.preloadAppPage && ![BDPInterruptionManager sharedManager].didEnterBackground) {
            self.preloadAppPage = [self createAppPage];
            self.preloadAppPage.preloadFrom = [preloadReason copy];
            // webview 预加载埋点，用于统计预加载量级
            [BDPWebViewRuntimePreloadManager monitorEvent:@"render_start" params:@{@"from":OPSafeString([preloadReason copy])}];
        }
    });
    monitor.timing().flush();
    return resultAppPage;
}

#pragma mark - ProcessPool
- (WKProcessPool *)getPreloadProcessPool {
    __block WKProcessPool *bPool = nil;
    BDPExecuteOnMainQueueSync(^{
        bPool = self.preloadProcessPool ?: [self createProcessPool];
    });
    return bPool;
}

- (void)tryPreloadPrecessPool {
    BDPExecuteOnMainQueue(^{
        if (!self.preloadProcessPool) {
            self.preloadProcessPool = [self createProcessPool];
        }
    });
}

- (WKProcessPool *)createProcessPool {
    return [[WKProcessPool alloc] init];
}

#pragma mark - Preload Track Info

- (void)updatePreloadFrom:(NSString * _Nonnull)preloadFrom {
    BDPExecuteOnMainQueue(^{
        // 如果预加载已完成，或在创建中状态，无需要更新预加载来源信息
        if (self.preloadAppPage || self.isPreloadingPage) {
            return;
        }
        self.preloadFrom = [preloadFrom copy];
    });
}

- (void)updatePreGadget:(NSString * _Nullable)appId startPath:(NSString *_Nullable)startPath {
    BDPExecuteOnMainQueue(^{
        if (![appId isKindOfClass:[NSString class]] || appId.length <= 0) {
            return;
        }
        self.preGadgetAppId = appId;
        self.preGadgetStartPath = startPath;
        self.preGadgetStartTime = [[NSDate date] timeIntervalSince1970];
        self.indexForOpenGadget ++;
    });
}

- (NSDictionary<NSString *, id> * _Nonnull)pagePreloadAndPreGadgetInfo {
    __block NSMutableDictionary<NSString *, id> *trackInfo = [NSMutableDictionary dictionaryWithCapacity:4];
    BDPExecuteOnMainQueueSync(^{
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        int preloadState = 0;
        if (self.isPreloadingPage || self.preloadAppPage) {
            // 1 : 完全预加载完成；2: 容器创建中；3: 加载html中;
            preloadState = self.isPreloadingPage ? 2 : (self.preloadAppPage ? 1 : 3);

            // 预加载触发原因：创建中时，从Factory中取预加载来源信息；完成时，从对象中取预加载信息；
            NSString *preloadFrom = self.isPreloadingPage ? self.preloadFrom : self.preloadAppPage.preloadFrom;
            preloadFrom = preloadFrom ? : @"unknow";
            [trackInfo setValue:preloadFrom forKey:@"render_preload_from"];

            if (self.preloadAppPage) {
                NSTimeInterval timeInterval = (currentTime - self.preloadAppPage.finishedInitTime)*1000;
                [trackInfo setValue:@(timeInterval) forKey:@"time_to_render_preload_finished"];
            }
        }else{
            NSString *nullReason = self.releaseReason ? : @"not_preload";
            [trackInfo setValue:nullReason forKey:@"render_release_reason"];
        }
        [trackInfo setValue:@(preloadState) forKey:@"render_preload_state"];

        // 距离飞书冷启动时间
        NSTimeInterval timeToLarkLaunch = (currentTime - BDPLarkColdLaunchTime())*1000;
        [trackInfo setValue:@(timeToLarkLaunch) forKey:@"time_to_lark_cold_launch"];

        // 打开小程序距后台切换前台时间间隔
        if (self.preActiveBgTime > 0) {
            [trackInfo setValue:@((currentTime - self.preActiveBgTime)*1000) forKey:@"time_to_active_from_bg"];
        }

        // 上一个打开小程序信息
        if (self.preGadgetAppId) {
            [trackInfo setValue:self.preGadgetAppId forKey:@"pre_appId"];
            [trackInfo setValue:self.preGadgetStartPath forKey:@"pre_app_start_page_path"];
            NSTimeInterval timeInterval = (currentTime - self.preGadgetStartTime)*1000;
            [trackInfo setValue:@(timeInterval) forKey:@"time_to_pre_app_launch"];
        }
        //当前是第几次打开小程序（主端冷启动一次生命周期内）
        [trackInfo setValue:@(self.indexForOpenGadget) forKey:@"index_app_launch"];
    });
    return trackInfo;
}

/// 根据场景来判断是否禁止预加载
- (BOOL)checkDisablePreloadIfNeed {
    NSString *safePreloadFrom = OPSafeString(self.preloadFrom);
    BOOL disablePreload = [BDPWebViewRuntimePreloadManager disableWebViewPreload:safePreloadFrom];
    if(disablePreload){
        // 禁止预加载时，预加载来源置空，同时标记不预加载原因
        NSString *disableReason = [NSString stringWithFormat:@"disable_%@",safePreloadFrom];
        self.preloadFrom = nil;
        self.releaseReason = disableReason;
        [BDPWebViewRuntimePreloadManager monitorEvent:@"render_disable" params:@{@"from":safePreloadFrom,
                                                                                 @"DR":@(OPGadgetDRManager.shareManager.isDRRunning)
                                                                               }];
    }
    return disablePreload;
}

@end
