//
//  ReclaimHostRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 新增强制转移主持人接口
/// - VC_OWNER_FORCE_TRANSFER_HOST
/// - ServerPB_Videochat_ForceTransferHostRequest
public struct ReclaimHostRequest {
    public static let command: NetworkCommand = .server(.vcOwnerForceTransferHost)

    public init(meetingId: String) {
        self.meetingId = meetingId
    }

    /// 会议ID
    public var meetingId: String
}

extension ReclaimHostRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_ForceTransferHostRequest
    func toProtobuf() throws -> ServerPB_Videochat_ForceTransferHostRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        return request
    }
}
