//
//  File.swift
//  OPJSEngine
//
//  Created by bytedance on 2022/11/8.
//

import Foundation
import vmsdk
import LarkJSEngine
import LKCommonsLogging

@objc
final class OPLoadDynamicComponentVmSdkModule: NSObject, LarkVmSdkJSModule {
    static let logger = Logger.log(OPLoadDynamicComponentVmSdkModule.self, category: "OPLoadDynamicComponentVmSdkModule")

    required override init() { //inherit from LarkVmSdkJSModule=>JSModule=>NSObject
        super.init()
    }
    
    required init(param: Any) { //inherit from LarkVmSdkJSModule=>JSModule
        guard let param_arr = param as? [Any] else {
            Self.logger.error("param convert to array fail, init fail")
            assertionFailure("OPLoadDynamicComponentVmSdkModule init failed! param convert to array fail")
            super.init()
            return
        }
        guard param_arr.count > 1 else {
            Self.logger.error("param length less than 2, init fail")
            assertionFailure("OPLoadDynamicComponentVmSdkModule init failed! param length less than 2")
            super.init()
            return
        }
        
        self.loadDynamicComponent = param_arr[0] as? any OPJSLoadDynamicComponent
        self.jsRuntime = param_arr[1] as? GeneralJSRuntime
        super.init()
    }
    

    @objc static var name: String {
        return "OPLoadDynamicComponentVmSdkModule"
    }
    
    @objc static var methodLookup: [String: String] {
        return [
            "loadPluginScript": NSStringFromSelector(#selector(loadPluginScript(pluginID:version:scriptPath:)))
        ]
    }
    
    private weak var loadDynamicComponent : OPJSLoadDynamicComponent?

    private weak var jsRuntime : GeneralJSRuntime?
    
    @objc func loadPluginScript(pluginID: NSString, version: NSString, scriptPath: NSString) -> Any? {
        guard let loadDynamicComponent = jsRuntime?.loadDynamicComponentHandler else {
            Self.logger.error("loadDynamicComponent is nil, pluginID: \(pluginID), version:\(version), scriptPath: \(scriptPath)")
            return nil
        }
        return loadDynamicComponent.loadPluginScript(pluginID: pluginID, version: version, scriptPath: scriptPath)
    }

    func setup() {
    }
}
