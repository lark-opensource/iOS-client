//
//  Created by 王浩宇 on 2018/11/18.
//

#import "BDPWebView.h"
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPSTLQueue.h>
#import "BDPTaskManager.h"
#import <OPFoundation/BDPUtils.h>
#import "BDPVdomAuthorization.h"
#import <OPFoundation/BDPWeakProxy.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPUIPluginDelegate.h>
#import <OPFoundation/BDPMacroUtils.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/OPAPIFeatureConfig.h>
#import <OPFoundation/EEFeatureGating.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPTracingManager.h>
#import <OPSDK/OPSDK-Swift.h>
#import <ECOInfra/ECOInfra-Swift.h>
#import <ECOInfra/ECOConfig.h>
#import <ECOInfra/ECOConfigService.h>
#import <ECOInfra/ECOCookieService.h>
#import <TTMicroApp/OPAppUniqueId+GadgetCookieIdentifier.h>
#import "WKScriptMessage+BDPWebViewFixCrash.h"
#import <LarkWebviewNativeComponent/LarkWebviewNativeComponent-Swift.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPModel+PackageManager.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPPluginManagerAdapter/OPPluginManagerAdapter-Swift.h>
#import <OPPluginManagerAdapter/OPBridgeRegisterOpt.h>


NSString * const kMessageNameInvoke = @"invoke";
NSString * const kMessageNamePublish = @"publish";
NSString * const kMessageNameOnDocumentReady = @"onDocumentReady";

// Editor 使用 Lark Bridge 的 fg
NSString * const kFeatureKeyEditorUseLarkBridge = @"editor.use.larkwebview.bridge";
NSString * const kFeatureKeyGadgetComponentUseLocalModel = @"gadget.component.use_local_model";
NSString * const kFeatureKeyGadgetRenderNewAddScriptDisable = @"gadget.render.new_add_script.disable";

@interface BDPWebView ()
@property (nonatomic, strong) OPPluginManagerAdapter *pm;

/// 头条封装的队列
@property (nonatomic, strong, readwrite) BDPSTLQueue *bwv_fireEventQueue;
@property (nonatomic, strong) OPAppUniqueID *uniqueID;
@property (nonatomic, weak) id<BDPWebViewInjectProtocol> bdpWebViewInjectdelegate;
@property (nonatomic, assign) BOOL fgNewAddScriptDisable; // 是否禁用新的script注入方式
@end

@implementation BDPWebView

@synthesize bridgeType = _bridgeType;
@synthesize authorization = _authorization;
@synthesize bridgeController = _bridgeController;

