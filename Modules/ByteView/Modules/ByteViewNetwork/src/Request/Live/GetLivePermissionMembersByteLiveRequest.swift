//
//  GetLivePermissionMembersByteLiveRequest.swift
//  ByteViewNetwork
//
//  Created by hubo on 2023/2/10.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB
import RustPB

/// - LIVE_MEETING_GET_PERMISSION_MEMBERS_BYTE_LIVE = 2396
/// - ServerPB_Videochat_live_GetLivePermissionMembersByteLiveRequest
public struct GetLivePermissionMembersByteLiveRequest {
    public typealias Response = GetLivePermissionMembersByteLiveResponse
    public static let command: NetworkCommand = .server(.liveMeetingGetPermissionMembersByteLive)

    public init(meetingId: String) {
        self.meetingId = meetingId
    }

    public var meetingId: String
}

/// ServerPB_Videochat_live_GetLivePermissionMembersByteLiveResponse
public struct GetLivePermissionMembersByteLiveResponse: Equatable {
    public var members: [LivePermissionMemberByteLive]
}

extension GetLivePermissionMembersByteLiveRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_live_GetLivePermissionMembersByteLiveRequest
    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.meetingID = meetingId
        return request
    }
}

extension GetLivePermissionMembersByteLiveResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_live_GetLivePermissionMembersByteLiveResponse
    init(pb: ProtobufType) throws {
        var realMembers: [LivePermissionMemberByteLive] = []
        for item in pb.members {
            realMembers.append(LivePermissionMemberByteLive(pb: item))
        }
        self.members = realMembers
    }
}
