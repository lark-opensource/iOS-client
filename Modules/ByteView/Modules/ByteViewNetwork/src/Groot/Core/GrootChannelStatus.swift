//
//  GrootChannelStatus.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public enum GrootChannelStatus: Int, Hashable {
    case unknown = 0
    case connecting // = 1
    case connected // = 2
    case unavailable // = 3

    /// 如果某个channel进入这个状态，客户端端收到通知后，如果客户端仍在订阅该channel，应该通过SEND_GROOT_CELLS响应一个空包，否则Groot会在5s后关闭该channel，用于客户端与Groot间的保活
    case willBeClosed // = 4
    case closed // = 5
}

extension GrootChannelStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .unavailable:
            return "unavailable"
        case .willBeClosed:
            return "willBeClosed"
        case .closed:
            return "closed"
        }
    }
}
