//
//  NotesAIConfig.swift
//  ByteViewSetting
//
//  Created by ByteDance on 2023/8/22.
//

import Foundation

// settings_key = notes_ai_config
// BOE https://cloud-boe.bytedance.net/appSettings-v2/detail/config/184993/detail/status
public struct NotesAIConfig: Decodable {
    /// 会议AI提示的ID
    public let vcPromptId: String
    /// 日历AI提示的ID
    public let calendarPromptId: String

    public static let `default` = NotesAIConfig(vcPromptId: "", calendarPromptId: "")
}
