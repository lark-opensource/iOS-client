//
//  OPMicroAppJSRuntime.m
//  TTMicroApp
//
//  Created by yi on 2021/12/8.
//
// 小程序worker类
// jsitodo 需要进一步对这个类进行拆分
#import "OPMicroAppJSRuntime.h"

#import "BDPAppLoadDefineHeader.h"
#import <OPFoundation/BDPCommonManager.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/BDPAppMetaUtils.h>
#import <OPFoundation/EEFeatureGating.h>
#import "BDPPluginUpdateManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
// debug
#import "BDPTracker+BDPLoadService.h"
#import <OPJSEngine/BDPJSRuntimeSocketConnection.h>
// app
#import <OPFoundation/BDPModuleManager.h>
#import <OPFoundation/BDPStorageModuleProtocol.h>
#import <OPFoundation/BDPTracker.h>
#import <ECOProbe/ECOProbe-Swift.h>

// private
#import "BDPTaskManager.h"

#import <OPJSEngine/BDPJSRunningThread.h>
#import "BDPJSRuntimeSettings.h"
#import "BDPPerformanceProfileManager.h"
#import <OPSDK/OPSDK-Swift.h>
#import "BDPTracingManager+Gadget.h"
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPDebugMacro.h"
#import <OPFoundation/BDPTimorClient.h>

#pragma mark - BDPJSContext
static char kOPJSRuntimeTraceKey;

@interface OPMicroAppJSRuntime ()<BDPJSRuntimeSocketConnectionDelegate, BDPJSRunningThreadDelegate>
@property (nonatomic, copy) NSString *delegateClassName;

@property (nonatomic, strong) BDPMultiDelegateProxy<BDPJSRuntimeDelegate>* otherDelegates;
@property (nonatomic, copy) BDPJSRuntimeCoreCompleteBlock coreCompleteBlk;
@property (nonatomic, assign) BOOL enablePublishLog;

@property (nonatomic, weak, readwrite) JSContext* jsContext; // 真正的js虚拟机
@end

@implementation OPMicroAppJSRuntime

@synthesize bridgeType = _bridgeType;
@synthesize authorization = _authorization;
@synthesize bridgeController = _bridgeController;
@synthesize workers = _workers;

#pragma mark - Initilize
- (instancetype)initWithCoreCompleteBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk
{
    return [self initWithCoreCompleteBlk:completeBlk isSocketDebug:NO];
}

- (instancetype)initWithCoreCompleteBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk isSocketDebug:(BOOL)isSocketDebug
{
    self = [super init];
    if (self) {
        // 优先创建tracing
        _isSocketDebug = isSocketDebug;
        [BDPTracingManager.sharedInstance generateTracingByJSRuntime:self];
        // 默认类型为小程序
        _appType = BDPTypeNativeApp;
        _otherDelegates = [[BDPMultiDelegateProxy<BDPJSRuntimeDelegate> alloc] init];
        _otherDelegates.silentWhenEmpty = YES;

        _jsRuntime = [[GeneralJSRuntime alloc] initWith:_runtimeType apiDispatcherModule: [[OPJSRuntimeAPIDispatchModule alloc] init]];
        _jsRuntime.loadScriptModule = [[OPJSLoadScriptModule alloc] init];
        _jsRuntime.loadDynamicComponentModule = [[OPJSLoadDynamicComponentModule alloc] init];

        
        if(self.runtimeType == OPRuntimeTypeVmsdkJscore || self.runtimeType == OPRuntimeTypeVmsdkQjs) {
            OPJSBridgeModuleLoadScript *loadScriptHandler = [[OPJSBridgeModuleLoadScript alloc] init];
            _jsRuntime.loadScriptHandler = loadScriptHandler;
            loadScriptHandler.jsRuntime = _jsRuntime;
            
            OPJSBridgeModulLoadDynamicComponent *loadDynamicHanlder = [[OPJSBridgeModulLoadDynamicComponent alloc] init];
            loadDynamicHanlder.jsRuntime = _jsRuntime;
            _jsRuntime.loadDynamicComponentHandler = loadDynamicHanlder;
        }
    
        _jsRuntime.isJSContextThreadForceStopped = NO;

        _jsRuntime.isSocketDebug = _isSocketDebug;
        _jsRuntime.delegate = self;
        self.coreCompleteBlk = completeBlk;

        NSString *threadName = [NSString stringWithFormat:@"%@preload", BDP_JSTHREADNAME_PREFIX];
        [_jsRuntime createJsContextDispatchQueueWithName:threadName delegate:self];

        BDPDebugNSLog(@"[JSAsync Debug] BDPJSContext init %@",@([self hash]));

        // workers 初始化
        _workers = [[OpenJSWorkerQueue alloc] init];
        _workers.sourceWorker = self;
        _workers.rootWorker = self;
        
        _enablePublishLog = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetEnablePublishLog];

        // 建立开放平台内存相关性能指标监控
        [OPObjectMonitorCenter setupMemoryMonitorWith:self];
        BDPLogInfo(@"BDPJSRuntime init, id=%@ hash is %@", self.uniqueID, @([self hash]));
    }
    return self;
}

- (NSArray<NSString *> *)executedJSPathes {
    return _jsRuntime.executedJSPathes;
}

- (void)runtimeLoad {
    self.jsContext = self.jsRuntime.jsContext;
}

- (void)runtimeException: (NSDictionary * _Nullable)data exception: (JSValue *)exception {
    BOOL exceptionConsumed = NO;

    if (self.delegate && [self.delegate respondsToSelector:@selector(onJSRuntimeLogException:)]) {
        [self.delegate onJSRuntimeLogException:exception];
        exceptionConsumed = YES;
    } else {
        BDPLogWarn(@"jsruntime_delegate_empty, uniqueID:%@, delegateType:%@", self.uniqueID, self.delegateClassName);
    }

    if ([self.otherDelegates count] > 0) {
        [self.otherDelegates onJSRuntimeLogException:exception];
        exceptionConsumed = YES;
    }
    NSString *exception_message = @"";

    if (exception) {
        JSValue *line = [exception valueForProperty:@"line"];
        JSValue *file = [exception valueForProperty:@"sourceURL"];
        NSString *message = [NSString stringWithFormat:@"%@ \n at %@:%@", [exception toString], [file toString], [line toString]];
        exception_message = message;
    }
    if (!exceptionConsumed) {
        BDPMonitorWithCode(GDMonitorCode.jsruntime_exception_unconsumed, self.uniqueID)
            .kv(@"action", @"logException")
            .kv(@"exp_message", exception_message)
            .kv(@"delegateType", self.delegateClassName)
            .flush();
    }
}


- (void)dealloc
{
    BDPLogInfo(@"BDPJSRuntime dealloc, id=%@ hash is %@", self.uniqueID, @([self hash]));
    BDPDebugNSLog(@"[JSAsync Debug] BDPJSContext dealloc %@",@([self hash]));
    if([EMAFeatureGating boolValueForKey:EEFeatureGatingKeyEvadeJSCoreDeadLock]) {
        GeneralJSRuntime *tmpRuntime = _jsRuntime;
        _jsRuntime = nil;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [tmpRuntime terminate];
        });
    } else {
        [_jsRuntime terminate];
    }
    
}

