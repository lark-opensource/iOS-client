//
//  DetailOwnerViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2022/7/18.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkAccountInterface

final class DetailOwnerViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let rxViewData: BehaviorRelay<DetailOwnerViewData?> = .init(value: nil)

    private let store: DetailModuleStore
    private let disposeBag = DisposeBag()
    private var sectionRes = Rust.OwnedSectionRefRes()

    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var listApi: TaskListApi?
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?
    @ScopedInjectedLazy private var completeService: CompleteService?

    var fg: Bool {
        return FeatureGating(resolver: userResolver).boolValue(for: .multiAssignee)
    }

    private var currentUserId: String { userResolver.userID }

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
        setup()
    }

    private func setup() {
        setupViewData()
    }

    private func setupViewData() {
        store.rxInitialized()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] _ in
                guard let self = self else { return }
                self.fetchSections()
            })
            .disposed(by: disposeBag)
        Observable.combineLatest(
            store.rxValue(forKeyPath: \.assignees),
            store.rxValue(forKeyPath: \.permissions).distinctUntilChanged(\.assignee),
            store.rxValue(forKeyPath: \.ownedSection),
            store.rxValue(forKeyPath: \.mode)
        )
        .observeOn(MainScheduler.instance)
        .map { [weak self] (assignees, permision, ownedSection, _) -> DetailOwnerViewData? in
            self?.makeViewData(assignees, permision.assignee, ownedSection)
        }
        .bind(to: rxViewData)
        .disposed(by: disposeBag)
    }

    private func makeViewData(_ assignees: [Assignee], _ permision: PermissionOption, _ ownedSection: Rust.ContainerSection?) -> DetailOwnerViewData? {
        if assignees.isEmpty {
            return DetailOwnerViewData(avatars: [], contentText: nil, scene: .empty)
        }
        let mySelfIsOwner = assignees.contains(where: { $0.identifier == currentUserId })
        var sectionName: String?
        if let section = sectionRes.sections.first(where: { section in
            if let ownedSection = ownedSection {
                return ownedSection.isValid ? section.guid == ownedSection.sectionGuid : section.isDefault
            } else {
                return false
            }
        }) {
            sectionName = section.displayName
        }
        switch store.state.mode {
        case .taskComplete:
            if assignees.count == 1 {
                let assignee = assignees[0]
                return DetailOwnerViewData(
                    avatars: [(seed: assignee.avatar, isCompleted: false)],
                    contentText: assignee.name,
                    scene: .single(canClear: permision.isEditable),
                    sectionText: mySelfIsOwner ? sectionName : nil
                )
            } else {
                let avatars = assignees.map { (seed: $0.avatar, isCompleted: false) }
                return DetailOwnerViewData(
                    avatars: avatars,
                    contentText: I18N.Todo_NumTaskOwners_ICU(avatars.count),
                    scene: .multi(showIcon: !fg),
                    sectionText: mySelfIsOwner ? sectionName : nil
                )
            }
        default:
            var enableChecked = false
            if store.state.scene.isForEditing,
               let todo = store.state.todo,
               let completeService = completeService,
               !completeService.useClassicMode(for: todo) {
                enableChecked = true
            }
            let uniqueAssignees = assignees.lf_unique(by: \.identifier)
            var completedCount = 0
            let avatars = uniqueAssignees.map { assignee in
                let isCompleted = enableChecked && assignee.completedTime != nil
                if isCompleted {
                    completedCount += 1
                }
                return (seed: assignee.avatar, isCompleted: isCompleted)
            }
            var contentText = fg ? I18N.Todo_MultiOwners_CompleteRatio_Text("\(completedCount)/\(avatars.count)") : I18N.Todo_NumTaskOwners_ICU(avatars.count)
            if uniqueAssignees.count == 1 {
                contentText = uniqueAssignees[0].name
            }
            return DetailOwnerViewData(
                avatars: avatars,
                contentText: contentText,
                scene: uniqueAssignees.count > 1 ? .multi(showIcon: !fg) : .single(canClear: permision.isEditable),
                sectionText: mySelfIsOwner ? sectionName : nil
            )
        }
    }

    func removeOwner() {
        Detail.Track.clickRemoveAssignee(with: guid)
        store.dispatch(.clearAssignees)
    }
}

// MARK: - Single Pick Owner

