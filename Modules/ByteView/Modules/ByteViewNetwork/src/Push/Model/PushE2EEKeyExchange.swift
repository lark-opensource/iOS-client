//
//  PushE2EEKeyExchange.swift
//  ByteViewNetwork
//
//  Created by ZhangJi on 2023/4/24.
//

import Foundation
import ServerPB

/// 会议秘钥请求推送
/// - PUSH_E2EE_KEY_EXCHANGE = 2357
/// - ServerPB_Videochat_E2EEKeyExchange
public struct PushE2EEKeyExchange {
    /// 单次 exchange 的唯一标识
    public var operationID: String
    /// 会议 ID
    public var meetingID: String
    /// 发起时间，精度为 ms
    public var timestamp: Int64
    /// 请求入会的参会人
    public var peer: ByteviewUser
    /// 请求入会的参会人的 E2EE 加密参数
    public var keyParameter: E2EEKeyParameter
}

extension PushE2EEKeyExchange: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = ServerPB_Videochat_E2EEKeyExchange
    init(pb: ServerPB_Videochat_E2EEKeyExchange) {
        self.operationID = pb.operationID
        self.meetingID = pb.meetingID
        self.timestamp = pb.timestamp
        self.peer = pb.peer.byteViewUser
        self.keyParameter = pb.keyParameter.vcType
    }
}
