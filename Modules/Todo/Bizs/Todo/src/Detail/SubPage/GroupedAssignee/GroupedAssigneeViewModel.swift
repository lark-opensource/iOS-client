//
//  GroupedAssigneeViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/8/16.
//

import RxSwift
import RxCocoa
import LarkContainer
import LarkAccountInterface

protocol GroupedAssigneeViewModelDependency: AnyObject {
    /// 添加执行人
    func appendAssignees(_ assignees: [Assignee], completion: ((UserResponse<Void>) -> Void)?)

    /// 移除执行人
    func removeAssignees(_ assignees: [Assignee], completion: ((UserResponse<Void>) -> Void)?)

    /// 自定义完成
    func customComplete(for assignee: Assignee) -> CustomComplete?

    /// 标记 assignee 为完成/未完成
    ///   - Parameter isCompleted: 是否完成
    ///   - Parameter assignee: 被标记的执行人
    ///   - Parameter completion: Bool 值描述是否应该退出页面，true 表示应该
    func updateCompleted(_ isCompleted: Bool, for assignee: Assignee, completion: ((UserResponse<Bool>) -> Void)?)

    /// 修改任务mode
    func changeTaskMode(_ newMode: Rust.TaskMode, completion: ((UserResponse<Bool>) -> Void)?)
}

struct GroupedAssigneeViewModelInput {
    /// 初始执行人
    var assignees: [Assignee]
    /// todo id
    var todoId: String
    /// 会话 Id，给选人组件提供 suggestion
    var chatId: String?
    /// 当前用户的角色
    var selfRole: MemberRole
    /// 是否可标记其他人的完成状态
    var canMarkOther: Bool
    /// 是否可编辑其他人（添加/删除执行人）
    var canEditOther: Bool
    /// 任务模式
    var mode: Rust.TaskMode = .taskComplete
    /// 任务模式编辑权限
    var modeEditable: Bool = false
}

