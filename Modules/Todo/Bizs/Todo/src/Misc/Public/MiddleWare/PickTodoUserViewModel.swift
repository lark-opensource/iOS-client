//
//  PickTodoUserViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2021/11/8.
//

import TodoInterface
import LarkContainer
import RxSwift
import RxCocoa

final class PickTodoUserViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    var onFinishFetch: ((Error?) -> Void)?
    let body: TodoUserBody

    // 当前执行者
    private var curAssignees = [Assignee]()

    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?

    init(resolver: UserResolver, body: TodoUserBody) {
        self.userResolver = resolver
        self.body = body
    }

    func setup() {
        fetchTodoUsers()
    }

}

extension PickTodoUserViewModel {

    func triggerCallBack() {
        let users = curAssignees.map { assignee in
            return [
                TodoUserBody.id: assignee.identifier,
                TodoUserBody.name: assignee.name,
                TodoUserBody.completedMilliTime: assignee.completedTime ?? 0
            ]
        }
        body.callback?(users)
    }

    var editable: Bool {
        guard let editable = body.param[TodoUserBody.editable] as? Bool else {
            return true
        }
        return editable
    }

    var enableMultiAssignee: Bool {
        guard let enable = body.param[TodoUserBody.enableMultiAssignee] as? Bool else {
            return true
        }
        return enable
    }

    private func userIds() -> [String]? {
        guard let ids = body.param[TodoUserBody.userIds] as? [String] else {
            return nil
        }
        return ids.filter { !$0.isEmpty }
    }

    func completedMilliTime(by userId: String) -> Int64 {
        guard let users = body.param[TodoUserBody.users] as? [Any] else {
            return 0
        }
        var completedMilliTime: Int64 = 0
        users.forEach { user in
            if let user = user as? [String: Any], let id = user[TodoUserBody.id] as? String {
                if id == userId, let time = user[TodoUserBody.completedMilliTime] as? Int64 {
                    completedMilliTime = time
                    return
                }
            }
        }
        return completedMilliTime
    }

}

extension PickTodoUserViewModel {

    private func fetchTodoUsers() {
        guard let userIds = userIds() else {
            return
        }
        fetchApi?.getUsers(byIds: userIds)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] users in
                    guard let self = self else { return }
                    self.curAssignees = users.map { u in
                        let m = Member.user(User(pb: u))
                        return Assignee(member: m, completedMilliTime: self.completedMilliTime(by: m.identifier))
                    }
                    self.onFinishFetch?(nil)
                },
                onError: { [weak self] err in
                    guard let self = self else { return }
                    self.onFinishFetch?(err)
                }
            )
            .disposed(by: disposeBag)
    }

}

extension PickTodoUserViewModel: MemberListViewModelDependency, GroupedAssigneeViewModelDependency {
    func changeTaskMode(input: MemberListViewModelInput, _ newMode: Rust.TaskMode, completion: Completion?) { }

    /// 展示 list 所需的信息
    enum AssigneeListType {
        /// 经典 list
        case classic(input: MemberListViewModelInput, dependency: MemberListViewModelDependency)
        /// 分组 list（未完成 & 完成）
        case grouped(input: GroupedAssigneeViewModelInput, dependency: GroupedAssigneeViewModelDependency)
    }

    func assigneeList() -> AssigneeListType {
        if enableMultiAssignee {
            let input = GroupedAssigneeViewModelInput(
                assignees: curAssignees,
                todoId: "",
                chatId: "",
                selfRole: [.creator],
                canMarkOther: true,
                canEditOther: editable
            )
            return .grouped(input: input, dependency: self)
        }
        let input = MemberListViewModelInput(
            todoId: "",
            todoSource: .todo,
            chatId: "",
            scene: .creating_assignee,
            selfRole: [.creator],
            canEditOther: editable,
            members: curAssignees.map { $0.asMember() }
        )
        return .classic(input: input, dependency: self)
    }

    typealias Completion = (UserResponse<Void>) -> Void

    // MARK: MemberListViewModelDependency

    func appendMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?) {
        let assignees = members.map { member in
            return Assignee(member: member)
        }
        appendAssignees(assignees)
        completion?(.success(void))
    }

    func removeMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?) {
        removeAssignees(by: members.map(\.identifier))
        completion?(.success(void))
    }

    // MARK: GroupedAssigneeViewModelDependency

    func appendAssignees(_ assignees: [Assignee], completion: Completion?) {
        appendAssignees(assignees)
        completion?(.success(void))
    }

    func removeAssignees(_ assignees: [Assignee], completion: Completion?) {
        removeAssignees(by: assignees.map(\.identifier))
        completion?(.success(void))
    }

    func customComplete(for assignee: Assignee) -> CustomComplete? {
        return nil
    }

    func updateCompleted(_ isCompleted: Bool, for assignee: Assignee, completion: ((UserResponse<Bool>) -> Void)?) {
        updateAssigneeCompleted(isCompleted, for: assignee.identifier)
        completion?(.success(false))
    }

    func changeTaskMode(_ newMode: Rust.TaskMode, completion: ((UserResponse<Bool>) -> Void)?) { }

}

extension PickTodoUserViewModel {

    private func appendAssignees(_ assignees: [Assignee]) {
        var exists = Set<String>()
        curAssignees.forEach { exists.insert($0.identifier) }
        let appending = assignees.filter { !exists.contains($0.identifier) }
        curAssignees.append(contentsOf: appending)
    }

    private func removeAssignees(by identifiers: [String]) {
        let needsRemove = Set(identifiers)
        curAssignees = curAssignees.filter { !needsRemove.contains($0.identifier) }
    }

    private func updateAssigneeCompleted(_ isCompleted: Bool, for identifier: String) {
        if let index = curAssignees.firstIndex(where: { $0.identifier == identifier }) {
           let completeTime = isCompleted ? Int64(Date().timeIntervalSince1970 * 1_000) : 0
            var assignee = curAssignees[index]
            assignee.completedTime = completeTime
            curAssignees[index] = assignee
        }
    }

}
