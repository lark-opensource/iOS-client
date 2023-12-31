//
//  CheckInterviewMeetingPromotionRequest.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2022/12/12.
//

import Foundation
import ServerPB

/// - ServerPB_Videochat_CheckInterviewMeetingPromotionRequest
public struct CheckInterviewMeetingPromotionRequest {
    public typealias Response = CheckInterviewMeetingPromotionResponse
    public static let command: NetworkCommand = .server(.checkInterviewMeetingPromotion)

    public init(meetingID: String, userID: String) {
        self.meetingID = meetingID
        self.userID = userID
    }

    public var meetingID: String
    public var userID: String
}

public struct CheckInterviewMeetingPromotionResponse {
    public var url: String?
}

extension CheckInterviewMeetingPromotionRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_CheckInterviewMeetingPromotionRequest
    func toProtobuf() throws -> ServerPB_Videochat_CheckInterviewMeetingPromotionRequest {
        var request = ProtobufType()
        request.meetingID = self.meetingID
        request.userID = self.userID
        return request
    }
}

extension CheckInterviewMeetingPromotionResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_CheckInterviewMeetingPromotionResponse
    init(pb: ServerPB_Videochat_CheckInterviewMeetingPromotionResponse) throws {
        self.url = pb.hasURL ? pb.url : nil
    }
}
