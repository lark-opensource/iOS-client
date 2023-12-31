//
//  OPJSVMModule.swift
//  TTMicroApp
//
//  Created by yi on 2021/11/30.
//

// jsvm module，包装jsvm的相关功能，runtime中不直接使用jsvm
import Foundation
import LKCommonsLogging
import LarkJSEngine
import OPFoundation

public final class OPJSVMModule: NSObject, GeneralJSRuntimeModuleProtocol {
    @objc public var jsContext: JSContext? // jsitodo 需要去掉public
    static let logger = Logger.log(OPJSVMModule.self, category: "OPJSEngine")
    public weak var jsRuntime: GeneralJSRuntime?
    public weak var loadScriptHandler: OPJSLoadScript?
    
    private var jsEngineType: LarkJSEngineType
    
    public var jsEngine: LarkJSEngineProtocol?
   
    public weak var loadDynamicComponentHandler: OPJSLoadDynamicComponent?

    public init(with opRuntimeType: OPRuntimeType) {
        self.jsEngineType = .jsCore
        if let type = opRuntimeType.toLarkJSEngineType()  {
            self.jsEngineType = type
        }
        super.init()
    }

    public func runtimeLoad() // js runtime初始化
    {
        createJSVM()
    }

    public func runtimeReady()
    {

    }

    func createJSVM() {
        guard let dispatchQueue = self.jsRuntime?.dispatchQueue else {
            Self.logger.error("worker init fail, self is nil")
            return
        }
        jsEngine = LarkJSEngineFactory.createJSEngine(type: jsEngineType)

        if jsEngineType == .vmsdkJSCore || jsEngineType == .vmsdkQuickJS {
            #if DEBUG
            jsEngine?.registerJSModule(ConsoleLogVmsdkModule.self, [])
            #endif
            jsEngine?.registerJSModule(OPWebKitVmSdkModule.self, [jsRuntime])
            jsEngine?.registerJSModule(OPTTJSCoreVmSdkModule.self, [jsRuntime])
            jsEngine?.registerJSModule(OPLoadScriptVmSdkModule.self, [loadScriptHandler, jsRuntime])
            jsEngine?.registerJSModule(OPLoadDynamicComponentVmSdkModule.self, [loadScriptHandler, jsRuntime])
        }
        // TODO: thread stop 的时候真的需要把 jsContext 和 jsvm 清空吗？
        if let engine = jsEngine as? LarkJSCore, let context = engine.jsContext {
            self.jsContext = context
            dispatchQueue.thread.jsContext = context
            dispatchQueue.thread.jsVM = context.virtualMachine
        }

    }

    public func evaluateScript(_ script: String) -> Void {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm evaluateScript fail, jscontext is nil")
            return
        }
        jsEngine.evaluateScript(script)
    }

    // 执行js脚本，指定sourceURL
    public func evaluateScript(_ script: String,
                        withSourceURL sourceURL: URL) -> Void {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm evaluateScript withSourceURL fail, jscontext is nil")
            return
        }
        jsEngine.evaluateScript(script, withSourceURL: sourceURL)
    }

    public func setObject(_ object: Any, forKeyedSubscript key: (NSCopying & NSObjectProtocol)) {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm setObject forKey fail, jscontext is nil")
            return
        }
        jsEngine.setGlobalProperties([((key as? String) ?? ""): object])
    }
    
    @objc public func setjsvmName(name: String) {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm setJSVMName fail, jscontext is nil")
            return
        }
        jsEngine.setJSVMName(name)
    }

    public func setExceptionHandler(handler: ((JSContext?, [String: String?]) -> Void)?) {

        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm setExceptionHandler fail, jscontext is nil")
            return
        }
        jsEngine.setExceptionHandler(handler: handler)
    }
    
    public func invokeJavaScriptModule(methodName: String, moduleName: String?, params: [Any]?) {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm invokeJavaScriptModule fail, jscontext is nil")
            return
        }
        jsEngine.invokeJavaScriptModule(methodName: methodName, moduleName: moduleName, params: params)
    }
    
    // timer
    public func setTimeOut(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void) {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm setTimeOut fail, jscontext is nil")
            return
        }
        jsEngine.setTimeOut(functionID: functionID, time: time, queue: queue, callback: callback)
    }
    
    public func setTimeOut(functionID: NSInteger, time: NSInteger, runloop: RunLoop, callback: @escaping () -> Void) {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm setTimeOut fail, jscontext is nil")
            return
        }
        jsEngine.setTimeOut(functionID: functionID, time: time, runloop: runloop, callback: callback)
    }
    
    public func setInterval(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void) {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm setTimeOut fail, jscontext is nil")
            return
        }
        jsEngine.setInterval(functionID: functionID, time: time, queue: queue, callback: callback)
    }
    
    public func setInterval(functionID: NSInteger, time: NSInteger, runloop: RunLoop, callback: @escaping () -> Void) {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm setTimeOut fail, jscontext is nil")
            return
        }
        jsEngine.setInterval(functionID: functionID, time: time, runloop: runloop, callback: callback)
    }
    
    public func clearTimeout(functionID: NSInteger) {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm clearTimeout fail, jscontext is nil")
            return
        }
        jsEngine.clearTimeout(functionID: functionID)
    }
    
    public func clearInterval(functionID: NSInteger) {
        guard let jsEngine = jsEngine else {
            Self.logger.error("jsvm clearInterval fail, jscontext is nil")
            return
        }
        jsEngine.clearInterval(functionID: functionID)
    }
}
