//
//  BDPTask.m
//  Timor
//
//  Created by muhuai on 2017/11/7.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPTask.h"
#import "BDPAppConfig.h"
#import "BDPAppPageFactory.h"
#import <OPFoundation/BDPCommonManager.h>
#import "BDPDefineBase.h"
#import "BDPJSRuntimePreloadManager.h"
#import <OPFoundation/BDPMacroUtils.h>
#import "BDPMonitor.h"
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPNotification.h>
#import "BDPTracker+BDPLoadService.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <KVOController/KVOController.h>
#import <OPFoundation/EEFeatureGating.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import "BDPGadgetLog.h"
#import <OPSDK/OPSDK-Swift.h>
#import "BDPTimorClient+Business.h"

@interface BDPTask()

@property (nonatomic, strong) BDPMonitor *monitor;

// readwrite
@property (nonatomic, strong, readwrite) BDPUniqueID *uniqueID;
@property (nonatomic, strong, readwrite) id<OPMicroAppJSRuntimeProtocol> context;
@property (nonatomic, strong, readwrite) BDPToolBarManager *toolBarManager;

@property (nonatomic, strong, readwrite) BDPAppConfig *config;
@property (nonatomic, strong, readwrite) BDPAppPageManager *pageManager;
@property (nonatomic, strong, readwrite) WKProcessPool *processPool;

@property (nonatomic, weak, nullable) OPContainerContext *containerContext;

@property (nonatomic, strong, readwrite) BDPWebComponentChannelManager *channelManager;

@property (nonatomic, assign) BOOL enablePublishLog;

@end

@implementation BDPTask

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithSchema:(BDPSchema *)schema
                      uniqueId:(BDPUniqueID *)uniqueID
                   containerVC:(UIViewController<BDPlatformContainerProtocol> *)containerVC
              containerContext:(OPContainerContext *)containerContext
{
    self = [super init];
    if (self) {
        BDPGadgetLogInfo(@"BDPTask initWithSchema %@", [schema description]);
        _containerContext = containerContext;
        _performanceMonitor = [BDPPerformanceMonitor<BDPAppTiming> new];
        _uniqueID = uniqueID;
        _containerVC = containerVC;
        _pageManager = [[BDPAppPageManager alloc] initWithUniqueID:uniqueID];
    }

    // 建立开放平台内存相关性能指标监控
    [OPObjectMonitorCenter setupMemoryMonitorWith:self];
    _enablePublishLog = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetEnablePublishLog];
    return self;
}

- (instancetype)initWithModel:(BDPModel *)model
                   configDict:(NSDictionary *)configDict
                       schema:(BDPSchema *)schema
                  containerVC:(UIViewController<BDPlatformContainerProtocol> *)containerVC
             containerContext:(OPContainerContext *)containerContext
{
    self = [super init];
    if (self) {
        BDPGadgetLogInfo(@"BDPTask initWithModel %@", [schema description]);
        _containerContext = containerContext;
        _performanceMonitor = [BDPPerformanceMonitor<BDPAppTiming> new];
        _uniqueID = model.uniqueID;
        _containerVC = containerVC;

        // 无内部Tab模式(例如Tab小程序)
        BOOL forceNoTab = NO;

        forceNoTab = self.containerContext.apprearenceConfig.forceTabBarHidden;
        
        NSDate *parseBegin = [NSDate date];
        _config = [[BDPAppConfig alloc] initWithDict:configDict noTab:forceNoTab];
        NSDate *parseEnd = [NSDate date];
        
        _context = [[BDPJSRuntimePreloadManager sharedManager] runtimeWithUniqueID:model.uniqueID delegate:(id<BDPJSRuntimeDelegate>)containerVC];
        
        // 仅小程序用到的主动创建, 小游戏如果用到会走懒加载
        if (model.uniqueID.appType == BDPTypeNativeApp) {
            _pageManager = [[BDPAppPageManager alloc] initWithUniqueID:model.uniqueID];
            _processPool = [[BDPAppPageFactory sharedManager] getPreloadProcessPool];
        }
        _toolBarManager = [BDPToolBarManager new];

        [_context setDelegate:(id<BDPJSRuntimeDelegate>)self];
        
        // 非首屏前一定用做的操作, 可以放到 `doImportantOperations`方法中, 加快启动速度
        
        BDPMonitorLoadTimelineDate(@"parse_json_begin", @{@"file_path": @"app-config.json"}, parseBegin, _uniqueID);
        BDPMonitorLoadTimelineDate(@"parse_json_end", @{@"file_path": @"app-config.json"}, parseEnd, _uniqueID);
    }

    // 建立开放平台内存相关性能指标监控
    [OPObjectMonitorCenter setupMemoryMonitorWith:self];
    _enablePublishLog = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetEnablePublishLog];
    return self;
}

