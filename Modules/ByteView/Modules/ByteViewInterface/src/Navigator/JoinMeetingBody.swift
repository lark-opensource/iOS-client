//
//  JoinMeetingBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/29.
//

import Foundation

/// 加入会议, /client/byteview/joinmeeting
public struct JoinMeetingBody: CodablePathBody {
    public static let path: String = "/client/byteview/joinmeeting"

    public enum IdType: String, Codable {
        case meetingId = "meeting_id"
        case number = "number"
        case group = "group"
        case interview = "interview"
        case openPlatform = "open_platform"
    }
    // id和idType所有场景必选
    public let id: String
    public let idType: IdType

    // 必选
    public let entrySource: VCMeetingEntry
    // meetingId、group 入会必选
    public let isFromSecretChat: Bool

    // 仅group入会使用
    public let isStartMeeting: Bool
    public var isE2Ee: Bool

    // meetintId入会必选
    public var topic: String?
    public var chatId: String?
    public var messageId: String?

    // 面试入会角色
    public var role: JoinMeetingRole?

    // 开放平台入会
    public var preview: Bool?       // 开放平台，必选
    public var mic: Bool?
    public var speaker: Bool?
    public var camera: Bool?

    // meetingSubtype == webinar
    // 用于 preview 页面异化 webinar 会议类型
    public var meetingSubtype: Int?

    public init(id: String, idType: IdType, isFromSecretChat: Bool = false, isE2Ee: Bool = false, isStartMeeting: Bool = false, entrySource: VCMeetingEntry, topic: String? = nil, chatId: String? = nil, messageId: String? = nil, role: JoinMeetingRole? = nil, preview: Bool? = nil, mic: Bool? = nil, speaker: Bool? = nil, camera: Bool? = nil, meetingSubtype: Int? = nil) {
        self.id = id
        self.idType = idType
        self.isFromSecretChat = isFromSecretChat
        self.isE2Ee = isE2Ee
        self.entrySource = entrySource
        self.topic = topic
        self.chatId = chatId
        self.messageId = messageId
        self.isStartMeeting = isStartMeeting
        self.role = role
        self.preview = preview
        self.mic = mic
        self.speaker = speaker
        self.camera = camera
        self.meetingSubtype = meetingSubtype
    }
}

extension JoinMeetingBody: CustomStringConvertible {
    public var description: String {
        "JoinMeetingBody(id: \(id), idType: \(idType), isFromSecretChat: \(isFromSecretChat), entrySource: \(entrySource), isStartMeeting: \(isStartMeeting), isE2Ee: \(isE2Ee), chatId: \(chatId ?? ""), messageId: \(messageId ?? ""), role: \(role?.description ?? ""), preview: \(String(describing: preview)), mic: \(String(describing: mic)), speaker: \(String(describing: speaker)), camera: \(String(describing: camera)), meetingSubtype: \(String(describing: meetingSubtype)))"
    }
}

/// [使用随机字符串定义面试角色](https://bytedance.feishu.cn/space/doc/doccnn0aCvc9B4MuVBDikgkgdMf#97gORe)
public enum JoinMeetingRole: String, Codable, CustomStringConvertible {
    case interviewee = "6wk88xnu"
    case interviewer = "tndfsgb5"

    public var description: String {
        switch self {
        case .interviewee:
            return "interviewee"
        case .interviewer:
            return "interviewer"
        }
    }
}
