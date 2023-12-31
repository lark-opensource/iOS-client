//
//  GeneralJSRuntime.swift
//  TTMicroApp
//
//  Created by yi on 2021/11/29.
//
/*
 通用JS runtime，通过加载不同runtime module来构造不同的JS runtime
 */

import Foundation
import OPSDK
import LKCommonsLogging
import LarkOpenAPIModel
import LarkOpenPluginManager
import JavaScriptCore
import UIKit
import LarkJSEngine
import ECOInfra
import OPFoundation
import LarkSetting

public final class GeneralJSRuntime: NSObject, BDPJSBridgeEngineProtocol, BDPEngineProtocol {
    static let logger = Logger.log(GeneralJSRuntime.self, category: "OPJSEngine")

    @objc public var runtimeType: OPRuntimeType = .jscore
    
    @objc public init(with runtimeType: OPRuntimeType, apiDispatcherModule: OPJSRuntimeAPIDispatchModuleProtocol) {
        self.runtimeType = runtimeType
        self.jsvmModule = OPJSVMModule(with: runtimeType)
        self.apiDispatcherModule = apiDispatcherModule
        super.init()

    }

    @objc public weak var delegate: GeneralJSRuntimeDelegate?

//    MARK: - GeneralJSRuntimeModuleProtocol
    @objc public func runtimeReady()
    {
        apiDispatcherModule.jsRuntime = self
        apiDispatcherModule.runtimeReady()
        setupObserver()
    }

    //    MARK: - jsvm

    @objc public func setjsvmName(name: String) {
        jsvmModule.setjsvmName(name: name)
    }

    @objc public func setObject(_ object: Any, forKeyedSubscript key: (NSCopying & NSObjectProtocol)) {
        jsvmModule.setObject(object, forKeyedSubscript: key)
    }
    @objc public func evaluateScript(_ script: String,
                        withSourceURL sourceURL: URL) -> Void {
        jsvmModule.evaluateScript(script, withSourceURL: sourceURL)
    }

    @objc public func evaluateScript(_ script: String) -> Void {
        jsvmModule.evaluateScript(script)
    }
    
    @objc public func invokeJavaScriptModule(methodName: String, moduleName: String?, params: [Any]?) {
        jsvmModule.invokeJavaScriptModule(methodName: methodName, moduleName: moduleName, params: params)
    }
    
    // timer
    @objc public func setTimeOut(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void) {
        jsvmModule.setTimeOut(functionID: functionID, time: time, queue: queue, callback: callback)
    }
    
    @objc public func setTimeOut(functionID: NSInteger, time: NSInteger, runloop: RunLoop, callback: @escaping () -> Void) {
        jsvmModule.setTimeOut(functionID: functionID, time: time, runloop: runloop, callback: callback)
    }
    
    @objc public func setInterval(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void) {
        jsvmModule.setInterval(functionID: functionID, time: time, queue: queue, callback: callback)
    }
    
    @objc public func setInterval(functionID: NSInteger, time: NSInteger, runloop: RunLoop, callback: @escaping () -> Void) {
        jsvmModule.setInterval(functionID: functionID, time: time, runloop: runloop, callback: callback)
    }
    
    @objc public func clearTimeout(functionID: NSInteger) {
        jsvmModule.clearTimeout(functionID: functionID)
    }
    
    @objc public func clearInterval(functionID: NSInteger) {
        jsvmModule.clearInterval(functionID: functionID)
    }
    
    @objc public func terminate() {
        jsvmModule.jsEngine?.terminate()
    }

    //    MARK: - BDPJSBridgeEngineProtocol & BDPEngineProtocol

    public var uniqueID: OPAppUniqueID = OPAppUniqueID(appID: "preload", identifier: nil, versionType: .current, appType: .unknown)

    public var bridgeType: BDPJSBridgeMethodType = [.nativeApp]

    public var authorization: BDPJSBridgeAuthorizationProtocol?

    private var _bridgeController: UIViewController?

    public weak var bridgeController: UIViewController? {
        get {
            return self.delegate?.runtimeBridgeController?()
        }
        set {
            _bridgeController = newValue
        }
    }

    public var workers: OpenJSWorkerQueue?