#pragma mark - Initilize
/*-----------------------------------------------*/
//              Initilize - 初始化相关
/*-----------------------------------------------*/
- (instancetype)initWithFrame:(CGRect)frame
                       config:(WKWebViewConfiguration *)config
                     delegate:(id<BDPWebViewInjectProtocol>)delegate
                      bizType:(LarkWebViewBizType *)bizType
    advancedMonitorInfoEnable:(BOOL)advancedMonitorInfoEnable
{
    // 必须要在这里，稍微晚一行都会导致时机不准确。
    NSString *newBridgeFGJS = [[NSString alloc] initWithFormat:@";window.EMANativeConfig = window.EMANativeConfig || {}; window.EMANativeConfig['shouldUseNewBridge'] = () => { return %@; };", @(BDPSDKConfig.sharedConfig.shouldUseNewBridge)];
    WKUserScript *fg = [[WKUserScript alloc] initWithSource:newBridgeFGJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    config = [BDPWebView bwv_processWebViewConfiguration:config];
    [config.userContentController addUserScript:fg];
    [config lnc_injectJSNativeComponentConfig];
    // 注入方向开关FG, JSSDK侧需要这个参数进行页面字体大小控制
    NSString *orientationFgJS = [[NSString alloc] initWithFormat:@";window.EMANativeConfig = window.EMANativeConfig || {}; window.EMANativeConfig['pageOrientationSwitchable'] = () => { return %@; };", @([OPSDKFeatureGating enablePageOrientation])];
    WKUserScript *orientationFg = [[WKUserScript alloc] initWithSource:orientationFgJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:orientationFg];

    LarkWebViewConfig *larkWebViewConfig = [GadgetLarkWebViewConfigHelper getLarkWebViewConfigWith:config bizType:bizType advancedMonitorInfoEnable:advancedMonitorInfoEnable];
    self = [super initWithFrame:frame config:larkWebViewConfig];
    if (self) {
        [WKScriptMessage bdpwebview_tryFixWKScriptMessageCrash];
        // WKNavigationDelegate
        self.navigationDelegate = self;
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        // 性能统计
        self.bwv_performanceMonitor = [BDPPerformanceMonitor<BDPWebViewTiming> new];
        _bdpWebViewInjectdelegate = delegate;
        self.bwv_fireEventQueue = [[BDPSTLQueue alloc] init];
        _isFireEventReady = NO;
        [self bwv_setupContext];
        [self setupCommonBridge];
        [self setupNativeComponent];
        _fgNewAddScriptDisable = [EEFeatureGating boolValueForKey:kFeatureKeyGadgetRenderNewAddScriptDisable];

        if ([self newAddScriptEnable]) {
            [self addMonitorUserScript];
            [self addEditorUserScript];
        }
    }
    return self;
}

// 这一行代码之前就会load一个模板了，如果在里边搞了些FG的逻辑，可能会导致时机过晚，建议lizhong lixiaorui 排查一下之前的FG会不会有问题
- (void)setupWebViewWithUniqueID:(BDPUniqueID *)uniqueID
{
    BDPLogTagInfo(BDPTag.webview, @"setup webview, app=%@", uniqueID.fullString);
    BDPCommon *common = BDPCommonFromUniqueID(uniqueID);
    _uniqueID = uniqueID;
    _bridgeType = 1 << common.uniqueID.appType;
    _authorization = common.auth;
    if (!_authorization) {
        _authorization = [[BDPVdomAuthorization alloc] init];
    }
    // 注入trace
    [self setUpTrace];
    // native webview配置,之前只用到了fg，所以可以在初始化的时候注入，现在要用到mina配置，需要在注入uniqueID的时候执行
    [self setupNativeConfig];
    // 同层组件配置信息注入
    [self setupNativeComponentConfig:uniqueID];
    // [BIG_COMPONENTS] 搜该关键字可以找到所有跟大组件相关的注释
    [self setupComponentsIfNeeded];
    // 注入settings中通用FG
    [self setupEMANativeConfigWithAppID:uniqueID.appID];

    self.customUserAgent = [BDPUserAgent getUserAgentStringWithUniqueID:uniqueID];

    _pm = [[OPPluginManagerAdapter alloc] initWith:self type:_uniqueID.appType];
    [OPManagerAdatperOCBridge gadgetRenderRegisterPoint:_pm];

    /// 将 gadget 隔离 cookie 同步到 dataStore
    /// 不区分是否开启隐私模式（即不论是否开启隐私模式，Gadget 本身相关的 Cookie 都需要考虑同步
    /// 如果开启了 Cookie 隔离，则需要用此方法解码相应的 Cookie 并同步，否则依赖当前业务已有 HTTPCookieStorage 默认同步策略即可。
    [[ECOCookie resolveService] syncGadgetWebsiteDataStoreWithGadgetId:uniqueID
                                                             dataStore:self.configuration.websiteDataStore];
}

- (void)dealloc
{
    //原封不动迁移 并未修改任何逻辑
    BDPLogTagInfo(BDPTag.webview, @"dealloc, app=%@", self.uniqueID);
    [self bwv_removeContext];
    self.navigationDelegate = nil;
    self.UIDelegate = nil;
    self.scrollView.delegate = nil;
}

- (void)setupNativeConfig {
    if ([self newAddScriptEnable]) {
        BDPLogInfo(@"[NativeConfig] injecting user script, newAddScriptEnable open");
        return;
    }
    BDPLogInfo(@"[NativeConfig] injecting user script");
    NSString *jsUserScriptString = [[NSString alloc] initWithFormat:@";window.EMANativeConfig = window.EMANativeConfig || {}; window.EMANativeConfig['apiUseJSSDKMonitor'] = () => { return %@; };", @([EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetAPIUseJSSDKMonitor])];
    [self evaluateJavaScript:jsUserScriptString completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        /// 这里会固定报错，因此用了 info
        BDPLogInfo(@"[NativeConfig] error %@", error);
    }];

    [self setupEditorNativeConfig];
}

- (void)setupNativeComponentConfig:(BDPUniqueID *)uniqueID {
    BDPTask *task = BDPTaskFromUniqueID(uniqueID);
    NativeComponentConfigManager *manager;
    if (task.componentConfigManager) {
        manager = task.componentConfigManager;
    } else {
        manager = [self nativeComponentConfigJSWithAppId:uniqueID.appID windowConfig:task.config.window.nativeComponent];
        task.componentConfigManager = manager;
    }
    
    NSString * _Nullable script = [manager configString];
    
    if (BDPIsEmptyString(script)) {
        BDPLogInfo(@"NativeComponentConfig script is nil %@", uniqueID.appID);
        return;
    }
    [self evaluateJavaScript:script completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        BDPLogInfo(@"NativeComponentConfig evaluate error%@", error)
    }];
}

