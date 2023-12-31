//
//  SyncTranscriptRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2023/7/2.
//

import Foundation
import RustPB

/// SYNC_TRANSCRIPT      = 88027
public struct SyncTranscriptRequest {
    public static let command: NetworkCommand = .rust(.syncTranscript)
    public typealias Response = SyncTranscriptResponse

    public var meetingID: String
    public var forceSync: Bool

    public init(meetingID: String, forceSync: Bool) {
        self.meetingID = meetingID
        self.forceSync = forceSync
    }
}

public struct SyncTranscriptResponse {

    public var meetingID: String

}

extension SyncTranscriptRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_SyncSubtitlesRequest

    func toProtobuf() throws -> Videoconference_V1_SyncSubtitlesRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.forceSync = forceSync
        return request
    }
}

extension SyncTranscriptResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_SyncSubtitlesResponse

    init(pb: Videoconference_V1_SyncSubtitlesResponse) throws {
        self.meetingID = pb.meetingID
    }
}
