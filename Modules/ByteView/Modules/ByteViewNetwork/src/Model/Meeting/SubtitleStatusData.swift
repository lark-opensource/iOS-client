//
//  SubtitleStatusData.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_InMeetingData.SubtitleStatusData
public struct SubtitleStatusData: Equatable {
    public init(isSubtitleOn: Bool, status: SubtitleStatus, globalSpokenLanguage: String,
                langDetectInfo: SubtitleStatusData.LangDetectInfo, firstOneOpenSubtitle: ByteviewUser,
                monitor: SubtitleStatusData.Monitor, breakoutRoomId: String) {
        self.isSubtitleOn = isSubtitleOn
        self.status = status
        self.globalSpokenLanguage = globalSpokenLanguage
        self.langDetectInfo = langDetectInfo
        self.firstOneOpenSubtitle = firstOneOpenSubtitle
        self.monitor = monitor
        self.breakoutRoomId = breakoutRoomId
    }

    public var status: SubtitleStatus

    public var langDetectInfo: SubtitleStatusData.LangDetectInfo

    public var firstOneOpenSubtitle: ByteviewUser

    public var isSubtitleOn: Bool

    public var globalSpokenLanguage: String

    public var monitor: SubtitleStatusData.Monitor

    public var breakoutRoomId: String

    public struct LangDetectInfo: Equatable {
        public init(type: LangDetectInfoType, language: String, languageKey: String,
                    detectedLanguage: String, detectedLanguageKey: String) {
            self.type = type
            self.language = language
            self.languageKey = languageKey
            self.detectedLanguage = detectedLanguage
            self.detectedLanguageKey = detectedLanguageKey
        }

        public var type: LangDetectInfoType

        /// 语种识别的语言
        public var detectedLanguage: String

        /// 语种识别的语言的i18n key
        public var detectedLanguageKey: String

        /// 当前语言
        public var language: String

        /// 当前语言的i18n key
        public var languageKey: String

        public enum LangDetectInfoType: Int, Hashable {

            case unknown // = 0

            /// 语种识别的语言与当前语言不匹配
            case mismatch // = 1

            /// 语种识别的语言不支持
            case unsupported // = 2
        }
    }

    public struct Monitor: Equatable {
        public init(reuseAsrTask: Bool?) {
            self.reuseAsrTask = reuseAsrTask
        }
        public var reuseAsrTask: Bool?
    }
}

public enum SubtitleStatus: Int, Hashable {
    case unknown // = 0

    /// 服务端开启实时字幕功能成功
    case openSuccess // = 1

    /// 服务端开启实时字幕功能失败
    case openFailed // = 2

    /// 服务端实时字幕功能出现不可恢复的异常
    case exception // = 3

    /// 服务端实时字幕功能出现可恢复的异常
    case recoverableException // = 4

    /// 服务端实时字幕功能恢复成功
    case recoverSuccess // = 5

    /// 服务端语种识别
    case langDetected // = 6

    /// 会议中第一次有人打开字幕
    case firstOpen // = 7

    /// 会议字幕状态变更
    case meetingSubtitleStatusChange // = 8

    /// 为所有人选择说话语言(会议维度)
    case applyGlobalSpokenLanguage // = 9
}

extension SubtitleStatusData: CustomStringConvertible {
    public var description: String {
        String(
            indent: "SubtitleStatusData",
            "isSubtitleOn: \(isSubtitleOn)",
            "status: \(status)",
            "globalSpokenLanguage: \(globalSpokenLanguage)",
            "firstOneOpenSubtitle: \(firstOneOpenSubtitle)",
            "langDetectInfo: \(langDetectInfo)"
        )
    }
}

extension SubtitleStatusData.LangDetectInfo: CustomStringConvertible {
    public var description: String {
        String(
            indent: "LangDetectInfo",
            "type: \(type)",
            "language: \(language)",
            "key: \(languageKey)",
            "detected: \(detectedLanguage)",
            "detectedKey: \(detectedLanguageKey)"
        )
    }
}
