//
//  MemberListViewModel.swift
//  Todo
//
//  Created by 张威 on 2021/9/12.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkAccountInterface
import LarkTag

/// MemberList - ViewModel

protocol MemberListViewModelDependency: AnyObject {
    typealias Completion = (UserResponse<Void>) -> Void
    func appendMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?)
    func removeMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?)
    func changeTaskMode(input: MemberListViewModelInput, _ newMode: Rust.TaskMode, completion: Completion?)
}

struct MemberListViewModelInput {
    enum Scene {
        case creating_assignee  // 新建任务 - 执行人 or 协作人
        case editing_assignee   // 编辑任务 - 执行人 or 协作人
        case creating_follower  // 新建任务 - 关注者
        case editing_follower   // 编辑任务 - 关注者
        case custom_fields(fieldKey: String, title: String)      // 自定义字段 - member 字段
        case creating_subTask_assignee(IndexPath)
    }
    // 用于旧埋点
    var todoId: String
    var todoSource: Rust.TodoSource
    // chatId，用于选人提供推荐
    var chatId: String?
    var scene: Scene
    // 当前用户的角色
    var selfRole: MemberRole
    /// 是否可编辑其他人（添加/删除）
    var canEditOther: Bool
    // 初始 members
    var members: [Member]
    // 任务模式
    var mode: Rust.TaskMode = .taskComplete
    // 任务模式的编辑权限
    var modeEditable: Bool = false
}

final class MemberListViewModel: UserResolverWrapper {

    enum NaviAddState {
        case hidden                     // 不可见
        case disable(message: String)   // 不可用，但可以点击（点击后弹 toast 提醒）
        case enable                     // 可用，可以点击
    }

    // list 数据更新
    var onListUpdate: (() -> Void)?
    var naviAddState: NaviAddState {
        if input.canEditOther {
            return .enable
        } else {
            if input.todoSource == .doc {
                return .disable(message: I18N.Todo_Task_UnableEditTaskFromDocs)
            } else {
                return .hidden
            }
        }
    }
    var title: String {
        switch input.scene {
        case .creating_assignee, .editing_assignee, .creating_subTask_assignee:
            return I18N.Todo_New_Owner_Text
        case .creating_follower, .editing_follower:
            return I18N.Todo_Task_Follower
        case .custom_fields(_, let titleText):
            return titleText
        }
    }
    var isAssigneeScene: Bool {
        switch input.scene {
        case .creating_assignee, .editing_assignee, .creating_subTask_assignee:
            return true
        default:
            return false
        }
    }
    var isAssigneeCreateScene: Bool {
        switch input.scene {
        case .creating_assignee, .creating_subTask_assignee:
            return true
        default:
            return false
        }
    }
    var modeEditable: Bool { input.modeEditable }
    var mode: Rust.TaskMode

    var userResolver: LarkContainer.UserResolver
    let input: MemberListViewModelInput

    private var cellItems = [CellItem]()

    private let dependency: MemberListViewModelDependency
    private lazy var currentUser: (chatterId: String, tenantId: String) = {
        return (
            chatterId: passportService?.user.userID ?? "",
            tenantId: passportService?.userTenant.tenantID ?? ""
        )
    }()
    @ScopedInjectedLazy var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var passportService: PassportUserService?
    private var currentUserId: String { userResolver.userID }

    private let disposeBag = DisposeBag()

    init(
        resolver: UserResolver,
        input: MemberListViewModelInput,
        dependency: MemberListViewModelDependency
    ) {
        self.userResolver = resolver
        self.input = input
        self.dependency = dependency
        self.mode = input.mode
        rebuildCellItems(with: .initial(input.members))
    }

    func setup() {
        onListUpdate?()
    }

    // MARK: - List DataSource

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfRows(in section: Int) -> Int {
        return cellItems.count
    }

    func cellData(at indexPath: IndexPath) -> MemberListCellDataType? {
        guard indexPath.row >= 0 && indexPath.row < cellItems.count else {
            assertionFailure()
            return nil
        }
        return cellItems[indexPath.row]
    }

    func chatterId(at indexPath: IndexPath) -> String? {
        return cellData(at: indexPath)?.member.asUser()?.chatterId
    }

    func allChatterIds() -> [String] {
        return cellItems.compactMap { $0.member.asUser()?.chatterId }
    }

    private struct CellItem: MemberListCellDataType {
        var member: Member
        var tags: [LarkTag.TagType]
        var deleteState: MemberListCellDeleteState
    }

    // MARK: - List Action

    typealias AppendCallback = (UserResponse<Void>) -> Void

    // MARK: List Action - Append

