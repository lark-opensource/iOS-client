//
//  GetReservationRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - GET_RESERVATION = 89701
/// - ServerPB_Videochat_GetReservationRequest
public struct GetReservationRequest {
    public static let command: NetworkCommand = .server(.getReservation)
    public typealias Response = GetReservationResponse

    public init(id: String) {
        self.id = id
    }

    public var id: String
}

/// - ServerPB_Videochat_GetReservationResponse
public struct GetReservationResponse {

    public var id: String

    public var meetingNo: String

    public var pstnSipUserInfo: ReservationPstnSipUserInfo?
}

/// - ServerPB_Videochat_GetReservationResponse.
public struct ReservationPstnSipUserInfo {

    public var userID: String

    public var userType: ParticipantType

    public var avatarKey: String

    public var nickname: String
}

extension GetReservationRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetReservationRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetReservationRequest {
        var request = ProtobufType()
        request.id = self.id
        return request
    }
}

extension GetReservationResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetReservationResponse
    init(pb: ServerPB_Videochat_GetReservationResponse) throws {
        self.id = pb.id
        self.meetingNo = pb.meetingNo
        if let user = pb.meetingPreConfig.autoInvitedUsers.first, user.hasPstnSipUserInfo {
            let pstn = user.pstnSipUserInfo
            self.pstnSipUserInfo = .init(userID: user.userID, userType: .init(rawValue: user.userType.rawValue),
                                         avatarKey: pstn.avatar.key, nickname: pstn.nickname)
        }
    }
}
