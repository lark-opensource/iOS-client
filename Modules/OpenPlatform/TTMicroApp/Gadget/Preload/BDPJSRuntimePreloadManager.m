//
//  BDPJSRuntimePreloadManager.m
//  Timor
//
//  Created by liubo on 2019/8/22.
//

#import "BDPJSRuntimePreloadManager.h"
#import <OPFoundation/BDPBootstrapKit.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPSTLQueue.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import "BDPTracker+BDPLoadService.h"
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPJSEngine/OPJSEngine-Swift.h>
#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/EEFeatureGating.h>
#import <mach/mach.h>
#import "BDPPerformanceProfileManager.h"
#import "BDPTracingManager+Gadget.h"
#import <OPFoundation/BDPMonitorEvent.h>
#import <pthread.h>

/// Runtime对象预加载的超时时间，秒为单位
unsigned long long const RuntimePreloadTimeoutSeconds = 10;

#pragma mark - BDPJSRuntimePreloadOperation

typedef void(^BDPJSRuntimePreloadOperationCompletionBlock)(id<OPMicroAppJSRuntimeProtocol> runtime);

@interface BDPJSRuntimePreloadOperation : NSOperation

@property (nonatomic, assign) BDPType coreType;
@property (nonatomic, copy) BDPJSRuntimePreloadOperationCompletionBlock completionBlk;
@property (nonatomic, strong) id<OPMicroAppJSRuntimeProtocol> runtime;

@property (nonatomic, strong) NSRecursiveLock *lock;
@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

@end

@implementation BDPJSRuntimePreloadOperation
@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - Init

- (instancetype)initWithCoreType:(BDPType)coreType completion:(BDPJSRuntimePreloadOperationCompletionBlock)completion {
    if (self = [super init]) {
        self.coreType = coreType;
        self.completionBlk = completion;
        self.lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

#pragma mark - Override

- (void)start {
    [self.lock lock];
    if (![self isCancelled]) {
        self.executing = YES;
        WeakSelf;
        BDPLogTagInfo(@"BDPJSRuntimePreloadManager", @"app: start preload");

        // 超时判断，如果预加载的时间超过了RuntimePreloadTimeoutSeconds还没有完成，那么就释放runtime，放弃此次预加载
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RuntimePreloadTimeoutSeconds * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
            StrongSelfIfNilReturn;
            if (self.finished) {
                return;
            }

            BDPLogTagWarn(@"BDPJSRuntimePreloadManager", @"app: preload timeout")
            [self invokeCompletionBlockWithRuntime:nil];
        });

        self.runtime = [[OPRuntimeFactory shared] microAppRuntimeWithCoreCompleteBlk:^{
            StrongSelfIfNilReturn;
            BDPLogTagInfo(@"BDPJSRuntimePreloadManager", @"app: end preload");
            [self invokeCompletionBlockWithRuntime:self.runtime];
        }];
    } else {
        [self invokeCompletionBlockWithRuntime:nil];
    }
    [self.lock unlock];
}

- (void)cancel {
    [self.lock lock];
    if (![self isFinished] && ![self isCancelled]) {
        [super cancel];
        if (self.isExecuting) {
            [self invokeCompletionBlockWithRuntime:nil];
        }
    }
    [self.lock unlock];
}

- (BOOL)isAsynchronous {
    return YES;
}

#pragma mark - Utility

- (void)invokeCompletionBlockWithRuntime:(id<OPMicroAppJSRuntimeProtocol>)runtime {
    [self.lock lock];
    if (self.completionBlk != nil) {
        BDPJSRuntimePreloadOperationCompletionBlock block = [self.completionBlk copy];
        BDPExecuteOnMainQueue(^{
            block(runtime);
            BDPLogTagInfo(@"BDPJSRuntimePreloadManager", @"%@: complete", [runtime class]);
        });
    }
    [self done];
    [self.lock unlock];
}

