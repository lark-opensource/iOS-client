//
//  DocumentUserPermission+ComposeAction.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/8/1.
//

import Foundation

extension DocumentUserPermission {

    func check(action: ComposeAction) -> Bool {
        switch action {
        case let .or(lhs, rhs):
            return check(action: lhs) || check(action: rhs)
        case let .and(lhs, rhs):
            return check(action: lhs) && check(action: rhs)
        case let .single(action):
            return check(action: action)
        }
    }

    func denyReason(for action: ComposeAction) -> DocumentPermissionDenyReason? {
        switch action {
        case let .or(lhs, rhs):
            if let reason = denyReason(for: lhs), denyReason(for: rhs) != nil {
                // 两个都失败了才返回，优先返回第一个条件的失败原因
                return reason
            }
            return nil
        case let .and(lhs, rhs):
            return denyReason(for: lhs) ?? denyReason(for: rhs)
        case let .single(action):
            return denyReason(for: action)
        }
    }

    func authReason(for action: ComposeAction) -> AuthReason? {
        switch action {
        case let .or(lhs, rhs),
            let .and(lhs, rhs):
            return authReason(for: lhs) ?? authReason(for: rhs)
        case let .single(action):
            return authReason(for: action)
        }
    }
}

extension DocumentUserPermission {

    /// 复合点位，由多个点位计算得到
    indirect enum ComposeAction: Equatable, CustomStringConvertible {
        case or(lhs: ComposeAction, rhs: ComposeAction)
        case and(lhs: ComposeAction, rhs: ComposeAction)
        case single(action: Action)

        var description: String {
            switch self {
            case let .or(lhs, rhs):
                return "(\(lhs.description)) | (\(rhs.description))"
            case let .and(lhs, rhs):
                return "(\(lhs.description)) & (\(rhs.description))"
            case let .single(action):
                return String(describing: action)
            }
        }

        static func &(lhs: ComposeAction, rhs: ComposeAction) -> ComposeAction {
            .and(lhs: lhs, rhs: rhs)
        }

        static func |(lhs: ComposeAction, rhs: ComposeAction) -> ComposeAction {
            .or(lhs: lhs, rhs: rhs)
        }

        static func &(lhs: Action, rhs: ComposeAction) -> ComposeAction {
            .and(lhs: .single(action: lhs), rhs: rhs)
        }

        static func &(lhs: ComposeAction, rhs: Action) -> ComposeAction {
            .and(lhs: lhs, rhs: .single(action: rhs))
        }

        static func |(lhs: Action, rhs: ComposeAction) -> ComposeAction {
            .or(lhs: .single(action: lhs), rhs: rhs)
        }

        static func |(lhs: ComposeAction, rhs: Action) -> ComposeAction {
            .or(lhs: lhs, rhs: .single(action: rhs))
        }

        // MARK: - 复合点位定义

        /// 可管理协作者
        static var manageCollaborator: ComposeAction {
            Action.manageContainerCollaborator | Action.manageSinglePageCollaborator
        }
        /// 可管理公共权限
        static var managePermissionMeta: ComposeAction {
            Action.manageContainerMeta | Action.manageSinglePageMeta
        }
        /// 更新 Base 时区
        static var updateTimeZone: ComposeAction {
            Action.preview & (Action.manageContainerMeta | Action.manageSinglePageMeta)
        }
        /// Drive 保存到本地 & 用其他应用打开
        static var openWithOtherApp: ComposeAction {
            Action.preview & Action.export
        }
    }
}
