//
//  Detail.swift
//  Todo
//
//  Created by 张威 on 2020/11/11.
//

import LKCommonsLogging
import LKCommonsTracker
import TodoInterface
import RxSwift

struct Detail { }

extension Detail {
    enum SaveError: Error {
        case sdkError(Error)
    }
}

// MARK: - Comment Input

extension Detail {

    // keyboad view height 的估计值
    static let commentKeyboardEstimateHeight: CGFloat = 320

    enum CommentInputScene: Equatable, CustomDebugStringConvertible {
        case create
        case edit(commentId: String)
        case reply(parentId: String, rootId: String)

        var debugDescription: String {
            switch self {
            case .create:
                return "create"
            case .edit(let commentId):
                return "edit(commentId: \(commentId)"
            case let .reply(parentId, rootId):
                return "reply(parentId: \(parentId), rootId: \(rootId)"
            }
        }
    }

    typealias CommentInputContent = (
        richContent: Rust.RichContent,
        attachments: [Rust.Attachment],
        fileAttachments: [Rust.Attachment]
    )

}

typealias CommentInputScene = Detail.CommentInputScene
typealias CommentInputContent = Detail.CommentInputContent

// MARK: - Logger

extension Detail {
    static let logger = Logger.log(Detail.self, category: "Todo.Detail")
}

// MARK: - Assert

extension Detail {

    enum AssertType: String {
        /// 未定义（默认）
        case `default`
        /// 加载失败
        case loadFailed
        /// 新建失败
        case saveFailed
        /// 更新失败
        case updateFailed
        /// 删除失败
        case deleteFailed
        /// 完成/反完成失败
        case completeFailed
        /// 根据 cell 找 indexpath 时失败
        case findIndexPath
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
        Detail.logger.error("msg: \(msg), type: \(type), extra: \(extra)", file: file, line: line)
        let assertConfig = AssertReporter.AssertConfig(scene: "detail", event: type.rawValue)
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

// MARK: - Tracker

// swiftlint:disable identifier_name
// warn: 枚举名字会被直接作为name填充，不要轻易修改
enum DetailTrackerName: String {
    case todo_task_members_back
    case todo_task_history_back
    case todo_create_cancel
    case todo_task_close
    case todo_create_confirm
    case todo_create_share_to_chat_confrim
    case todo_create_share_to_chat_cancel
    case todo_task_history_click
    case todo_task_delete
    case todo_task_delete_confirm
    case todo_task_delete_cancel
    case todo_create_person_click
    case todo_task_members
    case todo_task_date_delete
    case todo_create_date_click
    case todo_create
    case todo_task_members_delete
    case todo_task_click
    case todo_create_date_select
    case todo_create_person_select
    case todo_task_members_add
    case todo_task_share
    case todo_add_performer
    case todo_send_to_conversation
    case todo_date_click
    case todo_title_at_somebody
    case todo_revoke_click
    case todo_im_multi_select_message_expand
    case todo_im_conversions_task
    case todo_click_back_to_dialog
    case todo_comment
    case todo_task_follow
    case todo_task_follow_cancel
    case todo_task_status_done
    case todo_task_status_not_done
    case todo_task_detail_view
    case todo_task_detail_click
}

extension Detail {
    static func tracker(_ name: DetailTrackerName, params: [AnyHashable: Any] = [:]) {
        Tracker.post(TeaEvent(name.rawValue, params: params))
    }
}

// MARK: - BizTracker