- (void)done {
    [self.lock lock];
    self.finished  = YES;
    self.executing = NO;
    self.completionBlk = nil;
    self.runtime = nil;
    [self.lock unlock];
}

#pragma mark - KVO-Compliant

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

@end

#pragma mark - BDPJSRuntimePreloadManager

@interface BDPJSRuntimePreloadManager ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (atomic, assign) BOOL isPreloadingApp;

@property (nonatomic, strong, readwrite) id<OPMicroAppJSRuntimeProtocol> preloadRuntimeApp;

@property (nonatomic, strong) NSString * releaseReason;

@property (nonatomic, copy) NSString *preloadFrom;

@property (nonatomic, weak) id activeBgToken;
@property (nonatomic, assign) NSTimeInterval activeBgPreloadTime;

@end

#pragma mark - BDPJSRuntimePreloadManager

@implementation BDPJSRuntimePreloadManager

static BDPJSRuntimePreloadManager *gShareInstance = nil;

#pragma mark - Init

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gShareInstance = [[BDPJSRuntimePreloadManager alloc] init];
    });
    return gShareInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self buildJSRuntimeManager];
    }
    return self;
}

- (void)dealloc {
    id strongActiveToken = self.activeBgToken;
    if (strongActiveToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:strongActiveToken];
    }
}


- (void)buildJSRuntimeManager {
    // 如果宏开关打开, 则关闭预加载JS功能, 没有Queue就不会执行预加载
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    self.isPreloadingApp = NO;
    // 不在dispatch_once init里边搞这个, 防止launch里边又调用shareManager
    dispatch_async(dispatch_get_main_queue(), ^{
        [BDPBootstrapKit launch];
    });

    WeakSelf;
    self.activeBgToken =[[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        StrongSelfIfNilReturn;
        if (OPSDKFeatureGating.enableJsRuntimePreloadFromActivebg) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self checkPreloadActiveFromBackground];
            });
        }
    }];
}

#pragma mark - Preload js Runtime From background
- (void)checkPreloadActiveFromBackground {
    BDPExecuteOnMainQueue(^{
        if (self.preloadRuntimeApp || self.isPreloadingApp) {
            return;
        }
        // 如果距上次预加载时间间隔小于5s，就不进行预加载，控制一下频率
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        if (self.activeBgPreloadTime > 0 && (currentTime - self.activeBgPreloadTime) < 5) {
            return;
        }
        self.activeBgPreloadTime = currentTime;
        self.preloadFrom = @"active_from_background";
        [self preloadRuntimeIfNeed:BDPTypeNativeApp];
    });
}

#pragma mark - Obtain New Runtime

- (id<OPMicroAppJSRuntimeProtocol>)runtimeWithUniqueID:(BDPUniqueID *)uniqueID delegate:(id<BDPJSRuntimeDelegate>)delegate {
    if (!uniqueID) {
        return nil;
    }
    BDPMonitorLoadTimeline(@"create_jsEngine_begin", nil, uniqueID);
    __block id<OPMicroAppJSRuntimeProtocol> resultContext = nil;
    if ([[NSThread currentThread] isMainThread]) {
        resultContext = [self innerRuntimeWithUniqueID:uniqueID delegate:delegate];
    } else {
        WeakSelf;
        dispatch_sync(dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            resultContext = [self innerRuntimeWithUniqueID:uniqueID delegate:delegate];
        });
    }
    BDPMonitorLoadTimeline(@"create_jsEngine_end", nil, uniqueID);
    if (resultContext.loadTmaCoreEnd) {
        NSString *filePath = @"tma-core.js";
        BDPMonitorLoadTimelineDate(@"load_coreJs_begin", @{@"file_path": filePath}, resultContext.loadTmaCoreBegin, uniqueID);
        BDPMonitorLoadTimelineDate(@"load_coreJs_end", @{@"file_path": filePath}, resultContext.loadTmaCoreEnd, uniqueID);
        resultContext.loadTmaCoreBegin = nil;
        resultContext.loadTmaCoreEnd = nil;
    }
    [[BDPTracingManager.sharedInstance getTracingByUniqueID:uniqueID] linkTracing:[BDPTracingManager.sharedInstance getTracingByJSRuntime:resultContext]];
    return resultContext;
}

