//
//  MeetingTranscribeRequest.swift
//  ByteViewNetwork
//
//  Created by yangyao on 2023/6/15.
//

import Foundation
import RustPB
import ServerPB

public struct MeetingTranscribeRequest {
    public static let command: NetworkCommand = .server(.meetingTranscript)

    public init(meetingId: String, action: Action, requester: ByteviewUser? = nil, targetParticipant: ByteviewUser? = nil) {
        self.meetingId = meetingId
        self.action = action
        self.requester = requester
        self.targetParticipant = targetParticipant
    }

    public var meetingId: String

    public var action: Action

    /// 请求转录参会人
    public var requester: ByteviewUser?

    /// 主持人操作的目标参会人
    public var targetParticipant: ByteviewUser?

    /// ServerPB_Videochat_MeetingTranscriptRequest.Action
    public enum Action: Int {
        case unknown // = 0

        /// 开始转录
        case start // = 1

        /// 结束转录
        case stop // = 2

        /// 主持人接受参会人转录请求
        case hostAccept // = 3

        /// 主持人拒绝参会人转录请求
        case hostRefuse // = 4

        /// 参会人请求转录
        case participantRequestStart // = 5
    }
}

extension MeetingTranscribeRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_MeetingTranscriptRequest
    func toProtobuf() throws -> ServerPB_Videochat_MeetingTranscriptRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.action = .init(rawValue: action.rawValue) ?? .unknown
        if let user = requester {
            request.requester = user.serverPbType
        }
        return request
    }
}
