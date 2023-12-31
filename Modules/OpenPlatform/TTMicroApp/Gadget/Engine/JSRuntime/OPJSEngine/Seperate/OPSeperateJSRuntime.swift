//
//  OPSeperateJSRuntime.swift
//  TTMicroApp
//
//  Created by yi on 2021/12/1.
//


/*
openjsworker 和 BDPJSRuntime哪些是一模一样
 1.  线程到底要不要移动到GeneralJSRuntime， 如果不要就注入一个线程 大家共用;
 */

import Foundation
import OPSDK
import LarkOpenPluginManager
import LKCommonsLogging
import LarkOpenAPIModel
import ECOInfra
import OPJSEngine

final class OPSeperateJSRuntime: NSObject, BDPJSBridgeEngineProtocol, BDPEngineProtocol, TMASessionManagerDelegate, OPSeperateJSRuntimeProtocol, GeneralJSRuntimeDelegate {

    // MARK: engine
    // 实现BDPJSBridgeEngineProtocol, BDPEngineProtocol协议

    public var uniqueID: OPAppUniqueID

    public var bridgeType: BDPJSBridgeMethodType = [.nativeApp]

    private var _authorization: BDPJSBridgeAuthorizationProtocol?

    public var authorization: BDPJSBridgeAuthorizationProtocol? {
        set {
            _authorization = newValue
            jsRuntime.authorization = _authorization
        }

        get {
            return _authorization
        }
    }

    public weak var bridgeController: UIViewController?

    public var workers: OpenJSWorkerQueue? // jsitodo 可以派生子worker这个能力考虑做到generaljsruntime里面