- (void)updateWithModel:(BDPModel *)model configDict:(NSDictionary *)configDict
{
    // 无内部Tab模式(例如Tab小程序)
    BOOL forceNoTab = NO;

    forceNoTab = self.containerContext.apprearenceConfig.forceTabBarHidden;
    
    NSDate *parseBegin = [NSDate date];
    _config = [[BDPAppConfig alloc] initWithDict:configDict noTab:forceNoTab];
    NSDate *parseEnd = [NSDate date];

    _context = [[BDPJSRuntimePreloadManager sharedManager] runtimeWithUniqueID:self.uniqueID delegate:(id<BDPJSRuntimeDelegate>)self.containerVC];
    // 仅小程序用到的主动创建, 小游戏如果用到会走懒加载
    if (model.uniqueID.appType == BDPTypeNativeApp) {
        _processPool = [[BDPAppPageFactory sharedManager] getPreloadProcessPool];
    }
    _toolBarManager = [BDPToolBarManager new];

    [_context setDelegate:(id<BDPJSRuntimeDelegate>)self];

    // 非首屏前一定用做的操作, 可以放到 `doImportantOperations`方法中, 加快启动速度
    
    BDPMonitorLoadTimelineDate(@"parse_json_begin", @{@"file_path": @"app-config.json"}, parseBegin, _uniqueID);
    BDPMonitorLoadTimelineDate(@"parse_json_end", @{@"file_path": @"app-config.json"}, parseEnd, _uniqueID);
    BDPGadgetLogInfo(@"BDPTask updateWithModel with uniqueID:%@ ", self.uniqueID);
}

- (void)dealloc
{
    BDPGadgetLogInfo(@"BDPTask dealloc, id=%@", self.uniqueID);
    [self.monitor stop];

    BDPGadgetLogTagInfo(@"BDPTask LifeCycle", @"bdp_onDestroy %@", self.uniqueID);
    BDPPlugin(lifeCyclePlugin, BDPLifeCyclePluginDelegate);
    if ([lifeCyclePlugin respondsToSelector:@selector(bdp_onDestroy:)]) {
        [lifeCyclePlugin bdp_onDestroy:self.uniqueID];
    }
 
    // 这里由于有crash上报，由于没时间追查为啥appTask会在非主线程释放，先把processPool抛回主线程释放，保证申请释放在同一线程。
    // 看能不能解决这个crash问题
    // https://slardar.bytedance.net/node/app_detail/?aid=19&os=iOS&region=cn#/abnormal/detail/crash/19_a3241c960e42921b4573f649cfe6d345?params=%7B%0A++%22start_time%22%3A+1557926700%2C%0A++%22end_time%22%3A+1558013100%2C%0A++%22filters%22%3A+%7B%0A++++%22update_version_code%22%3A+null%2C%0A++++%22app_version%22%3A+%5B%0A++++++%227.2.4%22%0A++++%5D%2C%0A++++%22channel%22%3A+%5B%0A++++++%22App+Store%22%0A++++%5D%0A++%7D%0A%7D
    __block WKProcessPool *processPool = _processPool;
    self.processPool = nil;
    if (processPool) {
        dispatch_async(dispatch_get_main_queue(), ^{
            processPool = nil;
        });
    }
    // 将JSRuntime标记为预期销毁状态
    [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedDestroy for:_context];
}

- (void)setContainerVC:(UIViewController<BDPlatformContainerProtocol> *)containerVC
{
    _containerVC = containerVC;
    [self.pageManager updateContainerVC:containerVC];
}

- (void)doImportantOperations {
    // 开启性能监控
    [self startPerformanceMonitor];
}

#pragma mark - Performance Monitor
/*-----------------------------------------------*/
//         Performance Monitor - 性能监控
/*-----------------------------------------------*/
- (void)startPerformanceMonitor
{    
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    
    // Performance Monitor
    _monitor = [[BDPMonitor alloc] init];
    _monitor.uniqueID = common.model.uniqueID;
    [_monitor start];
    
    WeakSelf;
    // KVO Observer
    [self.KVOController observe:common keyPath:@"isActive" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        wself.monitor.isActive = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
        // 小程序active发生变化时，通知给OPObjectMonitorCenter，根据当前active状态开始或暂停内存波动检测
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:wself.uniqueID];
        if (common) {
            [OPObjectMonitorCenter setMemoryWaveWithActive:common.isActive with:wself];
        }

    }];
}

#pragma mark - navigateToMiniProgramAppIdList

- (BDPAppPageManager *)pageManager {
    if (!_pageManager) {
        _pageManager = [[BDPAppPageManager alloc] initWithUniqueID:_uniqueID];
    }
    return _pageManager;
}

- (WKProcessPool *)processPool {
    if (!_processPool) {
        _processPool = [[BDPAppPageFactory sharedManager] getPreloadProcessPool];
    }
    return _processPool;
}


#pragma mark - webview组件 与 小程序 双向通信 channel

- (BDPWebComponentChannelManager *)channelManager {
    if (!_channelManager) {
        _channelManager = [[BDPWebComponentChannelManager alloc] init];
        BDPGadgetLogTagWarn(@"messageChannel", @"channelManager is nil! Lazy initiated success.");
    }
    return _channelManager;
}

@end