- (UIViewController * __nullable) runtimeBridgeController
{
    return self.bridgeController;
}

- (void)bindCurrentThreadTracing
{
    BDPTracing *tracing = [BDPTracingManager.sharedInstance generateTracingWithParent:[BDPTracingManager.sharedInstance getTracingByJSRuntime:self]];
    [BDPTracingManager bindCurrentThreadTracing:tracing];
}

- (void)bindCurrentThreadTracingFromUniqueID
{
    BDPTracing *tracing = [BDPTracingManager.sharedInstance generateTracingWithParent:[self getLogParentTracing]];
    [BDPTracingManager bindCurrentThreadTracing:tracing];
}

#pragma mark - LifeCycle

- (void)handleInvokeInterruptionWithStatus:(GeneralJSRuntimeRenderStatus)status data:(NSDictionary *)data
{
    [self.jsRuntime handleInvokeInterruptionWithStatus: status data: data];
}

#pragma mark - Phased Initialization

- (void)setupUniqueID:(BDPUniqueID *)uniqueID delegate:(id<BDPJSRuntimeDelegate>)delegate
{
    BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
    _uniqueID = uniqueID;
    _delegate = delegate;
    _bridgeType = 1 << common.uniqueID.appType;
    _authorization = common.auth;
    [self.jsRuntime setjsvmNameWithName:common.model.name];

    self.jsRuntime.uniqueID = uniqueID;
    self.jsRuntime.bridgeType = _bridgeType;
    self.jsRuntime.authorization = _authorization;
    [self.jsRuntime runtimeReady];

    // 这里给jsc所在的线程用 uniqueID 标个名字，方便debug
    if (self.jsRuntime.dispatchQueue && uniqueID) {
        NSString *s = [NSString stringWithFormat:@"%@%@", BDP_JSTHREADNAME_PREFIX,uniqueID.fullString];
        [self.jsRuntime renameThreadName:s];
    }
    BDPLogInfo(@"BDPJSRuntime setupUniqueID, id=%@ hash is %@", uniqueID, @([self hash]));
    if (BDPSDKConfig.sharedConfig.showDebugWorkerTypeToast) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.jsRuntime.runtimeType == OPRuntimeTypeJscore) {
                [UDToastForOC showSuccessWith:[NSString stringWithFormat:@"JS Engine Type: jsCore"]  on:OPWindowHelper.fincMainSceneWindow];
            } else if (self.jsRuntime.runtimeType == OPRuntimeTypeVmsdkJscore) {
                [UDToastForOC showSuccessWith:[NSString stringWithFormat:@"JS Engine Type: vmsdk JSC"]  on:OPWindowHelper.fincMainSceneWindow];
            } else if (self.jsRuntime.runtimeType == OPRuntimeTypeVmsdkQjs) {
                [UDToastForOC showSuccessWith:[NSString stringWithFormat:@"JS Engine Type: vmsdk qjs"]  on:OPWindowHelper.fincMainSceneWindow];
            }
        });
    }

}

- (void)initPropertiesBeforeCommon
{
    _isContextReady = NO;
    _isFireEventReady = NO;
}

- (void)setupContextBeforeCommon
{
    [self.jsRuntime setjsvmNameWithName:@"BDPlatform-JSContext"];
}

- (void)setupContextAfterCommon
{
    // Get Common
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];

    // vConsole Debug Tools
    BOOL isDebugMode = [BDPAppMetaUtils metaIsDebugModeForVersionType:common.model.uniqueID.versionType];
    BOOL isDebugOpen = [[common.sandbox.privateStorage objectForKey:kBDPDebugVConsoleSwitchKey] boolValue];
    // 强制开启需要同时满足强制开启开关打开，且该小程序不是调试小程序
    BOOL isDebuggerApp = [common.uniqueID.appID isEqualToString:BDPSDKConfig.sharedConfig.debuggerAppID];
    BOOL isDebugForceOpen = BDPSDKConfig.sharedConfig.forceAppDebugOpen && !isDebuggerApp;
    BOOL isOpen = (isDebugMode && isDebugOpen) || isDebugForceOpen;

    NSMutableDictionary *nativeTMAConfig = @{@"platform" : @"ios",
                                             @"debug" : @(isOpen),
                                             @"sysVersion": BDPSystemVersion()}.mutableCopy;
    if (!BDPIsEmptyDictionary(BDPSDKConfig.sharedConfig.jssdkEnvConfig)) {
        nativeTMAConfig[@"hostConfig"] = BDPSafeDictionary(BDPSDKConfig.sharedConfig.jssdkEnvConfig.copy);
    }
    if ([BDPJSRuntimeSettings isUseNewNetworkAPIWithUniqueID: self.uniqueID]) {
        nativeTMAConfig[@"randomDeviceId"] = [BDPJSRuntimeSettings generateRandomID: self.uniqueID.appID];
    }
    if([BDPPerformanceProfileManager.sharedInstance enableProfileForCommon:common]){
        nativeTMAConfig[@"performanceAnalyzing"] = @(true);
    }
    /**
     * ⚠️ nativeTMAConfig warnning ⚠️
     * 由于小程序真机调试目前架构上的问题无法自动同步注入到 JSCore 内的变量
     * 如果修改了注入对象的内容，请至 OPMicroAppJSRuntime/BDPJSRuntimeSocketDebug.m:445  (- initWorker) 做同步修改
     */
    [self.jsRuntime setObject:nativeTMAConfig.copy forKeyedSubscript:@"nativeTMAConfig"];
    [self.jsRuntime setjsvmNameWithName:common.model.uniqueID.fullString];
}

#pragma mark - JSCore Inject Handler
/*-----------------------------------------------*/
//       JSCore Inject Handler - JS注入实现
/*-----------------------------------------------*/

- (void)publish:(NSString *)event param:(NSDictionary *)param appPageIDs:(NSArray<NSNumber *> *)appPageIDs useNewPublish:(BOOL)useNewPublish
{
    [self bindCurrentThreadTracingFromUniqueID];
    
    if(self.enablePublishLog) {
        BDPLogTagInfo(@"API", @"publish start event=%@, app=%@, appPageIDs=%@", event, self.uniqueID, appPageIDs);
    }
    
    NSTimeInterval jsBridgeReceiveTime = NSDate.date.timeIntervalSince1970;

    WeakSelf;
    void (^publishBlk)(void) = ^(void){
        StrongSelfIfNilReturn;
        // Publish Delegate
        [self publishDelegate:event param:param appPageIDs:appPageIDs];

        NSInteger duration = (NSDate.date.timeIntervalSince1970 - jsBridgeReceiveTime)*1000;
        if(self.enablePublishLog){
            BDPLogTagInfo(@"API", @"publish finish success, event=%@ appPageIDs=%@ duration=%@", event, appPageIDs, @(duration));
        }
    };

    BDPExecuteOnMainQueue(publishBlk);
}

