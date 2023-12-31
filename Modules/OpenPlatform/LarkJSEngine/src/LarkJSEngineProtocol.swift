//
//  LarkJsEngineProtocol.swift
//  LarkJSEngine
//
//  Created by Jiayun Huang on 2021/12/2.
//

import Foundation
import JavaScriptCore
import vmsdk
import LKCommonsLogging

public protocol LarkJSEngineProtocol {

    var jsEngineType: LarkJSEngineType { get }
    
    var jsTimer: LarkJSTimerProtocol? { get set }
    
    // 执行js脚本
    func evaluateScript(_ script: String) -> Void

    // 执行js脚本，指定sourceURL
    func evaluateScript(_ script: String,
          withSourceURL sourceURL: URL) -> Void
    
    func setGlobalProperties(_ properties: [String: Any]) -> Void
    
    func setExceptionHandler(handler: ((JSContext?, [String: String?]) -> Void)?)
    
    func setJSVMName(_ name: String)
    
    // 执行对应的js方法
    func invokeJavaScriptModule(methodName: String, moduleName: String?, params: [Any]?)
    
    // timer
    func setTimeOut(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void)
    
    func setTimeOut(functionID: NSInteger, time: NSInteger, runloop: RunLoop, callback: @escaping () -> Void)
    
    func setInterval(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void)
    
    func setInterval(functionID: NSInteger, time: NSInteger, runloop: RunLoop, callback: @escaping () -> Void)
    
    func clearTimeout(functionID: NSInteger)
    
    func clearInterval(functionID: NSInteger)
    
    func registerJSModule(_ jsModule: JSModule.Type, _ param: Any) -> Void
    
    func terminate()
}

#if ALPHA
fileprivate let logger = Logger.log(LarkJSEngineProtocol.self, category: "LarkJSEngineProtocol")
#endif

public extension LarkJSEngineProtocol {
    func registerJSModule(_ jsModule: JSModule.Type, _ param: Any) {
        #if ALPHA
        logger.error("LarkJSEngineProtocol registerJSModule function not override!")
        #endif
    }
    
    func terminate() {
        #if ALPHA
        logger.error("LarkJSEngineProtocol terminate function not override!")
        #endif
    }
    
    
    func setTimeOut(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void) {
        jsTimer?.setTimeOut(functionID: functionID, time: time, queue: queue, callback: callback)
    }
    
    func setTimeOut(functionID: NSInteger, time: NSInteger, runloop: RunLoop, callback: @escaping () -> Void) {
        jsTimer?.setTimeOut(functionID: functionID, time: time, runLoop: runloop, callback: callback)
    }
    
    func setInterval(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void) {
        jsTimer?.setInterval(functionID: functionID, time: time, queue: queue, callback: callback)
    }
    
    func setInterval(functionID: NSInteger, time: NSInteger, runloop: RunLoop, callback: @escaping () -> Void) {
        jsTimer?.setInterval(functionID: functionID, time: time, runLoop: runloop, callback: callback)
    }
    
    func clearTimeout(functionID: NSInteger) {
        jsTimer?.clearTimeout(functionID: functionID)
    }
    
    func clearInterval(functionID: NSInteger) {
        jsTimer?.clearInterval(functionID: functionID)
    }
}
