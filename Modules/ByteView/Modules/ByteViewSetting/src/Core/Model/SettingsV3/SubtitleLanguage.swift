//
//  Subtitle.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/12.
//

import Foundation
import ByteViewNetwork

public extension PullVideoChatConfigResponse {

    var allSubtitleLanguages: [SubtitleLanguage] {
        var languages: [SubtitleLanguage] = [.notTranslated]
        if !subtitleLanguages.isEmpty {
            languages.append(contentsOf: subtitleLanguages)
        } else {
            languages.append(contentsOf: SubtitleLanguage.defaults)
        }
        return languages
    }

    var allSpokenLanguages: [SubtitleLanguage] {
        var languages: [SubtitleLanguage] = [.auto]
        if !spokenLanguages.isEmpty {
            languages.append(contentsOf: spokenLanguages)
        } else {
            languages.append(contentsOf: SubtitleLanguage.defaults)
        }
        return languages
    }

    /// 会议首位开启字幕的用户为其他参会人设置的默认口说语言列表
    var selectableSpokenLanguages: [SubtitleLanguage] {
        var languages: [SubtitleLanguage] = []
        if !spokenLanguages.isEmpty {
            languages.append(contentsOf: spokenLanguages)
        } else {
            languages.append(contentsOf: SubtitleLanguage.defaults)
        }
        return languages
    }
}

public extension PullVideoChatConfigResponse.SubtitleLanguage {

    static let defaultLanguage = PullVideoChatConfigResponse.SubtitleLanguage(language: "zh_cn", desc: I18n.View_G_Chinese)

    static let defaults: [PullVideoChatConfigResponse.SubtitleLanguage] = {
        let chinese = PullVideoChatConfigResponse.SubtitleLanguage(language: "zh_cn", desc: I18n.View_G_Chinese)
        let english = PullVideoChatConfigResponse.SubtitleLanguage(language: "en_us", desc: I18n.View_G_English)
        return [chinese, english]
    }()

    /// 与后端定义的特殊字符
    static let app = PullVideoChatConfigResponse.SubtitleLanguage(language: "default", desc: I18n.View_G_AppLanguage)

    /// 与后端定义的特殊字符，行为同"app"
    static let auto = PullVideoChatConfigResponse.SubtitleLanguage(language: "default", desc: I18n.View_G_SubtitlesAutomatic)

    /// 与后端定义的特殊字符
    static let notTranslated = PullVideoChatConfigResponse.SubtitleLanguage(language: "source", desc: I18n.View_G_DontTranslate)
}
