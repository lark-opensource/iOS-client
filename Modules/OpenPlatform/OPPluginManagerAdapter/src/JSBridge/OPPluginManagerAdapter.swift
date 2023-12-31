//
//  OPPluginManagerAdapter.swift
//  OPPluginManagerAdapter
//
//  Created by lixiaorui on 2021/2/9.
//

import ECOProbe
import LarkContainer
import LarkDebug
import LarkOpenAPIModel
import LarkOpenPluginManager
import LarkSetting
import OPSDK
import OPFoundation

extension OPAppType {
    var apiBizType: OpenAPIBizType {
        switch self {
        case .block:
            return .block
        case .gadget:
            return .gadget
        case .webApp:
            return .webApp
        case .widget:
            return .widget
        case .thirdNativeApp:
            return .thirdNativeApp
        default:
            return .all
        }
    }
}

// 所有新老版API的兼容处理建议在此类中进行
@objc
public class OPPluginManagerAdapter: NSObject {

    @objc public let invokeInterceptorChain: OpenApiInvokeInterceptorChain
    internal let pluginManager: OpenPluginManager
    private let disablePluginManager: Bool
    
    private var bgKVOToken: NSKeyValueObservation?
    
    private var apiDispatchConfig: [AnyHashable: Any]?
    
    // api extension是否启用
    public let apiExtensionEnable: Bool

    private var isForeground: Bool = true // 初始化的时候肯定在前台
    //⚠️：不要在此OPPluginManagerAdapter类里强持有传入的engine，本adapter为接入PM过渡态，待后期auth拆分后及逻辑层迁移新容器架构后删除
    // TODO: 拆分auth与engine的依赖
    @objc
    public convenience init(
        with engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        type: OPAppType
    ) {
        self.init(with: engine, type: type, bizDomain: .openPlatform)
    }

