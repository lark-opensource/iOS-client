//
//  RecordMeetingRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// RECORD_MEETING
/// ServerPB_Videochat_RecordMeetingRequest
public struct RecordMeetingRequest {
    public static let command: NetworkCommand = .server(.recordMeeting)

    public init(meetingId: String, action: Action, requester: ByteviewUser? = nil, targetParticipant: ByteviewUser? = nil) {
        self.meetingId = meetingId
        self.action = action
        self.requester = requester
        self.targetParticipant = targetParticipant
    }

    public var meetingId: String

    public var action: Action

    /// 主持人所在时区
    public let timeZone: String? = TimeZone.current.abbreviation()

    /// 请求录制参会人
    public var requester: ByteviewUser?

    /// 主持人操作的目标参会人
    public var targetParticipant: ByteviewUser?

    /// Videoconference_V1_RecordMeetingRequest.Action
    public enum Action: Int {
        /// 开始录制
        case start = 1

        /// 结束录制
        case stop // = 2

        /// 主持人接受参会人录制请求
        case hostAccept // = 3

        /// 主持人拒绝参会人录制请求
        case hostRefuse // = 4

        /// 参会人请求录制
        case participantRequestStart // = 5

        /// 参会人拒绝留在会中，合规开启时需要
        case participantConsentLeave // = 6

        /// 参会人留在会中，合规开启时需要
        case participantConsentStay // = 7

        /// 同意参会人本地录制
        case manageApproveLocalRecord = 13

        /// 拒绝参会人本地录制
        case manageRejectLocalRecord // = 14

        /// 授予参会人本地录制权限
        case manageAuthorizeLocalRecord // = 15

        /// 取消授予参会人本地录制权限
        case manageRevokeLocalRecord // = 16

        /// 关闭参会人的本地录制
        case manageStopLocalRecord // = 17
    }
}

extension RecordMeetingRequest: RustRequest {
    typealias ProtobufType = ServerPB_Videochat_RecordMeetingRequest
    func toProtobuf() throws -> ServerPB_Videochat_RecordMeetingRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.action = .init(rawValue: action.rawValue) ?? .unknown
        if let tz = timeZone {
            request.timeZone = tz
        }
        if let user = requester {
            request.requester = user.serverPbType
        }
        if let target = targetParticipant {
            request.targetParticipant = target.serverPbType
        }
        return request
    }
}