- (id<OPMicroAppJSRuntimeProtocol>)innerRuntimeWithUniqueID:(BDPUniqueID *)uniqueID delegate:(id<BDPJSRuntimeDelegate>)delegate {
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
    return [self getPreloadAppJSRuntimeWithUniqueID:uniqueID common:common delegate:delegate];
}

#pragma mark - Preload Next Runtime

/// 重写preloadRuntimeApp属性的setter，新传入值的时候将新老对象的状态置为预期状态
- (void)setPreloadRuntimeApp:(id<OPMicroAppJSRuntimeProtocol>)preloadRuntimeApp {
    if (preloadRuntimeApp != _preloadRuntimeApp) {
        // 当传入一个新的runtime作为预加载对象的时候，旧的对象变为预期销毁状态，新的对象取代旧对象的位置变为预期持有状态
        [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedDestroy for:_preloadRuntimeApp];
        [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedRetain for:preloadRuntimeApp];
        _preloadRuntimeApp = preloadRuntimeApp;
        // 重新预加载，重置释放状态
        if (preloadRuntimeApp) {
            _releaseReason = nil;
            _preloadRuntimeApp.finishedInitTime = [[NSDate date] timeIntervalSince1970];
        }
    }
}

- (void)preloadRuntimeAppIfNeed {
    if ([BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSJSLibPreloadDisableTma]) {
        return;
    }
    
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        // 根据场景来判断是否禁止预加载
        if([self checkDisablePreloadIfNeed]){
            return;
        }

        if (self.preloadRuntimeApp || self.isPreloadingApp) {
            BDPLogTagInfo(@"BDPJSRuntimePreloadManager", @"app: already preloading");
            return;
        }
        NSString *curPreloadFrom = self.preloadFrom ? : @"unknown";
        self.isPreloadingApp = YES;
        BDPJSRuntimePreloadOperation *operation = [[BDPJSRuntimePreloadOperation alloc] initWithCoreType:BDPTypeNativeApp completion:^(id<OPMicroAppJSRuntimeProtocol> runtime) {
            StrongSelfIfNilReturn;
            if (self.preloadRuntimeApp == nil && runtime != nil) {
                self.preloadRuntimeApp = (id<OPMicroAppJSRuntimeProtocol>)runtime;
                self.preloadRuntimeApp.preloadFrom = curPreloadFrom;
                // js runtime 开始预加载上报埋点，用于命中率统计
                [BDPWebViewRuntimePreloadManager monitorEvent:@"worker_start" params:@{@"from":OPSafeString(curPreloadFrom)}];
            }
            self.isPreloadingApp = NO;
        }];
        [self.operationQueue addOperation:operation];
        self.preloadFrom = nil;
    });
}

- (void)releasePreloadRuntimeAppIfNeed {
    if ([BDPSettingsManager.sharedManager s_boolValueForKey:kBDPSJSLibPreloadDisableTma]) {
        return;
    }
    
    WeakSelf;
    [self.operationQueue cancelAllOperations];
    // 及时同步isPreloadingApp的状态。Doc: https://bytedance.feishu.cn/docs/doccnHVcRpJRigLIq0EX11Lckgd#
    self.isPreloadingApp = NO;
    [self.operationQueue addOperationWithBlock:^{
        BDPExecuteOnMainQueue(^{
            StrongSelfIfNilReturn;
            self.preloadRuntimeApp = nil;
            BDPLogTagInfo(@"BDPJSRuntimePreloadManager", @"app: release exist runtime");
            
            if (self.shouldPreloadRuntimeApp) {
                [self preloadRuntimeIfNeed:BDPTypeNativeApp];
            }
        });
    }];
}