- (void)onDocumentReady
{
    [self bindCurrentThreadTracingFromUniqueID];

    BDPLogTagInfo(@"API", @"onDocumentReady start, app=%@", self.uniqueID);
    self.isContextReady = YES;
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        BDPMonitorWithName(kEventName_mp_jscore_load_dom_ready, self.uniqueID).addCategoryValue(kEventKey_js_engine_type, _runtimeType).bdpTracing([BDPTracingManager.sharedInstance getTracingByJSRuntime:self]).flush();
        [self onDocumentReadyDelegate];
        BDPLogTagInfo(@"API", @"onDocumentReady finish");
    });
}

#pragma mark - JSCore Delegate Handler
/*-----------------------------------------------*/
//       JSCore Delegate Handler - JS方法代理
/*-----------------------------------------------*/
- (void)publishDelegate:(NSString *)event param:(NSDictionary *)param appPageIDs:(NSArray<NSNumber *> *)appPageIDs
{
    // Publish Delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(jsRuntimePublishMessage:param:appPageIDs:)]) {
        [self.delegate jsRuntimePublishMessage:event param:param appPageIDs:appPageIDs];
    } else {
        BDPLogWarn(@"jsruntime_delegate_empty, uniqueID:%@, delegateType:%@", self.uniqueID, self.delegateClassName);
    }

    if ([self.otherDelegates count] > 0) {
        [self.otherDelegates jsRuntimePublishMessage:event param:param appPageIDs:appPageIDs];
    }

    // Publish Log
    if(self.enablePublishLog) {
        BDPLogInfo(@"JSContext Publish 事件名(Event)：%@ 网页标示(WebViewID)：%@", event, appPageIDs);
    }
    
}

- (void)onDocumentReadyDelegate
{
    BOOL consumed = NO;

    if (self.delegate && [self.delegate respondsToSelector:@selector(jsRuntimeOnDocumentReady)]) {
        [self.delegate jsRuntimeOnDocumentReady];
        consumed = YES;
    } else {
        BDPLogWarn(@"jsruntime_delegate_empty, uniqueID:%@, delegateType:%@", self.uniqueID, self.delegateClassName);
    }

    if ([self.otherDelegates count] > 0) {
        [self.otherDelegates jsRuntimeOnDocumentReady];
        consumed = YES;
    }

    if(!consumed) {
        BDPMonitorWithCode(GDMonitorCode.jsruntime_document_ready_unconsumed, self.uniqueID)
            .kv(@"action", @"onDocumentReady")
            .kv(@"delegateType", self.delegateClassName)
            .flush();
    }

    // OnDocumentReady Log
    BDPLogInfo(@"JSContext OnDocumentReady");
}

#pragma mark - BDPJSBridgeEngineProtocol
/*-----------------------------------------------*/
//    BDPJSBridgeEngineProtocol - JSBridge协议
/*-----------------------------------------------*/
- (void)bdp_evaluateJavaScript:(NSString *)script completion:(void (^)(id result, NSError *error))completion
{
}

- (void)bdp_fireEventV2:(NSString *)event data:(NSDictionary *)data
{
    [self.jsRuntime bdp_fireEventV2:event data:data];
}

- (void)bdp_fireEvent:(NSString *)event sourceID:(NSInteger)sourceID data:(NSDictionary *)data
{
    [self.jsRuntime bdp_fireEvent:event sourceID:sourceID data:data];
}

- (UIViewController *)bridgeController
{
    __block UIViewController *vc = nil;
    BDPExecuteOnMainQueueSync(^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(jsRuntimeController)]) {
            vc = [self.delegate jsRuntimeController];
        }
    });
    return vc;
}

// worker间传递消息
- (void)transferMessage:(NSDictionary * _Nullable)data
{
    WeakSelf;
    void (^loadContextBlk)(void) = ^(void){
        StrongSelfIfNilReturn;
        BDPJSBridgeMethod *method = [BDPJSBridgeMethod methodWithName:@"workerTransferMessage" params:data];
        BDPTracing *appTracing = [BDPTracingManager.sharedInstance getTracingByUniqueID:self.uniqueID];
        OPTrace *apiTrace = [OPTraceService.defaultService generateTraceWithParent:appTracing bizName:@"workerTransferMessage"];
        BDPLogTagInfo(@"API", @"invoke start transferMessage, app=%@", self.uniqueID);
        [((OPJSRuntimeAPIDispatchModule *)self.jsRuntime.apiDispatcherModule).pluginManager invokeAPIWithMethod:method trace:apiTrace engine:self contextExtra:nil source:nil callback:^(BDPJSBridgeCallBackType status, NSDictionary * _Nullable response) {
            if (status != BDPJSBridgeCallBackTypeSuccess) {
                BDPLogTagWarn(@"API", @"invoke finish error transferMessage status=%@", @(status));
            } else {
                BDPLogTagInfo(@"API", @"invoke finish success transferMessage");
            }
            [apiTrace finish];
        }];
    };
    [self.jsRuntime.dispatchQueue dispatchASync:loadContextBlk];
}

#pragma mark - Utils
/*-----------------------------------------------*/
//                  Utils - 工具
/*-----------------------------------------------*/

- (void)loadScriptWithURL:(NSURL *)url callbackIsMainThread: (BOOL)callbackIsMainThread completion:(void (^ __nullable)(void))completion
{
    [self.jsRuntime loadScriptWithUrl:url callbackIsMainThread:callbackIsMainThread completion:completion];
}

- (void)loadScript:(NSString *)script withFileSource:(NSString *)fileSource  callbackIsMainThread: (BOOL)callbackIsMainThread completion:(void (^ __nullable)(void))completion
{
    [self.jsRuntime loadScriptWithScript:script fileSource:fileSource callbackIsMainThread:callbackIsMainThread completion:completion];
}

// jscontext异步执行相关
- (void)dispatchAsyncInJSContextThread:(dispatch_block_t)blk
{
    [self.jsRuntime dispatchAsyncInJSContextThread:blk];
}

- (void)cancelAllPendingAsyncDispatch
{
    [self.jsRuntime cancelAllPendingAsyncDispatch];
}

- (void)enableAcceptAsyncDispatch:(BOOL)enabled
{
    [self.jsRuntime enableAcceptAsyncDispatch:enabled];
}

- (BOOL)isJSContextThreadForceStopped
{
    return _jsRuntime.isJSContextThreadForceStopped;
}

+ (void)enableJSContextThreadProtection:(BOOL)enabled
{
    [BDPJSRunningThread enableThreadProtection:enabled];
}

+ (BOOL)isJSContextThreadProtectionEnabled
{
    return [BDPJSRunningThread isThreadProtectionEnabled];
}

+ (void)setJSThreadCrashHandler:(BDPJSThreadCrashHandler)handler
{
    [BDPJSRunningThread setCrashHandler:handler];
}


/// 获取一个用于打印日志的parent tracing
/// 如果uniqueID存在，使用uniqueID绑定的trace作为parent
/// 如果不存在，使用自身绑定的trace
- (BDPTracing *)getLogParentTracing {
    if (self.uniqueID) {
        return [BDPTracingManager.sharedInstance getTracingByUniqueID:self.uniqueID];;
    }
    return [BDPTracingManager.sharedInstance getTracingByJSRuntime:self];
}

