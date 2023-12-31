//
//  OPPluginManagerWebAppAdapter.swift
//  TTMicroApp
//
//  Created by yi on 2021/5/14.
//

import Foundation
import LarkOpenPluginManager
import ECOProbe
import OPSDK
import LarkOpenAPIModel
import LarkContainer

public final class OPPluginManagerWebAppAdapter: OPPluginManagerAdapter {
    private let webPM: OpenPluginManager
    @objc
    public convenience init(with engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
                type: OPAppType) {
        self.init(with: engine, type: type, bizDomain: .openPlatform)
    }
    
    // propertyWrapper修饰会导致link报objc-class-ref的错误，该类无法找到
    private var webAppExtensionContainer: OPAPIWebAppExtensionContainer?
    
    public override init(
        with engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol,
        type: OPAppType,
        bizDomain: OpenAPIBizDomain = .openPlatform,
        bizScene: String = "",
        developerConfig: (() -> [String: Any]?)? = nil,
        apiRegistrationFilter: ((String, [OpenAPIAccessConfig]) -> Bool)? = nil) {
        self.webPM = OpenPluginManager(bizDomain: .openPlatform,
                                    bizType: type.apiBizType,
                                    bizScene: bizScene,
                                    apiRegistrationFilter: apiRegistrationFilter)
        self.webAppExtensionContainer = LKResolver.shared.resolver.resolve(OPAPIWebAppExtensionContainer.self)
        super.init(with: engine, type: type, bizDomain: bizDomain)
        if let webAppExtensionContainer {
            webAppExtensionContainer.register(into: self.webPM)
            webAppExtensionContainer.register(into: self.pluginManager)
        }
    }
    
    @objc
    public func callAPI(method: BDPJSBridgeMethod, trace: OPTrace, engine: BDPEngineProtocol & BDPJSBridgeEngineProtocol, needAuth: Bool, callback: @escaping BDPJSBridgeCallback) {
        if needAuth {
            call(method: method, trace: trace, engine: engine, extra:nil, callback: callback)
        } else {
            call(pluginManager: webPM, method: method, trace: trace, engine: engine, callback: callback)
        }
    }
}
