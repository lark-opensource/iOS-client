//
//  BDPWebAppEngine.m
//  Timor
//
//  Created by yin on 2020/3/25.
//

#import "BDPWebAppEngine.h"
#import <OPFoundation/BDPWeakProxy.h>
#import <objc/runtime.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <OPPluginManagerAdapter/BDPJSBridgeUtil.h>
#import <OPPluginManagerAdapter/BDPJSBridgeInstancePlugin.h>
#import <OPPluginManagerAdapter/BDPJSBridgeCenter.h>
#import <OPPluginManagerAdapter/OPPluginManagerAdapter-Swift.h>
#import <OPFoundation/NSObject+Tracing.h>
#import <OPFoundation/BDPTracingManager.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPMonitorHelper.h>
#import <OPFoundation/BDPAuthorization.h>
#import <OPFoundation/BDPUniqueID.h>
#import <ECOInfra/BDPLogHelper.h>
#import <OPFoundation/BDPSchemaCodec.h>
#import <OPFoundation/BDPAppMetaBriefProtocol.h>
#import <OPFoundation/BDPJSBridgeProtocol.h>
#import <OPFoundation/BDPAppearanceConfiguration+Private.h>
#import "BDPTimorClient+Business.h"
#import <OPFoundation/OPAPIFeatureConfig.h>
#import <OPFoundation/BDPAPIPluginDelegate.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/BDPTracingManager.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import <OPFoundation/BDPAppContext.h>
#import <LarkOPInterface/LarkOPInterface-Swift.h>

@interface BDPWebAppEngine ()
// 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc
@property(nonatomic, weak) UIViewController *controller;
@property(nonatomic, weak) id<OPJsSDKImplProtocol> jsImp;
/// 引擎唯一标示符
@property (nonatomic, strong, readwrite, nonnull) BDPUniqueID *uniqueID;
/// 开放平台 JSBridge 方法类型
@property (nonatomic, assign, readwrite) BDPJSBridgeMethodType bridgeType;
/// 调用 API 所在的 ViewController 环境
@property (nonatomic, weak, readwrite, nullable) UIViewController *bridgeController;
/// shouldUseNewbridgeProtocol代表是否使用了新的协议，webappengine看了一下代码是和controller生命周期挂钩，但是webvc加载不同的网页的时候，不同网页引入的jssdk可能是新的也可能是老的，需要兼容
@property (nonatomic, assign) BOOL shouldUseNewBridgeProtocol;
@property (nonatomic, strong) OPPluginManagerWebAppAdapter *pluginManager;

@property (nonatomic, copy) NSDictionary *apiDispatchConfig;

@end

@implementation BDPWebAppEngine

- (instancetype)init {
    self = [super init];
    BDPResolveModule(storageModule, BDPStorageModuleProtocol, OPAppTypeWebApp);
    [storageModule restSandboxEntityMap];
    return self;
}

#pragma mark BDPEngineProtocol & BDPJSBridgeEngineProtocol

- (void)bdp_evaluateJavaScript:(NSString * _Nonnull)script
                    completion:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completion {
    NSAssert(false, @"BDPWebAppEngine has no implement, can not enter");
}

- (void)bdp_fireEvent:(NSString *)event data:(NSDictionary *)data {
    if (BDPIsEmptyString(event)) {
        BDPLogWarn(@"[bdp_fireEvent] JSContext cannot fire null event.");
        return;
    }
    
    if (!BDPIsEmptyDictionary(data)) {
        data = [data encodeNativeBuffersIfNeed];
    } else {
        data = [[NSDictionary alloc] init];
    }
    NSString *dataJSONStr = [data JSONRepresentation] ?: @"{}";
    NSString *eval;
    if (self.shouldUseNewBridgeProtocol) {
        eval = [CallBackForWebAppEngineNewBridgeProtocol callbackStringWith:data?:@{} callbackID:event?:@"" type:BDPJSBridgeCallBackTypeContinued];
    } else {
        //  原逻辑维持不变，等待全量再删除
        eval = [NSString stringWithFormat:@"ttJSBridge.subscribeHandler(\"%@\", %@)", event, dataJSONStr];
    }

    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        [self.jsImp evaluateJavaScriptWithScript:eval completion:nil];
    });
}