#pragma mark - Variables Getters & Setters
/*-----------------------------------------------*/
//     Variables Getters & Setters - 变量相关
/*-----------------------------------------------*/
- (void)setIsFireEventReady:(BOOL)isFireEventReady
{
    if (_isFireEventReady != isFireEventReady) {
        _isFireEventReady = isFireEventReady;
        _jsRuntime.isFireEventReady = isFireEventReady;
    }
}

- (void)setDelegate:(id<BDPJSRuntimeDelegate>)delegate
{
    _delegate = delegate;
    if (delegate) {
        self.delegateClassName = NSStringFromClass([delegate class]);
    }
}

#pragma mark <BDPJSRunningThreadDelegate>
- (void)onBDPJSRunningThreadForceStopped:(BDPJSRunningThread*)thread exceptionMsg:(NSString * _Nullable)exceptionMsg
{
    _jsRuntime.isJSContextThreadForceStopped = YES;

    if(self.uniqueID) {
        // 接入错误恢复框架
        OPError *error = OPErrorWithMsg(GDMonitorCode.js_running_thread_force_stopped, @"%@", (exceptionMsg ?: @""));
        [OPSDKRecoveryEntrance handleErrorWithUniqueID:self.uniqueID with:error recoveryScene:RecoveryScene.gadgetRuntimeFail contextUpdater:nil];
    } else {
        // 这里需要完全退出
        [[OPApplicationService.current getContainerWithUniuqeID:self.uniqueID] destroyWithMonitorCode:GDMonitorCode.js_running_thread_force_stopped];
    }

}

#pragma mark - socket debug

#pragma mark - Initilize
- (instancetype)initWithAddress:(NSString *)address completeBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk {
    return [self initWithAddress:address completeBlk:completeBlk runtimeType:OPRuntimeTypeJscore];
}

// 参考 BDPJSRuntimeApp 的实现
- (instancetype)initWithAddress:(NSString *)address completeBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk runtimeType:(OPRuntimeType)runtimeType {
    _runtimeType = runtimeType;

    if ([self initWithCoreCompleteBlk:completeBlk isSocketDebug:YES]) {
        BDPLogInfo(@"BDPJSContextApp init");
        [self buildJSContextApp:address];
    } else {
        BDPLogError(@"BDPJSContextApp init failed");
    }
    return self;
}

// 参考 BDPJSRuntimeApp 的实现，将一些js注入改成建立socket链接
- (void)buildJSContextApp:(NSString *)address {
    WeakSelf;
    [self dispatchAsyncInJSContextThread:^{
        StrongSelfIfNilReturn;
        [self initPropertiesBeforeCommon];
        [self setupContextBeforeCommon];
        //jsitodo 埋点
        BDPJSRuntimeSocketConnection *connection = [self.jsRuntime.socketDebugModule createConnectionWithAddress:address];
        OPMonitorEvent *event = BDPMonitorWithCode(RealmachineDebug.realmachine_socket_init, self.uniqueID);
        if (!connection) {
            event.setResultTypeFail().setErrorMessage(@"create connection result invalid!").flush();
            return;
        }
        event.setResultTypeSuccess().flush();
    }];
}

- (void) finishDebug {
    [self.jsRuntime.socketDebugModule finishDebug];
    BDPMonitorWithCode(RealmachineDebug.realmachine_socket_disconnected, self.uniqueID)
    .addCategoryValue(@"reason", @"afterFinishDebug").addCategoryValue(@"js_engine_type", self.jsRuntime.runtimeType)
    .flush();
}

#pragma mark - jscore 调用

// publish
- (void)_publishWithMessage:(BDPJSRuntimeSocketMessage *)message
{
    // webviewIDs类型从 NSString * -> NSArray<NSString *> *
    NSArray<NSNumber *> *appPageIDs = [message.webviewIds JSONValue];
    // param类型从 NSString -> NSDictionary
    NSDictionary *paramDict = [self.jsRuntime jsonValue:message.params];
    [self publish:message.event param:paramDict appPageIDs:appPageIDs useNewPublish:NO];
}

// onDocumentReady
- (void)_onDocumentReadyWithMessage:(BDPJSRuntimeSocketMessage *)message
{
    [self onDocumentReady];
}

#pragma mark - BDPJSRuntimeSocketConnectionDelegate

- (void)connection:(BDPJSRuntimeSocketConnection *)connection statusChanged:(BDPJSRuntimeSocketStatus)status {
    if (status == BDPJSRuntimeSocketStatusConnected) {
        [self initWorker];
        if ([self.delegate respondsToSelector:@selector(onSocketDebugConnected)]) {
            WeakSelf;
            // 切到主线程通知
            BDPExecuteOnMainQueue(^{
                StrongSelfIfNilReturn
                [self.delegate onSocketDebugConnected];
            });
        }
    } else if (status == BDPJSRuntimeSocketStatusDisconnected) {
        if ([self.delegate respondsToSelector:@selector(onSocketDebugDisconnected)]) {
            WeakSelf;
            // 切到主线程通知
            BDPExecuteOnMainQueue(^{
                StrongSelfIfNilReturn
                [self.delegate onSocketDebugDisconnected];
            });
        }
    } else if (status == BDPJSRuntimeSocketStatusFailed) {
        if ([self.delegate respondsToSelector:@selector(onSocketDebugConnectFailed)]) {
            WeakSelf;
            // 切到主线程通知
            BDPExecuteOnMainQueue(^{
                StrongSelfIfNilReturn
                [self.delegate onSocketDebugConnectFailed];
            });
        }
    }
}

- (void)connection:(BDPJSRuntimeSocketConnection *)connection didReceiveMessage:(BDPJSRuntimeSocketMessage *)message {
    if ([message.name isEqualToString:@"publish"]) {
        [self _publishWithMessage:message];
    } else if ([message.name isEqualToString:@"onDocumentReady"]) {
        [self _onDocumentReadyWithMessage:message];
    } else if ([message isPausedInspector]) {
        if ([self.delegate respondsToSelector:@selector(onSocketDebugPauseInspector)]) {
            WeakSelf;
            // 切到主线程通知
            BDPExecuteOnMainQueue(^{
                StrongSelfIfNilReturn
                [self.delegate onSocketDebugPauseInspector];
            });
        }
    } else if ([message isResumedInspector]) {
        if ([self.delegate respondsToSelector:@selector(onSocketDebugResumeInspector)]) {
            WeakSelf;
            // 切到主线程通知
            BDPExecuteOnMainQueue(^{
                StrongSelfIfNilReturn
                [self.delegate onSocketDebugResumeInspector];
            });
        }
    }
}

- (void)socketDidConnected {
    BDPMonitorWithCode(RealmachineDebug.realmachine_socket_open, self.uniqueID)
    .setResultTypeSuccess()
    .flush();
}

- (void)socketDidFailWithError:(NSError *)error {
    BDPMonitorWithCode(RealmachineDebug.realmachine_socket_failed, self.uniqueID)
    .setError(error)
    .flush();
}

- (void)socketDidCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    BDPMonitorWithCode(RealmachineDebug.realmachine_socket_disconnected, self.uniqueID)
    .addCategoryValue(@"reason", reason)
    .addCategoryValue(@"js_engine_type", self.jsRuntime.runtimeType)
    .addMetricValue(@"code", code)
    .addMetricValue(@"wasClean", wasClean)
    .flush();
}

