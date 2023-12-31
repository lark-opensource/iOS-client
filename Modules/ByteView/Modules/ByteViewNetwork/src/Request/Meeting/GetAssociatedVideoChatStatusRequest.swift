//
//  GetAssociatedVideoChatStatusRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - GET_ASSOCIATED_VC_STATUS = 2341
/// - Videoconference_V1_GetAssociatedVideoChatStatusRequest
public struct GetAssociatedVideoChatStatusRequest {
    public static let command: NetworkCommand = .rust(.getAssociatedVcStatus)
    public typealias Response = GetAssociatedVideoChatStatusResponse

    public init(id: String, idType: VideoChatIdType) {
        self.id = id
        self.idType = idType
    }

    public var id: String

    public var idType: VideoChatIdType
}

/// 推送给端上的也是这个
/// - PUSH_ASSOCIATED_VC_STATUS = 2334
/// - Videoconference_V1_GetAssociatedVideoChatStatusResponse
public struct GetAssociatedVideoChatStatusResponse: Equatable {

    public var id: String

    public var idType: VideoChatIdType

    /// 数组是为了保持扩展性，将来可能支持某些群组允许开多个会议
    public var activeMeetingIds: [String]

    /// 后端返回是否有活跃
    public var hasActiveMeeting: Bool

    public var activeMeetingId: String? {
        if hasActiveMeeting, let meetingId = activeMeetingIds.first, !meetingId.isEmpty {
            return meetingId
        }
        return nil
    }
}

extension GetAssociatedVideoChatStatusRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetAssociatedVideoChatStatusRequest
    func toProtobuf() throws -> Videoconference_V1_GetAssociatedVideoChatStatusRequest {
        var request = ProtobufType()
        request.id = id
        request.idType = .init(rawValue: idType.rawValue) ?? .unknownIDType
        return request
    }
}

extension GetAssociatedVideoChatStatusResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetAssociatedVideoChatStatusResponse
    init(pb: Videoconference_V1_GetAssociatedVideoChatStatusResponse) throws {
        self.id = pb.id
        self.idType = .init(rawValue: pb.idType.rawValue) ?? .unknown
        self.activeMeetingIds = pb.activeMeetingIds
        self.hasActiveMeeting = pb.hasActiveMeeting_p
    }
}