    public init(
        with engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        type: OPAppType,
        bizDomain: OpenAPIBizDomain = .openPlatform,
        bizScene: String = "",
        developerConfig: (() -> [String: Any]?)? = nil,
        apiRegistrationFilter: ((_ apiName: String, _ conditions: [OpenAPIAccessConfig]) -> Bool)? = nil
    ) {
        self.invokeInterceptorChain = OpenApiInvokeInterceptorChainImp(gadget: engine.uniqueID, developerConfig: developerConfig)
        self.disablePluginManager = EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyGadgetDisablePluginManager)
        self.apiExtensionEnable = FeatureGatingManager.shared.featureGatingValue(with: "openplatform.api.pluginmanager.extension.enable")
        self.pluginManager = OpenPluginManager(bizDomain: bizDomain,
                                               bizType: type.apiBizType,
                                               bizScene: bizScene,
                                               apiRegistrationFilter: apiRegistrationFilter,
                                               asyncAuthorizationChecker: { [weak engine] (event, authCallback) in
            guard let engine = engine else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setErrno(OpenAPICommonErrno.internalError)
                    .setMonitorMessage("engine is nil")
                authCallback(.failure(error: error))
                return
            }
            let method = BDPJSBridgeMethod(name: event, params: nil)
            guard let auth = engine.authorization else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setErrno(OpenAPICommonErrno.internalError)
                    .setMonitorMessage("authorization missing for app \(engine.uniqueID)")
                authCallback(.failure(error: error))
                return
            }
            auth.checkAuthorization(method, engine: engine, completion: { (result) in
                switch result {
                case .enabled:
                    authCallback(.success(data: nil))
                case .systemDisabled:
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.systemAuthDeny)
                        .setErrno(OpenAPICommonErrno.systemAuthDeny)
                        .setMonitorMessage("system auth dedy")
                    authCallback(.failure(error: error))
                case .userDisabled:
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.userAuthDeny)
                        .setErrno(OpenAPICommonErrno.userAuthDeny)
                        .setMonitorMessage("user auth dedy")
                    authCallback(.failure(error: error))
                default:
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setErrno(OpenAPICommonErrno.unknown)
                        .setMonitorMessage("auth failed, status \(result.rawValue)")
                    authCallback(.failure(error: error))
                }
            })
        })
        
        OPBridgeRegisterOpt.updateBridgeRegisterState()
        
        super.init()
        
        if self.apiExtensionEnable {
            // 应用维度extension注册
            // wifi
            self.pluginManager.register(OpenAPIWifiExtension.self) { resolver, context in
                try OpenAPIWifiExtensionAppImpl(extensionResolver: resolver, context: context)
            }
            
            // contact
            self.pluginManager.register(OpenAPIContactExtension.self) { resolver, context in
                try OpenAPIContactExtensionAppImpl(extensionResolver: resolver, context: context)
            }
            
            // monitor report
            self.pluginManager.register(OpenAPIMonitorReportExtension.self) { resolver, context in
                try OpenAPIMonitorReportExtension(extensionResolver: resolver, context: context)
            }
            
            // common
            self.pluginManager.register(OpenAPICommonExtension.self) { _, context in
                OpenAPICommonExtensionAppImpl(gadgetContext: try getGadgetContext(context))
            }
        }
        
        if type == .gadget {
            addEventObserver(engine.uniqueID)
        }
    }
    
    private func addEventObserver(_ id: OPAppUniqueID) {
        /// 这是 wangfei.heart 埋的一个坑
        /// 这个 async 千万别移除，否则出了问题自己写 case study 去
        /// 原因主要是，gadget runtime 初始化是在 BDPTask 的 init 中被触发的
        /// 所以在当前 init 环境的上下文是拿不到 task 的，那么下面监听页面变更的代码就无法进入了
        /// async 一下就可以了，因为 BDPTask init 后会被立即加入到 BDPTaskManager 中
        DispatchQueue.main.async {
            if let common = BDPCommonManager.shared().getCommonWith(id) {
                self.bgKVOToken = common.observe(\.isForeground) { [weak self] object, _ in
                    guard let self = self else { return }
                    if self.isForeground == object.isForeground {
                        // do nothing
                    } else {
                        let isForeground = object.isForeground
                        if isForeground {
                            self.onForeground()
                        } else {
                            self.onBackground()
                        }
                        self.isForeground = isForeground
                    }
                }

            } else {
                assertionFailure("who fucking code cause common nil")
            }

        }
    }
    
    private func onBackground() {
        pluginManager.onBackground()
    }
    
    private func onForeground() {
        pluginManager.onForeground()
    }

    @objc
    public func invokeAPI(
        method: BDPJSBridgeMethod,
        trace: OPTrace,
        engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        contextExtra: [AnyHashable: Any]? = nil,
        source: String? = nil,
        callback: @escaping BDPJSBridgeCallback
    ) {
        invokeAPI(
            method: method,
            trace: trace,
            engine: engine,
            contextExtra:contextExtra,
            source: source,
            isLazyInvoke: false,
            lazyInvokeElapsedDuration: nil,
            callback: callback
        )
    }

    public func invokeAPI(
        method: BDPJSBridgeMethod,
        trace: OPTrace,
        engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        contextExtra: [AnyHashable: Any]? = nil,
        source: String? = nil,
        isLazyInvoke: Bool = false,
        lazyInvokeElapsedDuration: Int64? = nil,
        callback: @escaping BDPJSBridgeCallback
    ) {
        let isSync = isSyncAPI(method: method, engine: engine)

        // PluginSystem上线策略详见：https://bytedance.feishu.cn/docs/doccnxe4b5UBc3AYHeovsAtzKGd
        var apiConfig = OPAPIFeatureConfig(command: "")
        if let apiPlugin = BDPTimorClient.shared().apiPlugin.sharedPlugin() as? BDPAPIPluginDelegate {
            if apiDispatchConfig == nil {
                apiDispatchConfig = apiPlugin.bdp_getAPIDispatchConfig()
            }
            apiConfig = apiPlugin.bdp_getAPIDispatchConfig(apiDispatchConfig, for: engine.uniqueID.appType, apiName: method.name)
        }
        
        let usePlugin = !disablePluginManager && apiConfig.apiCommand != .useOld
        var pmDowngrage = false

        OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_invoke_start)
            .setUniqueID(engine.uniqueID)
            .addMap(["api_name": method.name,
                     "param.keys": method.params?.map({ "\($0.key)" }) ?? [],
                     "usePM": usePlugin,
                     "disablePluginManagerFG": disablePluginManager,
                     "apiCommand": apiConfig.apiCommand.rawValue])
            .addCategoryValue("worker", source)
            .flushTo(trace)

        // 处理API结果：上报 & 回调
        var handleResult: (_ status: BDPJSBridgeCallBackType, _ data: [AnyHashable: Any]?, _ error: OpenAPIError?) -> Void = { [weak self, weak engine] status, data, error in
            guard let self = self else {
                trace.error("handleResult failed! OPPluginAdapter has been destroyed!")
                return
            }
            guard let engine = engine else {
                trace.error("handleResult failed! jsruntime has been destroyed!")
                return
            }
            var response = data ?? [:]
            // 填充对外的msg
            // 错误信息原拼接逻辑：
            // errMsg = "ok"/"fail "/"cancel " + codeMessage + " " + data["errMsg"]
            if let error = error, !pmDowngrage {
                // 新版API Code拼接
                let statusMsg = error.outerMessage ?? error.code.errMsg
                if !statusMsg.isEmpty {
                    response["errMsg"] = "\(statusMsg) \(data?["errMsg"] ?? "")"
                }
                response.merge(error.errnoInfo, uniquingKeysWith: { $1 })
            } else {
                // 老版API Code拼接
                if let codeMessage = BDPErrorMessageForStatus(status), !codeMessage.isEmpty {
                    response["errMsg"] = "\(codeMessage) \(data?["errMsg"] ?? "")"
                }
            }

            /// invoke result
            let nativeInvokeResult = OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_invoke_result)
                .setUniqueID(engine.uniqueID)
                .addCategoryValue("worker", source)
                .addMetricValue("pm_downgrade", pmDowngrage)
                .addMap(["result.keys": response.map { "\($0.key)" }])
            OPAPIReportResult(status, response, nativeInvokeResult.monitorEvent)
            if let innerMsg = error?.monitorMsg {
                nativeInvokeResult.addCategoryValue("innerMsg", innerMsg)
            }
            if let innerCode = error?.innerCode {
                nativeInvokeResult.addMetricValue("innerCode", innerCode)
            }
            nativeInvokeResult.setError(error?.detailError)
            nativeInvokeResult.flushTo(trace)

            callback(status, response)
        }

        // 线上降级为不可用状态，直接返回
        if apiConfig.apiCommand == .doNotUse {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
                .setMonitorMessage("apiCommand is do not use")
            handleResult(.noHandler,  nil,  error)
            return
        }

        // 派发API
        if (usePlugin) {
            // 使用PM派发
            invokeAPIByPluginManager(
                isSync: isSync,
                trace: trace,
                method: method,
                engine: engine,
                extra: contextExtra,
                isLazyInvoke: isLazyInvoke,
                lazyInvokeElapsedDuration: lazyInvokeElapsedDuration
            ) { [weak engine] (response) in
                guard let engine = engine else {
                    trace.error("invokeAPIByPluginManager callback failed! jsruntime has been destroyed!")
                    return
                }
                switch response {
                case let .failure(error: error):
                    if let commonCode = error.code as? OpenAPICommonErrorCode, commonCode == .unable, apiConfig.apiCommand != .removeOld {
                        pmDowngrage = true
                        BDPJSBridgeCenter.invokeMethod(method, engine: engine) { (status, data) in
                            handleResult(status, data,error)
                        }
                        return
                    }
                    let status = error.status
                    // 按需填充对外的errCode
                    var data = error.additionalInfo
                    if data["errCode"] == nil {
                        data["errCode"] = error.outerCode ?? error.code.rawValue
                    }
                    handleResult(status, data,error)
                case let .success(data: data):
                    let res = data?.toJSONDict()
                    handleResult(.success,  res,  nil)
                case .continue(event: _, data: _):
                    assertionFailure("should not enter here")
                    // 目前开放应用continue都是使用fireEvent实现，不应该走到这
                }
            }
        } else {
            BDPJSBridgeCenter.invokeMethod(method, engine: engine) { (status, data) in
                handleResult( status,data, nil)
            }
        }
    }

    private func invokeAPIByPluginManager(
        isSync: Bool,
        trace: OPTrace?,
        method: BDPJSBridgeMethod,
        engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        extra: [AnyHashable: Any]?,
        isLazyInvoke: Bool = false,
        lazyInvokeElapsedDuration: Int64? = nil,
        callback: @escaping OpenAPISimpleCallback
    ) {
        let params = method.params as? [String: Any] ?? [:]
        // 构造context
        let appContext = BDPAppContext()
        appContext.engine = engine

        let appTrace = BDPTracingManager.sharedInstance().getTracingBy(engine.uniqueID)
        let apiTrace = trace ?? OPTraceService.default().generateTrace(withParent: appTrace, bizName: method.name)
        var additionalInfo: [AnyHashable: Any] = ["gadgetContext": GadgetAPIContext(with: appContext)]
        if let extra = extra {
            extra.forEach {
                additionalInfo[$0.key] = $0.value
            }
        }
        let context = OpenAPIContext(trace: apiTrace,
                                     dispatcher: pluginManager,
                                     additionalInfo: additionalInfo,
                                     isLazyInvoke: isLazyInvoke,
                                     lazyInvokeElapsedDuration: lazyInvokeElapsedDuration)
        if isSync {
            let response = pluginManager.syncCall(apiName: method.name, params: params, canUseInternalAPI: false, context: context)
            callback(response)
        } else {
            pluginManager.asyncCall(apiName: method.name, params: params, canUseInternalAPI: false, context: context, callback: callback)
        }
    }

    // 兼容老版实现
    public func isSyncAPI(method: BDPJSBridgeMethod, engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol) -> Bool {
        if let isSync = pluginManager.defaultPluginConfig[method.name]?.isSync {
            return isSync
        } else {
            return BDPJSBridgeCenter.obtainMethodSynchronize(method, engine: engine)
        }
    }

    @available(*, deprecated, message: "Only for webApp, others use invokeAPI")
    public func call(
        method: BDPJSBridgeMethod,
        trace: OPTrace?,
        engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        extra: [AnyHashable: Any]?,
        callback: @escaping BDPJSBridgeCallback
    ) {
        call(pluginManager: pluginManager, method: method, trace: trace, engine: engine, extra: extra, callback: callback)
    }

    @available(*, deprecated, message: "Only for webApp, others use invokeAPI")
    public func call(
        pluginManager: OpenPluginManager,
        method: BDPJSBridgeMethod,
        trace: OPTrace?,
        engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        callback: @escaping BDPJSBridgeCallback
    ) {
        call(pluginManager: pluginManager, method: method, trace: trace, engine: engine, extra: nil, callback: callback)
    }

    public func call(
        pluginManager: OpenPluginManager,
        method: BDPJSBridgeMethod,
        trace: OPTrace?,
        engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        extra: [AnyHashable: Any]?,
        callback: @escaping BDPJSBridgeCallback
    ) {
        var pmResult: OPMonitor? = nil
        if trace != nil {
            OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_pm_invoke_start)
                .addMap(["api_name": method.name,
                         "param.keys": method.params?.map({ "\($0.key)" }) ?? []])
                .flushTo(trace!)

            pmResult = OPMonitor(name: kEventName_op_api_invoke,
                                 code: APIMonitorCodeCommon.native_pm_invoke_result)
        }

        let appContext = BDPAppContext()
        appContext.engine = engine
        appContext.controller = engine.bridgeController
        let appTrace = BDPTracingManager.sharedInstance().getTracingBy(engine.uniqueID)
        let apiTrace = trace ?? OPTraceService.default().generateTrace(withParent: appTrace, bizName: method.name)
        var additionalInfo: [AnyHashable: Any] = ["gadgetContext": GadgetAPIContext(with: appContext)]
        if let extra = extra {
            extra.forEach {
                additionalInfo[$0.key] = $0.value
            }
        }
        let context = OpenAPIContext(trace: apiTrace,
                                     dispatcher: pluginManager,
                                     additionalInfo: additionalInfo)

        pluginManager.asyncCall(
            apiName: method.name,
            params: method.params as? [String: Any] ?? [:],
            canUseInternalAPI: false,
            context: context
        ) { [weak self] (response) in
            switch response {
            case let .failure(error: error):
                pmResult?.setResultTypeFail()

                let status = error.status
                // 填充对外的errCode和errMsg
                var data = error.additionalInfo
                if status != .noHandler,
                   case let statusMsg = error.outerMessage ?? error.code.errMsg,
                   !statusMsg.isEmpty {
                    data["errMsg"] = "\(statusMsg) \(data["errMsg"] ?? "")"
                }
                if data["errCode"] == nil {
                    data["errCode"] = error.outerCode ?? error.code.rawValue
                }
                data.merge(error.errnoInfo, uniquingKeysWith: {$1})

                if let pmResult = pmResult, let trace = trace {
                    pmResult.setError(error.detailError)
                    OPAPIReportResult(status, data, pmResult.monitorEvent)
                    pmResult.flushTo(trace)
                }

                callback(status, data)
            case let .success(data: result):
                let res = result?.toJSONDict() ?? [:]
                if let pmResult = pmResult, let trace = trace {
                    pmResult.setResultTypeSuccess().addMap(["result.keys":res.map({ "\($0.key)" })]).flushTo(trace)
                }
                callback(.success, res)
            case .continue(event: _, data: _):
                assertionFailure("should not enter here")
                // 目前开放应用continue都是使用fireEvent实现，不应该走到这
            }
        }
    }

    public func postEvent(
        eventName: String,
        trace: OPTrace?,
        engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        extra: [AnyHashable: Any]?
    ) {
        do {
            let params = try OpenAPIBaseParams(with: [:])
            postEvent(eventName: eventName, params: params, trace: trace, engine: engine, extra: extra)
        } catch {
            trace?.error("post event failed", additionalData: ["eventName": eventName], error: error)
        }
    }

    // 派发多播消息
    public func postEvent<Param>(
        eventName: String,
        params: Param,
        trace: OPTrace?,
        engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        extra: [AnyHashable: Any]?
    ) where Param: OpenAPIBaseParams {
        let appContext = BDPAppContext()
        appContext.engine = engine
        appContext.controller = engine.bridgeController
        let appTrace = BDPTracingManager.sharedInstance().getTracingBy(engine.uniqueID)
        let apiTrace = trace ?? OPTraceService.default().generateTrace(withParent: appTrace, bizName: eventName)
        var additionalInfo: [AnyHashable: Any] = ["gadgetContext": GadgetAPIContext(with: appContext)]
        if let extra = extra {
            extra.forEach {
                additionalInfo[$0.key] = $0.value
            }
        }
        let context = OpenAPIContext(trace: apiTrace,
                                     dispatcher: pluginManager,
                                     additionalInfo: additionalInfo)
        /// callback 外部目前没有依赖，都是用的默认值，先收敛进来，有需要再开放
        pluginManager.postEvent(eventName: eventName, params: params, context: context, callback: { _ in })
    }
}

extension OPPluginManagerAdapter {
    public func register<Service>(
        _ serviceType: Service.Type,
        factory: @escaping (ExtensionResolver, OpenAPIContext) throws -> Service
    ) {
        pluginManager.register(serviceType, factory: factory)
    }
}

extension OpenAPIError {
    var status: BDPJSBridgeCallBackType {
        if let commonCode = self.code as? OpenAPICommonErrorCode {
            switch commonCode {
            case .unable:
                return .noHandler
            case .systemAuthDeny:
                return .noSystemPermission
            case .userAuthDeny:
                return .noUserPermission
            case .invalidParam:
                return .paramError
            default:
                return .failed
            }
        }
        return .failed
    }
}

let getGadgetContext: (OpenAPIContext) throws -> GadgetAPIContext = { context in
    guard let gadgetContext = context.gadgetContext as? GadgetAPIContext else {
        throw OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage("gadgetContext is nil")
            .setErrno(OpenAPICommonErrno.unknown)
    }
    return gadgetContext
}