- (void)initWorker {
    BDPJSRuntimeSocketMessage *message = [BDPJSRuntimeSocketMessage new];
    message.name = @"initWorker";

    NSDictionary *jssdkInfo = @{@"version": BDPSDKConfig.sharedConfig.jssdkVersion,
                                @"url": BDPSDKConfig.sharedConfig.jssdkDownloadURL,
                                @"greyHash": BDPSDKConfig.sharedConfig.jssdkGreyHash};

    NSDictionary *deviceEngineInfo = @{@"version": BDPDeviceTool.bundleShortVersion};

    NSDictionary *tmaConfig = @{@"platform" : @"ios",
                                @"sysVersion": BDPSystemVersion()};

    NSMutableDictionary *nativeTMAConfig = @{@"platform" : @"ios",
                                             @"debug" : @(YES),
                                             @"sysVersion": BDPSystemVersion()}.mutableCopy;
    if (!BDPIsEmptyDictionary(BDPSDKConfig.sharedConfig.jssdkEnvConfig)) {
        nativeTMAConfig[@"hostConfig"] = BDPSafeDictionary(BDPSDKConfig.sharedConfig.jssdkEnvConfig.copy);
    }
    /// initWorker
    NSDictionary *workerInitDict = @{};

    BDPLogInfo(@"BDPJSRuntimeSocketDebug InitWorker with FG");

    if ([BDPJSRuntimeSettings isUseNewNetworkAPIWithUniqueID: self.uniqueID]) {
        nativeTMAConfig[@"randomDeviceId"] = [BDPJSRuntimeSettings generateRandomID: self.uniqueID.appID];
    }

    BOOL shouldUseNewBridge = BDPSDKConfig.sharedConfig.shouldUseNewBridge;
    // api埋点链路是否使用jssdk埋点
    BOOL apiUseJSSDKMonitor = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetAPIUseJSSDKMonitor];
    BOOL workerApiUseJSSDKMonitor = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWorkerAPIUseJSSDKMonitor];
    BOOL nativeComponentEnableMap = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetNativeComponentEnableMap];
    BOOL nativeComponentEnableVideo = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetNativeComponentEnableVideo];

    BDPTracing *tmaTrace = [BDPTracingManager.sharedInstance getTracingByUniqueID:self.uniqueID];
    NSDictionary *trace = @{
        @"traceId": BDPSafeString(tmaTrace.traceId),
        @"createTime": @(tmaTrace.createTime),
        @"extensions": @[],
        @"config": @{@"optrace_batch_config":[OPTraceBatchConfig shared].rawConfig}
    };

    /// JSCoreFG
    NSMutableDictionary* jsCoreFG = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     @(shouldUseNewBridge), @"shouldUseNewBridge",
                                     @(apiUseJSSDKMonitor), @"apiUseJSSDKMonitor",
                                     @(workerApiUseJSSDKMonitor), @"workerApiUseJSSDKMonitor",
                                     @{ @"map": @(nativeComponentEnableMap),
                                        @"video": @(nativeComponentEnableVideo),
                                     }, @"nativeComponent",
                                     nil];
    [jsCoreFG addEntriesFromDictionary:[BDPJSRuntimeSettings getNetworkAPISettingsWithUniqueID: self.uniqueID]];
    /// initWorker with FG
    workerInitDict = @{@"device": deviceEngineInfo,
                       @"nativeTMAConfig": nativeTMAConfig,
                       @"TMAConfig": tmaConfig,
                       @"jssdk": jssdkInfo,
                       @"JSCoreFG": jsCoreFG,
                       @"TMATrace": trace};

    message.workerInitParams = workerInitDict;
    [self.jsRuntime.socketDebugModule sendMessageWithMessage:message];
    BDPMonitorWithCode(RealmachineDebug.realmachine_init_worker, self.uniqueID)
    .addCategoryValue(@"message",[message string])
    .addCategoryValue(@"js_engine_type", self.jsRuntime.runtimeType)
    .flush();
}

#pragma mark - app

#pragma mark - Initilize

- (instancetype)initWithCoreCompleteBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk withAppType:(BDPType )appType {
    return [self initWithCoreCompleteBlk:completeBlk withAppType:appType runtimeType:OPRuntimeTypeJscore];
}

- (instancetype)initWithCoreCompleteBlk:(BDPJSRuntimeCoreCompleteBlock)completeBlk withAppType:(BDPType )appType runtimeType:(OPRuntimeType)runtimeType {
    _runtimeType = runtimeType;
    BDPMonitorEvent *loadStartEvent = BDPMonitorWithName(kEventName_mp_jscore_load_start, nil);
    [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithStartKey:BDPPerformanceServiceContainerLoad uniqueId:self.uniqueID extra:nil];
    loadStartEvent.addCategoryValue(kEventKey_js_engine_type, runtimeType);
    if ([self initWithCoreCompleteBlk:completeBlk]) {
        BDPLogInfo(@"BDPJSContextApp init");
        self.appType = appType;
        BDPTracing *trace = [BDPTracingManager.sharedInstance getTracingByJSRuntime:self];
        loadStartEvent.bdpTracing(trace).flush();
        BDPMonitorWithName(kEventName_mp_jscore_load_result, nil).addCategoryValue(kEventKey_js_engine_type, runtimeType).bdpTracing(trace).setResultType(kEventValue_success).flush();
        [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithEndKey:BDPPerformanceServiceContainerLoad uniqueId:self.uniqueID extra:nil];
        [self buildJSContextApp];
    } else {
        BDPTracing *trace = [BDPTracingManager.sharedInstance generateTracing];
        loadStartEvent.bdpTracing(trace).flush();
        BDPMonitorWithName(kEventName_mp_jscore_load_result, nil).addCategoryValue(kEventKey_js_engine_type, runtimeType).bdpTracing(trace).setResultType(kEventValue_fail).setMonitorCode(GDMonitorCode.init_error).flush();
        [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithEndKey:BDPPerformanceServiceContainerLoad uniqueId:self.uniqueID extra:nil];
    }
    return self;
}

