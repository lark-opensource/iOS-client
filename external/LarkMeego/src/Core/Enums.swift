//
//  Enums.swift
//  LarkMeego
//
//  Created by shizhengyu on 2023/2/8.
//

import Foundation
import LarkModel
import LarkMeegoInterface

enum MessageContentType: String {
    case text
    case image
    case post
    case audio
    case media
    case file
}

enum EntryType {
    case createWorkItem(chat: Chat, messages: [Message]?, from: EntranceSource)
    case url

    var name: DiagnosisEntryName {
        switch self {
        case .createWorkItem(let chat, let messages, let from):
            return DiagnosisEntryName.entry(from: from)
        case .url:
            return DiagnosisEntryName.openUrl
        }
    }
}

enum HookURLQuery {
    enum ExternalQueryKey: String {
        // 飞书快捷应用打开某一个应用卡片的 url 参数
        case bdpLaunchQuery = "bdp_launch_query"
        // 飞书快捷应用打开某一个应用卡片携带的用于交换消息内容的唯一标识
        case triggerId = "__trigger_id__"
        // 从哪里打开 meego 落地页
        case meegoFrom = "meego_from"
        // 打开的 meego 目标场景
        case meegoScene = "meego_scene"
    }

    enum MeegoFrom: String {
        case shortcut = "shortcut"
    }

    enum MeegoScene: String {
        case createWorkItem = "create_work_item"
    }
}