    public func bdp_evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
    }

    public func bdp_fireEventV2(_ event: String, data: [AnyHashable : Any]?) {

        let fireEventBlk: (() -> Void) = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.fireEventModule.fireEvent(event, data: data, sourceID: NSNotFound, useArrayBuffer: true)
        }
        dispatchQueue?.dispatchASync(fireEventBlk)
    }

    // fireEvent native主动发送消息给js
    public func bdp_fireEvent(_ event: String, sourceID: Int, data: [AnyHashable : Any]?) {
        self.fireEventModule.fireEvent(event, data: data, sourceID: sourceID, useArrayBuffer: false)
    }

    @objc public var isFireEventReady: Bool {
        get {
            return fireEventModule.isFireEventReady
        }
        set {
            fireEventModule.isFireEventReady = newValue
        }
    }

    //    MARK: - info ready， 拿到uniqueID

    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector:#selector(handleReachabilityChanged(notification:)) , name: OPJSEngineService.shared.utils?.reachabilityChangedNotification(), object: nil)
        if !apiDispatcherModule.enableForegroundAPIDispatchFix() {
            NotificationCenter.default.addObserver(self, selector: #selector(handleInvokeInterruption(notification:)), name: Notification.Name("kBDPAPIInterruptionV1Notification"), object: nil)
        }
    }

    var isFirstTimeNetStateChange: Bool = true

    @objc func handleReachabilityChanged(notification: Notification) {
        let utils = OPJSEngineService.shared.utils
        //小程序/小游戏启动时首次变化是由未检测的状态变化到首次检测的值，QA提了bug，这里屏蔽掉
        if (isFirstTimeNetStateChange) {
            isFirstTimeNetStateChange = false;
            return;
        }
        let data: [String: Any] = [
            "isConnected": utils?.currentNetworkConnected() as Any,
            "networkType": utils?.currentNetworkType() as Any
        ]
        Self.logger.info("onNetworkStatusChange: \(data)")
        bdp_fireEvent("onNetworkStatusChange", sourceID: NSNotFound, data: data)
    }

    // 目前仅小程序worker和独立worker共用
    @objc func handleInvokeInterruption(notification: Notification) {
        if let userInfo = notification.userInfo {
            let invokeUniqueID = userInfo["kBDPUniqueIDUserInfoKey"] as? OPAppUniqueID
            let status = userInfo["kBDPInterruptionUserInfoStatusKey"] as? Int
            if invokeUniqueID != uniqueID {
                Self.logger.warn("handleInvokeInterruption uniqueID mismatch, current uniqueID\(uniqueID) invokeUniqueID\(invokeUniqueID)")
                return
            }
            Self.logger.info("runtime handleInvokeInterruption uniqueID:\(invokeUniqueID) status:\(status)")
            self.apiDispatcherModule.handleInvokeInterruption(stop: status == 0)
        }
    }

    //    MARK: - load script

    // innerLoadScriptWithURL
    @objc public func loadScript(url: URL?) -> Error? {
        guard let url = url else {
            if let monitorManager = OPJSEngineService.shared.monitor {
                let monitor = OPMonitor(OPMonitorCode(domain: "client.open_platform.gadget", code: 10008, level: OPMonitorLevelError, message: "load_script_from_url_error")).addCategoryValue("js_engine_type", runtimeType)
                monitorManager.bindTracing(monitor: monitor, uniqueID: self.uniqueID)
                monitor.setErrorMessage("url is nil").flush()
            }

            return NSError(domain: "GeneralJSRuntime", code: -1002, userInfo: [NSLocalizedDescriptionKey: "scriptUrl parse error"])
        }
        Self.logger.info("load script start, id=\(self.uniqueID), url=\(url)")
        do {
            let script = try String(contentsOf: url, encoding: .utf8)
            if !script.isEmpty && (jsvmModule.jsEngine != nil) {
                self.jsvmModule.evaluateScript(script, withSourceURL: url)
            } else {
                let monitor = OPMonitor(OPMonitorCode(domain: "client.open_platform.gadget", code: 10008, level: OPMonitorLevelError, message: "load_script_from_url_error")).addCategoryValue("script_url", url.absoluteString).addCategoryValue("js_engine_type", runtimeType)
                OPJSEngineService.shared.monitor?.bindTracing(monitor: monitor, uniqueID: self.uniqueID)

                if script.isEmpty {
                    monitor.setErrorMessage("script is empty").flush()
                    return NSError(domain: "GeneralJSRuntime", code: -1002, userInfo: [NSLocalizedDescriptionKey: "scriptUrl parse error"])

                } else if jsvmModule.jsEngine == nil {
                    monitor.setErrorMessage("jscontext is nil").flush()
                    return NSError(domain: "GeneralJSRuntime", code: -1001, userInfo: [NSLocalizedDescriptionKey: "context is nil when evaluateScript"])
                }
            }
            return nil
        } catch let e {
            let monitor = OPMonitor(OPMonitorCode(domain: "client.open_platform.gadget", code: 10008, level: OPMonitorLevelError, message: "load_script_from_url_error")).addCategoryValue("script_url", url.absoluteString).addCategoryValue("js_engine_type", runtimeType)
            OPJSEngineService.shared.monitor?.bindTracing(monitor: monitor, uniqueID: self.uniqueID)
            monitor.setErrorMessage("script is empty").flush()

            Self.logger.error("load script error, script parse fail, id=\(self.uniqueID), url=\(url), error=\(e)")
            return NSError(domain: "GeneralJSRuntime", code: -1002, userInfo: [NSLocalizedDescriptionKey: "scriptUrl parse error"])
        }
    }

    @objc public func loadScript(url: URL, callbackIsMainThread: Bool, completion:(() -> Void)?) -> Void {
        let loadContextBlk: (() -> Void) = { [weak self] in
            guard let `self` = self else {
                return
            }
            Self.logger.info("loadScriptWithURL, id=\(self.uniqueID), url=\(url)")
            self.loadScript(url: url)
            if let completion = completion {
                if callbackIsMainThread {
                    OPJSEngineService.shared.utils?.executeOnMainQueue(completion);
                } else {
                    completion()
                }
            }
        }
        dispatchQueue?.dispatchASync(loadContextBlk)
    }

    @objc public var executedJSPathes: [String] = []
    @objc public func loadScript(script: String, fileSource: String, callbackIsMainThread: Bool, completion:(() -> Void)?) -> Void {
        let loadContextBlk: (() -> Void) = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.loadScript(script: script, fileSource: fileSource)
            if !fileSource.isEmpty {
                self.executedJSPathes.append(fileSource)
            }
            if let completion = completion {
                if callbackIsMainThread {
                    OPJSEngineService.shared.utils?.executeOnMainQueue(completion);
                } else {
                    completion()
                }
            }
        }
        dispatchQueue?.dispatchASync(loadContextBlk)
    }

    // - (void)_innerLoadScript:(NSString *)script withFileSource:(NSString *)fileSource
    @objc public func loadScript(script: String, fileSource: String) -> Error? {
        if script.count > 0 {
            if let url = URL(string: fileSource) {
                jsvmModule.evaluateScript(script, withSourceURL: url)
            }
        } else {
            if let monitorManager = OPJSEngineService.shared.monitor {
                let monitor = OPMonitor(OPMonitorCode(domain: "client.open_platform.gadget", code: 10008, level: OPMonitorLevelError, message: "load_script_from_url_error"))
                monitorManager.bindTracing(monitor: monitor, uniqueID: self.uniqueID)
                monitor.setErrorMessage("script is empty").addCategoryValue("script_url", fileSource).flush()
            }
            return NSError(domain: "GeneralJSRuntime", code: -1, userInfo: [NSLocalizedDescriptionKey: "script is empty"])
        }
        return nil
    }


    //    MARK: - 初始化

    @objc public var jsContext: JSContext?

    public var isSeperateWorker: Bool = false
    @objc public var isSocketDebug: Bool = false
    private var isHandlingException = false

    // runtime module
    public var jsvmModule: OPJSVMModule
    @objc public let bridgeModule: OPJSBridgeModule = OPJSBridgeModule()
    @objc public let socketDebugModule: OPJSSocketDebugModule = OPJSSocketDebugModule()
    @objc public let apiDispatcherModule: OPJSRuntimeAPIDispatchModuleProtocol
    @objc public let fireEventModule: OPJSFireEventModule = OPJSFireEventModule()
    @objc public let timerModule: OPJSTimerModule = OPJSTimerModule()
    @objc public var loadScriptModule: GeneralJSRuntimeModuleProtocol?
    @objc public var loadScriptHandler: OPJSLoadScript? {
        didSet {
            jsvmModule.loadScriptHandler = loadScriptHandler
        }
    }

    @objc public var loadDynamicComponentModule: GeneralJSRuntimeModuleProtocol?
    @objc public var loadDynamicComponentHandler: OPJSLoadDynamicComponent? {
        didSet {
            jsvmModule.loadDynamicComponentHandler = loadDynamicComponentHandler
        }
    }

    // js环境注入
    func buildJSContextApp() {
        // js exception 上报
        jsvmModule.setExceptionHandler  { [weak self] (context, exception) in
            guard let `self` = self else {
                Self.logger.error("worker exceptionHandler fail, self is nil")
                return
            }

            let logMessage = exception["logMessage"]
            Self.logger.error("JSContext Exception 异常(JSContext Exception)：\(logMessage ?? "")")

            var args = exception
            args["worker"] = self.apiDispatcherModule.workerName
            let isNewBridge = OPJSEngineService.shared.utils?.shouldUseNewBridge() ?? false
            self.invoke(event: "reportJsRuntimeError", param: args, callbackID: nil, extra: nil, isNewBridge: isNewBridge)

            let jsContext = context ?? JSContext()
            self.delegate?.runtimeException?(args, exception: JSValue(object: exception, in: jsContext))
            
        }
    }

    deinit {
        self.dispatchQueue?.stopThread(false)
    }

    //    MARK: - 队列
    @objc public var dispatchQueue: BDPJSRunningThreadAsyncDispatchQueue?
    @objc public func createJsContextDispatchQueue(name: String) -> BDPJSRunningThreadAsyncDispatchQueue {
        return createJsContextDispatchQueue(name: name, delegate: nil)
    }

    @objc public func createJsContextDispatchQueue(name: String, delegate: BDPJSRunningThreadDelegate?) -> BDPJSRunningThreadAsyncDispatchQueue {
        // 队列初始化
        let threadName = name // thread name 不能太长，要不然会设置失败
        let thread = BDPJSRunningThread(name: threadName)
        let queue = BDPJSRunningThreadAsyncDispatchQueue(thread: thread)
        thread.delegate = delegate
        self.dispatchQueue = queue
        queue.startThread(true)

        // module初始化
        self.socketDebugModule.jsRuntime = self
        self.apiDispatcherModule.jsRuntime = self;
        self.jsvmModule.jsRuntime = self
        self.bridgeModule.jsRuntime = self
        self.fireEventModule.jsRuntime = self
        self.timerModule.jsRuntime = self
        self.loadScriptModule?.jsRuntime = self
        self.loadDynamicComponentModule?.jsRuntime = self

        queue.dispatchASync { [weak self] in
           guard let `self` = self else {
               Self.logger.error("worker init fail, self is nil")
               return
           }
            // module加载
            self.jsvmModule.runtimeLoad() // jsvm初始化
            // TODO: 暂时不能去掉，外部依赖

            if !self.runtimeType.isVMSDK() {
                self.jsContext = self.jsvmModule.jsContext
            }
            self.buildJSContextApp() // js环境 jsitodo 需要改造

            if self.isSocketDebug && !self.isSeperateWorker {
                self.socketDebugModule.runtimeLoad() // socket debug 初始化
            } else {
                self.bridgeModule.runtimeLoad() // bridge 初始化，注入bridge
                self.loadScriptModule?.runtimeLoad()
            }
            self.timerModule.runtimeLoad() // bridge 初始化，注入bridge
            self.loadDynamicComponentModule?.runtimeLoad()

            self.delegate?.runtimeLoad()
        }
        return queue
    }

    @objc public func enableAcceptAsyncDispatch(_ enabled: Bool) {
        guard let dispatchQueue = dispatchQueue else {
            Self.logger.info("enableAcceptAsyncDispatch jsContextMergedDispatchQueue is nil id=\(self.hash)")
            return
        }
        var enabledString = "enable"
        if !enabled {
            enabledString = "disable"
        }
        Self.logger.info("enableAcceptAsyncDispatch \(enabledString), id=\(self.hash)")
        dispatchQueue.enableAcceptAsyncCall  = enabled
    }

    @objc public var isJSContextThreadForceStopped: Bool = false

    @objc public func dispatchAsyncInJSContextThread(_ blk: (() -> Void)?) {
        if let dispatchQueue = dispatchQueue {
            if !isJSContextThreadForceStopped, let blk = blk {
                dispatchQueue.dispatchASync(blk)
            }
        } else {
            OPJSEngineService.shared.utils?.executeOnMainQueue(blk)
        }
    }

    @objc public func cancelAllPendingAsyncDispatch() {
        if let dispatchQueue = dispatchQueue {
            if !isJSContextThreadForceStopped {
                dispatchQueue.removeAllAsyncDispatch()
            }
        }
    }

    @objc public func renameThreadName(_ name: String) {
        func renameBlk() {
            pthread_setname_np(name)
        }
        if Thread.current == dispatchQueue?.thread {
            renameBlk()
        } else if let enableAcceptAsyncCall = dispatchQueue?.enableAcceptAsyncCall, enableAcceptAsyncCall {
            dispatchQueue?.dispatchASync(renameBlk)
        }
    }

    //    MARK: - 工具方法

    @objc public func jsonValue(_ param: NSString) -> NSDictionary? {
        let paramDict = param.jsonValue()
        var dict: NSDictionary?
        if let paramString = paramDict as? NSString {
            dict = paramString.jsonValue() as? NSDictionary
        } else if let paramDict = paramDict as? NSDictionary {
            dict = paramDict.decodeNativeBuffersIfNeed() as? NSDictionary
        }
        return dict
    }

    //    MARK: - bridge

    @objc public func invoke(event: String, param: [AnyHashable: Any]?, callbackID: String?, extra: [AnyHashable: Any]?, isNewBridge: Bool) -> Any? {
        return apiDispatcherModule.invoke(event: event, param: param, callbackID: callbackID, extra: extra, isNewBridge: isNewBridge)
    }

    @objc public func call(event: String, param: [AnyHashable: Any]?, callbackID: NSNumber?) -> NSDictionary? {
        return apiDispatcherModule.call(event: event, param: param, callbackID: callbackID)
    }

    // 统一bridge，用于native到js通信
    public func invokeNativeCallback(callbackID: String?, callbackType: String, data: [AnyHashable: Any]?, extra: [AnyHashable: Any]?) {
        if self.runtimeType.isVMSDK() {
            // vmsdk 内部会把NSData转成ArrayBuffer
            var responseValue:[AnyHashable: Any] = [:]
            responseValue["callbackID"] = callbackID ?? ""
            responseValue["callbackType"] = callbackType
            responseValue["data"] = data ?? [:]
            if let extra = extra {
                responseValue["extra"] = extra
            }
            self.invokeJavaScriptModule(methodName: "nativeCallBack", moduleName: "LarkWebViewJavaScriptBridge", params: [responseValue])
        } else {
            if let jsContext = self.jsvmModule.jsContext, let responseJSValue = JSValue(newObjectIn: jsContext) {
                responseJSValue.setValue(callbackID ?? "", forProperty: "callbackID")
                responseJSValue.setValue(callbackType, forProperty: "callbackType")
                if let extra = extra {
                    responseJSValue.setValue(extra, forProperty: "extra")
                }
                if let dataDict = data as? NSDictionary {
                    let dataParam = dataDict.bdp_jsvalue(in: jsContext)
                    responseJSValue.setValue(dataParam, forProperty: "data")
                } else {
                    responseJSValue.setValue([:], forProperty: "data")
                }
                self.invokeJavaScriptModule(methodName: "nativeCallBack", moduleName: "LarkWebViewJavaScriptBridge", params: [responseJSValue])
            } else {
                Self.logger.error("worker invokeNativeCallback fail, jsContext is nil, when call js module")
            }
        }
    }

    //    MARK: - socket debug

    public func connection(_ connection: BDPJSRuntimeSocketConnection, statusChanged status: BDPJSRuntimeSocketStatus) {
        if let delegate = delegate {
            delegate.connection?(connection, statusChanged: status)
        }
    }

    public func connection(_ connection: BDPJSRuntimeSocketConnection, didReceive message: BDPJSRuntimeSocketMessage) {
        if let delegate = delegate {
            delegate.connection?(connection, didReceive: message)
        }
    }

    public func socketDidConnected() {
        if let delegate = delegate {
            delegate.socketDidConnected?()
        }
    }

    public func socketDidFailWithError(_ error: Error) {
        if let delegate = delegate {
            delegate.socketDidFailWithError?(error)
        }
    }

    public func socketDidClose(withCode code: Int, reason: String, wasClean: Bool) {
        if let delegate = delegate {
            delegate.socketDidClose?(withCode: code, reason: reason, wasClean: wasClean)
        }
    }

    // MARK: - LifeCycle
    
    @objc public func handleInvokeInterruption(status: GeneralJSRuntimeRenderStatus, data: [AnyHashable: Any]?) {
        guard apiDispatcherModule.enableForegroundAPIDispatchFix() else {
            self.bdp_fireEvent(status.stringValue, sourceID: NSNotFound, data: data)
            return
        }
        
        self.apiDispatcherModule.handleInvokeInterruption(stop: status == .onAppEnterBackground)
        self.bdp_fireEvent(status.stringValue, sourceID: NSNotFound, data: data)
        if let workers {
            workers.works.forEach { (_, value) in
                value.bdp_fireEvent(status.stringValue, sourceID: NSNotFound, data: data)
            }
        }
    }
}

extension GeneralJSRuntimeRenderStatus {
    
    var stringValue: String {
        switch self {
        case .onAppEnterForeground:
            return "onAppEnterForeground"
        case .onAppEnterBackground:
            return "onAppEnterBackground"
        }
    }
}
