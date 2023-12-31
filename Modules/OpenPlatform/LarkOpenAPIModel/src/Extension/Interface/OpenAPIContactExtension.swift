//
//  OpenAPIContactExtension.swift
//  LarkOpenAPIModel
//
//  Created by baojianjun on 2023/8/15.
//

import Foundation
import ECOProbe
import ECOInfra

// MARK: Contact

open class OpenAPIContactExtension: OpenBaseExtension {
    
    final class AnyECONetworkServiceContext: ECONetworkServiceContext {
        func getTrace() -> OPTrace { OPTrace(traceId: "") }
    }
    
    open func requestParams(openid: String, ttcode: String) -> [String: String] { [:] }
    
    open func networkContext() -> ECONetworkServiceContext { AnyECONetworkServiceContext() }
    
    @OpenAPIRequiredExtension
    public var commonExtension: OpenAPICommonExtension
    
    @OpenAPIRequiredExtension
    public var sessionExtension: OpenAPISessionExtension
    
    public override var autoCheckProperties: [OpenAPIInjectExtension] {
        [_commonExtension, _sessionExtension]
    }
}

// MARK: ChatID

open class OpenAPIChatIDExtension: OpenBaseExtension {
    
    open func requestParams(openChatIDs: [String], ttcode: String) -> [String: Codable] { [:] }
    
    public func sessionHeader() -> [String: String] {
        var sessionHeader = sessionExtension.sessionHeader()
        let session = sessionExtension.session()
        sessionHeader["Cookie"] = "sessionKey=\(session)"
        return sessionHeader
    }
    
    open func sessionKey() -> String {
        "session"
    }
    
    @OpenAPIRequiredExtension
    public var sessionExtension: OpenAPISessionExtension
    
    public override var autoCheckProperties: [OpenAPIInjectExtension] {
        [_sessionExtension]
    }
}
