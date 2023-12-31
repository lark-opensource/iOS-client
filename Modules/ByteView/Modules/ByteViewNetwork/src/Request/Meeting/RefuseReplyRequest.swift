//
//  RefuseReplyRequest.swift
//  ByteViewNetwork
//
//  Created by wangpeiran on 2023/3/23.
//

import Foundation
import ServerPB

/// - commandID: 89317
/// - ServerPB_Videochat_RefuseReplyRequest
public struct RefuseReplyRequest {
    public static let command: NetworkCommand = .server(.refuseReply)
    public typealias Response = RefuseReplyResponse

    public init(meetingID: String, refuseReply: String, isSingleMeeting: Bool, inviterUserID: String) {
        self.meetingID = meetingID
        self.refuseReply = refuseReply
        self.isSingleMeeting = isSingleMeeting
        self.inviterUserID = inviterUserID
    }

    public var meetingID: String
    public var refuseReply: String
    public var isSingleMeeting: Bool
    public var inviterUserID: String
}

/// ServerPB_Videochat_RefuseReplyResponse
public struct RefuseReplyResponse {
    public var groupStatus: RefuseReplyGroupStatus
    public var singleStatus: RefuseReplySingleStatus

    public enum RefuseReplyGroupStatus: Int, Hashable {
        case groupSuccess // = 0
        case baseGroupFail // = 1
        ///会议结束
        case meetingEnd // = 2
        ///被邀请人离开
        case inviteIdle // = 3
    }

    public enum RefuseReplySingleStatus: Int, Hashable {
        case singleSuccess = 1 // = 1
        case baseSingleFail // = 2
    }
}

extension RefuseReplyRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_RefuseReplyRequest
    func toProtobuf() throws -> ServerPB_Videochat_RefuseReplyRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.refuseReply = refuseReply
        request.isSingleMeeting = isSingleMeeting
        request.inviterUserID = inviterUserID
        return request
    }
}

extension RefuseReplyResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_RefuseReplyResponse
    init(pb: ServerPB_Videochat_RefuseReplyResponse) throws {
        self.groupStatus = .init(rawValue: pb.groupStatus.rawValue) ?? .baseGroupFail
        self.singleStatus = .init(rawValue: pb.singleStatus.rawValue) ?? .baseSingleFail
    }
}
