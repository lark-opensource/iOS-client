//
//  OPJSBridgeModule.swift
//  TTMicroApp
//
//  Created by yi on 2021/12/16.
//

import Foundation
import LKCommonsLogging
import ECOInfra
import JavaScriptCore

// js bridge的module，负责注入jsvm的一些函数和变量
public final class OPJSBridgeModule: NSObject, GeneralJSRuntimeModuleProtocol {
    static let logger = Logger.log(OPJSBridgeModule.self, category: "OPJSEngine")
    public weak var jsRuntime: GeneralJSRuntime?

    public override init() {
        super.init()
    }

    public func runtimeLoad() // js runtime初始化
    {
        setupAppContext()
    }

    public func runtimeReady()
    {

    }

    func setupAppContext() {
        guard let jsRuntime = jsRuntime else {
            Self.logger.error("setupAppContext fail, jsRuntime is nil")
            return
        }

        if !jsRuntime.runtimeType.isVMSDK() {
            // 统一bridge注入，invokeNative为js->native逻辑层，publish为js->native渲染层（通过fireEvent实现）
            // ttjscore的注入
            let coreJSContextKey: NSString = "ttJSCore"
            let ttjscore = OPJSBridgeModuleTTJSCore(jsRuntime: jsRuntime)
            jsRuntime.jsvmModule.setObject(ttjscore, forKeyedSubscript: coreJSContextKey)
            
            let messageHandlerJSContextKey: NSString = "webkit"
            let messageHandler = OPJSBridgeModuleMessageHandlers(jsRuntime: jsRuntime)
            jsRuntime.jsvmModule.setObject(messageHandler, forKeyedSubscript: messageHandlerJSContextKey)
        }
    }
}
