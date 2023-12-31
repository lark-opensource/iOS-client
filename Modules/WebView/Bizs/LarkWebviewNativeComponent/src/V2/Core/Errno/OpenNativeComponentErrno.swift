//
//  OpenNativeComponentErrno.swift
//  LarkWebviewNativeComponent
//
//  Created by baojianjun on 2022/7/29.
//

import Foundation
import LarkOpenAPIModel

// MARK: - Component Enum

public enum OpenNativeComponentType: Int {
    case infra      = 00
    case input      = 01
    case textarea   = 02
    case video      = 03
    case map        = 04
    case camera     = 05
}

// MARK: - API Infra Domain

public enum OpenNativeAPIDomain: Int {
    case common         = 0
    case insert         = 1
    case update         = 2
    case delete         = 3
    case dispatchAction = 4
    case fireEvent      = 5
}

/// You should conform this protocol to use errno with apiDomain
public protocol OpenNativeComponentErrnoProtocol: OpenAPIErrnoProtocol {
    var componentDomain: OpenNativeComponentType { get }
    var apiDomain: OpenNativeAPIDomain { get }
}

extension OpenNativeComponentErrnoProtocol {
    public var bizDomain: Int { 90 }
    public var funcDomain: Int { componentDomain.rawValue }
}

public extension OpenNativeComponentErrnoProtocol {
    func errno() -> Int {
#if DEBUG
        let bizDomainRange = 10..<100
        let funcDomainRange = 0..<100
        let apiDomainRange = 0..<10
        let rawRange = 0..<100
        assert(bizDomainRange ~= bizDomain, "业务 code 范围 10 ～ 99")
        assert(funcDomainRange ~= funcDomain, "业务内细分 code 范围 00 ～ 99")
        assert(apiDomainRange ~= apiDomain.rawValue, "框架API code 范围 0 ～ 9")
        assert(rawRange ~= rawValue, "组件具体错误 code 00 ～ 99")
#endif
        return (bizDomain * 100 + funcDomain) * 1000 + apiDomain.rawValue * 100 + rawValue
    }
}

// MARK: - OpenAPIError extension

extension OpenAPIError {
    /// 适配旧的component error
    public func setNativeComponentError(_ error: OpenNativeComponentErrorProtocol) -> OpenAPIError {
        self.setMonitorCode(error.innerCode)
        if let errMsg = error.innerErrorMsg {
            self.setMonitorMessage(errMsg)
        }
        return self
    }
}

