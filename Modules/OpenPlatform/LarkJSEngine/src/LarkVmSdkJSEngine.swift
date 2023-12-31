//
//  LarkVmSdkJSEngine.swift
//  LarkJSEngine
//
//  Created by bytedance on 2022/11/7.
//

import Foundation
import JavaScriptCore
import vmsdk
import LKCommonsLogging

fileprivate let logger = Logger.log(LarkVmsdkJSEngineMessageHandler.self, category: "LarkVmSdkJSEngine")

public class LarkVmsdkJSEngineMessageHandler: NSObject, MessageCallback {
    public func handleMessage(_ msg: String) {
        logger.info("vmsdk worker handle message: \(msg)")
    }
}

public class LarkVmsdkJSEngineErrorHandler: NSObject, ErrorCallback {
    public func handleError(_ msg: String) {
        logger.error("vmsdk worker handle error: \(msg)")
    }
}

public class LarkVmSdkJSEngine: NSObject, LarkJSEngineProtocol
{
    public var jsEngineType: LarkJSEngineType = .vmsdkJSCore
    public var jsTimer: LarkJSTimerProtocol?
    
    private let jsWorker: JsWorkerIOS
    private let jsModules: [LarkVmSdkJSModule] = []
    
    private let msgHandler = LarkVmsdkJSEngineMessageHandler()
    private let errorHandler = LarkVmsdkJSEngineErrorHandler()
    
    private var exceptionHandler: ((JSContext?, [String: String?]) -> Void)?
    
    public init(useJSCore: Bool) {
        self.jsWorker = JsWorkerIOS(useJSCore, param: nil, isMutiThread: true, biz_name: "lark_miniapp")
        self.jsWorker.initJSBridge()
        super.init()

        self.jsWorker.onErrorCallback = errorHandler
        self.jsWorker.onMessageCallback = msgHandler
    }
    
    public func evaluateScript(_ script: String) {
        jsWorker.evaluateJavaScript(script, param: "")
    }
    
    public func evaluateScript(_ script: String, withSourceURL sourceURL: URL) {
        jsWorker.evaluateJavaScript(script, param: sourceURL.absoluteString)
    }
    
    public func setGlobalProperties(_ properties: [String: Any]) {
        jsWorker.setGlobalProperties(properties)
    }
    
    public func registerJSModule(_ jsModule: JSModule.Type, _ param: Any) {
        self.jsWorker.register(jsModule, param: param)
    }
    
    public func terminate() {
        self.jsWorker.terminate()
    }
    
    public func setExceptionHandler(handler: ((JSContext?, [String: String?]) -> Void)?) {
        exceptionHandler = handler
        
    }
    
    public func setJSVMName(_ name: String) {
        jsWorker.setContextName(name)
    }
    
    public func invokeJavaScriptModule(methodName: String, moduleName: String?, params: [Any]?) {
        if let moduleName = moduleName {
            jsWorker.invokeJavaScriptModule(moduleName, methodName: methodName, params: params ?? [])
        } else {
            jsWorker.invokeJavaScriptFunction(methodName, params: params ?? [])
        }
    }
}