- (void)bdp_fireEventV2:(NSString *)event data:(NSDictionary *)data {
    if (BDPIsEmptyString(event)) {
        BDPLogWarn(@"[bdp_fireEvent] JSContext cannot fire null event.");
        return;
    }
    
    if (!BDPIsEmptyDictionary(data)) {
        data = [data encodeNativeBuffersIfNeed];
    } else {
        data = [[NSDictionary alloc] init];
    }
    NSString *dataJSONStr = [data JSONRepresentation] ?: @"{}";
    NSString *eval;
    if (self.shouldUseNewBridgeProtocol) {
        eval = [CallBackForWebAppEngineNewBridgeProtocol callbackStringWith:data?:@{} callbackID:event?:@"" type:BDPJSBridgeCallBackTypeContinued];
    } else {
        //  原逻辑维持不变，等待全量再删除
        eval = [NSString stringWithFormat:@"ttJSBridge.subscribeHandler(\"%@\", %@)", event, dataJSONStr];
    }
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;
        [self.jsImp evaluateJavaScriptWithScript:eval completion:nil];
    });
}

- (void)bdp_fireEvent:(NSString *)event sourceID:(NSInteger)sourceID data:(NSDictionary *)data {
    [self bdp_fireEventV2:event data:data];
}

#pragma mark 普通方法

/// 回调 增加BDPJSBridgeCallBackType，满足新协议
- (void)callbackInvoke:(NSString *)callbackID data:(NSDictionary *)data
                  type:(BDPJSBridgeCallBackType)type trace:(OPTrace *)trace
{
    OPMonitorEvent *nativeResult;
    nativeResult = BDPMonitorWithNameAndCode(kEventName_op_api_invoke, APIMonitorCodeCommon.native_invoke_result, _uniqueID)
    .kv(@"callbackID", callbackID);
    OPAPIReportResult(type, data, nativeResult);
    nativeResult.flushTo(trace);

    OPMonitorEvent *callbackJS = BDPMonitorWithNameAndCode(kEventName_op_api_invoke, APIMonitorCodeCommon.native_callback_invoke, _uniqueID);

    if (!callbackID || ![callbackID isKindOfClass:[NSString class]]) {
        callbackJS.setResultTypeFail()
        .kv(@"innerMsg", @"callbackID invalid")
        .flushTo(trace);
        [trace finish];
        return;
    }
    WeakSelf;
    BDPExecuteOnMainQueue(^{
        StrongSelfIfNilReturn;

        NSDictionary *encodeData = data;
        if ([EMAFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetEnableH5NativeBufferEncode]) {
            encodeData = BDPIsEmptyDictionary(data) ? @{} : [data encodeNativeBuffersIfNeed];
        }

        //  每次API调用的时候
        NSString *eval;
        if (self.shouldUseNewBridgeProtocol) {
            //  组装新协议回调所需的结构
            eval = [CallBackForWebAppEngineNewBridgeProtocol callbackStringWith:encodeData?:@{} callbackID:callbackID?:@"" type:type];
        } else {
            //  原逻辑维持不变，等待全量再删除
            eval = [NSString stringWithFormat:@"ttJSBridge.invokeHandler(%@, %@)", callbackID, [encodeData JSONRepresentation]];
        }
        if (BDPIsEmptyString(eval)) {
            BDPLogError(@"webappengine callback str is empty")
            callbackJS.setResultTypeFail()
            .kv(@"innerMsg", @"webappengine callback str is empty")
            .flushTo(trace);
            [trace finish];
            return;
        }
        [self.jsImp evaluateJavaScriptWithScript:eval completion:nil];
        OPAPIReportResult(type, data, callbackJS);
        callbackJS.flushTo(trace);
        [trace finish];
    });
}