extension DetailOwnerViewModel {
    var canPick: Bool {
        return store.state.permissions.assignee.isEditable
    }

    var chatId: String? {
        return store.state.scene.chatId
    }

    var guid: String {
        guard let todo = store.state.todo else { return "" }
        return todo.guid
    }

    var isSubTask: Bool { store.state.isSubTask }

    var isEdit: Bool { store.state.scene.isForEditing }

    var selectedAssigneeIds: [String] {
        store.state.assignees.map { $0.identifier }
    }

    func addOwner(with chatterId: String) {
        guard !chatterId.isEmpty else { return }
        fetchApi?.getUsers(byIds: [chatterId]).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] users in
                    guard let self = self, let user = users.first else { return }
                    let member: Member = .user(User(pb: user))
                    Detail.logger.info("get owner success, user id :\(member.identifier)")
                    Detail.Track.clickAddCollaborator(with: self.guid)
                    self.store.dispatch(.resetAssignees([Assignee(member: member)]))
                },
                onError: { err in
                    Detail.logger.info("get owner failed \(err)")
                }
            )
            .disposed(by: disposeBag)
    }
}
// MARK: - Multi Pick Owner

extension DetailOwnerViewModel {
    func pickViewMessage() -> (chatId: String?, selectedChatterIds: [String])? {
        guard store.state.permissions.assignee.isEditable else {
            return nil
        }
        var selectedChatterIds = [String]()
        for assignee in store.state.assignees {
            switch assignee.asMember() {
            case .user(let user):
                selectedChatterIds.append(user.chatterId)
            default:
                break
            }
        }
        return (store.state.scene.chatId, selectedChatterIds)
    }

    func appendPickedAssignees(by ids: [String], completion: @escaping (UserResponse<Void>) -> Void) {
        guard !ids.isEmpty else {
            completion(.success(void))
            return
        }

        fetchApi?.getUsers(byIds: ids)
            .map { users -> [Assignee] in
                return users.map { u in
                    let m = Member.user(User(pb: u))
                    return Assignee(member: m)
                }
            }
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] in self?.store.dispatch(.appendAssignees($0), callback: completion) },
                onError: { completion(.failure(Rust.makeUserError(from: $0))) }
            )
            .disposed(by: disposeBag)

        // track
        for id in ids {
            var params: [AnyHashable: Any] = [:]
            params["select_user_id"] = id
            Detail.tracker(.todo_create_person_select, params: params)
        }
    }
}

// MARK: - Sections

extension DetailOwnerViewModel {