// Editor 使用 Lark Bridge 的 fg
- (void)setupEditorNativeConfig {
    BDPLogInfo(@"Editor [NativeConfig] injecting user script");
    BOOL editorUseLarkBridge = [EEFeatureGating boolValueForKey:kFeatureKeyEditorUseLarkBridge];
    NSString *jsUserScriptString = [[NSString alloc] initWithFormat:@";window.EMANativeConfig = window.EMANativeConfig || {}; window.EMANativeConfig['useEditorNewBridge'] = () => { return %@; };", @(editorUseLarkBridge)];
    [self evaluateJavaScript:jsUserScriptString completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        /// 这里会固定报错，因此用了 info
        BDPLogInfo(@"Editor [NativeConfig] error %@", error);
    }];
}

- (void)setUpTrace {
    BDPLogInfo(@"[NativeConfig] injecting app trace");
    BDPTracing *tmaTrace = [BDPTracingManager.sharedInstance getTracingByUniqueID:_uniqueID];
    // 注入给JS的根trace object, 挂载在 TMATrace 上
    NSDictionary *trace = @{
        @"traceId": BDPSafeString(tmaTrace.traceId),
        @"createTime": @(tmaTrace.createTime),
        @"extensions": @[],
        @"config": @{@"optrace_batch_config": [OPTraceBatchConfig shared].rawConfig}
    };
    NSString *jsUserScriptString = [[NSString alloc] initWithFormat:@";window.EMANativeConfig = window.EMANativeConfig || {}; window.EMANativeConfig['TMATrace'] = () => { return %@; };", [trace JSONRepresentation] ?: @""];
    [self evaluateJavaScript:jsUserScriptString completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        /// 这里会固定报错，因此用了 info
        BDPLogInfo(@"[NativeConfig] error %@", error);
    }];
}

- (void)setupComponentsIfNeeded {
    BDPModel *model = nil;

    MetaContext *context = [[MetaContext alloc] initWithUniqueID:self.uniqueID token:nil];
    BDPModuleManager *moduleManager = [BDPGetResolvedModule(CommonAppLoadProtocol, self.uniqueID.appType) moduleManager];
    id<MetaInfoModuleProtocol> metaModule = [moduleManager resolveModuleWithProtocol:@protocol(MetaInfoModuleProtocol)];
    id<AppMetaProtocol> meta = [metaModule getLocalMetaWith:context];
    BDPModel *localModel = nil;
    if (meta) {
        localModel = [[BDPModel alloc] initWithGadgetMeta:meta];
    }

    BOOL componentUseLocalModel = [EEFeatureGating boolValueForKey:kFeatureKeyGadgetComponentUseLocalModel]; // yes 使用local model， no 使用内存中model

    // 之前使用local model，在第一次载入小程序的时候是获取不到的。
    // 加个fg，如果使用内存model 没什么问题，之后删掉使用local model的代码
    BDPCommon *common = BDPCommonFromUniqueID(self.uniqueID);
    BDPModel *currentModel = common.model;
    model = currentModel; // 使用内存中的model
    if (componentUseLocalModel) {
        model = localModel;
    }

    if (!model) {
        BDPLogError(@"[BIG_COMPONENTS] model error, has current model %@ has local model %@", @(currentModel != nil), @(localModel != nil));
    }

    if (model.components && model.components.count > 0) {
        /// 将 path 信息整理到 components 中
        NSDictionary *components = [ComponentsManager.shared localModelsOfComponents:model.components appType:self.uniqueID.appType];
        NSMutableDictionary *breifComponents = [[NSMutableDictionary alloc] init];
        [components enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, ComponentModel *componentModel, BOOL * _Nonnull stop) {
            if (componentModel.localPath) {
                breifComponents[key] = @{@"path": componentModel.localPath};
            }
        }];

        NSError *parseError = nil;
        NSData *componentsJSON = [NSJSONSerialization dataWithJSONObject:breifComponents options:NSJSONWritingPrettyPrinted error:&parseError];
        if (parseError) {
            BDPLogError(@"[BIG_COMPONENTS] parse components to json error: %@", parseError);
            [OPNewMonitorEvent(CommonMonitorCodeComponent.invalid_component_content) flush];
        } else {
            BDPLogInfo(@"[BIG_COMPONENTS] injecting user script");
            NSString *componentsJSONString = [[NSString alloc] initWithData:componentsJSON encoding:NSUTF8StringEncoding];
            NSString *jsUserScriptString = [[NSString alloc] initWithFormat:@";window.EMANativeConfig = window.EMANativeConfig || {}; window.EMANativeConfig['getJsComponents'] = () => { return %@; };", componentsJSONString];
            [self evaluateJavaScript:jsUserScriptString completionHandler:^(id _Nullable data, NSError * _Nullable error) {
                /// 这里会固定报错，因此用了 info
                BDPLogInfo(@"[BIG_COMPONENTS] error %@", error);
            }];
        }
    }
}