- (void)preloadRuntimeIfNeed:(BDPType)type
{
    if (type == BDPTypeNativeApp) {
        [self preloadRuntimeAppIfNeed];
    }
}

- (void)releasePreloadRuntimeIfNeed:(BDPType)type
{
    switch (type) {
        case BDPTypeNativeApp:
            [self releasePreloadRuntimeAppIfNeed];
            break;
        default:
            break;
    }
}

+ (void)tryReleaseAllPreloadRuntime {
    if (gShareInstance) {
        BDPExecuteOnMainQueueSync(^{
            // 先取消所有task
            [gShareInstance.operationQueue cancelAllOperations];
            // 及时同步isPreloadingApp的状态。Doc: https://bytedance.feishu.cn/docs/doccnHVcRpJRigLIq0EX11Lckgd#
            gShareInstance.isPreloadingApp = NO;
            [gShareInstance.operationQueue addOperationWithBlock:^{
                gShareInstance.preloadRuntimeApp = nil;
            }];
            [gShareInstance.operationQueue waitUntilAllOperationsAreFinished];
        });
    }
}

+ (void)releaseAllPreloadRuntimeWithReason:(NSString * _Nonnull)releaseReason {
    BDPExecuteOnMainQueue(^{
        BDPJSRuntimePreloadManager *preloadManager = [BDPJSRuntimePreloadManager sharedManager];
        if (preloadManager.isPreloadingApp || preloadManager.preloadRuntimeApp) {
            preloadManager.releaseReason = [releaseReason copy];
            [self tryReleaseAllPreloadRuntime];
        }
    });
}

#pragma mark - App JSContext

- (id<OPMicroAppJSRuntimeProtocol>)createJSRuntimeAppWithUniqueId:(BDPUniqueID *)uniqueID runtimeType:(OPRuntimeType)runtimeType {
    return [[OPRuntimeFactory shared] microAppRuntimeWithCoreCompleteBlk:nil appType:uniqueID.appType runtimeType:runtimeType];
}

- (id<OPMicroAppJSRuntimeProtocol>)createJSRuntimeSocketDebug:(NSString *)realMachineDebugAddress {
    // FIXME: 类型不对啊 BDPJSRuntimeSocketDebug : BDPJSRuntime 并不是 BDPJSRuntimeApp
    return [[OPRuntimeFactory shared] debugMicroAppRuntimeWithAddress:realMachineDebugAddress coreCompleteBlk:nil];
}


