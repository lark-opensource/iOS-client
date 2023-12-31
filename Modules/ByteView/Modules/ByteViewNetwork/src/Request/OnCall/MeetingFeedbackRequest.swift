//
//  MeetingFeedbackRequest.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2022/9/1.
//

import Foundation
import ServerPB

/// 视频会议反馈 VC_MEETING_FEEDBACK = 89467
/// - ServerPB_Videochat_MeetingFeedbackRequest
public struct MeetingFeedbackRequest {
    public static let command: NetworkCommand = .server(.vcMeetingFeedback)
    public typealias Response = MeetingFeedbackResponse

    public var problemType: String
    public var problemText: String

    public init(problemType: String, problemText: String) {
        self.problemType = problemType
        self.problemText = problemText
    }
}

/// - ServerPB_Videochat_MeetingFeedbackResponse
public struct MeetingFeedbackResponse {

    public enum Status: Int {
        case unknown = 0
        case success = 1
        case fail = 2
    }

    public var status: Status
    public var feedbackID: Int64
}

extension MeetingFeedbackRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_MeetingFeedbackRequest
    func toProtobuf() throws -> ServerPB_Videochat_MeetingFeedbackRequest {
        var request = ProtobufType()
        request.problemType = problemType
        request.problemText = problemText
        return request
    }
}

extension MeetingFeedbackResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_MeetingFeedbackResponse
    init(pb: ServerPB_Videochat_MeetingFeedbackResponse) throws {
        self.status = Status(rawValue: pb.status.rawValue) ?? Status.unknown
        self.feedbackID = pb.feedbackID
    }
}
