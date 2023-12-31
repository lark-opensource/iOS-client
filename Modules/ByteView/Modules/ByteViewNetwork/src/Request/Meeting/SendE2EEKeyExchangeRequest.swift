//
//  SendE2EEKeyExchangeRequest.swift
//  ByteViewNetwork
//
//  Created by ZhangJi on 2023/4/24.
//

import Foundation
import RustPB

// ENCRYPT_AND_SEND_E2EE_KEY_EXCHANGE = 2358
// Videoconference_V1_EncryptAndSendE2EEKeyExchangeRequest
public struct SendE2EEKeyExchangeRequest {
    public static let command: NetworkCommand = .rust(.encryptAndSendE2EeKeyExchange)
    /// 单次 exchange 的唯一标识
    public var operationID: String
    /// 会议 ID
    public var meetingID: String
    /// 请求入会的参会人
    public var peer: ByteviewUser
    /// 发起时间，精度为 ms
    public var timestamp: Int64
    /// 不同版本的秘钥,当前只使用版本 0
    public var keys: [UInt64: E2EEKey] = [:]
    /// 请求入会的参会人的 E2EE 加密参数
    public var keyParameter: E2EEKeyParameter

    public init(exchangePush: PushE2EEKeyExchange, key: E2EEKey) {
        self.operationID = exchangePush.operationID
        self.meetingID = exchangePush.meetingID
        self.peer = exchangePush.peer
        self.timestamp = exchangePush.timestamp
        self.keyParameter = exchangePush.keyParameter
        self.keys = [0: key]
    }
}

extension SendE2EEKeyExchangeRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_EncryptAndSendE2EEKeyExchangeRequest
    func toProtobuf() throws -> RustPB.Videoconference_V1_EncryptAndSendE2EEKeyExchangeRequest {
        var request = ProtobufType()
        request.operationID = operationID
        request.meetingID = meetingID
        request.peer = peer.pbType
        request.timestamp = timestamp
        request.keys = keys.mapValues { $0.pbType }
        request.keyParameter = keyParameter.pbType
        return request
    }
}
