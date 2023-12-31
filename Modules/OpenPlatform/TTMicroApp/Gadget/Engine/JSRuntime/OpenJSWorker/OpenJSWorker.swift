//
//  BDPJSWorker.swift
//  TTMicroApp
//
//  Created by yi on 2021/7/1.
//

import Foundation
import OPSDK
import LarkOpenPluginManager
import LKCommonsLogging
import LarkOpenAPIModel
import ECOInfra
import OPPluginManagerAdapter

// jsworker 启动结果
public enum JSWorkerLoadResult: String {
    case success
    case scriptError // 加载js脚本失败
    case jsContextError // JSContext初始化失败
    case initError // 其他初始化失败
}

final class OpenJSWorker: NSObject, BDPJSBridgeEngineProtocol, BDPEngineProtocol, TMASessionManagerDelegate, OPSeperateJSRuntimeProtocol {

    // MARK: engine
    // 实现BDPJSBridgeEngineProtocol, BDPEngineProtocol协议

    public var uniqueID: OPAppUniqueID

    public var bridgeType: BDPJSBridgeMethodType = [.nativeApp]

    public var authorization: BDPJSBridgeAuthorizationProtocol?

    public weak var bridgeController: UIViewController?

    public var workers: OpenJSWorkerQueue?

    public func bdp_evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        Self.logger.error("bdp_evaluateJavaScript unimpletion")
    }

    public func bdp_fireEventV2(_ event: String, data: [AnyHashable: Any]?) {
    }

    // fireEvent native主动发送消息给js
    public func bdp_fireEvent(_ event: String, sourceID: Int, data: [AnyHashable: Any]?) {

        let fireEventInJSContext = { [weak self] in
            guard let `self` = self else {
                Self.logger.warn("bdp_fireEvent fail, self is nil")
                return
            }
            guard self.jsContextMergedDispatchQueue.enableAcceptAsyncCall else { return }
            var data = data
            if let encodeData = data as? NSDictionary {
                data = encodeData.encodeNativeBuffersIfNeed()
            } else {
                Self.logger.info("bdp_fireEvent, encodeNativeBuffersIfNeed fail")
            }
            var extra = [AnyHashable: Any]()
            if sourceID != NSNotFound {
                extra["webviewId"] = sourceID
            }
            if self.isFireEventReady {
                if !self.fireEventQueue.empty() {
                    let e: [AnyHashable: Any] = ["event": event, "params": data, "extra": extra]
                    self.fireEventQueue.enqueue(e)
                    self.fireAllEventIfNeed()
                } else {
                    let jsStr: String
                    do {
                        jsStr = try Self.callbackString(with: data, callbackID: event, type: .continued, extra: data ?? [AnyHashable: Any]())
                    } catch {
                        Self.logger.error("worker fireEvent failed, finalMap cannot trans to Data", error: error)
                        return
                    }
                    if let c = self.jsContext {
                        c.evaluateScript(jsStr)
                    } else {
                        Self.logger.error("worker fire event error, jscontext is nil")
                    }
                }
            } else {
                let e: [AnyHashable: Any] = ["event": event, "params": data, "extra": extra]
                self.fireEventQueue.enqueue(e)
            }
        }
        jsContextMergedDispatchQueue.dispatchASync(fireEventInJSContext)
    }

    // worker间传递消息
    public func transferMessage(_ data: [AnyHashable: Any]?) {
        jsContextMergedDispatchQueue.dispatchASync { [weak self] in
            guard let `self` = self else {
                Self.logger.warn("load script fail, self is nil")
                return
            }

            if let callback = self.onMessageCallback {
                if let data = data {
                    callback.call(withArguments: [data])
                } else {
                    Self.logger.warn("transferMessage fail, data is nil")
                }
            } else {
                Self.logger.warn("transferMessage fail, callback is nil")
            }
        }
    }

    // 清空发送js的事件队列
    func fireAllEventIfNeed() {
        jsContextMergedDispatchQueue.dispatchASync { [weak self] in
            guard let `self` = self else {
                Self.logger.error("worker fireAllEventIfNeed fail, self is nil")
                return
            }
            self.fireEventQueue.enumerateObjects { [weak self] (object, _) in
                guard let `self` = self else {
                    Self.logger.error("worker fireAllEventIfNeed fail, enumerateObjects error, self is nil")
                    return
                }
                if let dic = object as? [AnyHashable: Any] {
                    let event = dic["event"] as? String ?? ""
                    let params = dic["params"] as? [AnyHashable: Any]
                    let extra = dic["extra"] as? [AnyHashable: Any]
                    let jsStr: String
                    do {
                        jsStr = try Self.callbackString(with: params, callbackID: event, type: .continued, extra: extra ?? [AnyHashable: Any]())
                    } catch {
                        Self.logger.error("worker fireEvent failed, finalMap cannot trans to Data", error: error)
                        return
                    }
                    if let c = self.jsContext {
                        c.evaluateScript(jsStr)
                    } else {
                        Self.logger.error("worker fire event error, jscontext is nil")
                    }
                } else {
                    Self.logger.error("worker fire event error, event queue data invalid")
                }
            }
            self.fireEventQueue.clear()
        }
    }

    // worker
    public var workerName: String = "" // worker name
    public weak var sourceWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)? // 父worker
    public weak var rootWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)? // 根worker
    // worker js端的onMessage回调
    var onMessageCallback: JSValue?

    // jscontext
    var jsContext: JSContext?
    lazy var jsContextMergedDispatchQueue: BDPJSRunningThreadAsyncDispatchQueue = {
        let threadName = "\(BDP_JSTHREADNAME_PREFIX)_worker_\(workerName)" // thread name 不能太长，要不然会设置失败
        let thread = BDPJSRunningThread(name: threadName)
        return BDPJSRunningThreadAsyncDispatchQueue(thread: thread)
    }()

    // plugin manager
    var pluginManager: OPPluginManagerAdapter?

    static let logger = Logger.log(OpenJSWorker.self, category: "Worker")

    // 解释器配置
    var interpreters: OpenJSWorkerInterpreters

    // setTimeout timer map
    var timerMap: [Int: Timer] = [:]
    var timerID: Int = 0

    // lazy inoke queue

    lazy var lazyInvokeQueue: BDPSTLQueue = { return BDPSTLQueue() }()

    let lazyInvokeWhiteList: Set<String> = [
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
        "sendDebugPerformanceData"
    ]

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

    lazy var fireEventQueue: BDPSTLQueue = {
        return BDPSTLQueue()
    }()

    private var _isFireEventReady: Bool = true

    var isFireEventReady: Bool {
        get {
            return _isFireEventReady
        }
        set {
            if _isFireEventReady != newValue {
                _isFireEventReady = newValue
                if _isFireEventReady {
                    fireAllEventIfNeed()
                }
            }
        }
    }

    // worker启动监控
    let workerLoadMonitor = OPMonitor(EPMClientOpenPlatformWorkerLoadCode.worker_load_result)
    private var _workerLoadComplete: Bool = false

    var workerLoadComplete: Bool {
        get {
            var loadComplete: Bool = false
            objc_sync_enter(self)
            loadComplete = _workerLoadComplete
            objc_sync_exit(self)
            return loadComplete
        }
        set {
            objc_sync_enter(self)
            _workerLoadComplete = newValue
            objc_sync_exit(self)
        }
    }

    // worker 启动结束监控处理
    func handleWorkerLoadComplete(result: JSWorkerLoadResult, errMsg: String?) {
        if !workerLoadComplete {
            if let netResource = interpreters.netResource, let scriptVersion = netResource.scriptVersion {
                workerLoadMonitor.addCategoryValue("workerJssdkVersion", scriptVersion)
            }
            if result == .success {
                workerLoadMonitor.setResultTypeSuccess().timing().flush()
            } else {
                if let sourceWorker = sourceWorker, let sourceWorkers = sourceWorker.workers as? OpenJSWorkerQueue {
                    // 启动失败 terminate 当前worker
                    sourceWorkers.terminateWorker(workerID: workerName)
                }
                workerLoadMonitor.setErrorCode(result.rawValue).setErrorMessage(errMsg).setResultTypeFail().timing().flush()
            }
            workerLoadComplete = true
        }
    }

    // worker 传入参数
    public var contextData: [AnyHashable: Any] = [:]
    private var isHandlingException = false
    // MARK: init
    public init(sourceWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol), data: [AnyHashable: Any] = [:], interpreters: OpenJSWorkerInterpreters) {

        self.workerLoadMonitor.setUniqueID(sourceWorker.uniqueID).timing()
        self.sourceWorker = sourceWorker
        self.uniqueID = sourceWorker.uniqueID
        if let sourceWorker = sourceWorker as? OpenJSWorker {
            self.rootWorker = sourceWorker.rootWorker
        } else {
            self.rootWorker = sourceWorker
        }
        self.interpreters = interpreters
        super.init()

        self.contextData = data

        if let name = data["workerName"] as? String { // 从data参数取worker name
            self.workerName = name
        } else if let providerName = interpreters.resource?.workerName, let workerProviderName = providerName { // 从解释器取worker name
            self.workerName = workerProviderName
        }
        self.workerLoadMonitor.addCategoryValue("worker", self.workerName)
        if self.rootWorker == nil {
            self.handleWorkerLoadComplete(result: .initError, errMsg: "rootWorker is nil")
        }
        self.jsContextMergedDispatchQueue.startThread(true)
        self.jsContextMergedDispatchQueue.dispatchASync { [weak self] in
            guard let `self` = self else {
                Self.logger.error("worker init fail, self is nil")
                return
            }
            #if DEBUG
            /// 由于 DEBUG 宏的存在，如果 OPJSEngine 使用的是二进制 TTMicroApp 使用源码， 则会导致
            /// `JSVirtualMachineRenameForDebug` 和 `JSContextRenameForDebug` 符号缺失；
            ///
            /// 这里借助 runtime 在 DEBUG 模式下动态调用上面的两个 class； 以保证在其他业务 Demo 中，
            /// 无论 TTMicroApp 使用源码还是二进制 OPJSEngine 都可以使用二进制正常工作 (但使用二进制
            /// 会丢掉 DEBUG 打印的日志)；

            let jvmClass = (NSClassFromString("JSVirtualMachineRenameForDebug") as? JSVirtualMachine.Type) ?? JSVirtualMachine.self
            let jscClass = (NSClassFromString("JSContextRenameForDebug") as? JSContext.Type) ?? JSContext.self

            guard let jsVM = jvmClass.init(), let jsc = jscClass.init(virtualMachine: jsVM) else {
                Self.logger.error("worker init fail, jsVM is nil")
                self.handleWorkerLoadComplete(result: .jsContextError, errMsg: "jsVM is nil")
                return
            }
            #else
            guard let jsVM = JSVirtualMachine(), let jsc = JSContext(virtualMachine: jsVM) else {
                Self.logger.error("worker init fail, jsVM is nil")
                self.handleWorkerLoadComplete(result: .jsContextError, errMsg: "jsVM is nil")
                return
            }
            #endif
            self.jsContextMergedDispatchQueue.thread.jsContext = jsc
            self.jsContextMergedDispatchQueue.thread.jsVM = jsVM
            self.jsContext = jsc
            self.setupAppContext()
            self.setup()
            self.buildJSContextApp()
        }
    }

    public func terminate() {
        if let pluginManager = pluginManager {
            var additionalInfo: [AnyHashable: Any]?
            if let rootWorker = rootWorker {
                let appContext = BDPAppContext()
                appContext.engine = rootWorker
                appContext.controller = rootWorker.bridgeController
                appContext.workerEngine = self
                let gadgetContext = GadgetAPIContext(with: appContext)
                additionalInfo = ["gadgetContext": gadgetContext]
            } else {
                additionalInfo = ["gadgetContext": [:]]
                Self.logger.info("worker invoke terminate, root did deinit")
            }
            do {
                let params = try OpenAPIWorkerEnviromentParams(with: [:])
                pluginManager.postEvent(eventName: "enviromentTerminate", params: params, trace: nil, engine: self, extra: additionalInfo)
                Self.logger.info("worker invoke terminate success")
            } catch {
                Self.logger.error("worker invoke terminate fail, params invalid")
            }
        } else {
            Self.logger.error("worker invoke terminate fail, pluginManager is nil")
        }
    }

    deinit {
        for item in timerMap {
            if let timer = timerMap[item.key] {
                timer.invalidate()
            }
        }
        timerMap.removeAll()
        Self.logger.info("worker deinit, id=\(self.uniqueID)")
        self.jsContextMergedDispatchQueue.stopThread(false)
    }

    func buildJSContextApp() {

        var scriptUrl: URL?
        if let localResouce = self.interpreters.resource {
            scriptUrl = self.interpreters.netResource?.scriptUrl(workerName: workerName, local: localResouce)
        }
        if scriptUrl == nil {
            Self.logger.warn("get netResource fail, use local bundle url")
            scriptUrl = self.interpreters.resource?.scriptLocalUrl
        }
        if let scriptUrl = scriptUrl {
            self.loadScript(url: scriptUrl)
        } else {
            self.handleWorkerLoadComplete(result: .scriptError, errMsg: "scriptUrl is nil")
            Self.logger.error("load script fail, url is nil")
        }
        if let netResource = interpreters.netResource {
            netResource.updateJS(workerName: workerName)
        } else {
            Self.logger.warn("worker updateJS fail, netResource is nil")
        }
    }

    // 设置jscontext环境
    func setupAppContext() {
        guard let jsContext = jsContext else {
            Self.logger.warn("worker setupAppContext fail, jscontext is nil")
            return
        }
        jsContext.name = "\(uniqueID.fullString)_worker_\(workerName)"

        // js exception 上报
        jsContext.exceptionHandler = { [weak self] (_, exception) in
            guard let `self` = self else {
                Self.logger.error("worker exceptionHandler fail, self is nil")
                return
            }
            if let exception = exception {
                if self.isHandlingException { // 防止exception toString 再次exception 而陷入循环
                    Self.logger.warn("JSContext Exception handling exception")
                    return
                }
                self.isHandlingException = true
                let line = exception.forProperty("line")
                let file = exception.forProperty("sourceURL")
                let message = "\(exception.toString()) \n at \(file?.toString()):\(line?.toString())"
                Self.logger.error("JSContext Exception 异常(JSContext Exception)：\(message)")

                // 上报基础库未捕获的异常
                let jsMessage = exception.forProperty("message").toString()
                let jsStack = exception.forProperty("stack").toString()
                let jsErrorType = exception.forProperty("errorType").isUndefined ? "unCaughtScriptError" : exception.forProperty("errorType").toString()

                var args: [AnyHashable: Any] = [:]
                args["message"] = jsMessage
                args["stack"] = jsStack
                args["errorType"] = jsErrorType
                args["worker"] = self.workerName
                self.invoke(event: "reportJsRuntimeError", param: args, callbackID: nil, extra: nil)
                self.isHandlingException = false
            }
        }

        // postMessage 发送消息给sourceworker ， onMessage 接收sourceworker 发送过来的消息
        let postMessage: @convention(block) (JSValue) -> Any? = { [weak self] value in
            guard let `self` = self else {
                Self.logger.error("worker postMessage fail, self is nil")
                return nil
            }
            let dic = value.toDictionary()

            if let mainEngine = self.sourceWorker {
                mainEngine.transferMessage?(dic)
            }
            return nil
        }

        let onMessage: (@convention(block) (JSValue) -> Any?)? = { [weak self] callback in
            guard let `self` = self else {
                Self.logger.error("worker onMessage fail, self is nil")
                return nil
            }
            self.onMessageCallback = callback
            return nil
        }

        let workerJSContextKey: NSString = "worker"
        // postMessage 和 onMessage 函数类型入参 要保持一致，要不然在前端会识别为NSObject {} 函数。
        jsContext.setObject(["postMessage": postMessage, "onMessage": onMessage], forKeyedSubscript: workerJSContextKey)

        // 统一bridge invoke native方法
        let bridgePostMessage: @convention(block) ([AnyHashable: Any]) -> Any? = { [weak self] dic in
            guard let `self` = self else {
                Self.logger.error("worker bridgePostMessage fail, self is nil")
                return nil
            }

            if let apiName = dic["apiName"] as? String {
                let callbackID = dic["callbackID"] as? String
                let extra = dic["extra"] as? [AnyHashable: Any]
                let data = dic["data"] as? NSDictionary
                let decodeData = data?.decodeNativeBuffersIfNeed()
                return self.invoke(event: apiName, param: decodeData, callbackID: callbackID, extra: extra)
            } else {
                Self.logger.error("worker bridgePostMessage fail, apiName is nil")
            }
            return nil
        }
        let webkitJSContextKey: NSString = "webkit"
        jsContext.setObject( ["messageHandlers": ["invokeNative": ["postMessage": bridgePostMessage]]], forKeyedSubscript: webkitJSContextKey)

        // setTimeout, setInterval
        let setTimeout: (@convention(block) (JSValue, Double) -> Any?)? = { [weak self] (callback, timeout) in
            guard let `self` = self else {
                Self.logger.error("worker setTimeout fail, self is nil")
                return nil
            }

            let time = timeout / 1000.0
            let jsTimer = Timer(timeInterval: TimeInterval(time), repeats: false) { _ in
                callback.call(withArguments: [])
            }

            self.jsContextMergedDispatchQueue.thread.runLoop.add(jsTimer, forMode: .default)
            self.timerID = self.timerID + 1
            self.timerMap[self.timerID] = jsTimer
            return self.timerID
        }

        jsContext.setObject(setTimeout,
                                forKeyedSubscript: "setTimeout" as NSString)

        let clearTimeout: (@convention(block) (Int) -> Any?)? = { [weak self] (timerID) in
            guard let `self` = self else {
                Self.logger.error("worker clearTimeout fail, self is nil")
                return nil
            }
            if let timer = self.timerMap[timerID] {
                timer.invalidate()
                self.timerMap.removeValue(forKey: timerID)
            }
            return nil
        }
        jsContext.setObject(clearTimeout,
                                forKeyedSubscript: "clearTimeout" as NSString)

        let setInterval: (@convention(block) (JSValue, Double) -> Any?)? = { [weak self] (callback, timeout) in
            guard let `self` = self else {
                Self.logger.error("worker setInterval fail, self is nil")
                return nil
            }
            let time = timeout / 1000.0
            let jsTimer = Timer(timeInterval: TimeInterval(time), repeats: true) { _ in
                callback.call(withArguments: [])
            }
            self.jsContextMergedDispatchQueue.thread.runLoop.add(jsTimer, forMode: .default)
            self.timerID = self.timerID + 1
            self.timerMap[self.timerID] = jsTimer

            return self.timerID
        }

        jsContext.setObject(setInterval,
                                forKeyedSubscript: "setInterval" as NSString)

        let clearInterval: (@convention(block) (Int) -> Any?)? = { [weak self] (timerID) in
            guard let `self` = self else {
                Self.logger.error("worker clearInterval fail, self is nil")
                return nil
            }
            if let timer = self.timerMap[timerID] {
                timer.invalidate()
                self.timerMap.removeValue(forKey: timerID)
            }

            return nil
        }
        jsContext.setObject(clearInterval,
                                forKeyedSubscript: "clearInterval" as NSString)

        if let tmaTrace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID) {
            let traceId = tmaTrace.traceId
            let createTime = tmaTrace.createTime
            let extensions: [Any] = []
            let config = OPTraceBatchConfig.shared.rawConfig
            let tmaTraceJSContextKey: NSString = "tmaTrace"
            jsContext.setObject( ["traceId": traceId, "createTime": createTime, "extensions": extensions, "config": ["optrace_batch_config": config]], forKeyedSubscript: tmaTraceJSContextKey)
        }

        let jsCoreFGJSContextKey: NSString = "JSCoreFG"
        let workerApiUseJSSDKMonitor = EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyGadgetWorkerAPIUseJSSDKMonitor)
        jsContext.setObject( ["workerApiUseJSSDKMonitor": workerApiUseJSSDKMonitor], forKeyedSubscript: jsCoreFGJSContextKey)
    }

    public func setup() {
        let developerConfig: () -> [String: Any]? = { [weak self] in
            BDPTaskManager.shared().getTaskWith(self?.uniqueID)?.config?.apiConfig
        }
        pluginManager = OPPluginManagerAdapter(with: self, type: uniqueID.appType, bizDomain: .comment, developerConfig: developerConfig)
        if let pluginManager = pluginManager {
            pluginManager.seperateWorkerRegisterPoint()
            if let rootWorker = rootWorker {
                let appContext = BDPAppContext()
                appContext.engine = rootWorker
                appContext.controller = rootWorker.bridgeController
                appContext.workerEngine = self
                let gadgetContext = GadgetAPIContext(with: appContext)
                let additionalInfo = ["gadgetContext": gadgetContext]
                do {
                    let params = try OpenAPIEnviromentDidLoadParams(with: contextData)
                    pluginManager.postEvent(eventName: "enviromentDidLoad", params: params, trace: nil, engine: self, extra: additionalInfo)
                } catch {
                    Self.logger.error("worker invokeMethod fail, postEvent error, params invalid")
                }
            } else {
                Self.logger.error("worker invokeMethod fail, rootWorker is nil")
            }
        } else {
            Self.logger.error("worker invokeMethod fail, pluginManager is nil")
        }

        setupObserver()
    }

    // 添加session通知能力
    func setupSessionObeserver() {
        // 添加前先推送session信息
        let sandbox = BDPCommonManager.shared().getCommonWith(uniqueID).sandbox
        let session = TMASessionManager.shared().getSession(sandbox)
        sessionUpdated(session)

        // 添加session通知能力
        TMASessionManager.shared().add(self, sandbox: sandbox)
    }

    // session更新
    public func sessionUpdated(_ session: String?) {
        if let pluginManager = pluginManager {
            if let rootWorker = rootWorker {
                let appContext = BDPAppContext()
                appContext.engine = rootWorker
                appContext.controller = rootWorker.bridgeController
                appContext.workerEngine = self
                let gadgetContext = GadgetAPIContext(with: appContext)
                let additionalInfo = ["gadgetContext": gadgetContext]
                do {
                    // encode session，评论端上不感知，由开放平台encode session
                    let sessionMap = ["mina_session": session]
                    let sessionJson = try JSONSerialization.data(withJSONObject: sessionMap)
                    let encodeSession = sessionJson.base64EncodedString()

                    let params = try OpenAPIWorkerEnviromentParams(with: ["session": encodeSession])
                    pluginManager.postEvent(eventName: "onAppSessionChanged", params: params, trace: nil, engine: self, extra: additionalInfo)
                } catch {
                    Self.logger.error("worker invokeMethod fail, postEvent error, params invalid")
                }
            } else {
                Self.logger.error("worker invokeMethod fail, rootWorker is nil")
            }
        } else {
            Self.logger.error("worker invokeMethod fail, pluginManager is nil")
        }
    }

    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInvokeInterruption(notification:)), name: Notification.Name(kBDPAPIInterruptionV1Notification), object: nil)
        self.setupSessionObeserver()
    }

    @objc func handleInvokeInterruption(notification: Notification) {
        if let userInfo = notification.userInfo {
            let invokeUniqueID = userInfo[kBDPUniqueIDUserInfoKey] as? OPAppUniqueID
            let status = userInfo["kBDPInterruptionUserInfoStatusKey"] as? Int
            if invokeUniqueID != uniqueID {
                Self.logger.warn("handleInvokeInterruption uniqueID mismatch, current uniqueID\(uniqueID) invokeUniqueID\(invokeUniqueID)")
                return
            }
            Self.logger.info("worker handleInvokeInterruption uniqueID:\(invokeUniqueID) status:\(status)")

            // worker 前后台切换埋点
            if status == BDPInterruptionStatus.begin.rawValue {
                OPMonitor(GDMonitorCodeLifecycle.gadget_background).setUniqueID(uniqueID).addCategoryValue("worker", workerName).addCategoryValue("workerJssdkVersion", interpreters.netResource?.scriptVersion ?? "").flush()
            } else {
                OPMonitor(GDMonitorCodeLifecycle.gadget_foreground).setUniqueID(uniqueID).addCategoryValue("worker", workerName).addCategoryValue("workerJssdkVersion", interpreters.netResource?.scriptVersion ?? "").flush()
            }

            shouldInterruptionInvoke = status == BDPInterruptionStatus.begin.rawValue
            if status == BDPInterruptionStatus.stop.rawValue {
                resumeStageInvokes()
            }
        }
    }

    // MARK: invoke

    func callEvent(event: String, isSync: Bool, invokeBlk: (() -> Void)? = nil) {
        if let blk = invokeBlk {
            let whiteListEvent = lazyInvokeWhiteList.contains(event)
            if shouldInterruptionInvoke, !isSync, !whiteListEvent {
                lazyInvokeQueue.enqueue(blk)
            } else {
                blk()
            }
        } else {
            Self.logger.warn("callEvent fail, block is nil")
        }
    }

    func resumeStageInvokes() {
        while let blk = lazyInvokeQueue.dequeue() as? (() -> Void) {
            blk()
        }
    }

    // invoke
    public func invoke(event: String, param: [AnyHashable: Any]?, callbackID: String?, extra: [AnyHashable: Any]?) -> Any? {

        // 拦截器 用于在需要的时候修改 event 和 param
        let method = BDPJSBridgeMethod(name: event, params: param)
        do {
            try pluginManager?.invokeInterceptorChain.preInvoke(method: method, extra: nil)
        } catch {
             Self.logger.error("invokeInterceptorChain preInvoke method.name \(method.name) error: \(error)")
        }
        let event = method.name
        let param = method.params

        let isSyncMethod = pluginManager?.isSyncAPI(method: method, engine: self) ?? false

        let appTracing = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        var apiTrace = OPTraceService.default().generateTrace(withParent: appTracing, bizName: event)
        if let traceString = extra?["api_trace"] as? String, !traceString.isEmpty {
            apiTrace = OPTraceService.default().generateTrace(withTraceID: traceString, bizName: event).subTrace()
        }
        Self.logger.warn("invoke start, event=\(event) app=\(uniqueID) callbackID=\(callbackID) param.length=\(param?.count)")

        let subMethod = (param?["header"] as? [AnyHashable: Any])?["service"] as? String // rn通道biz.comment.postMessage子消息

        // native 收到js 调用 10002
        OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_receive_invoke)
            .addCategoryValue("api_name", event)
            .addCategoryValue("worker", workerName)
            .addCategoryValue("app_type", "gadget")
            .addCategoryValue("callbackID", callbackID)
            .addCategoryValue("param.length", param?.count)
            .addCategoryValue("sub_method", subMethod)
            .setUniqueID(uniqueID)
            .flushTo(apiTrace)

        // native回调js 10003
        let callbackInvoke = OPMonitor(name: kEventName_op_api_invoke, code: APIMonitorCodeCommon.native_callback_invoke).setUniqueID(uniqueID).addCategoryValue("app_type", "gadget").addCategoryValue("worker", workerName).addCategoryValue("isSyncMethod", isSyncMethod).addCategoryValue("sub_method", subMethod)
        var syncResponse: [AnyHashable: Any]?
        callEvent(event: event, isSync: isSyncMethod) { [weak self] in
            guard let `self` = self else {
                Self.logger.error("worker invoke fail, callEvent, self is nil")
                return
            }
            BDPAPIInterruptionManager.shared().beginInvokeEvent(event, uniqueID: self.uniqueID)
            self.invokeMethod(method: method, isSyncMethod: isSyncMethod, trace: apiTrace) { [weak self] (status, response) in
                guard let `self` = self else {
                    Self.logger.error("worker invoke fail, invokeMethod, self is nil")
                    return
                }
                var handleResponse = BDPProcessJSCallback(response, event, status, self.uniqueID)
                if let encodeResponse = handleResponse as? NSDictionary {
                    handleResponse = encodeResponse.encodeNativeBuffersIfNeed()
                }
                OPAPIReportResult(status, handleResponse, callbackInvoke.monitorEvent)

                if isSyncMethod {
                    callbackInvoke.flushTo(apiTrace)

                    apiTrace.finish()
                    syncResponse = handleResponse
                } else {
                    self.callbackInvoke(callbackID: callbackID, status: status, data: response, trace: apiTrace) {

                        if let callbackID = callbackID {
                            callbackInvoke.addCategoryValue("callbackId", callbackID)
                        } else {
                            callbackInvoke.setResultTypeFail().addCategoryValue("innerMsg", "invalid callbackId")
                        }
                        callbackInvoke.flushTo(apiTrace)

                        apiTrace.finish()
                    }
                }
                BDPAPIInterruptionManager.shared().completeInvokeEvent(event, uniqueID: self.uniqueID)
                if status != .success {
                    Self.logger.warn("invoke finish error, event=\(event) callbackID=\(callbackID) status=\(status) param.length=\(param?.count)")
                } else {
                    Self.logger.info("invoke finish success, event=\(event) callbackID=\(callbackID)")
                }
            }
        }
        return syncResponse
    }

    func invokeMethod(method: BDPJSBridgeMethod, isSyncMethod: Bool, trace: OPTrace, callback: @escaping BDPJSBridgeCallback) {
        guard let pluginManager = pluginManager else {
            Self.logger.error("worker invokeMethod fail, pluginManager is nil")
            return
        }
        guard let rootWorker = rootWorker else {
            Self.logger.error("worker invokeMethod fail, rootWorker is nil")
            return
        }
        let appContext = BDPAppContext()
        appContext.engine = rootWorker
        appContext.controller = rootWorker.bridgeController
        appContext.workerEngine = self
        let gadgetContext = GadgetAPIContext(with: appContext)
        let additionalInfo = ["gadgetContext": gadgetContext]
        pluginManager.invokeAPI(method: method, trace: trace, engine: self, contextExtra: additionalInfo, source: workerName, callback: { status, response in
            callback(status, response)
        })
    }

    // callback
    func callbackInvoke(callbackID: String?, status: BDPJSBridgeCallBackType, data: [AnyHashable: Any]?, trace: OPTrace, completion: (() -> Void)? = nil) {
        guard let callbackID = callbackID else {
            Self.logger.error("callbackID is nil")
            if let completion = completion {
                completion()
            }
            return
        }
        jsContextMergedDispatchQueue.dispatchASync { [weak self] in
            guard let `self` = self else {
                Self.logger.error("callbackInvoke fail, self is nil")
                return
            }
            do {
                let js = try Self.callbackString(with: data, callbackID: callbackID, type: status, extra: nil)
                if let jsContext = self.jsContext {
                    jsContext.evaluateScript(js)
                } else {
                    Self.logger.error("jsworker jsContext is nil")
                }
            } catch {
                Self.logger.error("build callback js str error")
            }
            if let completion = completion {
                completion()
            }
        }
    }

    public static func callbackString(with params: [AnyHashable: Any]?, callbackID: String, type: BDPJSBridgeCallBackType, extra: [AnyHashable: Any]?) throws -> String {

        var finalMap: [String: Any] = [
            "callbackID": callbackID,
            "callbackType": buildTypeString(with: type)
        ]
        if let params = params {
            finalMap["data"] = params
        }
        if let extra = extra {
            finalMap["extra"] = extra
        }
        if !JSONSerialization.isValidJSONObject(finalMap) {
            Self.logger.warn("build js string error, json invalid")
        }

        let data = try JSONSerialization.data(withJSONObject: finalMap)
        let str = String(data: data, encoding: .utf8) ?? ""
        let jsStr = "LarkWebViewJavaScriptBridge.nativeCallBack(\(str))"
        return jsStr
    }

    private static func buildTypeString(with type: BDPJSBridgeCallBackType) -> String {
        switch type {
        case .success:
            return "success"
        case .failed:
            return "failure"
        case .userCancel:
            return "cancel"
        case .continued:
            return "continued"
        default:
            return "failure"
        }
    }

    // MARK: script
    // load script
    func loadScript(url: URL) {
        Self.logger.info("load script start, id=\(self.uniqueID), url=\(url)")
        do {
            let script = try String(contentsOf: url, encoding: .utf8)
            if let jsContext = self.jsContext {
                jsContext.evaluateScript(script, withSourceURL: url)
                self.handleWorkerLoadComplete(result: .success, errMsg: nil)
            } else {
                self.handleWorkerLoadComplete(result: .jsContextError, errMsg: "context is nil when evaluateScript")
                Self.logger.error("load script error, context is nil, id=\(self.uniqueID), url=\(url)")
            }
        } catch {
            self.handleWorkerLoadComplete(result: .scriptError, errMsg: "scriptUrl parse error")
            Self.logger.error("load script error, script parse fail, id=\(self.uniqueID), url=\(url)")
        }
    }

    func loadScript(script: String, fileSource: String) {
        let url = URL(string: fileSource)
        if let jsContext = self.jsContext {
            jsContext.evaluateScript(script, withSourceURL: url)
        } else {
            Self.logger.error("load script error, context is nil, id=\(self.uniqueID)")
        }
    }
}
