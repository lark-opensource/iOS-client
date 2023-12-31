//
//  MeetingAttributes.swift
//  ByteViewWidget
//
//  Created by shin on 2023/2/13.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

#if swift(>=5.7.1)
import ActivityKit

@available(iOS 16.1, *)
public struct MeetingAttributes: ActivityAttributes {
    public typealias ContentState = MeetingContentState
    /// 会议 ID
    public var meetingID: String
}
#endif

/// 会议状态数据
public struct MeetingContentState: Codable, Hashable, CustomStringConvertible {
    /// 会议主题
    public var topic: String
    /// 会议提示文案
    public var tips: String
    /// 会议类型
    public var meetingType: MeetingType
    /// 正在讲话者
    public var speaker: String
    /// 当前网络状态
    public var networkStatus: MeetingNetworkStatus
    /// 头像 URL
    public var avatarURL: URL?
    /// meet 展示进行中模式
    public var isMeetOngoing: Bool?

    public init(topic: String,
                tips: String,
                meetingType: MeetingType = .unknown,
                speaker: String,
                networkStatus: MeetingNetworkStatus = .normal,
                avatarURL: URL? = nil,
                isMeetOngoing: Bool? = nil)
    {
        self.topic = topic
        self.tips = tips
        self.meetingType = meetingType
        self.speaker = speaker
        self.networkStatus = networkStatus
        self.avatarURL = avatarURL
        self.isMeetOngoing = isMeetOngoing
    }

    public var description: String {
        "meetingType: \(meetingType), networkStatus: \(networkStatus), avatar: \(avatarURL), isMeetOngoing: \(isMeetOngoing)"
    }
}

public enum MeetingType: Codable, Hashable, Equatable {
    /// 未知类型
    case unknown

    /// 音频 1v1
    case vocie

    /// 视频 1v1
    case video

    /// 会议
    case meet
}

public enum MeetingNetworkStatus: Codable, Hashable, Equatable {
    /// 网络正常，不展示
    case normal

    /// 断网，信号零格带红 ❌
    case disconnected

    /// 网络差，信号一格红色
    case bad

    /// 弱网，信号两格黄色
    case weak
}

public struct AlertConfig {
    public var title: String
    public var body: String
    public var sound: String?

    public init(title: String, body: String, sound: String? = nil) {
        self.title = title
        self.body = body
        self.sound = sound
    }

#if swift(>=5.7.1)
    @available(iOS 16.1, *)
    public func alertConfiguration() -> AlertConfiguration {
        let title = LocalizedStringResource(stringLiteral: self.title)
        let body = LocalizedStringResource(stringLiteral: self.body)
        let sound: AlertConfiguration.AlertSound = self.sound != nil ? .named(self.sound!) : .default
        return AlertConfiguration(title: title, body: body, sound: sound)
    }
#endif
}

public struct MeetingWidgetData {
    public typealias MeetingStatus = MeetingContentState
    /// 会议 ID
    public var meetingID: String

    public init(meetingID: String) {
        self.meetingID = meetingID
    }

#if swift(>=5.7.1)
    @available(iOS 16.1, *)
    public func activityAttributes() -> MeetingAttributes {
        MeetingAttributes(meetingID: meetingID)
    }
#endif
}
