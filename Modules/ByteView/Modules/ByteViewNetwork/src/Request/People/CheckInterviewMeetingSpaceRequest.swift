//
//  CheckInterviewMeetingSpaceRequest.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2023/6/6.
//

import Foundation
import ServerPB

/// - ServerPB_Videochat_CheckInterviewMeetingSpaceRequest
public struct CheckInterviewMeetingSpaceRequest {
    public typealias Response = CheckInterviewMeetingSpaceResponse
    public static let command: NetworkCommand = .server(.checkInterviewMeetingSpace)

    public init(meetingID: String) {
        self.meetingID = meetingID
    }

    public var meetingID: String
}

public struct CheckInterviewMeetingSpaceResponse {
    public var hasPermission: Bool
    public var url: String?
}

extension CheckInterviewMeetingSpaceRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_CheckInterviewMeetingSpaceRequest
    func toProtobuf() throws -> ServerPB_Videochat_CheckInterviewMeetingSpaceRequest {
        var request = ProtobufType()
        request.id = self.meetingID
        request.idType = .meetingID
        return request
    }
}

extension CheckInterviewMeetingSpaceResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_CheckInterviewMeetingSpaceResponse
    init(pb: ServerPB_Videochat_CheckInterviewMeetingSpaceResponse) throws {
        self.url = pb.hasURL ? pb.url : nil
        self.hasPermission = pb.hasPermission_p
    }
}
