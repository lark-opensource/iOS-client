//
//  GetGuestsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Videoconference_V1_PullParticipantInfoRequest
public struct GetGuestsRequest {
    public static let command: NetworkCommand = .rust(.pullParticipantInfo)
    public typealias Response = GetGuestsResponse

    public init(meetingId: String, users: [ByteviewUser]) {
        self.meetingId = meetingId
        self.users = users
    }

    public var meetingId: String

    public var users: [ByteviewUser]
}

/// - Videoconference_V1_PullParticipantInfoResponse
public struct GetGuestsResponse {

    public var guests: [Guest]
}

extension GetGuestsRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_PullParticipantInfoRequest
    func toProtobuf() throws -> Videoconference_V1_PullParticipantInfoRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.byteviewUsers = users.map { $0.pbType }
        return request
    }
}

extension GetGuestsResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_PullParticipantInfoResponse
    init(pb: Videoconference_V1_PullParticipantInfoResponse) throws {
        self.guests = pb.userInfos.map({ $0.toGuest() })
    }
}

private typealias PBByteViewUserInfo = Videoconference_V1_ByteViewUserInfo
private extension PBByteViewUserInfo {
    func toGuest() -> Guest {
        Guest(id: user.userID, type: user.userType.vcType, name: displayName, fullName: fullName, avatarKey: avatarKey)
    }
}
