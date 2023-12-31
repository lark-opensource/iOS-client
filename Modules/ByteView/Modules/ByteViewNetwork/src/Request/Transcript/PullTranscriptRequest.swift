//
//  PullTranscriptRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2023/6/21.
//

import Foundation
import RustPB

/// PULL_TRANSCRIPT = 89532
public struct PullTranscriptRequest {
    public static let command: NetworkCommand = .rust(.pullTranscript)
    public typealias Response = PullTranscriptResponse

    public init(meetingID: String, isForward: Bool, batchID: Int64?, count: Int64) {
        self.meetingID = meetingID
        self.isForward = isForward
        self.batchID = batchID
        self.count = count
    }

    public var meetingID: String
    public var isForward: Bool
    public var batchID: Int64?
    public var count: Int64

}

public struct PullTranscriptResponse {
    public init(transcripts: [MeetingSubtitleData], meetingID: String, hasMore: Bool) {
        self.transcripts = transcripts
        self.meetingID = meetingID
        self.hasMore = hasMore
    }

    public var transcripts: [MeetingSubtitleData]

    public var meetingID: String

    public var hasMore: Bool
}


extension PullTranscriptRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_PullTranscriptRequest

    func toProtobuf() throws -> Videoconference_V1_PullTranscriptRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.isForward = isForward
        if let batchID = self.batchID {
            request.batchID = batchID
        }
        return request
    }
}

extension PullTranscriptResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_PullTranscriptResponse

    init(pb: RustPB.Videoconference_V1_PullTranscriptResponse) throws {
        self.meetingID = pb.meetingID
        self.hasMore = pb.hasMore_p
        self.transcripts = pb.transcriptList.map({ $0.vcType })
    }

}