/// 给渲染层注入通用FG, 挂载在EMANativeConfig
- (void)setupEMANativeConfigWithAppID: (NSString *)appId
{
    NSMutableDictionary<NSString *, id> *registerRenderFG = [NSMutableDictionary dictionary];
    [self setupCopyConfigSettings:registerRenderFG];
    [self setupInputFocusFG:registerRenderFG];
    [self setupScalableFG:registerRenderFG appId:appId];
    [self setupScrollViewSetting:registerRenderFG appId:appId];
    if (BTD_isEmptyDictionary(registerRenderFG)) {
        return;
    }
    
    __block NSString *jsUserScriptString = @";window.EMANativeConfig = window.EMANativeConfig || {};";
    [registerRenderFG enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        jsUserScriptString = [jsUserScriptString stringByAppendingFormat:@"window.EMANativeConfig['%@'] = () => { return %@; };", key, obj];
    }];
    [self evaluateJavaScript:jsUserScriptString completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        BDPLogInfo(@"setupEMANativeConfig, %@", [registerRenderFG allKeys]);
    }];
}

- (void)setupScalableFG:(NSMutableDictionary *)registerRenderFG appId:(NSString *)appId {
    GadgetScalableConfig *config = [GadgetScalableConfig new];
    if([config checkScaleEnabledWithAppId: appId]) {
        [registerRenderFG btd_setObject:@"true" forKey:@"userScalable"];
    }
}

// 将settings中的'miniprogram_copyable_config'挂载在EMANativeConfig中
- (void)setupCopyConfigSettings:(NSMutableDictionary *)registerRenderFG {
    if (![OPSDKFeatureGating enableGadgetInjectCopyableConfig]) {
        return;
    }

    id<ECOConfigService> service = [ECOConfig service];
    NSDictionary<NSString *, id> * copyConfig = BDPSafeDictionary([service getDictionaryValueForKey: @"miniprogram_copyable_config"]);
    NSString *copyConfigJson = [copyConfig JSONRepresentation];
    NSString *result = [NSString stringWithFormat:@"'%@'", copyConfigJson ?: @""];
    [registerRenderFG btd_setObject:result forKey:@"getCopyableConfig"];
}

- (void)setupInputFocusFG:(NSMutableDictionary *)registerRenderFG {
    BOOL enable = [ECOSetting gadgetBugfixInputFocusPreventDefaultEnable];
    if (!enable) {
        return;
    }
    [registerRenderFG btd_setObject:@"true" forKey:@"inputFocusPreventDefault"];
}

- (void)setupScrollViewSetting:(NSMutableDictionary *)registerRenderFG appId:(NSString *)appId {
    BOOL enable = [ECOSetting gadgetScrollViewTouchMoveDisableEndEditingWithAppId:appId];
    if (!enable) {
        return;
    }
    [registerRenderFG btd_setObject:@"true" forKey:ECOSetting.kTouchMoveDisableEndEditingKey];
}

/*
 是否允许使用新的注入方式
 问题：在ios 15 快速打开一个含有editor的页面多次的情况下，会出现editor加载不出来（页面能正常加载）。
 原因：多次打开editor页面不能保证预加载load url完成从而导致注入editor配置（getJsComponents）失败
 解决办法：
 不依赖uniqueID的移动到url加载前，依赖uniqueID的在url加载后做补偿注入
 目前load url，setupUniqueID为预加载触发
 */
- (BOOL)newAddScriptEnable {
    if (@available(iOS 15.0, *)) { // iOS15以下旧的注入方式没有问题
        if (!_fgNewAddScriptDisable) {
            return YES;
        }
    }
    return NO;
}

// 注入monitor
- (void)addMonitorUserScript {
    BDPLogInfo(@"[NativeConfig] add user script at document start");
    NSString *jsUserScriptString = [[NSString alloc] initWithFormat:@";window.EMANativeConfig = window.EMANativeConfig || {}; window.EMANativeConfig['apiUseJSSDKMonitor'] = () => { return %@; };", @([EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetAPIUseJSSDKMonitor])];
    WKUserScript *fg = [[WKUserScript alloc] initWithSource:jsUserScriptString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self.configuration.userContentController addUserScript:fg];
}

