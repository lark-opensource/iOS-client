//
//  MeetingType.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VideoChatInfo.TypeEnum
public enum MeetingType: Int, Hashable, Codable {

    /// 未知状态，向后兼容
    case unknown // = 0

    /// 1v1 视频通话
    case call // = 1

    /// 多人视频会议
    case meet // = 2
}

/// Videoconference_V1_VideoChatSettings.SubType
public enum MeetingSubType: Int, Hashable, Codable {

    case `default` = 0 // = 0

    /// 单人共享屏幕会议
    case screenShare = 1 // = 1

    /// 有线投屏会议
    case wiredScreenShare = 2 // = 2

    /// 共享内容投屏会议，目前后端和Rust已不再使用，而用screenShare统一表示“本地投屏会议”
    case followShare = 3 // = 3

    /// 聊天室会议
    case chatRoom = 4 // = 4

    /// 飞阅会
    case samePageMeeting = 5 // = 5

    /// 企业办公电话 1v1 会议
    case enterprisePhoneCall = 6 // = 6

    /// 网络研讨会
    case webinar = 8 // = 8
}

extension MeetingType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .call:
            return "call"
        case .meet:
            return "meet"
        }
    }
}

extension MeetingSubType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .default:
            return "default"
        case .screenShare:
            return "screenShare"
        case .wiredScreenShare:
            return "wiredScreenShare"
        case .followShare:
            return "followShare"
        case .chatRoom:
            return "chatRoom"
        case .samePageMeeting:
            return "samePageMeeting"
        case .enterprisePhoneCall:
            return "enterprisePhoneCall"
        case .webinar:
            return "webinar"
        }
    }
}
