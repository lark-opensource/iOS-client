//
//  TodoEditSource.swift
//  Todo
//
//  Created by 白言韬 on 2021/4/30.
//

import Foundation
import TodoInterface

indirect enum TodoEditSource {
    /// 列表页
    case list(needLoading: Bool)
    /// 任务助手-普通提醒卡片
    case bot(messageId: String)
    /// 任务助手-每日提醒卡片
    case dailyReminder(messageId: String)
    /// 分享卡片
    case share(chatId: String, messageId: String)
    /// 会话内任务列表
    case chatTodo(chatId: String, messageId: String)
    /// appLink
    case appLink(authScene: DetailAppLinkScene, authId: String?)
    /// 路由
    case body(source: TodoDetailBody.SourceType)
    /// 重复
    case rrule(source: TodoEditSource)
    /// 父任务
    case ancestor
    /// 子任务列表
    case subTasks
    // 动态
    case activity
    // 依赖
    case dependent
}

enum DetailAppLinkScene: Int {
    /// applink 的授权参数没有要求强制填写，当没有传授权参数时，会被处理为 unknown
    case unknown = 0
    case message = 1
}

struct TodoEditCallbacks {
    /// 编辑回调：详情页采用实时保存，每次保存的时候都会调用本回调
    var updateHandler: ((Rust.Todo) -> Void)?
    /// 当自己是任务的创建者，真正的「删除」任务时，会调用本回调
    var deleteHandler: ((Rust.Todo) -> Void)?
}

extension TodoEditSource {

    var authScene: Rust.DetailAuthScene? {
        var authScene = Rust.DetailAuthScene()
        switch self {
        case .share(_, let messageId), .chatTodo(_, let messageId):
            authScene.type = .message
            authScene.id = messageId
        case .bot(let messageId), .dailyReminder(let messageId):
            authScene.type = .message
            authScene.id = messageId
        case .appLink(let applinkScene, let authId):
            switch applinkScene {
            case .message:
                authScene.type = .message
                if let authId = authId {
                    authScene.id = authId
                }
            case .unknown:
                authScene.type = .default
            }
        case .rrule(let source):
            return source.authScene
        case .list, .body, .ancestor, .subTasks, .activity, .dependent:
            return nil
        }
        return authScene
    }

    var chatId: String? {
        switch self {
        case .list, .bot, .dailyReminder, .appLink, .body, .ancestor, .subTasks, .activity, .dependent:
            return nil
        case .share(let chatId, _), .chatTodo(let chatId, _):
            return chatId
        case .rrule(let source):
            return source.chatId
        }
    }

    // 是不是需要展示loading，从列表也过来已完成需要loading,进行中不需要
    var showLoading: Bool {
        var showLoading = true
        if case .list(let needLoading) = self {
            showLoading = needLoading
        } else {
            showLoading = true
        }
        return showLoading
    }

}