+ (instancetype)getInstance:(UIViewController *)controller
                      jsImp:(id)jsImp
 shouldUseNewbridgeProtocol:(BOOL)shouldUseNewbridgeProtocol {
    BDPWebAppEngine *instance = objc_getAssociatedObject(controller, _cmd);
    if (!instance) {
        instance = [[BDPWebAppEngine alloc] init];
        
        BOOL conform = [jsImp conformsToProtocol:@protocol(OPJsSDKImplProtocol)];
        if (conform) {
            id<OPJsSDKImplProtocol> jsSDkImp = jsImp;
            instance.uniqueID = [OPAppUniqueID uniqueIDWithAppID:jsSDkImp.appId identifier:nil versionType:OPAppVersionTypeCurrent appType:OPAppTypeWebApp];
        } else {
            BDPLogWarn(@"instance not comformTo protocol");
            NSAssert(!conform, @"instance not conformTo protocol");
            instance.uniqueID = [OPAppUniqueID uniqueIDWithAppID:nil identifier:nil versionType:OPAppVersionTypeCurrent appType:OPAppTypeWebApp];
        }
        instance.pluginManager = [[OPPluginManagerWebAppAdapter alloc] initWith:instance type:OPAppTypeWebApp];
        
        // TODO: 此处强转类型需要适配确认
        // 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 评审要求，去除导致KA问题「最大之错误」的API在网页调用，没有修改任何其他逻辑
        instance.controller = controller;
        [[BDPTimorClient sharedClient].appearanceConfg bdp_apply];
        objc_setAssociatedObject(controller, _cmd, instance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    //  虽然webengine对象和controller挂钩，但是一个controller里webview跳转的时候可能还是会变化协议，所以每次掉调用都需要重新设置shouldUseNewBridgeProtocol
    instance.shouldUseNewBridgeProtocol = shouldUseNewbridgeProtocol;
    return instance;
}

// H5应用 API迁移 JS 参数格式 如下:
// {
//    "__v2__":  ;     // 标识是否走新版ttbridge相关接口
//    "callbackId": ;
//    "params": {};    // 真正调用接口需要的参数
// }
// 示例：methodName = "showToast"
// params = {
//    "__v2__": 1;
//    "callbackId": 5;
//    "params": {
//        duration = 2000;
//        icon = success;
//        title = "\U4e3e\U62a5\U6210\U529f";
//    };
//}
- (void)invokeMethod:(NSString *)methodName params:(NSDictionary *)params jsImp:(id)jsImp controller: (UIViewController *)controller needAuth:(BOOL)needAuth trace: (OPTrace *)trace webTrace: (OPTrace *)webTrace {
    // 此处 params 不是业务层 params，包含 callbackId 等字段，业务层 params 在下一级
    BDPJSBridgeMethod *method = [BDPJSBridgeMethod methodWithName:methodName params:params];
    // 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 评审要求，去除导致KA问题「最大之错误」的API在网页调用，没有修改任何其他逻辑
    BOOL conform =  [jsImp conformsToProtocol:@protocol(OPJsSDKImplProtocol)];
    if (!conform) {
        NSString *err_msg = [NSString stringWithFormat:@"BDPWebAppEngine can not invoke with controller %@ and jsImp %@", NSStringFromClass([controller class]), NSStringFromClass([jsImp class])];
        BDPMonitorWithNameAndCode(kEventName_op_h5_api_error, OWMonitorCodeApi.fail, nil)
            .setResultTypeFail()
            .setErrorMessage(err_msg)
            .kv(kEventKey_method, methodName)
            .flush();
        BDPLogWarn(@"instance not comformTo protocol");
        NSAssert(!conform, @"BDPJSBridgeInvoking invokeWebMethod: instance not conformTo protocol");

        BDPMonitorWithNameAndCode(kEventName_op_api_invoke, APIMonitorCodeCommon.native_callback_invoke, _uniqueID)
        .setResultTypeFail()
        .kv(@"innerMsg", err_msg)
        .flushTo(trace);
        [trace finish];
        return;
    }
    // TODO: 此处强转类型需要适配确认
    // 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 
    [self invokeMethodForCallback:method jsImp:jsImp controller:controller needAuth:needAuth trace:trace webTrace:webTrace];
}

// API授权体系策略如下
//1. 白名单，无需走授权体系，直接调用API
//2. 非白名单，需要走授权体系，且已经经过鉴权（有session）, 调用tt. API之前先校验权限
//3. 非白名单，需要走授权体系，但没有鉴权过（无session），不允许调用任何tt. API
// 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 评审要求，去除导致KA问题「最大之错误」的API在网页调用，没有修改任何其他逻辑 这里只是去掉了一个废弃协议名字
- (void)invokeMethodForCallback:(BDPJSBridgeMethod *)method jsImp:(id<OPJsSDKImplProtocol>)jsImp controller: (UIViewController *)controller needAuth:(BOOL)needAuth trace:(OPTrace *)trace webTrace:(OPTrace *)webTrace{
    BDPLogInfo(@"BDPWebEngine invoke method, appId=%@ name=%@ needAuth=%@ emptySession=%@", jsImp.appId, method.name, @(needAuth), @(BDPIsEmptyString(jsImp.authSession)));
    self.jsImp = jsImp;
    self.url = jsImp.url;
    self.bridgeType = BDPJSBridgeMethodTypeWebApp;
    BDPUniqueID *jsImpUniqueID = [BDPUniqueID uniqueIDWithAppID:jsImp.appId
                                                     identifier:nil
                                                    versionType:OPAppVersionTypeCurrent
                                                        appType:BDPTypeWebApp];
    self.uniqueID = jsImpUniqueID;
    self.bridgeController = controller;

    NSMutableDictionary *mParams = [NSMutableDictionary dictionaryWithDictionary:method.params];
    method.params = [[mParams bdp_dictionaryValueForKey:@"params"] decodeNativeBuffersIfNeed];
    NSString *callbackID = [mParams bdp_stringValueForKey:@"callbackId"];

    OPMonitorEvent *invokeStart;
    invokeStart = BDPMonitorWithNameAndCode(kEventName_op_api_invoke, APIMonitorCodeCommon.native_invoke_start, jsImpUniqueID)
    .kv(@"api_name", method.name)
    .kv(@"url", [BDPLogHelper safeURLString:jsImp.url])
    .kv(@"emptySession", BDPIsEmptyString(jsImp.authSession))
    .kv(@"needAuth", needAuth)
    .kv(@"callbackId", callbackID);

    if (needAuth) {
        id<BDPMetaWithAuthProtocol> authModel = jsImp.authModel;
        id<BDPAuthStorage> authStorage = jsImp.authStorage;
        if (authModel && authStorage) {
            BDPAuthorization *auth = [[BDPAuthorization alloc] initWithAuthDataSource:authModel storage:authStorage];
            __weak typeof(self) wself = self;
            auth.authSyncSession = ^NSString * _Nonnull {
                __strong typeof(wself) self = wself;
                if (!self) {
                    BDPLogError(@"BDPWebEngine released");
                    return @"";
                }
                return self.jsImp.authSession;
            };
            self.authorization = auth;
        }
        if (BDPIsEmptyString(self.jsImp.authSession)) {
            OPErrorWithMsg(OWMonitorCodeApiAuth.auth_has_no_session, @"BDPWebEngine invoke method need auth, but session is empty, uniqueID=%@ name=%@", self.uniqueID, method.name);
        }
    }
    
    OPAPIFeatureConfig *apiConfig = [[OPAPIFeatureConfig alloc] initWithCommandString:@""];
    BDPPlugin(apiPlugin, BDPAPIPluginDelegate);
    if (apiPlugin && [apiPlugin respondsToSelector:@selector(bdp_getAPIDispatchConfig)] && [apiPlugin respondsToSelector:@selector(bdp_getAPIDispatchConfig:forAppType:apiName:)]) {
        if (!self.apiDispatchConfig) {
            self.apiDispatchConfig = [apiPlugin bdp_getAPIDispatchConfig];
        }
        apiConfig = [apiPlugin bdp_getAPIDispatchConfig:self.apiDispatchConfig forAppType:self.uniqueID.appType apiName:method.name];
    }
    
    BOOL usePluginManager = YES;
    // PluginSystem上线策略详见：https://bytedance.feishu.cn/docs/doccnxe4b5UBc3AYHeovsAtzKGd
    switch (apiConfig.apiCommand) {
        case OPAPIFeatureCommandDoNotUse:
            return;
        case OPAPIFeatureCommandUseOld:
            usePluginManager = NO;
            break;
        default:
            break;
    }
    BOOL disablePluginManager = [EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetDisablePluginManager];
    if (!disablePluginManager && usePluginManager && self.pluginManager) { // 没有auth 交给v1处理
        invokeStart.kv(@"usePM", YES).flushTo(trace);
        [self invokeMethodV2ForCallback:method jsImp:jsImp controller:controller needAuth:needAuth callbackID:callbackID apiConfig:apiConfig trace:trace webTrace:webTrace]; // OPPluginManagerAdapter的调用，兼容旧的
    } else {
        invokeStart.kv(@"usePM", NO).flushTo(trace);
        [self invokeMethodV1ForCallback:method jsImp:jsImp controller:controller needAuth:needAuth callbackID:callbackID trace:trace]; // 旧的api调用
        [BDPJSBridgeCenter monitorDowngradeAPIWithMethod:method uniqueID:jsImpUniqueID];
    }
}
// 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 评审要求，去除导致KA问题「最大之错误」的API在网页调用，没有修改任何其他逻辑 这里只是去掉了一个废弃协议名字
- (void)invokeMethodV2ForCallback:(BDPJSBridgeMethod *)method jsImp:(id<OPJsSDKImplProtocol>)jsImp controller: (UIViewController *)controller needAuth:(BOOL)needAuth callbackID:(NSString *)callbackID apiConfig:(OPAPIFeatureConfig *)apiConfig trace:(OPTrace *)trace webTrace:(OPTrace *)webTrace {
    BDPUniqueID *jsImpUniqueID = self.uniqueID;
    WeakSelf;
    WeakObject(controller);
    [self.pluginManager callAPIWithMethod:method trace: trace engine:self needAuth:needAuth callback:^(BDPJSBridgeCallBackType status, NSDictionary * _Nullable response) {
        StrongSelfIfNilReturn;
        StrongObjectIfNilReturn(controller);
        if (status == BDPJSBridgeCallBackTypeNoHandler && apiConfig.apiCommand != OPAPIFeatureCommandRemoveOld) {
            [self invokeMethodV1ForCallback:method jsImp:jsImp controller:controller needAuth:needAuth callbackID:callbackID trace:trace];
            [BDPJSBridgeCenter monitorDowngradeAPIWithMethod:method uniqueID:jsImpUniqueID];
            return;
        }
        
        [self monitorEvent:method.name uniqueID:jsImpUniqueID callbackType:status];
        NSDictionary *responseInfo = BDPProcessJSCallback(response, method.name, status, jsImpUniqueID);
        
        // 若调用的是config api，考虑到OpenAPIConfigPlugin无法获取sdk，考虑在该回调中进行sdk的逻辑处理，并修改responseInfo
        if([method.name isEqualToString: @"config"]){
            NSDictionary *data = [[response bdp_dictionaryValueForKey: @"data"] bdp_dictionaryValueForKey: @"data"];
            NSMutableDictionary *resultInfo = [NSMutableDictionary dictionary];
            [resultInfo setValue: [response bdp_stringValueForKey: @"errorCode"] forKey: @"errorCode"];
            [resultInfo setValue: [response bdp_stringValueForKey: @"errorMessage"] forKey: @"errorMessage"];
            [resultInfo setValue: [response bdp_stringValueForKey: @"errno"] forKey: @"errno"];
            [resultInfo setValue: [response bdp_stringValueForKey: @"errString"] forKey: @"errString"];
            if([response bdp_stringValueForKey: @"apiCaller"] == nil || [[response bdp_stringValueForKey: @"apiCaller"] isEqualToString: @"other"]) {
                [jsImp callbackConfigWithResponse: response webTrace: webTrace];
                NSString *sessionKey = [data bdp_stringValueForKey: @"session_key"];
                [resultInfo setValue: sessionKey forKey: @"session_key"];
            } else {
                NSString *sessionKey = [data bdp_stringValueForKey: @"jssdk_session"];
                [resultInfo setValue: sessionKey forKey: @"jssdk_session"];
            }
            responseInfo = resultInfo;
        }
        [self callbackInvoke:callbackID data:responseInfo type:status trace:trace];
    }];
}
// 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 评审要求，去除导致KA问题「最大之错误」的API在网页调用，没有修改任何其他逻辑 这里只是去掉了一个废弃协议名字
- (void)invokeMethodV1ForCallback:(BDPJSBridgeMethod *)method jsImp:(id<OPJsSDKImplProtocol>)jsImp controller: (UIViewController *)controller needAuth:(BOOL)needAuth callbackID: (NSString *)callbackID trace:(OPTrace *)trace {

    // 💡类实例方法全名拼写规则：[方法名].[方法类型]
    NSString *fullName = [NSString stringWithFormat:@"%@.%@", method.name, @(BDPJSBridgeMethodTypeWebApp)];
    BOOL isOnMainThread = [[BDPJSBridgeCenter defaultCenter] isOnMainThreadFullName:fullName];
    // 寻找 InstanceMethod 类实例方法
    BDPJSBridgeInstanceClass class = [[BDPJSBridgeCenter defaultCenter] classForFullName:fullName];
    BDPUniqueID *jsImpUniqueID = self.uniqueID;
    if (!class) {
        NSURL *monitor_url = [NSURL URLWithString:jsImp.url];
        NSString *err_msg = [NSString stringWithFormat:@"BDPWebAppEngine can not find class to invoke instance method with url: host = %@ path = %@", monitor_url.host, monitor_url.path];
        BDPMonitorWithNameAndCode(kEventName_op_h5_api_error, OWMonitorCodeApi.fail, nil)
            .setResultTypeFail()
            .kv(kEventKey_method, method.name)
            .kv(kEventKey_app_id, jsImp.appId)
            .setErrorMessage(err_msg).flush();
        NSDictionary *response = BDPProcessJSCallback(@{@"errMsg": err_msg, @"errorCode": @103, @"errno": @103, @"errString": @"API not available"}, method.name, BDPJSBridgeCallBackTypeUnknown, jsImpUniqueID);
        [self callbackInvoke:callbackID data:response type:BDPJSBridgeCallBackTypeUnknown trace:trace];
        return;
    }

    WeakSelf;
    if (needAuth) {
        if (!BDPIsEmptyString(self.jsImp.authSession) && self.authorization && [self.authorization respondsToSelector:@selector(checkAuthorization:engine:completion:)]) {
            [self.authorization checkAuthorization:method engine:self completion:^(BDPAuthorizationPermissionResult result) {
                // 权限申请成功
                if (result == BDPAuthorizationPermissionResultEnabled) {
                    [self invokeMethod:method callback:^(BDPJSBridgeCallBackType type, NSDictionary *args) {
                        StrongSelfIfNilReturn;
                        [self monitorEvent:method.name uniqueID:jsImpUniqueID callbackType:type];
                        NSMutableDictionary *mutableDict = args? [args mutableCopy]: [[NSMutableDictionary alloc] init];
                        NSString *appendErrorMsg = [mutableDict stringValueForKey:@"errMsg" defaultValue:@""];
                        NSString *errMsg = [NSString stringWithFormat:@"%@ %@", BDPErrorMessageForStatus(type), appendErrorMsg];
                        [mutableDict setValue:errMsg forKey:@"errMsg"];
                        NSDictionary *response = BDPProcessJSCallback(mutableDict, method.name, type, jsImpUniqueID);
                        [self callbackInvoke:callbackID data:response type:type trace:trace];
                    } engine:jsImp controller:controller isOnMainThread:isOnMainThread];
                    return;
                }

                // 权限申请失败
                [self monitorEvent:method.name uniqueID:jsImpUniqueID callbackType:BDPMatchCallBackByPermissionResult(result)];
                NSDictionary *response = BDPProcessJSCallback(@{@"errMsg": BDPErrorMessageForStatus(BDPMatchCallBackByPermissionResult(result))}, method.name, BDPMatchCallBackByPermissionResult(result), jsImpUniqueID);
                [self callbackInvoke:callbackID data:response type:BDPMatchCallBackByPermissionResult(result) trace:trace];
            }];
            return;
        }
        // 无权限管理器时或者之前未成功鉴权（没有session），不允许任何 API 调用
        [self monitorEvent:method.name uniqueID:jsImpUniqueID callbackType:BDPJSBridgeCallBackTypeNoAuthorization];
        NSDictionary *response = BDPProcessJSCallback(@{@"errMsg": BDPErrorMessageForStatus(BDPJSBridgeCallBackTypeNoAuthorization)}, method.name, BDPJSBridgeCallBackTypeNoAuthorization, jsImpUniqueID);
        [self callbackInvoke:callbackID data:response type:BDPJSBridgeCallBackTypeNoAuthorization trace:trace];
        return;
    }

    [self invokeMethod:method callback:^(BDPJSBridgeCallBackType type, NSDictionary *args) {
        StrongSelfIfNilReturn;
        [self monitorEvent:method.name uniqueID:jsImpUniqueID callbackType:type];
        NSMutableDictionary *mutableDict = args? [args mutableCopy]: [[NSMutableDictionary alloc] init];
        NSString *appendErrorMsg = [mutableDict stringValueForKey:@"errMsg" defaultValue:@""];
        NSString *errMsg = [NSString stringWithFormat:@"%@ %@", BDPErrorMessageForStatus(type), appendErrorMsg];
        [mutableDict setValue:errMsg forKey:@"errMsg"];
        NSDictionary *response = BDPProcessJSCallback(mutableDict, method.name, type, jsImpUniqueID);
        [self callbackInvoke:callbackID data:response type:type trace:trace];
    } engine:jsImp controller:controller isOnMainThread:isOnMainThread];

}
// 按照 https://bytedance.feishu.cn/docs/doccn0k42BSp3FYqY8KMnvaHFMc 评审要求，去除导致KA问题「最大之错误」的API在网页调用，没有修改任何其他逻辑 这里只是去掉了一个废弃协议名字
- (void)invokeMethod:(BDPJSBridgeMethod *)method callback:(BDPJSBridgeCallback)callback engine:(id<OPJsSDKImplProtocol>)engine controller: (UIViewController *)controller isOnMainThread:(BOOL)isOnMainThread {

    NSURL *monitor_url = [NSURL URLWithString:engine.url];
    NSString *err_msg = [NSString stringWithFormat:@"BDPWebAppEngine invoke api not implemented with url: host = %@ path = %@", monitor_url.host, monitor_url.path];
    OPMonitorEvent *event = BDPMonitorWithNameAndCode(kEventName_op_h5_api_error, OWMonitorCodeApi.fail, nil)
        .setResultTypeFail()
        .setErrorMessage(err_msg)
        .kv(kEventKey_method, method.name)
        .kv(kEventKey_app_id, engine.appId);

    BDPJSBridgeInstancePlugin *plugin = [self getInstancePlugin:method controller:controller];
    // TODO: 此处强转类型需要适配确认
    BDPJSBridgeEngine proxyEngine = (id<BDPEngineProtocol>)self.bdp_weakProxy;
    BDPAppContext *context = [[BDPAppContext alloc] init];
    context.controller = controller;
    context.engine = proxyEngine;
    [self assicateEngine:proxyEngine context:context];

    // 默认先找新实现，在mina里或没有新实现，则用旧实现
    if ([self handledByInternalInvoke:YES method:method callback:callback context:context plugin:plugin isOnMainThread:isOnMainThread shouldCallback:NO]) {
        return;
    }
    if (![self handledByInternalInvoke:NO method:method callback:callback context:context plugin:plugin isOnMainThread:isOnMainThread shouldCallback:YES]) {
        event.flush();
    }
}

// 返回值代表是否被处理
- (BOOL)handledByInternalInvoke: (BOOL)useOPAPI method: (BDPJSBridgeMethod *)method callback:(BDPJSBridgeCallback)callback context:(BDPAppContext *)context plugin:(BDPJSBridgeInstancePlugin *)plugin isOnMainThread:(BOOL)isOnMainThread shouldCallback:(BOOL)shouldCallback
{
    NSString *methodRegex = useOPAPI ? @"WithParam:context:callback:" : @"WithParam:callback:context:";
    NSString *selectorStr = [method.name stringByAppendingString:methodRegex];
    SEL selector = NSSelectorFromString(selectorStr);
    if (![plugin respondsToSelector:selector]) {
        if (callback && shouldCallback) {
            NSDictionary *errDict = @{@"errMsg": @"api not implemented"};
            callback(BDPJSBridgeCallBackTypeFailed, errDict);
        }
        return NO;
    }
    NSMethodSignature *signature = [plugin methodSignatureForSelector:selector];
    if (!signature) {
        if (callback && shouldCallback) {
            NSDictionary *errDict = @{@"errMsg": @"api not implemented"};
            callback(BDPJSBridgeCallBackTypeFailed, errDict);
        }
        return NO;
    }

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = plugin;
    invocation.selector = selector;

    NSDictionary *params = method.params;
    [invocation setArgument:&params atIndex:2];
    if (useOPAPI) {
        [invocation setArgument:&context atIndex:3];
        [invocation setArgument:&callback atIndex:4];
    } else {
        [invocation setArgument:&callback atIndex:3];
        [invocation setArgument:&context atIndex:4];
    }
    if (!isOnMainThread || (isOnMainThread && [NSThread isMainThread])) {
        BDPExecuteTracing(^{
            [invocation invoke];
        });
        return YES;
    }
    [invocation bdp_tracingPerformSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
    return YES;
}

- (BDPJSBridgeInstancePlugin *)getInstancePlugin:(BDPJSBridgeMethod *)method controller:(UIViewController *)controller
{
    // 根据 Engine 类型拼写完整 API 调用名
    // 💡类实例方法全名拼写规则：[方法名].[方法类型]
    NSString *fullName = [NSString stringWithFormat:@"%@.%@", method.name, @(BDPJSBridgeMethodTypeWebApp)];
    
    // 寻找 InstanceMethod 类实例方法
    BDPJSBridgeInstanceClass class = [[BDPJSBridgeCenter defaultCenter] classForFullName:fullName];
    if (![class isSubclassOfClass:[BDPJSBridgeInstancePlugin class]]) {
        return nil;
    }
    
    BDPJSBridgeInstancePlugin *plugin = nil;
    BDPJSBridgePluginMode pluginType = [class pluginMode];
    
    // 插件模式 - 每次使用新实例(默认)
    if (pluginType == BDPJSBridgePluginModeNewInstance) {
        plugin = [[class alloc] init];
        
    // 插件模式 - 全局单例
    } else if (pluginType == BDPJSBridgePluginModeGlobal) {
        plugin = [class sharedPlugin];
    // 插件模式 - 跟随 JavaScriptEngine 生命周期
    } else {
        // 关联引用来保证同一个 JavaScriptEngine 下只有一个 plugin 实例
        NSString *className = NSStringFromClass(class);
        plugin = objc_getAssociatedObject(controller, NSSelectorFromString(className));
        if (!plugin) {
            plugin = [[class alloc] init];
            objc_setAssociatedObject(controller, NSSelectorFromString(className), plugin, OBJC_ASSOCIATION_RETAIN);
        }
    }
    return plugin;
}

- (void)assicateEngine:(id<BDPEngineProtocol>)engine context:(BDPAppContext *)context {
    BDPAppContext *c = objc_getAssociatedObject(engine, _cmd);
    if (!c) {
        objc_setAssociatedObject(engine, _cmd, context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

#pragma mark Web应用的方法
- (NSString *)getSession {
    return self.jsImp.authSession;
}

- (void)dealloc
{
    BDPLogDebug(@"BDPWebAppEngine dealloc");
}

#pragma make 监控埋点
- (void)monitorEvent:(NSString *) method uniqueID:(BDPUniqueID *)uniqueID callbackType:(BDPJSBridgeCallBackType) type
{
    OPMonitorEvent *invoke_error_event = BDPMonitorWithName(kEventName_op_h5_api_error, uniqueID)
                                            .setResultTypeFail()
                                            .kv(kEventKey_method, method);
    switch (type) {
        case BDPJSBridgeCallBackTypeFailed:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.fail).flush();
            break;
        case BDPJSBridgeCallBackTypeUserCancel:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.cancel).flush();
            break;
        case BDPJSBridgeCallBackTypeParamError:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.param_error).flush();
            break;
        case BDPJSBridgeCallBackTypeInvalidScope:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.invalid_scope).flush();
            break;
        case BDPJSBridgeCallBackTypeNoHandler:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.no_handler).flush();
            break;
        case BDPJSBridgeCallBackTypeNoHostHandler:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.no_host_handler).flush();
            break;
        case BDPJSBridgeCallBackTypeNoAuthorization:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.no_authorization).flush();
            break;
        case BDPJSBridgeCallBackTypeNoUserPermission:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.no_user_permission).flush();
            break;
        case BDPJSBridgeCallBackTypeNoSystemPermission:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.no_system_permisson).flush();
            break;
        case BDPJSBridgeCallBackTypeNoPlatformPermission:
            invoke_error_event.setMonitorCode(OWMonitorCodeApi.no_platform_permisson).flush();
            break;
        default:
            break;
    }
}

@end



