//
//  OPLoadScriptVmSdkModule.swift
//  OPJSEngine
//
//  Created by bytedance on 2022/11/8.
//

import Foundation
import vmsdk
import LarkJSEngine
import LKCommonsLogging

@objc
final class OPLoadScriptVmSdkModule: NSObject, LarkVmSdkJSModule {
    static let logger = Logger.log(OPLoadScriptVmSdkModule.self, category: "OPLoadScriptVmSdkModule")
    
    required init(param: Any) {
        guard let param_arr = param as? [Any] else {
            Self.logger.error("param convert to array fail, init fail")
            assertionFailure("OPLoadScriptVmSdkModule init failed! param convert to array fail")

            super.init()
            return
        }
        guard param_arr.count > 1 else {
            Self.logger.error("param length less than 2, init fail")
            assertionFailure("OPLoadScriptVmSdkModule init failed! param length less than 2")
            super.init()
            return
        }
        self.loadScriptHander = param_arr[0] as? any OPJSLoadScript
        self.jsRuntime = param_arr[1] as? GeneralJSRuntime
        super.init()
    }
    
    required override init() {
    }
    
    private weak var loadScriptHander : OPJSLoadScript?
    
    private weak var jsRuntime : GeneralJSRuntime?
    
    @objc static var name: String {
        return "LoadScriptModule"
    }
    
    @objc static var methodLookup: [String: String] {
        return [
            "loadScript": NSStringFromSelector(#selector(loadScript(relativePath:requiredModules:)))
        ]
    }
    
    @objc func loadScript(relativePath: NSString, requiredModules: NSArray) -> Any? {
        return loadScriptHander?.loadScript(relativePath: relativePath, requiredModules: requiredModules)
    }
    
    func setup() {
    }
}
