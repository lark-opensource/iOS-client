//
//  GetTranscriptParticipantListRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2023/6/26.
//

import Foundation
import RustPB

/// GET_TRANSCRIPT_PARTICIPANT_LIST       = 88026
public struct GetTranscriptParticipantListRequest {
    public static let command: NetworkCommand = .rust(.getTranscriptParticipantList)
    public typealias Response = GetTranscriptParticipantListResponse

    public init() {}
}

extension GetTranscriptParticipantListRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetTranscriptParticipantListRequest

    func toProtobuf() throws -> Videoconference_V1_GetTranscriptParticipantListRequest {
        return ProtobufType()
    }
}


public struct GetTranscriptParticipantListResponse {
    public var userInfoList: [SubtitleUser]
}

extension GetTranscriptParticipantListResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetTranscriptParticipantListResponse
    init(pb: Videoconference_V1_GetTranscriptParticipantListResponse) throws {
        self.userInfoList = pb.userInfoList.map { $0.vcType }
    }
}
