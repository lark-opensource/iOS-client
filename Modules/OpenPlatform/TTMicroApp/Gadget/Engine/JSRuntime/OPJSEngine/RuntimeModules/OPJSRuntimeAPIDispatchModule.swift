//
//  OPJSRuntimeAPIDispatchModule.swift
//  TTMicroApp
//
//  Created by yi on 2021/11/29.
//
// api分发的module
import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import LKCommonsLogging
import JavaScriptCore
import OPJSEngine
import ECOInfra
import OPFoundation
import LarkSetting
import OPPluginManagerAdapter

public final class OPJSRuntimeAPIDispatchModule: NSObject, OPJSRuntimeAPIDispatchModuleProtocol {
    static let logger = Logger.log(OPJSRuntimeAPIDispatchModule.self, category: "OPJSEngine")

    @objc public var pluginManager: OPPluginManagerAdapter? // jsitodo 要避免暴露
    var uniqueID: OPAppUniqueID?
    weak public var jsRuntime: GeneralJSRuntime?
    // api callback 支持arraybuffer类型
    let bridgeCallbackArrayBufferFg = EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyBridgeCallbackArrayBuffer)
    
    // App回前台时api dispatch在子线程派发
    private let foregroundAPIDispatchFix =  FeatureGatingManager.shared.featureGatingValue(with: "openplatform.runtime.return.foreground.dispatch.fix")
    
    private let apiBackgroundReport: OPJSRuntimeBackgroundAPIReport?
    
    public override init() {
        self.apiBackgroundReport = !FeatureGatingManager.shared.featureGatingValue(with: "openplatform.api_background_report.disable")
        ? OPJSRuntimeBackgroundAPIReport() : nil
        super.init()
        
    }

    public func runtimeLoad() {

    }
    public func runtimeReady()
    {
        guard let engine = jsRuntime else {
            Self.logger.error("runtimeReady fail, jsRuntime is nil")
            return
        }
        uniqueID = engine.uniqueID
        guard let uniqueID = uniqueID else {
            Self.logger.error("runtimeReady fail, uniqueID is nil")
            return
        }
        
        if let settingsWhiteList = Self.apiBackgroundWhiteList(appID: uniqueID.appID) {
            lazyInvokeWhiteList.formUnion(settingsWhiteList)
        }

        let developerConfig: () -> [String: Any]? = {
            BDPTaskManager.shared().getTaskWith(uniqueID)?.config?.apiConfig
        }
        if engine.isSeperateWorker {
            let pluginManager = OPPluginManagerAdapter(with: engine, type: uniqueID.appType, bizDomain: .comment, developerConfig: developerConfig)
            pluginManager.seperateWorkerRegisterPoint()
            self.pluginManager = pluginManager
        } else {
            let pluginManager = OPPluginManagerAdapter(with: engine, type: uniqueID.appType, bizDomain: .openPlatform, developerConfig: developerConfig)
            pluginManager.gadgetRegisterPoint()
            self.pluginManager = pluginManager
        }
        
    }

    public weak var rootWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)? // 根worker // jsitodo 需要把rootWorker的内容放到GeneralJSRuntime上
    public var workerName: String = "" // worker name


    func invokeMethod(
        method: BDPJSBridgeMethod,
        isSyncMethod: Bool,
        trace: OPTrace,
        isLazyInvoke: Bool = false,
        lazyInvokeElapsedDuration: Int64? = nil,
        callback: @escaping BDPJSBridgeCallback
    ) {
        guard let pluginManager = pluginManager else {
            Self.logger.error("worker invokeMethod fail, pluginManager is nil")
            return
        }

        var engine: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)? = jsRuntime
        var additionalInfo: [AnyHashable: Any]?
        if let isSeperateWorker = jsRuntime?.isSeperateWorker, isSeperateWorker {
            if let rootWorker = rootWorker {
                let appContext = BDPAppContext()
                appContext.engine = rootWorker
                appContext.controller = rootWorker.bridgeController
                appContext.workerEngine = engine
                let gadgetContext = GadgetAPIContext(with: appContext)
                additionalInfo = ["gadgetContext": gadgetContext]
            } else {
                Self.logger.error("worker invokeMethod fail, rootWorker is nil")
            }
        } else {
            engine = jsRuntime?.delegate as? BDPEngineProtocol & BDPJSBridgeEngineProtocol
        }

        guard let engine = engine else {
            return
        }
        pluginManager.invokeAPI(
            method: method,
            trace: trace,
            engine: engine,
            contextExtra: additionalInfo,
            source: workerName,
            isLazyInvoke: isLazyInvoke,
            lazyInvokeElapsedDuration: lazyInvokeElapsedDuration,
            callback: { status, response in
                callback(status, response)
            }
        )
    }


    // invoke
    @objc public func invoke(event: String, param: [AnyHashable: Any]?, callbackID: String?, extra: [AnyHashable: Any]?) -> Any? {
        return invoke(event: event, param: param, callbackID: callbackID, extra: extra, isNewBridge: true)
    }

    @objc public func invoke(event: String, param: [AnyHashable: Any]?, callbackID: String?, extra: [AnyHashable: Any]?, isNewBridge: Bool) -> Any? {
        guard let uniqueID = uniqueID else {
            Self.logger.error("worker invoke fail, uniqueID is nil")
            return nil
        }
        guard let engine = jsRuntime else {
            Self.logger.error("worker invoke fail, jsRuntime is nil")
            return nil
        }
        // 拦截器 用于在需要的时候修改 event 和 param
        let method = BDPJSBridgeMethod(name: event, params: param)
        do {
            try pluginManager?.invokeInterceptorChain.preInvoke(method: method, extra: nil)
        } catch {
             Self.logger.error("invokeInterceptorChain preInvoke method.name \(method.name) error: \(error)")
        }
        let event = method.name
        let param = method.params
        
        let isSyncMethod = pluginManager?.isSyncAPI(method: method, engine: engine) ?? false
        let subMethod = (param?["header"] as? [AnyHashable: Any])?["service"] as? String // rn通道biz.comment.postMessage子消息

        let jsBridgeReceiveTime = Date().timeIntervalSince1970
        var syncResponse: [AnyHashable: Any]? = nil

        Self.logger.warn("invoke start, event=\(event) app=\(uniqueID) callbackID=\(callbackID) param.length=\(param?.count)")

        // trace
        self.jsRuntime?.delegate?.bindCurrentThreadTracingFromUniqueID?()
        let appTracing = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        var apiTrace = OPTraceService.default().generateTrace(withParent: appTracing, bizName: event)
        var traceDowngrade = false
        var useJSTrace = false
        if let shouldUseNewBridge = OPJSEngineService.shared.utils?.shouldUseNewBridge(), shouldUseNewBridge {
            if let traceString = extra?["api_trace"] as? String, !traceString.isEmpty {
                apiTrace = OPTraceService.default().generateTrace(withTraceID: traceString, bizName: event)
                useJSTrace = true
            } else {
                traceDowngrade = true
            }
        }

        // native 收到js 调用 10002
        OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_receive_invoke)
            .addCategoryMap([
                "api_name" : event,
                "worker" : workerName,
                "app_type" : "gadget",
                "callbackID" : callbackID,
                "param.length": param?.count,
                "sub_method" : subMethod,
                "isNewBridge" : isNewBridge,
                "trace_downgrade" : traceDowngrade,
                "use_js_trace" : useJSTrace,
                "js_engine_type" : self.jsRuntime?.runtimeType.rawValue,
            ])
            .setUniqueID(uniqueID).tracing(appTracing)
            .flushTo(apiTrace)

        // native回调js 10003
        let callbackInvokeMonitor = self.makeCallbackInvokeMonitor(appTracing: appTracing, isSyncMethod: isSyncMethod, subMethod: subMethod)

        if !queueEnableAcceptAsyncCall() {
            callbackInvokeMonitor.setResultTypeFail().addCategoryValue("innerMsg", "disableAcceptAsyncCall, jsruntime is destoryed")
            callbackInvokeMonitor.flushTo(apiTrace)
            apiTrace.finish()
            Self.logger.warn("disableAcceptAsyncCall, id=\(uniqueID)")
            return nil
        }

        let callEventStartTimestamp = Date().timeIntervalSince1970 * 1000
        callEvent(event: event, isSync: isSyncMethod, appTracing: appTracing, apiTrace: apiTrace) { [weak self] (lazyInvoke) in
            guard let `self` = self else {
                Self.logger.error("worker invoke fail, callEvent, self is nil")
                return
            }

            if lazyInvoke {
                OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_invoke_back_foreground)
                    .setUniqueID(self.uniqueID)
                    .addCategoryValue("api_name", event)
                    .tracing(appTracing)
                    .flushTo(apiTrace)
            }

            let callEventEndTimestamp = Date().timeIntervalSince1970 * 1000
            let lazyInvokeElapsedDuration: Int64? = lazyInvoke ? Int64(callEventEndTimestamp - callEventStartTimestamp) : nil
            
            BDPAPIInterruptionManager.shared().beginInvokeEvent(event, uniqueID: uniqueID)
            self.invokeMethod(
                method: method,
                isSyncMethod: isSyncMethod,
                trace: apiTrace,
                isLazyInvoke: lazyInvoke,
                lazyInvokeElapsedDuration: lazyInvokeElapsedDuration
            ) { [weak self] (status, response) in
                guard let `self` = self else {
                    Self.logger.error("worker invoke fail, invokeMethod, self is nil")
                    return
                }
                if !self.queueEnableAcceptAsyncCall() {
                    callbackInvokeMonitor.setResultTypeFail().addCategoryValue("innerMsg", "disableAcceptAsyncCall, jsruntime is destoryed")
                    callbackInvokeMonitor.flushTo(apiTrace)
                    apiTrace.finish()
                    return
                }

                // 处理response
                var handleResponse = BDPProcessJSCallback(response, event, status, self.uniqueID)
                if let encodeResponse = handleResponse as? NSDictionary {
                    if !self.bridgeCallbackArrayBufferFg || !isNewBridge { // 旧bridge 或者没开fg 依然使用base64
                        handleResponse = encodeResponse.encodeNativeBuffersIfNeed()
                    }
                }

                if isSyncMethod {
                    OPAPIReportResult(status, handleResponse, callbackInvokeMonitor.monitorEvent)
                    callbackInvokeMonitor.flushTo(apiTrace)
                    apiTrace.finish()

                    syncResponse = handleResponse
                } else {
                    // 执行callback js
                    self.callbackInvoke(callbackID: callbackID, status: status, data: handleResponse, trace: apiTrace, isNewBridge: isNewBridge, method: method)
                }
                BDPAPIInterruptionManager.shared().completeInvokeEvent(event, uniqueID: uniqueID)

                let duration = (Date().timeIntervalSince1970 - jsBridgeReceiveTime) * 1000
                if status != .success {
                    Self.logger.warn("invoke finish error, event=\(event) callbackID=\(callbackID) status=\(status) duration=\(duration) param.length=\(param?.count) bridgeCallbackArrayBufferFg=\(self.bridgeCallbackArrayBufferFg)")
                } else {
                    Self.logger.info("invoke finish success, event=\(event) callbackID=\(callbackID) duration=\(duration) bridgeCallbackArrayBufferFg=\(self.bridgeCallbackArrayBufferFg)")
                }
            }
        }
        if isNewBridge {
            if self.bridgeCallbackArrayBufferFg,
                (self.jsRuntime?.runtimeType == .jscore) {
                if let jsContext = self.jsRuntime?.jsvmModule.jsContext as? JSContext { //开启fg 使用jsvalue传递arraybuffer类型
                    if let dataDict = syncResponse as? NSDictionary {
                        let dataParam = dataDict.bdp_jsvalue(in: jsContext)
                        return dataParam
                    } else {
                        return nil
                    }
                }
            }
            // vmsdk 场景下直接返回 Dictionary，内部会做 Data -> ArrayBuffer 的转换
            return syncResponse
        }
        if let syncResponse = syncResponse as? NSDictionary {
            return syncResponse.jsonRepresentation()
        }
        return nil
    }


    // call 旧的js->native的通道，现已全部到invoke，只有小程序worker有这个通道
    public func call(event: String, param: [AnyHashable: Any]?, callbackID: NSNumber?) -> NSDictionary? {
        // 与统一webview & bridge沟通，确认新版bridge中不会再有call的调用，所以call只处理旧版未加入jssdk埋点的逻辑（相当于useNewBridge = false）

        guard let uniqueID = uniqueID else {
            Self.logger.error("worker call fail, uniqueID is nil")
            return nil
        }
        guard let engine = jsRuntime as? GeneralJSRuntime else {
            Self.logger.error("worker call fail, jsRuntime is nil")
            return nil
        }

        // 拦截器 用于在需要的时候修改 event 和 param
        let method = BDPJSBridgeMethod(name: event, params: param)
        do {
            try pluginManager?.invokeInterceptorChain.preInvoke(method: method, extra: nil)
        } catch {
             Self.logger.error("invokeInterceptorChain preInvoke method.name \(method.name) error: \(error)")
        }
        let event = method.name
        let param = method.params
        
        let isSyncMethod = pluginManager?.isSyncAPI(method: method, engine: engine) ?? false
        let subMethod = (param?["header"] as? [AnyHashable: Any])?["service"] as? String // rn通道biz.comment.postMessage子消息
        var syncResponse: NSDictionary? = nil

        // trace
        self.jsRuntime?.delegate?.bindCurrentThreadTracingFromUniqueID?()
        let appTracing = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        var apiTrace = OPTraceService.default().generateTrace(withParent: appTracing, bizName: event)

        // native 收到js 调用 10002
        OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_receive_invoke)
            .addCategoryValue("api_name", event)
            .addCategoryValue("callbackID", callbackID)
            .addCategoryValue("js_engine_type", self.jsRuntime?.runtimeType.rawValue)
            .setUniqueID(uniqueID).tracing(appTracing)
            .flushTo(apiTrace)

        // native回调js 10003
        let callbackInvokeMonitor = self.makeCallbackInvokeMonitor(appTracing: appTracing, isSyncMethod: isSyncMethod, subMethod: subMethod)

        // 销毁后不再支持API调用
        if !self.queueEnableAcceptAsyncCall() {
            callbackInvokeMonitor.setResultTypeFail().addCategoryValue("innerMsg", "disableAcceptAsyncCall, jsruntime is destoryed")
            callbackInvokeMonitor.flushTo(apiTrace)
            apiTrace.finish()
            return nil
        }
        Self.logger.info("call start event=\(event), app=\(uniqueID), callbackID=\(callbackID)")
        callEvent(event: event, isSync: isSyncMethod, appTracing: appTracing, apiTrace: apiTrace) { [weak self] (lazyInvoke) in
            guard let `self` = self else {
                Self.logger.error("worker call fail, callEvent, self is nil")
                return
            }

            if lazyInvoke {
                OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_invoke_back_foreground)
                    .setUniqueID(self.uniqueID)
                    .addCategoryValue("api_name", event)
                    .tracing(appTracing)
                    .flushTo(apiTrace)
            }

            self.invokeMethod(method: method, isSyncMethod: isSyncMethod, trace: apiTrace) { [weak self] (status, response) in
                guard let `self` = self else {
                    Self.logger.error("worker call fail, invokeMethod, self is nil")
                    return
                }
                if !self.queueEnableAcceptAsyncCall() {
                    callbackInvokeMonitor.setResultTypeFail().addCategoryValue("innerMsg", "disableAcceptAsyncCall, jsruntime is destoryed")
                    callbackInvokeMonitor.flushTo(apiTrace)
                    apiTrace.finish()
                    return
                }

                // 处理response
                let handleResponse = BDPProcessJSCallback(response, event, status, self.uniqueID)

                if isSyncMethod {
                    OPAPIReportResult(status, handleResponse, callbackInvokeMonitor.monitorEvent)
                    callbackInvokeMonitor.flushTo(apiTrace)
                    apiTrace.finish()

                    syncResponse = handleResponse as? NSDictionary
                } else {
                    // 执行callback js
                    self.callbackCall(callbackID: callbackID, status: status, data: handleResponse, trace: apiTrace, method:method)
                }
                if status != .success {
                    Self.logger.warn("call finish error, event=\(event) callbackID=\(callbackID) status=\(status) param.length=\(param?.count)")
                } else {
                    Self.logger.info("call finish success, event=\(event) callbackID=\(callbackID)")
                }
            }
        }
        return syncResponse
    }

    func callbackInvoke(callbackID: String?, status: BDPJSBridgeCallBackType, data: [AnyHashable: Any]?, trace: OPTrace, isNewBridge: Bool, method: BDPJSBridgeMethod) {
        guard let uniqueID = uniqueID else {
            Self.logger.error("worker callbackInvoke fail, uniqueID is nil")
            return
        }

        guard let engine = jsRuntime else {
            Self.logger.error("worker callbackInvoke fail, jsRuntime is nil")
            return
        }

        let appTracing = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        let apiTrace = trace
        let subMethod = (method.params?["header"] as? [AnyHashable: Any])?["service"] as? String // rn通道biz.comment.postMessage子消息

        let callbackInvokeMonitor = self.makeCallbackInvokeMonitor(appTracing: appTracing, isSyncMethod: false, subMethod: subMethod)
        OPAPIReportResult(status, data, callbackInvokeMonitor.monitorEvent)

        guard let callbackID = callbackID else {
            Self.logger.error("callbackID is nil")
            callbackInvokeMonitor.setResultTypeFail().addCategoryValue("innerMsg", "invalid callbackId")
            callbackInvokeMonitor.flushTo(apiTrace)
            apiTrace.finish()
            return
        }
        guard let dispatchQueue = self.jsRuntime?.dispatchQueue else {
            return
        }

        dispatchQueue.dispatchASync { [weak self, weak engine] in
            guard let `self` = self else {
                Self.logger.error("callbackInvoke fail, self is nil")
                return
            }
            guard let engine = engine else {
                Self.logger.error("callbackInvoke fail, runtime has been destroyed!")
                return
            }
            if engine.isSocketDebug {
                // 处理socket debug
                if self.queueEnableAcceptAsyncCall() {
                    let dataDict = data as? NSDictionary
                    let dataValue = dataDict?.jsonRepresentation()
                    engine.socketDebugModule.sendMessage(name: "invokeHandler", event: nil, callbackId: Int(callbackID) as? NSNumber, data: dataValue)
                }
            } else {
                if self.queueEnableAcceptAsyncCall() {
                    callbackInvokeMonitor.addCategoryValue("callbackId", callbackID)
                    callbackInvokeMonitor.flushTo(apiTrace)
                    apiTrace.finish()

                    if isNewBridge {
                        // 新bridge调用
                        if self.bridgeCallbackArrayBufferFg {
                            if let jsRuntime = self.jsRuntime {
                                jsRuntime.invokeNativeCallback(callbackID: callbackID, callbackType: self.BDPJSBridgeCallBackTypeToCallBackType(status).rawValue, data: data, extra: nil)
                            } else {
                                Self.logger.error("worker callbackInvoke fail, jsRuntime is nil, when call js module")
                            }
                        } else {
                            if let js = self.callbackStr(callbackID: callbackID, params: data, type: status, extra: nil) {
                                engine.jsvmModule.evaluateScript(js)
                            } else {
                                Self.logger.error("jsworker js script is nil")
                            }
                        }
                    } else {
                        // 旧bridge调用
                        if(self.jsRuntime?.runtimeType.isVMSDK() ?? false) {
                            let callbackIDNumber = NSNumber(value: (callbackID as NSString).intValue)
                            let dataDict: NSDictionary = (data as? NSDictionary) ?? [:]
                            self.jsRuntime?.invokeJavaScriptModule(methodName: "invokeHandler", moduleName: "ttJSBridge", params: [callbackIDNumber, dataDict])
                        } else if let jsContext = self.jsRuntime?.jsvmModule.jsContext as? JSContext, let invokeHandler = jsContext.objectForKeyedSubscript("ttJSBridge").objectForKeyedSubscript("invokeHandler") {
                            let callbackIDNumber = NSNumber(value: (callbackID as NSString).intValue)
                            let dataDict: NSDictionary = (data as? NSDictionary) ?? [:]
                            invokeHandler.call(withArguments: [callbackIDNumber, dataDict])
                        }
                    }
                } else {
                    callbackInvokeMonitor.setResultTypeFail().addCategoryValue("callbackId", callbackID).addCategoryValue("innerMsg", "disableAcceptAsyncCall, jsruntime is destoryed")
                    callbackInvokeMonitor.flushTo(apiTrace)
                    apiTrace.finish()
                    Self.logger.warn("disableAcceptAsyncCall, id=\(uniqueID)")
                }
            }
        }
    }

    func callbackStr(
        callbackID: String?,
        params: [AnyHashable: Any]?,
        type: BDPJSBridgeCallBackType,
        extra: [AnyHashable: Any]?) -> String? {
        var str: String?
        do {
            str = try LarkWebViewBridge.buildCallBackJavaScriptString(callbackID: callbackID, params: params ?? [AnyHashable: Any](), extra: extra, type: BDPJSBridgeCallBackTypeToCallBackType(type))
        } catch {
            Self.logger.error("build callback js str error", error: error)
        }
        return str
    }


    func BDPJSBridgeCallBackTypeToCallBackType(_ type: BDPJSBridgeCallBackType) -> LarkWebViewContainer.CallBackType {
        switch type {
        //  新协议只有这三种
        case .success:
            return .success
        case .failed:
            return .failure
        case .userCancel:
            return .cancel
        case .continued:
            return .continued
        //  原先的其他情况收敛为 failure
        default:
            return .failure
        }
    }

    func callbackCall(callbackID: NSNumber?, status: BDPJSBridgeCallBackType, data: [AnyHashable: Any]?, trace: OPTrace, method: BDPJSBridgeMethod) {
        guard let uniqueID = uniqueID else {
            Self.logger.error("worker callbackCall fail, uniqueID is nil")
            return
        }
        guard let engine = jsRuntime else {
            Self.logger.error("worker callbackCall fail, jsRuntime is nil")
            return
        }

        let appTracing = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        let apiTrace = trace
        let callbackInvokeMonitor = OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_callback_invoke)
            .setUniqueID(uniqueID).tracing(appTracing)
            .addCategoryValue("app_type", "gadget")
            .addCategoryValue("worker", workerName)
            .addCategoryValue("isSyncMethod", false)
            .addCategoryValue("js_engine_type", self.jsRuntime?.runtimeType.rawValue)

        OPAPIReportResult(status, data, callbackInvokeMonitor.monitorEvent)

        guard let callbackID = callbackID else {
            callbackInvokeMonitor.setResultTypeFail().addCategoryValue("innerMsg", "invalid callbackId")
            callbackInvokeMonitor.flushTo(apiTrace)
            apiTrace.finish()
            return
        }
        guard let dispatchQueue = engine.dispatchQueue else {
            Self.logger.error("worker callbackCall fail, dispatchQueue is nil")
            return
        }

        dispatchQueue.dispatchASync { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.queueEnableAcceptAsyncCall() {

                if engine.isSocketDebug {
                    // socket debug
                    let dataDict = data as? NSDictionary
                    let dataValue = dataDict?.jsonRepresentation()
                    engine.socketDebugModule.sendMessage(name: "callHandler", event: nil, callbackId: callbackID, data: dataValue)
                } else {
                    // 执行callback js
                    if(self.jsRuntime?.runtimeType.isVMSDK() ?? false) {
                        var params: [Any] = [callbackID]
                        if(data != nil) {
                            params.append(data)
                        } else {
                            params.append([:])
                        }
                        engine.jsvmModule.invokeJavaScriptModule(methodName: "callHandler", moduleName: "ttJSBridge", params: params)
                    } else if let jsContext = engine.jsvmModule.jsContext,
                                let invokeHandler = jsContext.objectForKeyedSubscript("ttJSBridge").objectForKeyedSubscript("callHandler") {
                        if let dataDict = (data ?? [:]) as? NSDictionary {
                            let dataParam = dataDict.bdp_jsvalue(in: jsContext)
                            invokeHandler.call(withArguments: [callbackID, dataParam])
                        }
                    }
                    callbackInvokeMonitor.addCategoryValue("callbackId", callbackID)
                    callbackInvokeMonitor.flushTo(apiTrace)
                    apiTrace.finish()
                }
            } else {
                callbackInvokeMonitor.setResultTypeFail().addCategoryValue("callbackId", callbackID).addCategoryValue("innerMsg", "disableAcceptAsyncCall, jsruntime is destoryed")
                callbackInvokeMonitor.flushTo(apiTrace)
                apiTrace.finish()
                Self.logger.warn("disableAcceptAsyncCall, id=\(uniqueID)")

            }
        }
    }

    func queueEnableAcceptAsyncCall() -> Bool {
        var enableAcceptAsyncCall = false
        if let enableAsync = self.jsRuntime?.dispatchQueue?.enableAcceptAsyncCall {
            enableAcceptAsyncCall = enableAsync
        }
        return enableAcceptAsyncCall
    }


    @objc public func handleInvokeInterruption(stop: Bool) {
        shouldInterruptionInvoke = stop
        if !stop {
            resumeStageInvokes()
        } else {
            apiBackgroundReport?.enterBackground()
        }
    }
    
    @objc public func enableForegroundAPIDispatchFix() -> Bool {
        return foregroundAPIDispatchFix
    }

    lazy var lazyInvokeQueue: BDPSTLQueue = { return BDPSTLQueue() }()

    var lazyInvokeWhiteList: Set<String> = [
        "operateVideoContext",
        "setScreenBrightness",
        "operateBgAudio",
        "setBgAudioState",
        "getBgAudioState",
        "createRequestTask",
        "createDownloadTask",
        "createUploadTask",
        "createSocketTask",
        "systemLog",
        "monitorReport",
        "reportTimelinePoints",
        "nfcStopDiscovery",
        "nfcConnect",
        "nfcClose",
        "nfcTransceive",
        "sendDebugPerformanceData"]

    private var _shouldInterruptionInvoke: Bool = false

    var shouldInterruptionInvoke: Bool {
        get {
            var interruption: Bool = false
            objc_sync_enter(self)
            interruption = _shouldInterruptionInvoke
            objc_sync_exit(self)
            return interruption
        }
        set {
            objc_sync_enter(self)
            _shouldInterruptionInvoke = newValue
            objc_sync_exit(self)
        }
    }

    func callEvent(event: String, isSync: Bool, appTracing: OPTraceProtocol?, apiTrace: OPMonitorServiceProtocol, invokeBlk: ((Bool) -> Void)? = nil) {
        if let blk = invokeBlk {
            let whiteListEvent = lazyInvokeWhiteList.contains(event)
            if shouldInterruptionInvoke, !isSync, !whiteListEvent {
                OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_invoke_enter_background)
                    .setUniqueID(uniqueID)
                    .addCategoryValue("api_name", event)
                    .tracing(appTracing)
                    .flushTo(apiTrace)
                lazyInvokeQueue.enqueue(blk)
                apiBackgroundReport?.push(apiName: event)
            } else {
                blk(false)
            }
        } else {
            Self.logger.warn("callEvent fail, no callback, event=\(event)")
        }
    }


    func resumeStageInvokes() {
        apiBackgroundReport?.enterForeground(uniqueID: uniqueID)
        guard foregroundAPIDispatchFix,
                let dispatchQueue = jsRuntime?.dispatchQueue else {
            __resumeStageInvokes()
            return
        }
        dispatchQueue.dispatchASync { [weak self] in
            self?.__resumeStageInvokes()
        }
    }
    
    @inline(__always)
    private func __resumeStageInvokes() {
        while let blk = lazyInvokeQueue.dequeue() as? ((Bool) -> Void) {
            blk(true)
        }
    }
    
    private func makeCallbackInvokeMonitor(
        appTracing: OPTraceProtocol?,
        isSyncMethod: Bool,
        subMethod: String?
    ) -> OPMonitor {
        return OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_callback_invoke)
            .setUniqueID(uniqueID)
            .tracing(appTracing)
            .addCategoryMap([
                "app_type": "gadget",
                "worker": workerName,
                "isSyncMethod": isSyncMethod,
                "sub_method": subMethod,
                "js_engine_type": self.jsRuntime?.runtimeType.rawValue,
            ])
    }
}
