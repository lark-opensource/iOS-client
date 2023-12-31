//
//  OPJSLoadScriptModule.swift
//  TTMicroApp
//
//  Created by yi on 2022/1/4.
//
// 前端loadScript实现
import Foundation
import OPJSEngine
import LKCommonsLogging

public final class OPJSLoadScriptModule: NSObject, GeneralJSRuntimeModuleProtocol {
    static let logger = Logger.log(OPJSLoadScriptModule.self, category: "OPJSEngine")
    weak public var jsRuntime: GeneralJSRuntime?
    let loadScriptModule = OPJSBridgeModuleLoadScript()
    public override init() {
        super.init()
    }

    public func runtimeLoad() {
        loadScript()

    }
    public func runtimeReady()
    {
    }

    func loadScript() {
        loadScriptModule.jsRuntime = self.jsRuntime
        let loadScript: (@convention(block) (NSString, NSArray) -> Any?) = { [weak self] (relativePath, requiredModules) in
            guard let `self` = self else {
                Self.logger.error("worker loadScript fail, self is nil")
                return nil
            }
            return self.loadScriptModule.loadScript(relativePath: relativePath, requiredModules: requiredModules)
        }
        jsRuntime?.setObject(loadScript,
                                forKeyedSubscript: "loadScript" as NSString)
    }
}
