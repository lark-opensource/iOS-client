//
//  CompleteService.swift
//  Todo
//
//  Created by 张威 on 2021/8/13.
//

import Foundation
import RxSwift
import LarkUIKit
import EENavigator
import LarkAccountInterface
import LarkContainer

/// 集中管理 Todo 的完成状态

// MARK: - CompleteService

protocol CompleteService: AnyObject {

    /// todo 的完成状态
    func state(for todo: Rust.Todo) -> CompleteState

    /// 翻转 todo 的完成状态
    func toggleState(with context: CompleteContext, todoId: String, todoSource: Rust.TodoSource, containerID: String?)
        -> Single<(newState: CompleteState, todo: Rust.Todo)>

    /// 根据完成状态更新 Todo
    func updateTodo(_ todo: inout Rust.Todo, to toState: CompleteState)

    /// 自定义完成
    func customComplete(from todo: Rust.Todo) -> CustomComplete?

    typealias DoubleCheckContext = (title: String, content: String, confirm: String)

    func doubleCheckBeforeToggleState(
        _ fromState: CompleteState,
        with role: CompleteRole,
        assignees: [Assignee]
    ) -> DoubleCheckContext?

    func doubleCheckBeforeToggleState(
        with role: CompleteRole,
        todo: Rust.Todo,
        hasContainerPermission: Bool
    ) -> DoubleCheckContext?

    func mergeCompleteState(_ fromState: CompleteState, with todoCompleted: Bool) -> CompleteState
}

// MARK: - CompleteState

extension CompleteService {

    /// 使用经典完成模式
    func useClassicMode(for todo: Rust.Todo) -> Bool {
        if case .classicMode = state(for: todo) {
            return true
        } else {
            return false
        }
    }

    /// 用户视角的完成时间（单位：秒）
    func userCompletedTime(for todo: Rust.Todo) -> Int64 {
        return todo.userCompletedTime(with: state(for: todo))
    }

}

typealias CompleteDoubleCheckContext = CompleteService.DoubleCheckContext

/// 完成状态
enum CompleteState: Equatable {
    /// 新完成策略

    /// 局外人（既不是执行者，又不是创建者）
    case outsider(isCompleted: Bool)
    /// 作为执行者
    case assignee(isCompleted: Bool)
    /// 作为创建者
    case creator(isCompleted: Bool)
    /// 双角色（创建者 + 执行者）
    case creatorAndAssignee(todo: Bool, self: Bool)

    /// 旧完成策略/经典模式

    /// - parameter isCompleted: 是否已完成
    /// - parameter isOutsider: 是否是局外人
    case classicMode(isCompleted: Bool, isOutsider: Bool)
}

extension CompleteState {

    /// 状态迁移：
    ///   - `outsider(todo: true/false)` <-> `outsider(todo: true/false)`
    ///   - `assignee(self: true)` <-> `assignee(self: false)`
    ///   - `creator(todo: true)` <-> `creator(todo: false)`
    ///   - `creatorAndAssignee(todo: true, self: yesOrNo)` <-> `creatorAndAssignee(todo: false, self: yesOrNo)`
    ///   - `creatorAndAssignee(todo: yesOrNo, self: true)` <-> `creatorAndAssignee(todo: yesOrNo, self: false)`
    ///
    ///   - `classicMode(true, false)` <-> `classicMode(false, false)`
    func toggled(by role: CompleteRole) -> CompleteState {
        switch self {
        case .outsider(let b):
            return .outsider(isCompleted: !b)
        case .assignee(let b):
            return .assignee(isCompleted: !b)
        case .creator(let b):
            return .creator(isCompleted: !b)
        case .creatorAndAssignee(let isTodoCompleted, let isSelfCompleted):
            switch role {
            case .`self`:
                return .creatorAndAssignee(todo: isTodoCompleted, self: !isSelfCompleted)
            case .todo:
                return .creatorAndAssignee(todo: !isTodoCompleted, self: isSelfCompleted)
            }
        case let .classicMode(isCompleted, isOutsider):
            return .classicMode(isCompleted: !isCompleted, isOutsider: isOutsider)
        }
    }

    /// 切换完成状态的 toast 文案，此处进行统一收敛
    func toggleSuccessToast(by role: CompleteRole) -> String? {
        switch self {
        case .outsider(let b):
            return b ? I18N.Todo_CollabTask_Successful : I18N.Todo_Task_TasksDone
        case .assignee(let b), .creator(let b):
            return b ? I18N.Todo_CollabTask_Successful : I18N.Todo_Task_TasksDone
        case .creatorAndAssignee(let isTodoCompleted, let isSelfCompleted):
            switch role {
            case .`self`:
                return isSelfCompleted ? I18N.Todo_CollabTask_Successful : I18N.Todo_Task_TasksDone
            case .todo:
                return isTodoCompleted ? I18N.Todo_CollabTask_Successful : I18N.Todo_Task_TasksDone
            }
        case let .classicMode(isCompleted, _):
            return isCompleted ? I18N.Todo_CollabTask_Successful : I18N.Todo_Task_TasksDone
        }
    }

}

extension CompleteState {
    var isCompleted: Bool {
        switch self {
        case .outsider(let b): return b
        case .assignee(let b): return b
        case .creator(let b): return b
        case .creatorAndAssignee(let b, _): return b
        case .classicMode(let b, _): return b
        }
    }
}

// MARK: - CustomComplete

enum CustomComplete {
    case url(URL, LarkContainer.UserResolver)
    case tip(String)
}

extension CustomComplete {

    func doAction(on vc: UIViewController) {
        switch self {
        case .url(let url, let userResolver):
            userResolver.navigator.present(
                url,
                wrap: LkNavigationController.self,
                from: vc,
                prepare: { $0.modalPresentationStyle = .formSheet }
            )
        case .tip(let tip):
            Utils.Toast.showWarning(with: tip, on: vc.view)
        }
    }
}

// MARK: - CompleteRole

enum CompleteRole: Int {
    case `self`
    case todo
}

// MARK: - CompleteContext

struct CompleteContext {
    var fromState: CompleteState
    var role: CompleteRole
    // 如果为 nil，则认为是当期用户
    var userId: String?
}