// 注入editor开关
- (void)addEditorUserScript {
    BDPLogInfo(@"Editor [NativeConfig] add user script at document start");
    BOOL editorUseLarkBridge = [EEFeatureGating boolValueForKey:kFeatureKeyEditorUseLarkBridge];
    NSString *jsUserScriptString = [[NSString alloc] initWithFormat:@";window.EMANativeConfig = window.EMANativeConfig || {}; window.EMANativeConfig['useEditorNewBridge'] = () => { return %@; };", @(editorUseLarkBridge)];
    WKUserScript *fg = [[WKUserScript alloc] initWithSource:jsUserScriptString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [self.configuration.userContentController addUserScript:fg];
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:kMessageNameInvoke]) {
        NSDictionary *body = message.body;
        if (![body isKindOfClass:NSDictionary.class]) {
            // 不会走到这里
            body = NSDictionary.dictionary;
        }
        NSString *event = [body bdp_stringValueForKey:@"event"];
        NSString *callbackID = [body bdp_stringValueForKey:@"callbackId"];
        NSDictionary *paramDict = [self bwv_JSONValue:[body bdp_stringValueForKey:@"paramsString"]];
        [self invokeApiName:event data:paramDict callbackID:callbackID extra:nil useNewBridge:NO complete:nil];
    } else if ([message.name isEqualToString:kMessageNamePublish]) {
        //  Allowed types are NSNumber, NSString, NSDate, NSArray, NSDictionary, and NSNull.
        NSDictionary *body = message.body;
        NSString *event;
        NSDictionary *data;
        event = [body bdp_stringValueForKey:@"event"];
        data = [self bwv_JSONValue:[body bdp_stringValueForKey:@"paramsString"]];
        [self publishDelegate:event param:data];
    } else if ([message.name isEqualToString:@"publish2"]) {
        //  Allowed types are NSNumber, NSString, NSDate, NSArray, NSDictionary, and NSNull.
        NSDictionary *body = message.body;
        NSString *event;
        NSDictionary *data;
        event = [body bdp_stringValueForKey:@"apiName"];
        data = [[body bdp_dictionaryValueForKey:@"data"] decodeNativeBuffersIfNeed];
        [self publishDelegate:event param:data];
    } else if ([message.name isEqualToString:kMessageNameOnDocumentReady]) {
        [self onDocumentReadyDelegate];
    } else {
        //  兜底逻辑，预防webview向native发送了错误的信息，虽然不addScriptMessageHandler收不到，但还是兜底一下
        BDPLogTagError(BDPTag.webview, @"native recieve worng msg: %@", message.name)
    }
}

#pragma mark - WebView Inject Handler
/*-----------------------------------------------*/
//           JSCore Block - JS调用实现
/*-----------------------------------------------*/
- (void)invokeApiName:(NSString *)apiName data:(NSDictionary *)data callbackID:(NSString *)callbackID extra:(NSDictionary *)extra useNewBridge:(BOOL)useNewBridge complete:(void(^)(NSDictionary *, BDPJSBridgeCallBackType))complete
{
        // 拦截器 用于在需要的时候修改 event 和 param
    BDPJSBridgeMethod *method = [BDPJSBridgeMethod methodWithName:apiName params:data];
    [self.pm.invokeInterceptorChain preInvokeWithMethod:method extra:nil error: nil];
    apiName = method.name;
    data = method.params;

    // receive js call
    BDPTracing *appTracing = [[BDPTracingManager sharedInstance] getTracingByUniqueID:_uniqueID];
    OPTrace *tracing = nil;
    BOOL traceDowngrade = NO;
    BOOL useJSTrace = NO;
    
    // 使用了新bridge，则从extra字段反序列化trace
    if (useNewBridge) {
        NSString *traceString = [extra bdp_stringValueForKey:@"api_trace"];
        if (!BDPIsEmptyString(traceString)) {
            tracing = [[OPTraceService defaultService] generateTraceWithTraceID:traceString bizName:apiName];
            useJSTrace = YES;
        } else {
            traceDowngrade = YES;
        }
    }
    if (!tracing) {
        tracing = [OPTraceService.defaultService generateTraceWithParent:appTracing];
    }

    OPMonitorEvent *jsInvokeEvent = BDPMonitorWithNameAndCode(kEventName_op_api_invoke, APIMonitorCodeCommon.native_receive_invoke, _uniqueID);
    jsInvokeEvent.kv(@"isNewBridge", useNewBridge);
    OPMonitorEvent *callbackJSInvokeEvent = BDPMonitorWithNameAndCode(kEventName_op_api_invoke, APIMonitorCodeCommon.native_callback_invoke, _uniqueID);

    jsInvokeEvent
    .kv(@"api_name", apiName)
    .kv(@"callbackID", callbackID)
    .kv(@"param.count", data.count)
    .kv(@"trace_downgrade", traceDowngrade)
    .kv(@"use_js_trace", useJSTrace)
    .flushTo(tracing);

    // 销毁后不再支持API调用
    BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
    if (!common || common.isDestroyed) {
        BDPLogTagInfo(BDPTag.webview, @"app={%@} is destroyed, do not call invoke", common.uniqueID ?: @"")
        callbackJSInvokeEvent
        .setResultTypeFail()
        .kv(@"innerMsg", @"common is nil or destoryed")
        .flushTo(tracing);
        [tracing finish];
        return;
    }
    if (self.authorization != common.auth && common.auth) {
        self.authorization = common.auth;
    }

    // Invoke Delegate
    if ([OPBridgeRegisterOpt bridgeRegisterOptDisable]) {
        // 打开的话走原逻辑; 否则reportTimeline走PM派发
        [self invokeDelegate:apiName param:data];
    }

    WeakSelf;
    [self.pm invokeAPIWithMethod:method trace:tracing engine:self contextExtra:nil source:nil callback:^(BDPJSBridgeCallBackType status, NSDictionary * _Nullable response) {
        StrongSelfIfNilReturn;
        response = BDPProcessJSCallback(response, apiName, status, self.uniqueID);
        OPAPIReportResult(status, response, callbackJSInvokeEvent);
        callbackJSInvokeEvent.flushTo(tracing);
        [tracing finish];
        response = [response encodeNativeBuffersIfNeed];
        if (useNewBridge) {
            if (complete) {
                complete(response, status);
            }
        } else {
            [self callbackInvoke:callbackID data:response uniqueID:self.uniqueID];
        }
        BDPLogTagInfo(BDPTag.webview, @"WebView InvokeCallback Event Name: %@ ", apiName)
    }];
}

