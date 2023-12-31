//
//  OPAPIWebAppExtension.swift
//  EcosystemWeb
//
//  Created by baojianjun on 2023/7/12.
//

import Foundation
import ECOInfra
import OPFoundation
import LarkOpenAPIModel
import LarkOpenPluginManager
import TTMicroApp

import LarkContainer
import LKCommonsLogging

let getGadgetContext: (OpenAPIContext) throws -> GadgetAPIContext = { context in
    guard let gadgetContext = context.gadgetContext as? GadgetAPIContext else {
        throw OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage("gadgetContext is nil")
            .setErrno(OpenAPICommonErrno.unknown)
    }
    return gadgetContext
}

public final class OPAPIWebAppExtensionContainerImpl: OPAPIWebAppExtensionContainer {
    
    public init() {}
    
    public func register(into pluginManager: OpenPluginManager) {
        
        // session
        pluginManager.register(OpenAPISessionExtension.self) { _, context in
            OpenAPISessionExtensionWebAppImpl(gadgetContext: try getGadgetContext(context))
        }
        
        // monitorReport, 覆盖
        pluginManager.register(OpenAPIMonitorReportExtension.self) { resolver, context in
            try OpenAPIMonitorReportExtensionH5Impl(extensionResolver: resolver, context: context)
        }
        
        // getSystemInfo
        pluginManager.register(OpenAPIGetSystemInfoExtension.self) { resolver, context in
            try OpenAPIGetSystemInfoExtensionWebAppImpl(extensionResolver: resolver, context: context)
        }
        
        // getFilterFG
        pluginManager.register(OpenAPIGetFilterFGExtension.self) { resolver, context in
            try OpenAPIGetFilterFGExtensionWebAppImpl(extensionResolver: resolver, context: context)
        }
        
        // getChatIDsByOpenChatIDs
        pluginManager.register(OpenAPIChatIDExtension.self) { resolver, context in
            try OpenAPIChatIDExtensionWebAppImpl(extensionResolver: resolver, context: context)
        }
    }
}

final class OpenAPISessionExtensionWebAppImpl: OpenAPIExtensionApp, OpenAPISessionExtension {
    let gadgetContext: GadgetAPIContext
    
    init(gadgetContext: GadgetAPIContext) {
        self.gadgetContext = gadgetContext
    }
    
    func session() -> String {
        getSession() ?? ""
    }
    
    func sessionHeader() -> [String: String] {
        guard let session = getSession() else {
            return [:]
        }
        return [
            SessionKey.sessionType.rawValue: SessionKey.h5Session.rawValue,
            SessionKey.sessionValue.rawValue: session
        ]
    }
    
    func getSession() -> String? {
        // H5获取session的方式: engine.getSession()
        gadgetContext.session
    }
}

final class OpenAPIMonitorReportExtensionH5Impl: OpenAPIMonitorReportExtension {
    override func apiDisable() -> Bool {
        EMAFeatureGating.boolValue(forKey: EEFeatureGatingKeyGadgetWebAppApiMonitorReport)
    }
}