final class GroupedAssigneeViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    typealias UserActionCompletion = (UserResponse<Void>) -> Void

    /// 列表类型：完成 & 未完成
    enum ListType {
        case completed
        case uncompleted
    }

    /// 可点击
    enum ClickType {
        /// 可点击
        case enabled
        /// 不可点
        case disabled(warn: String?)
    }

    enum MoreAction: Int {
        /// 标记为完成
        case markAsCompleted
        /// 标记为未完成
        case markAsInProgress
        /// 移除协作者
        case removeAssignee

        var title: String {
            switch self {
            case .markAsCompleted:
                return I18N.Todo_CollabTask_MarkAsComplete
            case .markAsInProgress:
                return I18N.Todo_CollabTask_MarkAsNotComplete
            case .removeAssignee:
                return I18N.Todo_RemoveOwner_Button
            }
        }
    }

    typealias MoreItem = (action: MoreAction, type: ClickType)

    /// 列表数据刷新
    var onListDataUpdate: ((ListType) -> Void)?

    /// 退出页面（完成）
    var onNeedsCompleteExit: (() -> Void)?

    /// 允许添加
    var enableAddAssignee: Bool { input.canEditOther }
    var modeEditable: Bool { input.modeEditable }
    var mode: Rust.TaskMode

    private let input: GroupedAssigneeViewModelInput
    private let dependency: GroupedAssigneeViewModelDependency
    private var assignees: [Assignee]
    private lazy var currentUser: (chatterId: String, tenantId: String) = {
        return (
            chatterId: passportService?.user.userID ?? "",
            tenantId: passportService?.userTenant.tenantID ?? ""
        )
    }()
    private var cellItems = (completed: [CellItem](), uncompleted: [CellItem]())

    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var passportService: PassportUserService?
    private let disposeBag = DisposeBag()

    init(
        resolver: UserResolver,
        input: GroupedAssigneeViewModelInput,
        dependency: GroupedAssigneeViewModelDependency
    ) {
        self.userResolver = resolver
        self.input = input
        self.dependency = dependency
        self.assignees = input.assignees
        self.mode = input.mode
    }

    func setup() {
        rebuildCellItems()
    }

    func assignee(at indexPath: IndexPath, for type: ListType) -> Assignee? {
        return cellItem(at: indexPath, for: type)?.assignee
    }

    func numberOfSections(for type: ListType) -> Int {
        return 1
    }

    func numberOfRows(in section: Int, for type: ListType) -> Int {
        switch type {
        case .completed:
            return cellItems.completed.count
        case .uncompleted:
            return cellItems.uncompleted.count
        }
    }

    func cellData(at indexPath: IndexPath, for type: ListType) -> GroupedAssigneeListCellDataType? {
        return cellItem(at: indexPath, for: type)
    }

    func addAssignees(by chatterIds: [String], completion: @escaping UserActionCompletion) {
        guard !chatterIds.isEmpty else { return }

        fetchApi?.getUsers(byIds: chatterIds).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] users in
                    guard let self = self else { return }
                    let assignees = users.map { Assignee(member: .user(User(pb: $0))) }
                    self.doAddAssignees(assignees, completion: completion)
                    Detail.logger.info("add assignees: \(assignees.map({ $0.asMember().logInfo }))")
                },
                onError: { err in
                    Detail.logger.error("add assignees failed. err: \(err)")
                    Detail.assertionFailure("add assignees failed. err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    func moreActionItems(at indexPath: IndexPath, for type: ListType) -> [(action: MoreAction, type: ClickType)] {
        return cellItem(at: indexPath, for: type)?.moreItems ?? []
    }

    func customComplete(at indexPath: IndexPath, for type: ListType) -> CustomComplete? {
        guard let target = assignee(at: indexPath, for: type) else { return nil }
        return dependency.customComplete(for: target)
    }

    func toggleCompleteState(at indexPath: IndexPath, for type: ListType) {
        guard
            var target = assignee(at: indexPath, for: type),
            case .user(let user) = target.asMember()
        else {
            return
        }
        let moreActions = moreActionItems(at: indexPath, for: type)
        let actionItem = moreActions.first { item in
            if item.action == .markAsInProgress || item.action == .markAsCompleted,
               case .enabled = item.type {
                return true
            } else {
                return false
            }
        }
        var needsUpdate: Bool
        switch actionItem?.action {
        case .markAsCompleted:
            dependency.updateCompleted(true, for: target) { [weak self] res in
                if case .success(let needsExit) = res, needsExit {
                    self?.onNeedsCompleteExit?()
                }
            }
            target.completedTime = Int64(Date().timeIntervalSince1970) * Utils.TimeFormat.Thousandth
            needsUpdate = true
        case .markAsInProgress:
            dependency.updateCompleted(false, for: target, completion: nil)
            target.completedTime = nil
            needsUpdate = true
        default:
            assertionFailure()
            needsUpdate = false
        }
        if needsUpdate, let index = assignees.firstIndex(where: { $0.identifier == target.identifier }) {
            assignees[index] = target
            rebuildCellItems()
        }
    }

    func needsAlertBeforeRemoveAssignee(at indexPath: IndexPath, for type: ListType) -> Bool {
        if let target = assignee(at: indexPath, for: type),
           target.identifier == currentUser.chatterId,
           input.selfRole == .assignee {
            return true
        } else {
            return false
        }
    }

    func removeItem(at indexPath: IndexPath, for type: ListType, completion: @escaping UserActionCompletion) {
        guard let target = assignee(at: indexPath, for: type) else {
            completion(.success(void))
            return
        }
        dependency.removeAssignees([target]) { [weak self] res in
            if case .success = res {
                self?.assignees.removeAll(where: { $0.identifier == target.identifier })
                self?.rebuildCellItems()
            }
            completion(res)
        }
    }

    func pickChattersContext() -> (chatId: String?, selectedChatterIds: [String]) {
        let selectedChatterIds = assignees.compactMap { assignee -> String? in
            guard case .user(let user) = assignee.asMember() else { return nil }
            return user.chatterId
        }
        return (input.chatId, selectedChatterIds)
    }

    private func doAddAssignees(_ newAssignees: [Assignee], completion: @escaping UserActionCompletion) {
        guard !newAssignees.isEmpty else {
            completion(.success(void))
            return
        }
        var appendAssignees = newAssignees
        // 乐观更新UI上的数据
        if mode == .userComplete, cellItems.uncompleted.isEmpty, !cellItems.completed.isEmpty {
            appendAssignees = newAssignees.map({ assignee in
                var new = assignee
                new.completedTime = Int64(Date().timeIntervalSince1970) * Utils.TimeFormat.Thousandth
                return new
            })
        }
        dependency.appendAssignees(appendAssignees) { [weak self] res in
            if case .success = res, let self = self {
                self.assignees += appendAssignees
                self.assignees = self.assignees.lf_unique(by: \.identifier)
                self.rebuildCellItems()
            }
            completion(res)
        }
    }

    private func cellItem(at indexPath: IndexPath, for type: ListType) -> CellItem? {
        switch type {
        case .completed:
            guard indexPath.row >= 0 && indexPath.row < cellItems.completed.count else { return nil }
            return cellItems.completed[indexPath.row]
        case .uncompleted:
            guard indexPath.row >= 0 && indexPath.row < cellItems.uncompleted.count else { return nil }
            return cellItems.uncompleted[indexPath.row]
        }
    }

    private func moreItems(for assignee: Assignee) -> [MoreItem] {
        var ret = [MoreItem]()
        guard case .user(let user) = assignee.asMember() else { return ret }
        let isSelf = user.chatterId == currentUser.chatterId

        // 标记完成/未完成
        if isSelf || input.canMarkOther {
            ret.append((action: assignee.completedTime == nil ? .markAsCompleted : .markAsInProgress, type: .enabled))
        }

        // 移除执行人
        if input.canEditOther || isSelf {
            ret.append((action: .removeAssignee, type: .enabled))
        }
        return ret
    }

    private func rebuildCellItems() {
        cellItems.completed.removeAll()
        cellItems.uncompleted.removeAll()
        for assignee in assignees {
            guard case .user = assignee.asMember() else { continue }
            let item = CellItem(
                assignee: assignee,
                moreItems: moreItems(for: assignee)
            )
            if assignee.completedTime != nil {
                cellItems.completed.append(item)
            } else {
                cellItems.uncompleted.append(item)
            }
        }
        onListDataUpdate?(.completed)
        onListDataUpdate?(.uncompleted)
    }

    func changeTaskMode(_ newMode: Rust.TaskMode) {
        mode = newMode
        dependency.changeTaskMode(newMode, completion: nil)
        onListDataUpdate?(.completed)
        onListDataUpdate?(.uncompleted)
    }

}

// MARK: - CellItem

extension GroupedAssigneeViewModel {
    private struct CellItem: GroupedAssigneeListCellDataType, MemberConvertible {
        var assignee: Assignee
        var moreItems: [MoreItem]

        var name: String { assignee.name }
        var avatar: AvatarSeed { assignee.avatar }
        var showMore: Bool { !moreItems.isEmpty }

        func asMember() -> Member {
            return assignee.asMember()
        }
    }
}

// MARK: - Track

extension GroupedAssigneeViewModel {

    func trackPickChatters(_ chatterIds: [String]) {
        for id in chatterIds {
            var params: [AnyHashable: Any] = [:]
            params["task_id"] = input.todoId
            params["select_user_id"] = id
            Detail.tracker(.todo_task_members_add, params: params)
        }
    }

    func trackGoBack() {
        Detail.tracker(.todo_task_members_back, params: ["task_id": input.todoId])
    }

}
