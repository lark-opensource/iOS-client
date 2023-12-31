//
//  WebSocketStatus.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 网络状态变化，会触发registerClientInfo拉取会议信息
/// - PUSH_WEB_SOCKET_STATUS = 5005
/// - Basic_V1_GetWebSocketStatusResponse
public struct GetWebSocketStatusResponse {
    public var status: WebSocketStatus
}

public enum WebSocketStatus: Int, Hashable {
    case unknown = 0
    case opening // = 1
    case success // = 2
    case close // = 3

    /// When receiving this status, client should display `ServiceUnvaliable`.
    case closedForLongTime // = 4
}

extension GetWebSocketStatusResponse: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Basic_V1_GetWebSocketStatusResponse
    init(pb: Basic_V1_GetWebSocketStatusResponse) {
        self.status = .init(rawValue: pb.status.rawValue) ?? .unknown
    }
}
