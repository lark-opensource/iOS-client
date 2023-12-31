//
//  GetParticipantListRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Videoconference_V1_GetParticipantListRequest
public struct GetParticipantListRequest {
    public static let command: NetworkCommand = .rust(.getParticipantList)
    public typealias Response = GetParticipantListResponse

    public var breakoutRoomId: String?

    public init(breakoutRoomId: String?) {
        self.breakoutRoomId = breakoutRoomId
    }
}

/// - Videoconference_V1_GetParticipantListResponse
public struct GetParticipantListResponse {

    public var userInfoList: [SubtitleUser]

    public var breakoutRoomId: String
}

extension GetParticipantListRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetParticipantListRequest
    func toProtobuf() throws -> Videoconference_V1_GetParticipantListRequest {
        var request = ProtobufType()
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutRoomID = id
        }
        return request
    }
}

extension GetParticipantListResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetParticipantListResponse
    init(pb: Videoconference_V1_GetParticipantListResponse) throws {
        self.userInfoList = pb.userInfoList.map({ $0.vcType })
        self.breakoutRoomId = pb.breakoutRoomID
    }
}