#pragma mark - JSCore Delegate Handler
/*-----------------------------------------------*/
//       JSCore Delegate Handler - JS方法代理
/*-----------------------------------------------*/
- (void)invokeDelegate:(NSString *)event param:(NSDictionary *)param
{
    // Invoke Delegate
    if (self.bdpWebViewInjectdelegate && [self.bdpWebViewInjectdelegate respondsToSelector:@selector(webViewInvokeMethod:param:)]) {
        [self.bdpWebViewInjectdelegate webViewInvokeMethod:event param:param];
    }

    // Invoke Log
    BDPLogInfo(@"WebView Invoke 事件名(Event)：%@ ", event);
}

- (void)publishDelegate:(NSString *)event param:(NSDictionary *)param
{
    // Publish Delegate
    if (self.bdpWebViewInjectdelegate && [self.bdpWebViewInjectdelegate respondsToSelector:@selector(webViewPublishMessage:param:)]) {
        [self.bdpWebViewInjectdelegate webViewPublishMessage:event param:param];
    }

    // Publish Log
    BDPLogInfo(@"WebView Publish 事件名(Event)：%@ ", event);
}

- (void)onDocumentReadyDelegate
{
    // onDocumentReady Delegate
    if (self.bdpWebViewInjectdelegate && [self.bdpWebViewInjectdelegate respondsToSelector:@selector(webViewOnDocumentReady)]) {
        [self.bdpWebViewInjectdelegate webViewOnDocumentReady];
    }

    // OnDocumentReady Log
    BDPLogInfo(@"WebView OnDocumentReady");
}

#pragma mark - SendMsg to JavaScript
- (void)fireEvent:(NSString *)event data:(NSDictionary *)data
{
    if (BDPIsEmptyString(event)) {
        BDPLogWarn(@"[BDPlatform-JSEngine] JSContext cannot fire null event.");
        return;
    }

    if (!BDPIsEmptyDictionary(data)) {
        data = [data encodeNativeBuffersIfNeed];
    } else {
        data = [[NSDictionary alloc] init];
    }

    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID];
        if (common && !common.isDestroyed) {
            if (BDPSDKConfig.sharedConfig.shouldUseNewBridge) {
                [self sendAsyncEventIfFireeventReadyWithEvent:event params:data];
            } else {
            NSString *dataJSONStr = [data JSONRepresentation] ?: @"{}";
            [self fireEventWithArguments:@[event, dataJSONStr]];
            }
        }
    });
}

