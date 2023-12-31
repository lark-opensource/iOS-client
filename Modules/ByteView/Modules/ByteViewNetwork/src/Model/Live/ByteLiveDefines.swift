//   
//   ByteDefines.swift
//   ByteViewNetwork
// 
//  Created by hubo on 2023/2/10.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//   


import Foundation

// ServerPB_Videochat_live_LivePermissionByteLive
public enum LivePermissionByteLive: Int, Hashable {
    case unknow // = 0
    /// 所有人可见
    case all // = 1
    /// 本企业可见
    case enterprise // = 2
    // chat，没有用
    case chat // = 3
    /// 指定用户可见
    case custom // = 4
    /// 其他
    case other // = 5

    public init(lp: LivePrivilege) {
        switch lp {
        case .unknown:
            self = .unknow
        case .anonymous:
            self = .all
        case .employee:
            self = .enterprise
        case .chat:
            self = .chat
        case .custom:
            self = .custom
        case .other:
            self = .other
        }
    }

    public var livePrivilege: LivePrivilege {
        switch self {
        case .unknow:
            return .unknown
        case .all:
            return .anonymous
        case .enterprise:
            return .employee
        case .chat:
            return .chat
        case .custom:
            return .custom
        case .other:
            return .other
        }
    }
}

/// ServerPB_Videochat_live_LiveBrand
public enum LiveBrand: Int, Hashable {
    case unknow // = 0
    case byteLive // = 1
    case larkLive // = 2
}