    // 新增
    func appendItems(by chatterIds: [String], callback: @escaping AppendCallback) {
        trackPickMembers(with: chatterIds)
        trackAppendMembers()

        fetchApi?.getUsers(byIds: chatterIds)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] users in
                    guard let self = self else { return }
                    let newMembers = users.map { Member.user(User(pb: $0)) }
                    self.rebuildCellItems(with: .append(newMembers))
                    self.dependency.appendMembers(input: self.input, newMembers, completion: callback)
                },
                onError: { err in
                    callback(.failure(Rust.makeUserError(from: err)))
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: List Action - Delete

    typealias DeleteCallback = (UserResponse<(toast: String?, needsExit: Bool)>) -> Void

    struct DeleteConfirmContext {
        var tip: String?
        var text: String
        var action: (@escaping DeleteCallback) -> Void
    }

    /// 删除前的确认弹窗
    func confirmContextForDeleting(at indexPath: IndexPath) -> DeleteConfirmContext? {
        guard let cellItem = cellData(at: indexPath) else { return nil }

        var tip: String?
        var text = ""
        var needsExit = false
        switch input.scene {
        case .creating_follower, .creating_assignee, .custom_fields, .creating_subTask_assignee:
            return nil
        case .editing_assignee:
            if input.selfRole == .assignee {
                tip = I18N.Todo_Task_RemoveOneselfFromAssigneesDialogContent
                text = I18N.Todo_Task_RemoveOneselfFromAssigneesRemoveButton
                needsExit = true
            } else {
                text = I18N.Todo_RemoveOwner_Button
            }
        case .editing_follower:
            // 只是关注者角色，且移除的自己的时候
            if input.selfRole == .follower, cellItem.member.identifier == currentUserId {
                tip = I18N.Todo_Task_RemoveYourselfFromFollowersDialogueContent
                text = I18N.Todo_Task_RemoveOneselfFromAssigneesRemoveButton
                needsExit = true
            } else {
                text = I18N.Todo_Task_RemoveFollower
            }
        }
        return .init(tip: tip, text: text) { [weak self] callback in
            guard
                let self = self,
                let index = self.cellItems.firstIndex(where: { $0.member.identifier == cellItem.member.identifier })
            else {
                callback(.success((nil, false)))
                return
            }
            self.deleteItem(at: indexPath, callback: callback)
        }
    }

    /// 删除
    func deleteItem(at indexPath: IndexPath, callback: @escaping DeleteCallback) {
        guard let cellItem = cellData(at: indexPath) else {
            callback(.success((nil, false)))
            return
        }

        rebuildCellItems(with: .delete(at: indexPath))

        var needsExit = false
        switch input.scene {
        case .editing_assignee: needsExit = input.selfRole == .assignee
        case .editing_follower: needsExit = input.selfRole == .follower && cellItem.member.identifier == currentUserId
        default: break
        }
        dependency.removeMembers(input: input, [cellItem.member]) { res in
            switch res {
            case .success:
                callback(.success((toast: nil, needsExit: needsExit)))
            case .failure(let userErr):
                callback(.failure(userErr))
            }
        }
    }

    // MARK: - Privates

    private enum ViewAction {
        case initial([Member])
        case delete(at: IndexPath)
        case append([Member])
    }

    private func rebuildCellItems(with action: ViewAction) {
        var curMembers = cellItems.map(\.member)
        switch action {
        case let .initial(members):
            curMembers = members
        case let .append(newMembers):
            let existIds = Set(curMembers.map(\.identifier))
            let new = newMembers.filter { !existIds.contains($0.identifier) }
            curMembers.append(contentsOf: new)
        case let .delete(indexPath):
            if indexPath.row >= 0 && indexPath.row < curMembers.count {
                curMembers.remove(at: indexPath.row)
            }
        }
        cellItems = curMembers.map(makeCellItem(from:))
        onListUpdate?()
    }

    private func makeCellItem(from member: Member) -> CellItem {
        var isSelf = false
        if let user = member.asUser() {
            isSelf = user.chatterId == currentUser.chatterId
        }
        var isCustomFields = false
        if case .custom_fields = input.scene {
            isCustomFields = true
        }

        let deleteState: MemberListCellDeleteState
        if (isSelf && !isCustomFields) || input.canEditOther {
            deleteState = .enable
        } else {
            if input.todoSource == .doc {
                deleteState = .disable(message: I18N.Todo_Task_UnableEditTaskFromDocs)
            } else {
                deleteState = .hidden
            }
        }
        // 目前负责人与关注页面无外部标签
        return CellItem(member: member, tags: [], deleteState: deleteState)
    }

    func trackAppendMembers() {
        var source = ""
        switch input.scene {
        case .creating_follower: source = "create"
        case .editing_follower: source = "edit"
        default: return
        }
        Detail.tracker(.todo_task_follow, params: ["source": source, "task_id": input.todoId])
    }

    func trackPickMembers(with chatterIds: [String]) {
        for id in chatterIds {
            Detail.tracker(.todo_task_members_add, params: ["task_id": input.todoId, "select_user_id": id])
        }
    }

    func changeTaskMode(_ newMode: Rust.TaskMode) {
        mode = newMode
        dependency.changeTaskMode(input: input, newMode, completion: nil)
        onListUpdate?()
    }



}
