//
//  PushSendMessageToRtcResponse.swift
//  ByteViewNetwork
//
//  Created by wangpeiran on 2022/3/3.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// RTC数据通道
/// - PUSH_SEND_MESSAGE_TO_RTC = 88889
/// - PushSendMessageToRtcResponse
public struct PushSendMessageToRtcResponse {
    public var messageContext: UInt8
    public var messageType: UInt8
    public var packet: Data
    public var requestId: String
}

extension PushSendMessageToRtcResponse: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_PushSendMessageToRtc
    init(pb: Videoconference_V1_PushSendMessageToRtc) {
        self.messageContext = UInt8(Int8(pb.messageContext))
        self.messageType = UInt8(Int8(pb.messageType))
        self.packet = pb.packet
        self.requestId = pb.requestID
    }
}
