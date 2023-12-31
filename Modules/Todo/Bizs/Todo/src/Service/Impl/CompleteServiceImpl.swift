//
//  CompleteServiceImpl.swift
//  Todo
//
//  Created by 张威 on 2021/8/13.
//

import LarkContainer
import RxSwift
import CTFoundation
import LKCommonsLogging
import LarkAccountInterface
import LarkLocalizations

class CompleteServiceImpl: CompleteService, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var completeApi: TodoOperateApi?

    private var currentUserId: String { userResolver.userID }
    let logger = Logger.log(RustApiImpl.self, category: "Todo.CompleteServiceImpl")

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func state(for todo: Rust.Todo) -> CompleteState {
        let selfAssignee = todo.assignees.first(where: { $0.assigneeID == currentUserId })
        let isOutsider = todo.creatorID != currentUserId && selfAssignee == nil
        guard todo.source != .doc, todo.mode != .taskComplete else {
            return .classicMode(isCompleted: todo.completedMilliTime > 0, isOutsider: isOutsider)
        }
        if isOutsider {
            return .outsider(isCompleted: todo.completedMilliTime > 0)
        }
        var todoCompletedTime: Int64?
        if currentUserId == todo.creatorID {
            todoCompletedTime = todo.completedMilliTime
        }
        // let selfCompletedTime: Int64? = selfAssignee?.completedMilliTime
        var selfCompletedTime: Int64?
        if let pb = selfAssignee, pb.type == .user, case .user(let u) = pb.assignee {
            selfCompletedTime = u.completedMilliTime
        }

        switch (todoCompletedTime, selfCompletedTime) {
        case (.none, .none):
            return .outsider(isCompleted: todo.completedMilliTime > 0)
        case (.none, .some(let selfCompletedTime)):
            return .assignee(isCompleted: selfCompletedTime > 0)
        case (.some(let todoCompletedTime), .none):
            return .creator(isCompleted: todoCompletedTime > 0)
        case (.some(let todoCompletedTime), .some(let selfCompletedTime)):
            return .creatorAndAssignee(todo: todoCompletedTime > 0, self: selfCompletedTime > 0)
        }
    }

    func toggleState(
        with context: CompleteContext,
        todoId: String,
        todoSource: Rust.TodoSource,
        containerID: String?
    ) -> Single<(newState: CompleteState, todo: Rust.Todo)> {
        var toState = context.fromState.toggled(by: context.role)
        guard let completeApi = completeApi else {
            logger.error("complete Api is nil")
            return .just((newState: toState, todo: .init()))
        }
        let userId = context.userId ?? currentUserId
        var observable: Observable<Rust.Todo>
        switch toState {
        case .outsider(let isCompleted):
            observable = isCompleted ?
                completeApi.markTodoAsCompleted(forId: todoId, source: todoSource, containerID: containerID)
                : completeApi.markTodoAsInProcess(forId: todoId, source: todoSource, containerID: containerID)
        case .assignee(let isCompleted):
            observable = isCompleted ?
                completeApi.markAssigneeAsCompleted(forId: userId, todoId: todoId, source: todoSource, containerID: containerID)
                : completeApi.markAssigneeAsInProcess(forId: userId, todoId: todoId, source: todoSource, containerID: containerID)
        case .creator(let isCompleted):
            observable = isCompleted ?
                completeApi.markTodoAsCompleted(forId: todoId, source: todoSource, containerID: containerID)
                : completeApi.markTodoAsInProcess(forId: todoId, source: todoSource, containerID: containerID)
        case .creatorAndAssignee(let isTodoCompleted, let isSelfCompleted):
            switch context.role {
            case .`self`:
                observable = isSelfCompleted ?
                    completeApi.markAssigneeAsCompleted(forId: userId, todoId: todoId, source: todoSource, containerID: containerID)
                : completeApi.markAssigneeAsInProcess(forId: userId, todoId: todoId, source: todoSource, containerID: containerID)
            case .todo:
                observable = isTodoCompleted ?
                    completeApi.markTodoAsCompleted(forId: todoId, source: todoSource, containerID: containerID)
                    : completeApi.markTodoAsInProcess(forId: todoId, source: todoSource, containerID: containerID)
            }
        case let .classicMode(isCompleted, _):
            observable = isCompleted ?
                completeApi.markTodoAsCompleted(forId: todoId, source: todoSource, containerID: containerID)
                : completeApi.markTodoAsInProcess(forId: todoId, source: todoSource, containerID: containerID)
        }
        return observable.take(1).asSingle().map { [weak self] todo in
            let newState: CompleteState
            if todoSource == .doc {
                newState = toState
            } else {
                newState = self?.state(for: todo) ?? toState
            }
            return (newState, todo)
        }
    }

    func updateTodo(_ todo: inout Rust.Todo, to toState: CompleteState) {
        let isSelf: Bool
        let isCompleted: Bool
        switch toState {
        case .assignee(let b):
            isSelf = true
            isCompleted = b
        case .classicMode(let isTodoCompleted, _),
             .creator(let isTodoCompleted),
             .creatorAndAssignee(let isTodoCompleted, _):
            isSelf = false
            isCompleted = isTodoCompleted
        case .outsider:
            assertionFailure()
            return
        }
        let completedTime = isCompleted ? Int64(Date().timeIntervalSince1970 * 1_000) : 0
        for i in 0..<todo.assignees.count {
            var assignee = todo.assignees[i]
            guard
                assignee.type == .user,
                case .user(var u) = assignee.assignee
            else {
                continue
            }
            u.completedMilliTime = completedTime
            assignee.assignee = .user(u)
            todo.assignees[i] = assignee
        }
        if useClassicMode(for: todo) {
            todo.completedMilliTime = completedTime
        } else {
            if !isSelf {
                todo.completedMilliTime = completedTime
            }
            todo.displayCompletedMilliTime = completedTime
        }
    }

    func customComplete(from todo: Rust.Todo) -> CustomComplete? {
        let customComplete = todo.customComplete
        logger.info("todo custom complete href: \(customComplete.ios.href), tip: \(customComplete.ios.tip)")
        if !customComplete.ios.href.isEmpty {
            if let url = URL(string: customComplete.ios.href) {
                return .url(url, userResolver)
            }
        } else if !customComplete.ios.tip.isEmpty {
            let id = LanguageManager.currentLanguage.localeIdentifier.lowercased()
            if let tip = customComplete.ios.tip[id] {
                return .tip(tip)
            }
        }
        return nil
    }

    func doubleCheckBeforeToggleState(
        _ fromState: CompleteState,
        with role: CompleteRole,
        assignees: [Assignee]
    ) -> DoubleCheckContext? {
        guard role == .todo else { return nil }

        /// 创建者操作「全部完成」或者「恢复任务」，可能弹窗提醒，需要满足如下条件：
        /// - 操作者是创建者
        /// - 操作「全部完成」时，有其他用户未完成
        /// - 操作「恢复任务」时，有其他执行者

        var maybeNeedsCompleteAlert = false     // 可能需要「全部完成」的弹窗
        var maybeNeedsRestoreAlert = false      // 可能需要「恢复任务」的弹窗
        switch fromState {
        case .creator(let isCompleted):
            maybeNeedsCompleteAlert = !isCompleted
            maybeNeedsRestoreAlert = isCompleted
        case .creatorAndAssignee(let isTodoCompleted, _):
            maybeNeedsCompleteAlert = !isTodoCompleted
            maybeNeedsRestoreAlert = isTodoCompleted
        default:
            break
        }
        let currentUserId = userResolver.userID
        let otherAssignees = assignees.filter { $0.identifier != currentUserId }
        if maybeNeedsCompleteAlert && otherAssignees.contains(where: { $0.completedTime == nil }) {
            return (
                title: I18N.Todo_CollabTask_CompletedTask,
                content: I18N.Todo_CollabTask_CompleteTaskDialog,
                confirm: I18N.Todo_CollabTask_ConfirmComplete
            )
        } else if maybeNeedsRestoreAlert && !otherAssignees.isEmpty {
            return (
                title: I18N.Todo_CollabTask_RestoreTask,
                content: I18N.Todo_CollabTask_RestoreTaskDesc,
                confirm: I18N.Todo_CollabTask_ComfirmRestore
            )
        } else {
            return nil
        }
    }

    func doubleCheckBeforeToggleState(with role: CompleteRole, todo: Rust.Todo, hasContainerPermission: Bool) -> DoubleCheckContext? {
        var fromState = state(for: todo)
        if hasContainerPermission {
            fromState = mergeCompleteState(fromState, with: todo.isTodoCompleted)
        }
        let assignees = todo.assignees.map(Assignee.init(model:))
        return doubleCheckBeforeToggleState(fromState, with: role, assignees: assignees)
    }

    // 有容器（清单）的权限的时候，清单赋予了任务创建人的角色，那么需要合并只有负责人这一种角色到双重角色
    func mergeCompleteState(_ fromState: CompleteState, with todoCompleted: Bool) -> CompleteState {
        switch fromState {
        case .outsider(let isCompleted):
            return .creator(isCompleted: isCompleted)
        case .assignee(let isCompleted):
            return .creatorAndAssignee(todo: todoCompleted, self: isCompleted)
        default:
            return fromState
        }
    }

}