- (void)buildJSContextApp {
    WeakSelf;
    [self dispatchAsyncInJSContextThread:^{
        StrongSelfIfNilReturn;
        [self initPropertiesBeforeCommon];
        [self setupContextBeforeCommon];
        BOOL shouldUseNewBridge = BDPSDKConfig.sharedConfig.shouldUseNewBridge;
        // api埋点链路是否使用jssdk埋点
        BOOL apiUseJSSDKMonitor = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetAPIUseJSSDKMonitor];
        BOOL workerApiUseJSSDKMonitor = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetWorkerAPIUseJSSDKMonitor];
        BOOL nativeComponentEnableMap = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetNativeComponentEnableMap];
        BOOL nativeComponentEnableVideo = [EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetNativeComponentEnableVideo];

        /**
         * ⚠️ warnning ⚠️
         * 由于小程序真机调试目前架构上的问题无法自动同步注入到 JSCore 内的变量
         * 如果修改了注入对象的内容，请至 OPMicroAppJSRuntime/BDPJSRuntimeSocketDebug.m:445  (- initWorker) 做同步修改
         */
        
        // TMAConfig
        [self.jsRuntime setObject:@{@"platform" : @"ios", @"sysVersion": BDPSystemVersion()} forKeyedSubscript:@"TMAConfig"];
        //  如果需要对JSCore进行FG，请在这里统一加，请不要加TMAConfig里，build的时候会动态替换掉
        [self.jsRuntime setObject:@{
            @"shouldUseNewBridge": @(shouldUseNewBridge),
            @"apiUseJSSDKMonitor": @(apiUseJSSDKMonitor),
            @"workerApiUseJSSDKMonitor": @(workerApiUseJSSDKMonitor),
            @"nativeComponent": @{
                @"map": @(nativeComponentEnableMap),
                @"video": @(nativeComponentEnableVideo),
            }
        } forKeyedSubscript:@"JSCoreFG"];

        BDPMonitorWithName(kEventName_mp_jscore_lib_load_start, self.uniqueID).addCategoryValue(kEventKey_js_engine_type, _runtimeType).bdpTracing([BDPTracingManager.sharedInstance getTracingByJSRuntime:self]).flush();
        // Load tma-core.js
        [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithStartKey:BDPPerformanceServiceJSSDKLoad uniqueId:self.uniqueID extra:nil];
        BDPResolveModule(storageModule, BDPStorageModuleProtocol, self.appType);
        NSString *libPath = [[storageModule sharedLocalFileManager] pathForType:BDPLocalFilePathTypeJSLibAppCore] ?: @"";
        NSString *scriptPath = [NSString stringWithFormat:@"file://%@", libPath];
        [self eventMpJsLoadStart];
        self.loadTmaCoreBegin = [NSDate date];
        [self loadScriptWithURL:[NSURL URLWithString:scriptPath] callbackIsMainThread:NO completion:^{
            StrongSelfIfNilReturn;
            NSDate *endDate = [NSDate date];
            // 记录下执行耗时
            self.jsCoreExecCost = ([endDate timeIntervalSince1970] - [self.loadTmaCoreBegin timeIntervalSince1970]) * 1000.0;
            if (self.uniqueID) {
                BDPMonitorLoadTimelineDate(@"load_coreJs_begin", @{ @"file_path": @"tma-core.js" }, self.loadTmaCoreBegin, self.uniqueID);
                BDPMonitorLoadTimeline(@"load_coreJs_end", @{ @"file_path": @"tma-core.js" }, self.uniqueID);
                self.loadTmaCoreBegin = nil;
            } else {
                self.loadTmaCoreEnd = endDate;
            }
            [self eventMpJsLoadResult];
            BDPMonitorWithName(kEventName_mp_jscore_lib_load_result, self.uniqueID).addCategoryValue(kEventKey_js_engine_type, _runtimeType).bdpTracing([BDPTracingManager.sharedInstance getTracingByJSRuntime:self]).setResultType(kEventValue_success).flush();
            [BDPPerformanceProfileManager.sharedInstance monitorLoadTimelineWithEndKey:BDPPerformanceServiceJSSDKLoad uniqueId:self.uniqueID extra:@{@"isPreload":@(false)}];
            // 2019-8-22 增加core执行完成的Blk
            if (self.coreCompleteBlk != nil) {
                self.coreCompleteBlk();
            }
        }];
    }];
}

#pragma mark - Setup

- (void)updateUniqueID:(BDPUniqueID *)uniqueID delegate:(id<BDPJSRuntimeDelegate>)delegate
{
    [self setupUniqueID:uniqueID delegate:delegate];

    WeakSelf;
    [self dispatchAsyncInJSContextThread:^{
        StrongSelfIfNilReturn;
        [self setupContextAfterCommon];
        if (!self.isSocketDebug) {
            // Inject TMATrace
            BDPTracing *tmaTrace = [BDPTracingManager.sharedInstance getTracingByUniqueID:uniqueID];
            // 注入给JS的根trace object, 挂载在 TMATrace 上
            [self.jsRuntime setObject:@{
                @"traceId": BDPSafeString(tmaTrace.traceId),
                @"createTime": @(tmaTrace.createTime),
                @"extensions": @[],
                @"config": @{@"optrace_batch_config":[OPTraceBatchConfig shared].rawConfig}
            } forKeyedSubscript:@"TMATrace"];

            [self injectJSCoreFG];

            // TMAConfig.ready();
            [self.jsRuntime evaluateScript:@"TMAConfig.ready();"];
        }
    }];
}

- (void)appConfigLoaded:(OPAppUniqueID *)uniqueID {
    WeakSelf;
    [self dispatchAsyncInJSContextThread:^{
        StrongSelfIfNilReturn;
        [self injectJSCoreFG];
    }];
}

- (void)injectJSCoreFG {
    NSDictionary *networkAPISettings = [BDPJSRuntimeSettings getNetworkAPISettingsWithUniqueID: self.uniqueID];
    NSString *networkAPIScript = @"";
    BOOL prefetchCrashOpt = PrefetchLarkFeatureGatingDependcy.prefetchCrashOpt;
    BOOL useNewRequestAPI = [[networkAPISettings objectForKey:@"useNewRequestAPI"] boolValue];
    if (prefetchCrashOpt) {
        NSString *useNewRequestAPIStr = useNewRequestAPI ? @"true" : @"false";
        networkAPIScript = [NSString stringWithFormat:@"%@JSCoreFG.useNewRequestAPI = %@;", networkAPIScript, useNewRequestAPIStr];
    } else if (useNewRequestAPI) {
        networkAPIScript = [NSString stringWithFormat:@"%@JSCoreFG.useNewRequestAPI = true;", networkAPIScript];
    }
    BOOL useNewUploadAPI = [[networkAPISettings objectForKey:@"useNewUploadAPI"] boolValue];
    if (prefetchCrashOpt) {
        NSString *useNewUploadAPIStr = useNewUploadAPI ? @"true" : @"false";
        networkAPIScript = [NSString stringWithFormat:@"%@JSCoreFG.useNewUploadAPI = %@;", networkAPIScript, useNewUploadAPIStr];
    } else if (useNewUploadAPI) {
        networkAPIScript = [NSString stringWithFormat:@"%@JSCoreFG.useNewUploadAPI = true;", networkAPIScript];
    }
    BOOL useNewDownloadAPI = [[networkAPISettings objectForKey:@"useNewDownloadAPI"] boolValue];
    if (prefetchCrashOpt) {
        NSString *useNewDownloadAPIStr = useNewDownloadAPI ? @"true" : @"false";
        networkAPIScript = [NSString stringWithFormat:@"%@JSCoreFG.useNewDownloadAPI = %@;", networkAPIScript, useNewDownloadAPIStr];
    } else if (useNewDownloadAPI) {
        networkAPIScript = [NSString stringWithFormat:@"%@JSCoreFG.useNewDownloadAPI = true;", networkAPIScript];
    }
    if ([ChatAndContactSettings isGetChatInfoStandardizeEnabled]) {
        networkAPIScript = [NSString stringWithFormat:@"%@JSCoreFG.isGetChatInfoStandardizeEnabled = true;", networkAPIScript];
    }
    if ([ChatAndContactSettings isEnterChatStandardizeEnabled]) {
        networkAPIScript = [NSString stringWithFormat:@"%@JSCoreFG.isEnterChatStandardizeEnabled = true;", networkAPIScript];
    }
    if (networkAPIScript.length > 0) {
        [self.jsRuntime evaluateScript:networkAPIScript];
    }
}