    public func bdp_evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil) {
        Self.logger.error("bdp_evaluateJavaScript unimpletion")
    }

    public func bdp_fireEventV2(_ event: String, data: [AnyHashable : Any]?) {
    }

    // fireEvent native主动发送消息给js
    public func bdp_fireEvent(_ event: String, sourceID: Int, data: [AnyHashable : Any]?) {
        self.jsRuntime.bdp_fireEvent(event, sourceID: sourceID, data: data)
    }

    // worker间传递消息
    public func transferMessage(_ data: [AnyHashable : Any]?) {
        self.jsRuntime.dispatchQueue?.dispatchASync { [weak self] in
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

    // MARK: 初始化
    public var jsRuntime: GeneralJSRuntime
    // worker
    public var workerName: String = "" // worker name
    public weak var sourceWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)? // 父worker
    public weak var rootWorker: (BDPEngineProtocol & BDPJSBridgeEngineProtocol)? // 根worker
    // worker js端的onMessage回调
    var onMessageCallback: JSValue?

    // plugin manager
    var pluginManager: OPPluginManagerAdapter? // jsitodo 不要直接使用api dispatcher通道

    static let logger = Logger.log(OPSeperateJSRuntime.self, category: "Worker")

    // 解释器配置
    var interpreters: OpenJSWorkerInterpreters

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
            workerLoadMonitor.addCategoryValue("js_engine_type", jsRuntime.runtimeType.rawValue)
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
        var runtimeType: OPRuntimeType = OPRuntimeType.jscore
        if let runtime = sourceWorker as? OPMicroAppJSRuntime {
            runtimeType = runtime.runtimeType
        }
        let apiDispatcherModule = OPJSRuntimeAPIDispatchModule()
        self.jsRuntime = GeneralJSRuntime(with: runtimeType, apiDispatcherModule: apiDispatcherModule)
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
        apiDispatcherModule.workerName = self.workerName
        apiDispatcherModule.rootWorker = self.rootWorker
        self.jsRuntime.uniqueID = uniqueID
        self.jsRuntime.delegate = self
        self.jsRuntime.isSeperateWorker = true
        self.jsRuntime.createJsContextDispatchQueue(name: "\(BDP_JSTHREADNAME_PREFIX)_worker_\(workerName)")
    }

    public func runtimeLoad() // js runtime初始化
    {
        if(self.jsRuntime.runtimeType.isVMSDK()) {
            self.setupAppContext()
            self.setup()
            self.buildJSContextApp()
            return
        }
        guard let jsContext = self.jsRuntime.jsvmModule.jsContext else {
            self.handleWorkerLoadComplete(result: .jsContextError, errMsg: "jsVM is nil")
            return
        }
        self.setupAppContext()
        self.setup()
        self.buildJSContextApp()
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
        Self.logger.info("worker deinit, id=\(self.uniqueID)")
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

    public func runtimeInterrupt(_ stop: Bool) {
        if stop {
            OPMonitor(GDMonitorCodeLifecycle.gadget_background).setUniqueID(uniqueID).addCategoryValue("worker", workerName).addCategoryValue("workerJssdkVersion", interpreters.netResource?.scriptVersion ?? "").addCategoryValue("js_engine_type", jsRuntime.runtimeType.rawValue).flush()
        } else {
            OPMonitor(GDMonitorCodeLifecycle.gadget_foreground).setUniqueID(uniqueID).addCategoryValue("worker", workerName).addCategoryValue("workerJssdkVersion", interpreters.netResource?.scriptVersion ?? "").addCategoryValue("js_engine_type", jsRuntime.runtimeType.rawValue).flush()
        }
    }

    // 设置jscontext环境
    func setupAppContext() {
        jsRuntime.setjsvmName(name: "\(uniqueID.fullString)_worker_\(workerName)")

        
        if jsRuntime.runtimeType.isVMSDK() {
            // postMessage 发送消息给sourceworker ， onMessage 接收sourceworker 发送过来的消息
            let postMessage: (@convention(block) ([AnyHashable: Any]) -> Any?)? = { [weak self] value in
                guard let `self` = self else {
                    Self.logger.error("worker postMessage fail, self is nil")
                    return nil
                }
                
                if let mainEngine = self.sourceWorker {
                    mainEngine.transferMessage?(value)
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
            jsRuntime.setObject(["postMessage": postMessage, "onMessage": onMessage], forKeyedSubscript: workerJSContextKey)
        } else {
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
            jsRuntime.setObject(["postMessage": postMessage, "onMessage": onMessage], forKeyedSubscript: workerJSContextKey)
        }

        if let tmaTrace = BDPTracingManager.sharedInstance().getTracingBy(uniqueID) {
            let traceId = tmaTrace.traceId
            let createTime = tmaTrace.createTime
            let extensions: [Any] = []
            let config = OPTraceBatchConfig.shared.rawConfig
            let tmaTraceJSContextKey: NSString = "tmaTrace"
            jsRuntime.setObject( ["traceId": traceId, "createTime": createTime, "extensions": extensions, "config": ["optrace_batch_config": config]], forKeyedSubscript: tmaTraceJSContextKey)
        }

        let jsCoreFGJSContextKey: NSString = "JSCoreFG"
        let workerApiUseJSSDKMonitor = EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyGadgetWorkerAPIUseJSSDKMonitor)
        jsRuntime.setObject( ["workerApiUseJSSDKMonitor": workerApiUseJSSDKMonitor], forKeyedSubscript: jsCoreFGJSContextKey)
    }


    public func setup() {
        guard let apiDispatcherModule = self.jsRuntime.apiDispatcherModule as? OPJSRuntimeAPIDispatchModule else {
            return
        }
        self.jsRuntime.runtimeReady()
        pluginManager = apiDispatcherModule.pluginManager
        if let pluginManager = pluginManager {
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

        self.setupSessionObeserver()
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

    // MARK: load script
    // load script
    func loadScript(url: URL) {
        if let error = jsRuntime.loadScript(url: url) as? NSError {
            if error.code == -1001 {
                self.handleWorkerLoadComplete(result: .jsContextError, errMsg: "context is nil when evaluateScript")
            } else if error.code == -1002 {
                self.handleWorkerLoadComplete(result: .scriptError, errMsg: error.localizedDescription)
            }
        } else {
            self.handleWorkerLoadComplete(result: .success, errMsg: nil)
        }
    }
}
