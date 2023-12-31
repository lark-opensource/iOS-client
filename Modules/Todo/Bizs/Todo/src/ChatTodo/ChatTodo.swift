//
//  ChatTodo.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/28.
//

import Foundation
import LKCommonsLogging
import LKCommonsTracker

struct ChatTodo { }

// MARK: - Logger

extension ChatTodo {
    static let logger = Logger.log(Setting.self, category: "Todo.ChatTodo")
}

// MARK: - Assert

extension ChatTodo {

    enum AssertType: String {
        /// 未定义（默认）
        case `default`
        /// 根据 cell 找 indexpath 时失败
        case findIndexPath
        /// 检验 indexpath 是否越界时失败
        case unwrapIndexPath
    }

    // nolint: long parameters
    static func assert(
        _ condition: @autoclosure () -> Bool,
        _ message: @autoclosure () -> String = String(),
        type: AssertType = .default,
        extra: [AnyHashable: Any] = .init(),
        file: String = #fileID,
        line: Int = #line
    ) {
        guard !condition() else { return }
        let msg = message()
        ChatTodo.logger.error("msg: \(msg), type: \(type), extra: \(extra)", file: file, line: line)
        let assertConfig = AssertReporter.AssertConfig(scene: "chat_todo", event: type.rawValue)
        AssertReporter.report(msg, extra: extra, config: assertConfig, file: file, line: line)
        Swift.assertionFailure()
    }
    // enable-lint: long parameters

    static func assertionFailure(
        _ message: @autoclosure () -> String = String(),
        type: AssertType = .default,
        extra: [AnyHashable: Any] = .init(),
        file: String = #fileID,
        line: Int = #line
    ) {
        self.assert(false, message(), type: type, extra: extra, file: file, line: line)
    }

}

// MARK: - Model

enum ChatTodoSectionType {
    case newCreated
    case assignToMe
    case assignToOther
    case completed
}

extension ChatTodoSectionType {

    var titleStr: String {
        switch self {
        case .newCreated: return ""
        case .assignToMe: return I18N.Todo_Task_TasksAssignedToMe
        case .assignToOther: return I18N.Todo_Chat_OtherTasksTitle
        case .completed: return I18N.Todo_Task_TasksDone
        }
    }

}

final class ChatTodoListSection {
    var header: V3ListSectionHeaderData
    var items: [ChatTodoCellData]

    init(header: V3ListSectionHeaderData, items: [ChatTodoCellData]) {
        self.header = header
        self.items = items
    }
}