#pragma mark - Event
/*------------------------------------------*/
//             Event - 埋点上报
/*------------------------------------------*/
- (void)eventMpJsLoadStart
{
    // 埋点 - mp_js_load_start, 开始计时
    [BDPTracker beginEvent:BDPTEJSLoadStart primaryKey:BDPTrackerPKAppLibJSLoad attributes:nil reportStart:NO uniqueID:self.uniqueID];
}

- (void)eventMpJsLoadResult
{
    // 埋点 - mp_js_load_result, 加载结果
    NSMutableDictionary *params = [BDPTracker buildJSContextParams:self.jsRuntime.jsContext];
    if ([params objectForKey:BDPTrackerParamSpecialKey] == nil) {
        [params setValue:BDPTrackerApp forKey:BDPTrackerParamSpecialKey];
    }
    [BDPTracker endEvent:BDPTEJSLoadResult primaryKey:BDPTrackerPKAppLibJSLoad attributes:params uniqueID:self.uniqueID];
}

#pragma mark - JS注入

- (void)runtimePublish:(NSString *)event param:(NSDictionary *)param appPageIDs:(NSArray<NSNumber *> *)appPageIDs useNewPublish:(BOOL)useNewPublish
{
    [self publish:event param:param appPageIDs:appPageIDs useNewPublish:useNewPublish];
}

- (void)runtimeOnDocumentReady;
{
    [self onDocumentReady];
}

@end

#pragma mark - UpdateStrategyControl

typedef NS_ENUM(NSUInteger, BDPOnUpdateReadySource) {
    BDPOnUpdateReadyFromUnknowSource = 0,
    BDPOnUpdateReadyFromUpdateManager,
    BDPOnUpdateReadyFromAyncUpdate
};


@interface OPAppUniqueID (UpdateStrategyControl)
-(NSString *)maxAgeForUpdateStrategyControl;
-(NSString *)maxAgeForUpdateStrategyControlWithoutUniqueId;
@end


@implementation OPAppUniqueID (UpdateStrategyControl)
//带AppID纬度的uniqueKey
-(NSString *)maxAgeForUpdateStrategyControl
{
    return [[self fullString] stringByAppendingFormat:@"_%@", [OPAppUniqueID userDefaultKeyWithoutUniqueId]];
}

//用户+租户纬度的uniqueKey
+(NSString *)userDefaultKeyWithoutUniqueId
{
    BDPPlugin(userPlugin, BDPUserPluginDelegate);
    NSString * userId = @"";
    if ([userPlugin respondsToSelector:@selector(bdp_sessionId)]) {
        userId = [[userPlugin bdp_userId] bdp_md5String];
    }
    NSString * encyptTenantId = @"";
    if ([userPlugin respondsToSelector:@selector(bdp_encyptTenantId)]) {
        encyptTenantId = [userPlugin bdp_encyptTenantId];
    }
    NSString * maxAgeKey = [NSString stringWithFormat:@"%@_%@_%@", userId, encyptTenantId,@"kBDPJSRuntimeUpdateStrategyControlTimestamp"];
    return maxAgeKey;
}

@end

@implementation OPMicroAppJSRuntime (UpdateStrategyControl)

-(NSString *)userDefaultKey
{
    return [BDPUniqueID userDefaultKeyWithoutUniqueId];
}

//成功更新后更新过期时间戳
-(void)updateTimestampAfterApplyUpdateSuccessWith:(BDPUniqueID * _Nonnull)uniqueID;
{
    if (uniqueID.isValid) {
        NSTimeInterval  currentTimeinterval = NSDate.new.timeIntervalSince1970;
        [[LSUserDefault dynamic] setDouble:currentTimeinterval
                                                  forKey:[uniqueID maxAgeForUpdateStrategyControl]];
        NSString * defaultKey = [self userDefaultKey];
        NSMutableArray * updateTimestampList = BDPSafeArray([[LSUserDefault dynamic] getArrayForKey:defaultKey]).mutableCopy;
        //按照时间顺序在队尾添加最近一次的更新时间，不能从中间插入
        [updateTimestampList addObject:@(currentTimeinterval)];
        [[LSUserDefault dynamic] setArray:updateTimestampList
                                                  forKey:defaultKey];
        BDPLogInfo(@"updateTimestampAfterApplyUpdateSuccessWith, timestamp:%@", @(currentTimeinterval));
    }
}