#pragma mark - SendMsg Queue
/*-----------------------------------------------*/
//           SendMsg Queue - 消息队列
/*-----------------------------------------------*/
//  小程序接入套件统一灰度Bridge结束之后，这个方法需要迁移到web-view
- (void)fireEventWithArguments:(NSArray *)arguments
{
    if (!BDPIsEmptyArray(arguments)) {
        if (self.isFireEventReady) {
            NSString *arg0 = [arguments firstObject];
            NSString *arg1 = [arguments lastObject];
            NSString *eval = [NSString stringWithFormat:@"ttJSBridge.subscribeHandler(\"%@\", %@)", arg0, arg1];
            [self evaluateJavaScript:eval completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                if (error) {
                    BDPMonitorWithCode(GDMonitorCode.evaluate_javascript_error, self.uniqueID)
                    .setError(error)
                    .setErrorMessage(@"fireEvent error")
                    .flush();
                }
            }];
        } else {
            [self.bwv_fireEventQueue enqueue:arguments];
        }
    }
}
//  小程序接入套件统一灰度Bridge结束之后，这个方法需要迁移到web-view
//  该方法主要是为了实现向web发送消息，具体需求为webview与小程序双向通信，需要多传入一个参数
- (void)publishMsgWithApiName:(NSString * _Nonnull)apiName
                    paramsStr:(NSString * _Nonnull)paramsStr
                    webViewId:(NSInteger)webViewId {
    if (self.isFireEventReady) {
        NSString *eval = [NSString stringWithFormat:@"ttJSBridge.subscribeHandler(\"%@\",%@,%d)", apiName, paramsStr, webViewId];
        [self evaluateJavaScript:eval completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (error) {
                BDPMonitorWithCode(GDMonitorCode.evaluate_javascript_error, self.uniqueID)
                .setError(error)
                .setErrorMessage(@"fireEvent error")
                .flush();
            }
        }];
    } else {
        BDPLogError(@"fireEvent is not ready!");
    }
}

- (void)setIsFireEventReady:(BOOL)isFireEventReady
{
    if (_isFireEventReady != isFireEventReady) {
        _isFireEventReady = isFireEventReady;
        if (isFireEventReady) {
            [self fireAllEventIfNeedWithUniqueID:self.uniqueID];
        }
    }
}

#pragma mark - BDPJSBridgeEngineProtocol

- (void)bdp_fireEventV2:(NSString *)event data:(NSDictionary *)data
{
    // ArrayBuffer Not Supported in WebView
    [self fireEvent:event data:data];
}

- (void)bdp_fireEvent:(NSString *)event sourceID:(NSInteger)sourceID data:(NSDictionary *)data
{
    [self fireEvent:event data:data];
}

- (UIViewController *)bridgeController
{
    UIViewController *controller = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID].containerVC;
    if (self.bdpWebViewInjectdelegate && [self.bdpWebViewInjectdelegate respondsToSelector:@selector(webViewController)]) {
        controller = [self.bdpWebViewInjectdelegate webViewController] ?: controller;
    }
    return controller;
}

#pragma mark - WKNavigationDelegate
/*-----------------------------------------------*/
//       WKNavigationDelegate - 网页路由协议
/*-----------------------------------------------*/
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    if (webView == self) {
        BDPLogError(@"WebView Process DidTerminate");
        [webView reload];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    if (webView == self) {
        if ([self newAddScriptEnable] && self.uniqueID) {
            // 修复问题：在iOS 15只有load url finish之后的evaluateJavaScript才会执行成功（失败没有体现）
            // 思路：load url finish 和 setupWebViewWithUniqueID 没有相关性，所以这里finish后再次注入的补偿是解决setupWebViewWithUniqueID先执行但没有finish导致evaluateJavaScript失败的情况。
            BDPLogInfo(@"[NativeConfig] injecting user script when url load finish");
            [self setUpTrace];
            [self setupNativeComponentConfig: self.uniqueID];
            [self setupComponentsIfNeeded];
            [self setupEMANativeConfigWithAppID:self.uniqueID.appID];
        }
    }
}

//下面是原封不动迁移过来的，未修改任何逻辑
- (void)fireAllEventIfNeedWithUniqueID:(OPAppUniqueID *)uniqueID
{
    WeakSelf;
    [self.bwv_fireEventQueue enumerateObjectsUsingBlock:^(id  _Nonnull object, BOOL * _Nonnull stop) {
        StrongSelfIfNilReturn;
        if (BDPSDKConfig.sharedConfig.shouldUseNewBridge) {
            NSDictionary *dic = object;
            NSString *event = [dic bdp_stringValueForKey:@"event"] ?: @"";
            NSDictionary *params = [dic bdp_dictionaryValueForKey:@"params"] ?: @{};
            [self sendAsyncEventWithEvent:event params:params];
        } else {
        NSArray *arguments = (NSArray *)object;
        if (self && !BDPIsEmptyArray(arguments)) {
            NSString *arg0 = [arguments firstObject];
            NSString *arg1 = [arguments lastObject];
            NSString *eval = [NSString stringWithFormat:@"ttJSBridge.subscribeHandler(\"%@\", %@)", arg0, arg1];
            [self evaluateJavaScript:eval completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                if (error) {
                    BDPMonitorWithCode(GDMonitorCode.evaluate_javascript_error, uniqueID)
                    .setError(error)
                    .setErrorMessage(@"fireAllEvent error")
                    .flush();
                }
            }];
        }
        }
    }];
    [self.bwv_fireEventQueue empty];
}

