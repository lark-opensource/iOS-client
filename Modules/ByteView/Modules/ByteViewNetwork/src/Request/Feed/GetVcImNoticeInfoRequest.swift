//
//  GetVcImNoticeInfoRequest.swift
//  ByteViewNetwork
//
//  Created by lutingting on 2022/9/20.
//

import Foundation
import RustPB

/// 获取vc主端事件全量数据
/// GET_VC_IM_NOTICE_INFO = 89218
/// Videoconference_V1_GetVcImNoticeInfoRequest
public struct GetVcImNoticeInfoRequest {
    public static let command: NetworkCommand = .rust(.getVcImNoticeInfo)
    public typealias Response = GetVcImNoticeInfoResponse

    public var timeZone: String

    public init() {
        self.timeZone = TimeZone.current.identifier
    }
}

/// Videoconference_V1_IMNoticeInfo
public struct IMNoticeInfo {

    public enum AttendeeStatus: Int, Hashable {
        case unknown = 0
        case needsAction = 1
        case accept = 2
        case tentative = 3
        case decline = 4
        case removed = 5
    }

    public var meetingId: String

    public var topic: String

    public var i18NDefaultTopic: I18nDefaultTopic

    public var meetingNumber: String

    public var startTime: Int64

    public var attendeeStatus: AttendeeStatus

    public var containsMultipleTenant: Bool

    public var sameTenantId: String

    public var isCrossWithKa: Bool

    public var version: Int32
    public var meetingSubType: MeetingSubType

    public var allParticipantTenant: [Int64]

    /// 会议来源: 用户发起、日程会议、面试会议
    public var meetingSource: Videoconference_V1_VideoChatInfo.MeetingSource

    /// 彩排状态
    public var rehearsalStatus: WebinarRehearsalStatusType

    /// 单独提供独立tab列表排序字段，避免排序需求变更
    public var sortTime: Int64

    /// 会中聊天群ID
    public var bindChatID: Int64

    /// 日程群ID
    public var calendarGroupID: Int64

    /// 视频会议助手botID
    public var videoBotID: Int64

    /// Basic_V1_VideoChatI18nDefaultTopic
    public struct I18nDefaultTopic: Equatable, Codable {
        public var i18NKey: String
    }
}

extension IMNoticeInfo: CustomStringConvertible {
    public var description: String {
        return String(indent: "IMNoticeInfo",
                      "meetingId: \(meetingId)",
                      "topic: \(topic.hash)",
                      "meetingNumber: \(meetingNumber)",
                      "startTime: \(startTime)",
                      "attendeeStatus: \(attendeeStatus)",
                      "containsMultipleTenant: \(containsMultipleTenant)",
                      "sameTenantId: \(sameTenantId)",
                      "isCrossWithKa: \(isCrossWithKa)",
                      "version: \(version)",
                      "meetingSubType: \(meetingSubType)",
                      "allParticipantTenant: \(allParticipantTenant)",
                      "meetingSource: \(meetingSource)",
                      "sortTime: \(sortTime)",
                      "bindChatID: \(bindChatID)",
                      "calendarGroupID: \(calendarGroupID)",
                      "videoBotID: \(videoBotID)",
                      "rehearsalStatus: \(rehearsalStatus)"
        )
    }
}

public struct GetVcImNoticeInfoResponse {
    public var imNoticeInfos: [IMNoticeInfo]

    public var downVersion: Int32
}


extension GetVcImNoticeInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVcImNoticeInfoRequest
    func toProtobuf() throws -> Videoconference_V1_GetVcImNoticeInfoRequest {
        var request = ProtobufType()
        request.timeZone = TimeZone.current.identifier
        return request
    }
}

extension GetVcImNoticeInfoResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVcImNoticeInfoResponse

    init(pb: Videoconference_V1_GetVcImNoticeInfoResponse) {
        self.imNoticeInfos = pb.imNoticeInfos.map({ $0.vcType })
        self.downVersion = pb.downVersion
    }
}
