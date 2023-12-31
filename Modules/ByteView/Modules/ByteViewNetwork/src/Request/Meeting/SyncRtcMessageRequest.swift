//
//  SyncRtcMessageRequest.swift
//  ByteViewNetwork
//
//  Created by Prontera on 2022/1/6.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 新增RTC数据通道接口
/// ON_RTC_MESSAGE = 88888
/// Videoconference_V1_OnRtcMessageRequest
public struct SyncRtcMessageRequest {
    public static let command: NetworkCommand = .rust(.onRtcMessage)
    public init(packet: Data?, messageType: Int32, messageContext: Int32) {
        self.packet = packet
        self.messageType = messageType
        self.messageContext = messageContext
    }

    public var packet: Data?
    public var messageType: Int32
    public var messageContext: Int32
}

extension SyncRtcMessageRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_OnRtcMessageRequest
    func toProtobuf() throws -> Videoconference_V1_OnRtcMessageRequest {
        var request = ProtobufType()
        if let packet = packet {
            request.packet = packet
        }
        request.messageType = messageType
        request.messageContext = messageContext
        return request
    }
}
