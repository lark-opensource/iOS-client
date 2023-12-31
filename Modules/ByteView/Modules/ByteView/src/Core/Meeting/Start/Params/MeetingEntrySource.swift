//
//  MeetingEntrySource.swift
//  ByteView
//
//  Created by kiri on 2023/6/20.
//

import Foundation

public struct MeetingEntrySource: RawRepresentable, ExpressibleByStringLiteral, Equatable, Codable, CustomStringConvertible {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public var description: String { rawValue }

    /// 通讯录卡片
    static let addressBookCard = MeetingEntrySource(rawValue: "user_profile")
    /// 日历详情页
    static let calendarDetails = MeetingEntrySource(rawValue: "calendar_detail")
    /// 日程会议入会提醒
    static let calendarPrompt = MeetingEntrySource(rawValue: "calendar_reminder")
    /// 群下方加号
    static let groupPlus = MeetingEntrySource(rawValue: "group_plus")
    /// 独立tab
    static let independTab = MeetingEntrySource(rawValue: "independ_tab")
    /// 面试会议
    static let interview = MeetingEntrySource(rawValue: "interview")
    /// 开放平台
    static let openPlatform1v1 = MeetingEntrySource(rawValue: "openplatform_1v1")
    static let openPlatform = MeetingEntrySource(rawValue: "open_platform")
    static let handoff = MeetingEntrySource(rawValue: "handoff")


}