//判断距离上次更新是否过期，收否可以发 onUpdateReady 事件
-(BOOL)shouldSendOnUpdateReadyEventOrApplyUpdateWith:(BDPUniqueID * _Nonnull)uniqueID
{
    BDPTracing *trace = [BDPTracingManager.sharedInstance getTracingByUniqueID:uniqueID];
    OPMonitorEvent *event = BDPMonitorWithName(@"op_analysis_onUpdateReady", uniqueID).bdpTracing(trace).kv(@"appid_valid", @(uniqueID.isValid));
    //默认过期时间是一周，具体看 settings 配置【一周能只允许发一次 onUpdateReady】
    if ([uniqueID isValid]) {
        id<ECOConfigService> service = [ECOConfig service];
        //获取settings配置
        NSDictionary * expirationSettings = BDPSafeDictionary([service getLatestDictionaryValueForKey: @"meta_expiration_time_setting"]);
        //settings 里是新的key，和mina中的不同。需要做兼容处理
        NSDictionary<NSString *, id> * updateReadyMaxAgeConfig = expirationSettings[@"on_update_ready_max_age"];
        //获取用户级别的应用配置
        //settings 里是新的key，和mina中的不同。需要做兼容处理
        NSDictionary<NSString *, id> * userStrategyConfig = updateReadyMaxAgeConfig[@"user_strategy"];
        NSDictionary * userStrategyConfigForAppId = userStrategyConfig[uniqueID.appID];
        //先通过 AppId 取一次，没有的话根结点取默认配置
        id maxAgeForUserConfig = BDPSafeDictionary(userStrategyConfigForAppId)[@"max_age"]?:userStrategyConfig[@"max_age"];
        id maxUpdateCountForUserConfig = BDPSafeDictionary(userStrategyConfigForAppId)[@"max_update_count"]?:userStrategyConfig[@"max_update_count"];
        //默认没有配置时更新周期为0，允许随时更新
        NSTimeInterval maxAgeForUser = ([maxAgeForUserConfig respondsToSelector:@selector(doubleValue)] ? [maxAgeForUserConfig doubleValue] : 0) / 1000;
        //默认没有配置时更新次数为 1
        NSTimeInterval maxUpdateCountForUser = [maxUpdateCountForUserConfig respondsToSelector:@selector(intValue)] ? [maxUpdateCountForUserConfig intValue] : 1;
        //边界条件保护.防止settings 配置错误
        if (maxUpdateCountForUser<=0) {
            maxUpdateCountForUser = 1;
        }
        //先从settings里取对应app_id的配置，如果没有，取defaultMaxAge的默认配置
        id maxAgeConfig = updateReadyMaxAgeConfig[uniqueID.appID]?:updateReadyMaxAgeConfig[@"default_max_age"];
        //配置下发的单位是毫秒
        NSTimeInterval maxAge = ([maxAgeConfig respondsToSelector:@selector(doubleValue)] ? [maxAgeConfig doubleValue] : 0) / 1000;
        //取 userDefault 里配置的缓存值
        NSArray<NSNumber *> * updateTimestampList = BDPSafeArray([[LSUserDefault dynamic] getArrayForKey:[self userDefaultKey]]);
        //设置埋点的一系列kv
        //https://bytedance.feishu.cn/docs/doccnrGxIrFALHFIwJmLh5A04yd
        event.kv(@"user_max_age", maxAgeForUserConfig)
        .kv(@"app_id_fullstring", [uniqueID description])
        .kv(@"user_frequency", @(maxUpdateCountForUser))
        .kv(@"app_max_age", maxAgeConfig)
        .kv(@"last_apply_update_success_for_user", updateTimestampList.count>0 ? updateTimestampList.lastObject : @"0")
        .kv(@"last_apply_update_success", @([[LSUserDefault dynamic] getDoubleForKey:[uniqueID maxAgeForUpdateStrategyControl]]))
        .kv(@"is_app_first_trigger", @(NO))
        .kv(@"first_update_control", [BDPSafeDictionary(updateReadyMaxAgeConfig) bdp_boolValueForKey2:@"first_update_control"])
        .kv(@"trigger_on_update_ready_event", @(NO))
        .kv(@"original_fg", [expirationSettings JSONRepresentation]);

        //如果本地没有缓存，且配置里首次管控开启，则需要阻止更新
        if ([BDPSafeDictionary(updateReadyMaxAgeConfig) bdp_boolValueForKey2:@"first_update_control"] &&
            //maxAge 都是0的情况，满足逃逸命中
            (maxAge>0 || maxAgeForUser>0)) {
            NSString * firstTriggerKey = [NSString stringWithFormat:@"%@_first_trigger",[uniqueID maxAgeForUpdateStrategyControl]];
            if (![[LSUserDefault dynamic] getStringForKey:firstTriggerKey]) {
                //首次阻止更新，记录标记
                [[LSUserDefault dynamic] setString:@"YES" forKey:firstTriggerKey];
                event.kv(@"is_app_first_trigger", @(YES))
                .kv(@"update_forbidden", @(0)).flush();
                return NO;
            }
        }
        //先检查更新次数,如果更新次数已经到达上限，需要从后往前数找到最近符合条件的更新时间点
        if (updateTimestampList.count >= maxUpdateCountForUser) {
            BDPLogInfo(@"UpdateStrategyControl updateTimestampList.count >= maxUpdateCountForUser match");
            //先移除队列中头部的数据，不停添加更新导致数据太长
            NSMutableArray * cleanedTimestampList = updateTimestampList.mutableCopy;
            while (cleanedTimestampList.count > maxUpdateCountForUser) {
                [cleanedTimestampList removeObjectAtIndex:0];
            }
            [[LSUserDefault dynamic] setArray:cleanedTimestampList
                                                      forKey:[self userDefaultKey]];
            //找到符合更新时间点的倒数往前最近一次更新index
            NSInteger lastTimestampIndex = updateTimestampList.count - maxUpdateCountForUser;
            //检查index合法性
            if (lastTimestampIndex>=0 && [updateTimestampList[lastTimestampIndex] respondsToSelector:@selector(doubleValue)]){
                BDPLogInfo(@"UpdateStrategyControl ready check max age for user");
                NSTimeInterval nowTimestamp = [[NSDate new] timeIntervalSince1970];
                NSTimeInterval lastUpdateTimestamp = [updateTimestampList[lastTimestampIndex] doubleValue];
                //检查最早合法的一次更新时间和现在的时间间隔
                //如果小于设置的 maxAge，不允许发更新通知
                if ((nowTimestamp - lastUpdateTimestamp) < maxAgeForUser){
                    event.kv(@"update_forbidden", @(1)).flush();
                    return NO;
                }
            }
        }
        //获取本地记录的上次applyUpdate的timestap
        NSString * maxAgeKeyWithUniqueID = [uniqueID maxAgeForUpdateStrategyControl];

        NSTimeInterval nowTimestamp = [[NSDate new] timeIntervalSince1970];

        NSTimeInterval lastApplyUpdateTimestamp = [[LSUserDefault dynamic] getDoubleForKey:maxAgeKeyWithUniqueID];
        //如果小于maxAge，不允许更新
        if ((nowTimestamp - lastApplyUpdateTimestamp) < maxAge) {
            event.kv(@"update_forbidden", @(2)).flush();
            return NO;
        }
    }
    event.kv(@"trigger_on_update_ready_event", @(YES)).flush();
    return YES;
}

-(void)sendOnUpdateReadyEventFromAsyncStartupWithError:(NSError *)error
{
    if (error) {
        [self bdp_fireEvent:BDPCallbackEventOnUpdateFailed
                   sourceID:NSNotFound
                       data:nil];
    }else{
        [self sendOnUpdateReadyEventWithSource:BDPOnUpdateReadyFromAyncUpdate];
    }
}

-(void)sendOnUpdateReadyEventFromUpdateManager
{
    [self sendOnUpdateReadyEventWithSource:BDPOnUpdateReadyFromUpdateManager];
}

-(void)sendOnUpdateReadyEventWithSource:(BDPOnUpdateReadySource)soure
{
    BDPLogInfo(@"sendOnUpdateReadyEventWithSource, source=%lu", (unsigned long)soure);
    if ([self shouldSendOnUpdateReadyEventOrApplyUpdateWith:self.uniqueID]) {
        [self bdp_fireEvent:BDPCallbackEventOnUpdateReady
                   sourceID:NSNotFound
                       data:nil];
    } else {
        //log here, timstamp check fail
        BDPLogWarn(@"shouldSendOnUpdateReadyEventWith check fail with uniqueId: %@", self.uniqueID);
    }
}

@end


@interface OPMicroAppJSRuntime(Tracing)

@property (nonatomic, strong, readonly) BDPTracing *trace;

- (void)bindTracing:(BDPTracing *)trace;

@end

@implementation OPMicroAppJSRuntime(Tracing)


#pragma mark - trace
- (void)bindTracing:(BDPTracing *)trace {
    if (!trace) {
        BDPLogWarn(@"traceId is null");
        NSAssert(NO, @"traceId is null");
        return;
    }
    if (self.trace) {
        // 实例重复绑定trace
        BDPLogWarn(@"bind traceId repeat");
        NSAssert(NO, @"bind traceId repeat");
        return;
    }
    objc_setAssociatedObject(self, &kOPJSRuntimeTraceKey, trace, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDPTracing *)trace {
    return objc_getAssociatedObject(self, &kOPJSRuntimeTraceKey);
}

@end