    private func fetchSections() {
        fetchApi?.getOwnedSections(with: store.state.todo?.guid)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] res in
                var newRes = res
                newRes.sections = res.sections.sorted(by: { $0.rank < $1.rank })
                self?.sectionRes = newRes
                self?.handleSectionResult(newRes)
            })
            .disposed(by: self.disposeBag)
    }

    private func handleSectionResult(_ res: Rust.OwnedSectionRefRes) {
        var cs = Rust.ContainerSection()
        if res.ref.isValid {
            // 编辑场景
            cs.containerGuid = res.ref.containerGuid
            cs.sectionGuid = res.ref.sectionGuid
            cs.rank = res.ref.rank
        } else {
            // 新建场景
            if let ownedSection = store.state.ownedSection, ownedSection.isValid {
                // 比如快捷展开
                cs = ownedSection
            } else if let sourceCS = store.state.scene.createSource?.containerSection, store.state.scene.isForCreating {
                // 比如行内创建
                cs = sourceCS
            } else {
                if let defaultSection = res.sections.first(where: { $0.isDefault }) {
                    cs.containerGuid = res.containerGuid
                    cs.sectionGuid = defaultSection.guid
                    cs.rank = Utils.Rank.defaultMinRank
                }
            }
        }
        store.dispatch(.updateOwnSection(cs))
    }

    func handlePickerRes(_ picker: DetailTaskListPicker) {
        Detail.logger.info("owned section picked")
        switch picker {
        case .ownedSection(let oldContainerSection, let taskSection):
            updateSection(old: oldContainerSection, selected: taskSection)
        case .none, .taskList, .sectionRef: break
        }
    }

    func createNewSection(by res: DetailTaskListCreate) {
        guard case .ownedSection(let name) = res, let name = name, let cs = store.state.ownedSection, cs.isValid else { return }
        Detail.logger.info("owned section start create new section")
        // 乐观更新
        let new = {
            var section = Rust.TaskSection()
            section.containerID = cs.containerGuid
            section.guid = UUID().uuidString.lowercased()
            section.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if let first = sectionRes.sections.first {
                section.rank = Utils.Rank.pre(of: first.rank)
            } else {
                section.rank = Utils.Rank.defaultMinRank
            }
            return section
        }()
        // 乐观更新
        sectionRes.sections.insert(new, at: 0)
        var newContainerSection = cs
        newContainerSection.sectionGuid = new.guid
        store.dispatch(.updateOwnSection(newContainerSection))
        operateApi?.upsertSection(old: nil, new: new).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    guard let self = self else { return }
                    self.updateSection(old: cs, selected: new, optimisticUpdate: false, isNewSection: true)
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.sectionRes.sections.removeAll(where: { $0.guid == new.guid })
                    self.store.dispatch(.updateOwnSection(cs))
                    Detail.logger.error("create owned section faild. err: \(err)")
                })
            .disposed(by: disposeBag)
    }

    private func updateSection(old: Rust.ContainerSection?, selected: Rust.TaskSection, optimisticUpdate: Bool = true, isNewSection: Bool = false) {
        guard old?.containerGuid == selected.containerID, old?.sectionGuid != selected.guid else {
            return
        }
        guard let cs = store.state.ownedSection, cs.isValid else {
            return
        }
        let newRef = {
            var ref = Rust.ContainerTaskRef()
            ref.sectionGuid = selected.guid
            ref.rank = cs.rank
            ref.containerGuid = selected.containerID
            ref.taskGuid = store.state.todo?.guid ?? ""
            return ref
        }()

        let oldRef: Rust.ContainerTaskRef? = {
            guard let old = old else { return nil }
            var ref = old.toContainerTasKRef
            ref.taskGuid = store.state.todo?.guid ?? ""
            return ref
        }()

        // 乐观更新
        if optimisticUpdate {
            store.dispatch(.updateOwnSection(newRef.toContainerSection))
        }
        // 只需要处理编辑场景
        guard store.state.scene.isForEditing else {
            Detail.Track.clickCrateNewSection(with: store.state.todo?.guid)
            return
        }

        listApi?.updateTaskContainerRef(new: newRef, old: oldRef).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] _ in
                    guard let self = self else { return }
                    Detail.Track.clickOwnedSection(with: self.store.state.todo?.guid, isNew: isNewSection)
                }, onError: { [weak self] err in
                    guard let self = self else { return }
                    self.store.dispatch(.updateOwnSection(old))
                    Detail.logger.error("update owned section faild. err: \(err)")
                })
            .disposed(by: disposeBag)
    }

    var scene: DetailTaskListPickerViewModel.TaskListPickerScene {
        if let ownedSection = store.state.ownedSection, ownedSection.isValid {
            return .ownedSections(ownedSection, sectionRes.sections)
        }
        // 回到默认分组
        var cs = Rust.ContainerSection()
        if let defaultSection = sectionRes.sections.first(where: { $0.isDefault }) {
            cs.containerGuid = sectionRes.containerGuid
            cs.sectionGuid = defaultSection.guid
            cs.rank = Utils.Rank.defaultMinRank
        }
        store.dispatch(.updateOwnSection(cs))
        return .ownedSections(cs, sectionRes.sections)
    }
}

// MARK: - List Owners

extension DetailOwnerViewModel: MemberListViewModelDependency, GroupedAssigneeViewModelDependency {

    /// 展示 list 所需的信息
    enum ShowListViewMessage {
        /// 经典 list
        case classic(input: MemberListViewModelInput, dependency: MemberListViewModelDependency)
        /// 分组 list（未完成 & 完成）
        case grouped(input: GroupedAssigneeViewModelInput, dependency: GroupedAssigneeViewModelDependency)
    }

