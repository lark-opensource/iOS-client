//
//  ApplyDTMFRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - APPLY_DTMF
/// - ServerPB_Videochat_ApplyDTMFRequest
public struct ApplyDTMFRequest {
    public static let command: NetworkCommand = .server(.applyDtmf)

    public init(dtmfCmd: String, seqId: Int64, userId: String?, meetingId: String?) {
        self.dtmfCmd = dtmfCmd
        self.seqId = seqId
        self.userId = userId
        self.meetingId = meetingId
    }

    /// DTMF具体输入的字符串，不包括末尾的井号
    public var dtmfCmd: String

    /// DTMF序列号，从 1 开始计数自增， 每通电话独立计数
    public var seqId: Int64

    /// DTMF目标电话用户 ID, 每个请求只会操作一个目标电话用户
    public var userId: String?

    /// 会议 ID
    public var meetingId: String?
}

extension ApplyDTMFRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_ApplyDTMFRequest
    func toProtobuf() throws -> ServerPB_Videochat_ApplyDTMFRequest {
        var request = ProtobufType()
        request.dtmfCmd = dtmfCmd
        request.seqID = seqId
        if let userId = userId {
            request.userID = userId
        }
        if let meetingId = meetingId {
            request.meetingID = meetingId
        }
        return request
    }
}
