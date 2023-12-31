//
//  OpenNativeComponentErrno+Infra.swift
//  LarkWebviewNativeComponent
//
//  Created by baojianjun on 2022/7/29.
//

import Foundation

// MARK: - Infra Errno

extension OpenNativeComponentErrnoProtocol {
    public var componentDomain: OpenNativeComponentType { .infra }
}

enum OpenNativeInfraErrnoCommon: Int, OpenNativeComponentErrnoProtocol {
    
    var apiDomain: OpenNativeAPIDomain { .common }
    
    case internalError = 00
    
    var errString: String {
        switch self {
        case .internalError: fallthrough
        default:
            return "internalError"
        }
    }
}

public enum OpenNativeInfraErrnoInsert: Int, OpenNativeComponentErrnoProtocol {
    
    public var apiDomain: OpenNativeAPIDomain { .insert }
    
    case internalError = 00
    
    public var errString: String {
        switch self {
        case .internalError: fallthrough
        default:
            return "internalError"
        }
    }
}

enum OpenNativeInfraErrnoUpdate: Int, OpenNativeComponentErrnoProtocol {
    
    public var apiDomain: OpenNativeAPIDomain { .update }
    
    case internalError = 00
    
    public var errString: String {
        switch self {
        case .internalError: fallthrough
        default:
            return "internalError"
        }
    }
}

public enum OpenNativeInfraErrnoDispatchAction: Int, OpenNativeComponentErrnoProtocol {
    
    public var apiDomain: OpenNativeAPIDomain { .dispatchAction }
    
    case internalError = 00
    
    public var errString: String {
        switch self {
        case .internalError: fallthrough
        default:
            return "internalError"
        }
    }
}
