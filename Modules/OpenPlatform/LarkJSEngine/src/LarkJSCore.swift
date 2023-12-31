//
//  LarkJSCore.swift
//  LarkJSEngine
//
//  Created by Jiayun Huang on 2021/12/3.
//

import Foundation
import JavaScriptCore

public final class LarkJSCore: LarkJSEngineProtocol {
    
    public var jsEngineType: LarkJSEngineType = .jsCore
    
    public var jsContext: JSContext?
    
    public var jsTimer: LarkJSTimerProtocol?
    
    private var isHandlingException = false
    
    public init() {
        guard let jsvm = JSVirtualMachine(), let jsContext = JSContext(virtualMachine: jsvm) else {
            return
        }
        self.jsContext = jsContext
        self.jsTimer = LarkJSCoreTimer()
    }
    
    public func evaluateScript(_ script: String) {
        jsContext?.evaluateScript(script)
    }
    
    public func evaluateScript(_ script: String, withSourceURL sourceURL: URL) {
        jsContext?.evaluateScript(script, withSourceURL: sourceURL)
    }
    
    public func setGlobalProperties(_ properties: [String: Any]) {
        properties.forEach { (key: String, value: Any) in
            jsContext?.setObject(value, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
        }
    }
    
    public func setExceptionHandler(handler: ((JSContext?, [String: String?]) -> Void)?) {
        jsContext?.exceptionHandler = { [weak self] (context, exception) in
            guard let `self` = self else {
                return
            }
            
            if let exception = exception,
               // 防止exception toString 再次exception 而陷入循环
               !self.isHandlingException  {
                self.isHandlingException = true

                let line = exception.forProperty("line").toString() ?? ""
                let file = exception.forProperty("sourceURL").toString() ?? ""
                let logMessage = "\(exception.toString() ?? "") \n at \(file):\(line)"
                // 上报基础库未捕获的异常
                let jsMessage = exception.forProperty("message").toString()
                let jsStack = exception.forProperty("stack").toString()
                let jsErrorType = exception.forProperty("errorType").isUndefined ? "unCaughtScriptError" : exception.forProperty("errorType").toString()
                
                let errorInfo = [
                    "line": line,
                    "sourceURL": file,
                    "logMessage": logMessage,
                    "message": jsMessage,
                    "stack": jsStack,
                    "errorType": jsErrorType
                ]
                
                handler?(self.jsContext, errorInfo)
                
                self.isHandlingException = false
            }
        }
    }
    
    public func setJSVMName(_ name: String) {
        jsContext?.name = name
    }
    
    public func invokeJavaScriptModule(methodName: String, moduleName: String?, params: [Any]?) {
        guard let context = jsContext else {
            return
        }
        var jsHandler: JSValue
        if let moduleName = moduleName {
            jsHandler = context.objectForKeyedSubscript(moduleName).objectForKeyedSubscript(methodName)
        } else {
            jsHandler = context.objectForKeyedSubscript(methodName)
        }
        
        jsHandler.call(withArguments: params)
    }
}