- (id<OPMicroAppJSRuntimeProtocol>)getPreloadAppJSRuntimeWithUniqueID:(BDPUniqueID *)uniqueID common:(BDPCommon *)common delegate:(id<BDPJSRuntimeDelegate>)delegate {
    BDPMonitorEvent *monitor = BDPMonitorWithCode(EPMClientOpenPlatformGadgetLaunchWorkerCode.worker_load_result, uniqueID).timing();

    id<OPMicroAppJSRuntimeProtocol> resultContext = nil;
    [BDPTracker monitorService:@"mp_jsc_preload_usage"
                        metric:@{
                            @"duration": @(self.preloadRuntimeApp.jsCoreExecCost)
                        }
                      category:@{
                                @"type": @(BDPTypeNativeApp),
                                @"preload": (self.preloadRuntimeApp.jsCoreExecCost ? @1 : @0),
                                }
                         extra:nil
          uniqueID:uniqueID];

    [[OPRuntimeFactory shared] registerService];
    OPRuntimeType runtimeType = [GeneralJSRuntimeTypeFg setupSettingsWithAppID:uniqueID.appID];
    monitor.addMetricValue(kEventKey_js_engine_type, runtimeType); // 使用 metric, 便于 bytest 配置指标
    if (!BDPIsEmptyString(common.realMachineDebugAddress)) {
        // 真机调试每次都创建新的jsruntime，不会用缓存的jsruntime
        monitor.addMetricValue(@"is_preloaded",0);         ///使用的是metric，目的是 bytest 可配置相应的指标，方便查看是否是预加载
        resultContext = [self createJSRuntimeSocketDebug:common.realMachineDebugAddress];
    } else if([BDPPerformanceProfileManager.sharedInstance enableProfileForCommon:common]){
        // 性能分析 每次都新建worker，避免数据波动
        resultContext = [self createJSRuntimeAppWithUniqueId:uniqueID runtimeType:runtimeType];
        [[BDPPerformanceProfileManager sharedInstance] buildConnectionWithAddress:common.performanceTraceAddress jsThread:resultContext];
        [BDPPerformanceProfileManager sharedInstance].uniqueID = uniqueID;
        monitor.addMetricValue(@"is_preloaded",0);
    } else {
        if (self.preloadRuntimeApp &&
            //需要检查AppType是否一致，否则H5小程序使用了标准小程序的runtime环境，会有异常
            [uniqueID appType] == self.preloadRuntimeApp.appType && (runtimeType == OPRuntimeTypeUnknown)) {
            resultContext = self.preloadRuntimeApp;
            // 置空前记录一下预加载状态, 1 : 完全预加载完成；3: 加载jssdk中;
            int preloadState = (self.preloadRuntimeApp.loadTmaCoreEnd ? 1 : 3);

            self.preloadRuntimeApp = nil;
            self.releaseReason = @"consumed";
            monitor.addMetricValue(@"is_preloaded",1);        ///使用的是metric，目的是 bytest 可配置相应的指标，方便查看是否是预加载
            // 被消费时上报埋点
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
            [params setValue:uniqueID.appID forKey:kEventKey_app_id];
            [params setValue:@(preloadState) forKey:@"state"];
            [BDPWebViewRuntimePreloadManager monitorEvent:@"worker_consumed" params:params];
        } else {
            resultContext = [self createJSRuntimeAppWithUniqueId:uniqueID runtimeType:runtimeType];
            monitor.addMetricValue(@"is_preloaded",0);         ///使用的是metric，目的是 bytest 可配置相应的指标，方便查看是否是预加载
        }
    }
    [self upgradeWorkerPriorityForContext:resultContext];
    [resultContext updateUniqueID:uniqueID delegate:delegate];
    // 外部从这个统一入口拿runtime对象使用的时候，要将runtime状态标记为活跃
    [OPObjectMonitorCenter updateState:OPMonitoredObjectStateExpectedRetain for:resultContext];
    monitor.timing().flush();
    return resultContext;
}