    /// 点击执行人 list 的行为
    func listViewMessage() -> ShowListViewMessage {
        let state = store.state
        let assignees = state.assignees.lf_unique(by: \.identifier)

        if state.scene.isForEditing,
           let todo = state.todo,
           let completeService = completeService,
           !completeService.useClassicMode(for: todo) {
            let input = GroupedAssigneeViewModelInput(
                assignees: assignees,
                todoId: state.todo?.guid ?? "",
                chatId: state.scene.chatId,
                selfRole: state.selfRole,
                canMarkOther: state.todo?.editable(for: .todoCompletedMilliTime) ?? false,
                canEditOther: state.permissions.assignee.isEditable,
                mode: state.mode,
                modeEditable: state.todo?.editable(for: .taskMode) ?? false
            )
            return .grouped(input: input, dependency: self)
        } else {
            let input = MemberListViewModelInput(
                todoId: state.todo?.guid ?? "",
                todoSource: state.todo?.source ?? .todo,
                chatId: store.state.scene.chatId,
                scene: state.scene.isForCreating ? .creating_assignee : .editing_assignee,
                selfRole: state.selfRole,
                canEditOther: state.permissions.assignee.isEditable,
                members: assignees.map { $0.asMember() },
                mode: state.mode,
                modeEditable: state.scene.isForCreating ? true : (state.todo?.editable(for: .taskMode) ?? false)
            )
            return .classic(input: input, dependency: self)
        }
    }

    typealias ListCompletion = (UserResponse<Void>) -> Void

    // MARK: MemberListViewModelDependency

    func appendMembers(input: MemberListViewModelInput, _ members: [Member], completion: ListCompletion?) {
        OwnerPicker.Track.finalAddClick(with: guid, isEdit: isEdit, isSubTask: false)
        let assignees = members.map { member in
            return Assignee(member: member)
        }
        store.dispatch(.appendAssignees(assignees), callback: completion)
    }

    func removeMembers(input: MemberListViewModelInput, _ members: [Member], completion: ListCompletion?) {
        let assignees = members.map { member in
            return Assignee(member: member)
        }
        store.dispatch(.removeAssignees(assignees), callback: completion)
    }

    func changeTaskMode(input: MemberListViewModelInput, _ newMode: Rust.TaskMode, completion: Completion?) {
        OwnerPicker.Track.changeDoneClick(with: guid, isEdit: isEdit, isSubTask: false)
        store.dispatch(.updateMode(newMode))
    }

    // MARK: GroupedAssigneeViewModelDependency

    func appendAssignees(_ assignees: [Assignee], completion: ListCompletion?) {
        OwnerPicker.Track.finalAddClick(with: guid, isEdit: isEdit, isSubTask: false)
        store.dispatch(.appendAssignees(assignees), callback: completion)
    }

    func removeAssignees(_ assignees: [Assignee], completion: ListCompletion?) {
        store.dispatch(.removeAssignees(assignees), callback: completion)
        Detail.Track.clickRemoveAssignee(with: store.state.scene.todoId ?? "")
    }

    func customComplete(for assignee: Assignee) -> CustomComplete? {
        guard let todo = store.state.todo else { return nil }
        return completeService?.customComplete(from: todo)
    }

    func updateCompleted(_ isCompleted: Bool, for assignee: Assignee, completion: ((UserResponse<Bool>) -> Void)?) {
        let action: DetailModuleAction
        if assignee.identifier == currentUserId {
            let fromState: CompleteState
            switch store.state.completedState {
            case .assignee:
                fromState = .assignee(isCompleted: !isCompleted)
            case let .creatorAndAssignee(isTodoCompleted, _):
                fromState = .creatorAndAssignee(todo: isTodoCompleted, self: !isCompleted)
            default:
                completion?(.failure(.init(message: "")))
                return
            }
            action = .updateCurrentUserCompleted(fromState: fromState, role: .`self`)
        } else {
            action = .updateOtherAssigneeCompleted(identifier: assignee.identifier, isCompleted: isCompleted)
        }
        let oldCompleted = store.state.completedState.isCompleted
        store.dispatch(action, onState: nil) { [weak self] _ in
            guard let state = self?.store.state else { return }
            // 如果完成状态从 false -> true，则退出页面
            if oldCompleted == false && state.completedState.isCompleted {
                completion?(.success(true))
            } else {
                completion?(.success(false))
            }
        }

        Detail.Track.clickCompleteAssignee(with: store.state.todo?.guid ?? "", isCompleted: isCompleted)
    }

    func changeTaskMode(_ newMode: Rust.TaskMode, completion: ((UserResponse<Bool>) -> Void)?) {
        OwnerPicker.Track.changeDoneClick(with: guid, isEdit: isEdit, isSubTask: false)
        store.dispatch(.updateMode(newMode))
    }

}