- (void)bwv_setupContext
{
    BDPLogTagInfo(BDPTag.webview, @"addScriptMessageHandler: invoke, publish, onDocumentReady")
    // addScriptMessageHandler会导致self被持有无法释放，因此需要用NSProxy代理内部来引用一个WeakSelf;
    id<WKScriptMessageHandler> weakSelf = (id<WKScriptMessageHandler>)[BDPWeakProxy weakProxy:self];
    [self.configuration.userContentController addScriptMessageHandler:weakSelf name:kMessageNameInvoke];
    [self.configuration.userContentController addScriptMessageHandler:weakSelf name:kMessageNamePublish];
    [self.configuration.userContentController addScriptMessageHandler:weakSelf name:kMessageNameOnDocumentReady];
    [self.configuration.userContentController addScriptMessageHandler:weakSelf name:@"publish2"];
}

- (void)bwv_removeContext
{
    BDPLogTagInfo(BDPTag.webview, @"removeScriptMessageHandlerForName: invoke, publish, onDocumentReady")
    [self.configuration.userContentController removeScriptMessageHandlerForName:kMessageNameInvoke];
    [self.configuration.userContentController removeScriptMessageHandlerForName:kMessageNamePublish];
    [self.configuration.userContentController removeScriptMessageHandlerForName:kMessageNameOnDocumentReady];
    [self.configuration.userContentController removeScriptMessageHandlerForName:@"publish2"];
}

// 老协议回调
- (void)callbackInvoke:(NSString *)callbackID data:(NSDictionary *)data uniqueID:(OPAppUniqueID *)uniqueID
{
    if (!callbackID) {
        BDPLogTagError(BDPTag.webview, @"[BDPlatform-JSEngine] WebView cannot invoke with null callbackID.")
        return;
    }

    if (![callbackID isKindOfClass:NSString.class]) {
        BDPLogTagError(BDPTag.webview, @"[BDPlatform-JSEngine] WebView cannot invoke with worng format callbackID, %@", NSStringFromClass(callbackID.class))
        return;
    }
    NSNumber *callbackIDNumber = [NSNumber numberWithInteger:callbackID.integerValue];
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        if (common && !common.isDestroyed) {
            NSString *eval = [NSString stringWithFormat:@"ttJSBridge.invokeHandler(%@, %@)", callbackIDNumber, [data JSONRepresentation]];
            [self evaluateJavaScript:eval completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                if (error) {
                    BDPMonitorWithCode(GDMonitorCode.evaluate_javascript_error, uniqueID)
                    .setError(error)
                    .setErrorMessage(@"callbackInvoke error")
                    .flush();
                }
            }];
        }
    });
}

- (void)bdp_evaluateJavaScript:(NSString *)script completion:(void (^)(id, NSError *))completion
{
    BDPExecuteOnMainQueue(^{
        [self evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            if (error) {
                BDPMonitorWithCode(GDMonitorCode.evaluate_javascript_error, self.uniqueID)
                .setError(error)
                .setErrorMessage(@"evaluateJavaScript error")
                .flush();
            }
            if (completion) {
                completion(result, error);
            }
        }];
    });
}

- (NSDictionary *)bwv_JSONValue:(NSString *)param
{
    NSDictionary *dict = nil;
    id paramDict = [param JSONValue];
    if ([paramDict isKindOfClass:[NSString class]]) {
        dict = [(NSString *)paramDict JSONValue];
    } else if ([paramDict isKindOfClass:[NSDictionary class]]) {
        dict = [paramDict decodeNativeBuffersIfNeed];
    }

    if ([dict isKindOfClass:[NSDictionary class]]) {
        return dict;
    }
    return nil;
}

+ (WKWebViewConfiguration *)bwv_processWebViewConfiguration:(WKWebViewConfiguration *)config
{
    config.allowsInlineMediaPlayback = YES;                     // 是否允许内联或使用本机全屏控制器
    config.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;   // 是否要求必须手动点击播放
    return config;
}

@end