-(void)upgradeWorkerPriorityForContext:(id<OPMicroAppJSRuntimeProtocol>)resultContext{
    if(![EEFeatureGating boolValueForKey:@"gadget.worker.upgrade.priority"]){
        return ;
    }
    __weak id<OPMicroAppJSRuntimeProtocol> weak_resultContext = resultContext;
    [weak_resultContext dispatchAsyncInJSContextThread:^{
        // 临时提升线程优先级
        if (qos_class_self() < QOS_CLASS_USER_INTERACTIVE) {
            int ret = pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
            BDPLogInfo(@"[thread] worker update to QOS_CLASS_USER_INTERACTIVE, ret %d", ret);
        }
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(),^{
        [weak_resultContext dispatchAsyncInJSContextThread:^{
            if (!weak_resultContext) {
                BDPLogInfo(@"[thread] worker has gone, don't need downgrade")
                return ;
            }
            if (qos_class_self() == QOS_CLASS_USER_INTERACTIVE) {
                pthread_set_qos_class_self_np(QOS_CLASS_DEFAULT, 0);
                BDPLogInfo(@"[thread] worker downgrade to QOS_CLASS_DEFAULT");
            }
        }];
    });
}

//打印优先级，调试用

/*
void print_thread_priority(void) {
    thread_t cur_thread = mach_thread_self();
    mach_port_deallocate(mach_task_self(), cur_thread);
    mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
    thread_info_data_t thinfo;
    kern_return_t kr = thread_info(cur_thread, THREAD_EXTENDED_INFO, (thread_info_t)thinfo, &thread_info_count);
    if (kr != KERN_SUCCESS) {
        return;
    }
    thread_extended_info_t extend_info = (thread_extended_info_t)thinfo;
    printf("[thread] This is run on the pth_curpri: %d\n", extend_info->pth_curpri);
}
*/

#pragma mark - Preload Track Info

- (void)updateReleaseReason:(NSString * _Nonnull)releaseReason {
    BDPExecuteOnMainQueue(^{
        if (self.preloadRuntimeApp || self.isPreloadingApp) {
            self.releaseReason = [releaseReason copy];
        }
        self.preloadFrom = releaseReason;
    });
}

- (void)updatePreloadFrom:(NSString * _Nonnull)preloadFrom {
    BDPExecuteOnMainQueue(^{
        if (self.preloadRuntimeApp || self.isPreloadingApp) {
            return;
        }
        self.preloadFrom = [preloadFrom copy];
    });
}

- (NSDictionary<NSString *, id> * _Nonnull)runtimePreloadInfo {
    __block NSMutableDictionary<NSString *, id> *preloadTrackInfo = [NSMutableDictionary dictionaryWithCapacity:4];
    BDPExecuteOnMainQueueSync(^{
        int preloadState = 0;
        if (self.isPreloadingApp || self.preloadRuntimeApp) {
            // 1 : 完全预加载完成；2: 容器创建中；3: 加载jssdk中;
            preloadState = self.isPreloadingApp ? 2 : (self.preloadRuntimeApp.loadTmaCoreEnd ? 1 : 3);

            // 预加载触发原因：创建中时，从Manger中取预加载来源信息；完成时，从对象中取预加载来源信息；
            NSString *preloadFrom = self.isPreloadingApp ? self.preloadFrom : self.preloadRuntimeApp.preloadFrom;
            preloadFrom = preloadFrom ? : @"unknow";
            [preloadTrackInfo setValue:preloadFrom forKey:@"worker_preload_from"];

            if (self.preloadRuntimeApp && self.preloadRuntimeApp.finishedInitTime > 0) {
                NSTimeInterval timeInterval = ([[NSDate date] timeIntervalSince1970] - self.preloadRuntimeApp.finishedInitTime)*1000;
                [preloadTrackInfo setValue:@(timeInterval) forKey:@"time_to_worker_preload_finished"];
            }
        }else {
            NSString *nullReason = self.releaseReason ? : @"not_preload";
            [preloadTrackInfo setValue:nullReason forKey:@"worker_release_reason"];
        }
        [preloadTrackInfo setValue:@(preloadState) forKey:@"worker_preload_state"];
    });
    return preloadTrackInfo;
}

/// 根据场景来判断是否禁止预加载
- (BOOL)checkDisablePreloadIfNeed {
    // 根据场景来判断是否禁止预加载
    NSString *safePreloadFrom = OPSafeString(self.preloadFrom);
    BOOL disablePreload = [BDPWebViewRuntimePreloadManager disableRuntimePreload:safePreloadFrom];
    if(disablePreload){
        NSString *disableReason = [NSString stringWithFormat:@"disable_%@",safePreloadFrom];
        self.preloadFrom = nil;
        self.releaseReason = disableReason;
        [BDPWebViewRuntimePreloadManager monitorEvent:@"worker_disable" params:@{@"from":safePreloadFrom,
                                                                                 @"DR":@(OPGadgetDRManager.shareManager.isDRRunning)
                                                                               }];
    }
    return disablePreload;
}

@end
