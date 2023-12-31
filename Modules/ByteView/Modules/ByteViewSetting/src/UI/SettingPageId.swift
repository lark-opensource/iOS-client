//
//  SettingPageId.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation

public enum SettingPageId: String {
    case unknown
    /// 飞书-设置-视频会议
    case generalSetting
    /// 会中-设置
    case inMeetSetting
    /// 会中-安全
    case inMeetSecurity
    /// 日程设置
    case calendarSetting
    /// webinar日程设置
    case webinarCalendarSetting
    /// 传译员设置
    case interpreterSetting
    /// 问题反馈
    case feedback
    /// 问题反馈详情页
    case feedbackDetail
    /// 聊天翻译语言
    case chatLanguage
    /// 字幕翻译语言
    case subtitleLanguage
    /// 字幕口说语言
    case spokenLanguage
    /// 字幕设置
    case subtitleSetting
    /// 表情显示样式
    case reactionDisplayMode
}

extension SettingPageId: CustomStringConvertible {
    public var description: String { rawValue }
}
