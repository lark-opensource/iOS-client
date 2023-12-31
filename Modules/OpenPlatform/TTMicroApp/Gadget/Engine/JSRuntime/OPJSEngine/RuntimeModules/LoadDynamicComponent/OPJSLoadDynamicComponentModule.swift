//
//  OPJSLoadDynamicComponentModule.swift
//  TTMicroApp
//
//  Created by laisanpin on 2022/6/5.
//

import Foundation
import OPJSEngine
import LKCommonsLogging

public final class OPJSLoadDynamicComponentModule: NSObject, GeneralJSRuntimeModuleProtocol {
    static let logger = Logger.log(OPJSLoadDynamicComponentModule.self, category: "OPJSEngine")
    weak public var jsRuntime: GeneralJSRuntime?
    let loadDynamicComponentHandler = OPJSBridgeModulLoadDynamicComponent()
    public func runtimeLoad() {
        loadDynamicComponent()
    }

    public func runtimeReady() {}

    func loadDynamicComponent() {
        loadDynamicComponentHandler.jsRuntime = self.jsRuntime
        let loadDynamicComponent: (@convention(block) (NSString, NSString, NSString) -> Any?) = { [weak self] (pluginID, version, scriptPath) in
            guard let `self` = self else {
                Self.logger.error("new worker load dynamic component fail, self is nil")
                return nil
            }
            return self.loadDynamicComponentHandler.loadPluginScript(pluginID: pluginID, version: version, scriptPath: scriptPath)
        }

        Self.logger.info("new worker inject loadPluginScript to jsRuntime success")
        jsRuntime?.setObject(loadDynamicComponent,
                                forKeyedSubscript: "loadPluginScript" as NSString)
    }

}
