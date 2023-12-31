//
//  DetailViewModel.swift
//  Todo
//
//  Created by 白言韬 on 2021/1/25.
//

import RxSwift
import RxCocoa
import LarkContainer
import TodoInterface
import LarkAccountInterface
import LarkUIKit
import Foundation

/// Detail - ViewModel

final class DetailViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    enum ViewState {
        /// 待续
        case idle
        /// 加载中
        case loading(showLoading: Bool)
        /// 加载完成
        case succeed
        /// 加载失败
        case failed(ViewStateFailure)
    }

    let store: RxStore<DetailModuleState, DetailModuleAction>
    let rxViewState = BehaviorRelay<ViewState>(value: .idle)
    let rxRightNaviItems = BehaviorRelay<[NaviItem]>(value: [])
    let rxBottomCreate = BehaviorRelay<DetailBottomCreateViewDataType?>(value: nil)

    typealias ViewActionCallback = (UserResponse<Void>) -> Void

    /// 需要退出页面
    var onNeedsExit: ((DetailViewController.ExitReason) -> Void)?

    let input: DetailInput
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var todoService: TodoService?
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?
    @ScopedInjectedLazy private var shareService: ShareService?
    @ScopedInjectedLazy private var timeService: TimeService?
    @ScopedInjectedLazy private var anchorService: AnchorService?
    @ScopedInjectedLazy private var updateNoti: TodoUpdateNoti?
    @ScopedInjectedLazy private var completeService: CompleteService?
    @ScopedInjectedLazy private var passportService: PassportUserService?

    private var currentUserId: String { userResolver.userID }

    // 保存 Todo，使用串行队列进行保护
    private lazy var commitOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "TodoListQueueManagerQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()

    private var draftScene: Rust.DraftScene?

    init(resolver: UserResolver, input: DetailInput) {
        self.userResolver = resolver
        self.input = input
        let scene: DetailModuleState.Scene
        switch input {
        case .create(let source, _), .quickExpand(_, _, _, _, _, let source, _):
            scene = .create(source: source)
        case let .edit(guid, source, _):
            scene = .edit(guid: guid, source: source)
        }
        self.store = .init(name: "Detail.Store", state: .init(scene: scene))
    }

    /// 初始化
    func setup() {
        setupStore()
        setupNaviItem()
        setupBottomCreate()
        switch input {
        case .create(let source, _):
            Detail.logger.info("createWithContext source: \(source.logInfo)")
            Detail.Track.viewCreate()
            trackBeginCreating(with: source)
            setupForCreate(with: source)
            // 新建场景，可能会从其他业务域路径带入 RichContent，将其中的 Anchor Hang 资源给缓存起来，方便后续使用
            anchorService?.cacheHangEntities(in: store.state.richSummary)
            anchorService?.cacheHangEntities(in: store.state.richNotes)
        case .quickExpand(let todo, let subTasks, let relatedTaskLists, let sectionRefResult, let ownedSection, let source, _):
            Detail.Track.viewCreate()
            var todo = todo.fixedForCreating()
            if let origin = Rust.TodoOrigin(source: source) {
                todo.source = .chat
                todo.origin = origin
            }
            let res = Rust.DetailRes(
                todo: todo,
                subtasks: subTasks,
                relatedTaskLists: relatedTaskLists,
                sectionRefResult: sectionRefResult,
                ownedSection: ownedSection
            )
            updateStoreState(with: res, type: .initialize)
        case .edit(let guid, let source, _):
            Detail.logger.info("editWithContext guid:\(guid) source:\(source)")
            trackBeginEditing(with: guid, source: source)
            loadRustTodo(with: guid, source: source)
        }
    }

    // 加载失败重试
    func retryFromFail() {
        guard
            case .edit(let guid, let source, _) = input,
            store.state.todo == nil
        else {
            return
        }
        loadRustTodo(with: guid, source: source)
    }

    private func loadRustTodo(with guid: String, source: TodoEditSource) {
        rxViewState.accept(.loading(showLoading: source.showLoading))
        // 第一次加载
        let onFirstLoad = { [weak self] (res: Rust.DetailRes) -> Void in
            guard let self = self, let todo = res.todo else { return }
            Detail.logger.info("get todo success, todo:\(todo.logInfo)")
            guard self.setDefaultPage(todo) else {
                Detail.logger.info("get todo success but Blocked. isReadable: \(todo.selfPermission.isReadable), isDeleted: \(todo.isDeleted)")
                return
            }
            self.updateStoreState(with: res, type: .initialize)
            self.rxViewState.accept(.succeed)
            Detail.tracker(.todo_task_detail_view)
            Detail.Track.viewDetail(with: guid)
        }

        // 第二次加载
        let onSecondLoad = { [weak self] (res: Rust.DetailRes) -> Void in
            guard let self = self, let todo = res.todo else {
                return
            }
            guard self.setDefaultPage(todo) else { return }
            self.updateStoreState(with: res, type: .update)
            // 需要等待server接口返回才进行监听，否则parentTodo会被重置
            self.listenUpdateNoti(with: todo)
        }

        let onError = { [weak self] (error: Error) -> Void in
            if source.authScene != nil {
                Detail.logger.error("get shared todo error \(error)")
            } else {
                Detail.assertionFailure("get todo error \(error)", type: .loadFailed)
            }
            self?.rxViewState.accept(.failed(.needsRetry))
        }

        if let authScene = source.authScene {
            Detail.logger.info("Authorization Info. type: \(authScene.logInfo) id: \(authScene.id)")
            fetchApi?.getSharedTodo(byId: guid, authScene: authScene).take(1).asSingle()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(
                    onSuccess: { [weak self] res in
                        guard let todo = res.todo, todo.guid == guid else {
                            Detail.logger.info("getSharedTodos result is Empty")
                            self?.rxViewState.accept(.failed(.needsRetry))
                            return
                        }
                        onFirstLoad(res)
                        self?.loadServerTodo(with: res, onResult: onSecondLoad)
                    },
                    onError: onError
                )
                .disposed(by: disposeBag)
        } else {
            fetchApi?.getTodo(guid: guid).take(1).asSingle()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(
                    onSuccess: { [weak self] res in
                        onFirstLoad(res)
                        self?.loadServerTodo(with: res, onResult: onSecondLoad)
                    },
                    onError: onError
                )
                .disposed(by: disposeBag)
        }
    }

    private func loadServerTodo(with res: Rust.DetailRes, onResult: @escaping (Rust.DetailRes) -> Void) {
        guard let todo = res.todo else {
            Detail.assertionFailure()
            onResult(res)
            return
        }
        fetchApi?.getServerTodo(byId: todo.guid).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe { res in
                guard let newTodo = res.todo, newTodo.guid == todo.guid else {
                    Detail.logger.info("mgetServerTodos result is Empty")
                    return
                }
                Detail.logger.info("loadServerTodo succeed")
                onResult(res)
            } onError: { err in
                onResult(res)
                Detail.logger.error("loadServerTodo failed. error \(err)")
            }
            .disposed(by: disposeBag)
    }

    private func setupForCreate(with source: TodoCreateSource) {
        guard source.isEnableDraft() else {
            setupCreateStoreState(with: source)
            return
        }

        let draftScene = source.getDraftScene()
        self.draftScene = draftScene
        operateApi?.getTodoDraft(byScene: draftScene).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] draftTodo in
                    guard let self = self, let draftTodo = draftTodo, draftTodo.isValidDraft else {
                        self?.setupCreateStoreState(with: source)
                        return
                    }
                    var res = draftTodo.fixedForCreating()
                    if let origin = Rust.TodoOrigin(source: source) {
                        res.source = .chat
                        res.origin = origin
                    }
                    // 草稿的标题为空的时候，需要用chat里面的内容填充
                    if res.richSummary.richText.isEmpty,
                       case .chat(let context) = source,
                       let richSummary = context.extractRichSummary(SettingConfig(resolver: self.userResolver).summaryLimit) {
                        res.richSummary = richSummary
                    }
                    self.initializeStoreState(self.updateStoreState(with: res))
                },
                onError: { [weak self] err in
                    Detail.logger.error("get todo draft failed. error \(err)")
                    self?.setupCreateStoreState(with: source)
                }
            )
            .disposed(by: disposeBag)
    }

    private func setupCreateStoreState(with source: TodoCreateSource) {
        var state = updateStoreState(with: source.taskForCreate)
        state.permissions = setupPermissions(permission: .writable)
        if let user = User.current(passportService) {
            if source.autoFillOwner, state.assignees.isEmpty {
                // 只有任务中心才填充，草稿的时候不管
                state.assignees = [Assignee(member: .user(user))]
            }
        }
        switch source {
        case .chat(let chatContext):
            if let richSummary = chatContext.extractRichSummary(SettingConfig(resolver: userResolver).summaryLimit) {
                state.richSummary = richSummary
            }
            let refResourceStates = getRefResourceStates(by: chatContext)
            if !refResourceStates.isEmpty {
                state.refResourceStates = refResourceStates
            }
            var summaryUserIds = [String]()
            let richText = state.richSummary.richText
            for atEleId in richText.atIds {
                if let userId = richText.elements[atEleId]?.property.at.userID,
                   !userId.isEmpty {
                    summaryUserIds.append(userId)
                }
            }
            if summaryUserIds.isEmpty {
                initializeStoreState(state)
            } else {
                // 从 chat 中流入的 at 信息，可能包含了昵称，需要 fix 一下
                fetchApi?.getUsers(byIds: summaryUserIds)
                    .asDriver(onErrorJustReturn: [])
                    .drive(onNext: { [weak self] users in
                        var userIdNameMap = [String: String]()
                        users.forEach { userIdNameMap[$0.userID] = $0.name }
                        for (key, ele) in state.richSummary.richText.elements where ele.tag == .at {
                            if let fixedName = userIdNameMap[ele.property.at.userID], !fixedName.isEmpty {
                                state.richSummary.richText.elements[key]?.property.at.content = fixedName
                            }
                        }
                        self?.initializeStoreState(state)
                    })
                    .disposed(by: disposeBag)
            }
        case .list, .subTask, .inline:
            initializeStoreState(state)
        }
    }

    private func initializeStoreState(_ state: DetailModuleState) {
        var newState = state
        updateSelfRoleAndActiveChatters(from: &newState)
        store.initialize(newState)
    }

    private func getRefResourceStates(by chatContext: TodoCreateBody.ChatSourceContext) -> [DetailModuleState.RefResourceState] {
        var result = [DetailModuleState.RefResourceState]()
        switch chatContext.fromContent {
        case .textMessage, .chatKeyboard, .chatSetting, .postMessage:
            if let messageId = chatContext.messageId {
                result = [.untransformed(.message(messageIds: [messageId], chatId: chatContext.chatId, needsMerge: true))]
            }
        case .multiSelectMessages(let messageIds, _):
            result = [.untransformed(.message(messageIds: messageIds, chatId: chatContext.chatId, needsMerge: true))]
        case .mergeForwardMessage(let messageId, _):
            result = [.untransformed(.message(messageIds: [messageId], chatId: chatContext.chatId, needsMerge: false))]
        case .needsMergeMessage(let messageId, _):
            result = [.untransformed(.message(messageIds: [messageId], chatId: chatContext.chatId, needsMerge: true))]
        case .threadMessage(_, _, let threadId):
            result = [.untransformed(.thread(threadId: threadId))]
        default:
            break
        }
        return result
    }

    private func setupPermissions(pbPermissions: Rust.DetailPermissions) -> DetailPermissions {
        var permissions = DetailPermissions()
        permissions.upgradePermissions(by: pbPermissions.canReadCommitKeys, permission: .readable)
        permissions.upgradePermissions(by: pbPermissions.canEditCommitKeys, permission: .writable)
        Detail.logger.info("setupPermissions readKeys: \(pbPermissions.canReadCommitKeys) editKeys: \(pbPermissions.canEditCommitKeys) permissions: \(permissions)")
        return permissions
    }

    private func setupPermissions(permission: PermissionOption) -> DetailPermissions {
        let permissions = DetailPermissions(
            summary: permission,
            notes: permission,
            refMessage: permission,
            assignee: permission,
            follower: permission,
            dueTime: permission,
            rrule: permission,
            origin: permission,
            subTask: permission,
            comment: permission,
            attachment: permission,
            customFields: permission
        )
        return permissions
    }

}

// MARK: - Setup Store

extension DetailViewModel {

    private func setupStore() {
        store.registerReducer { [weak self] state, action, callback in
            guard let self = self else {
                callback?(.success(void))
                return state
            }
            let newState = self.reduceStoreState(with: state, action: action)

            if state.scene.isForEditing {
                self.commitStoreAction(action, fromState: state, toState: newState, callback: callback)
            } else {
                callback?(.success(void))
            }

            return newState
        }
    }

    private func reduceStoreState(with preState: DetailModuleState, action: DetailModuleAction) -> DetailModuleState {
        var newState = preState
        var memberMaybeChanged = false
        switch action {
        case .updateMode(let mode):
            newState.mode = mode
        case .updateDependents(let dependents, let dependentsMap):
            newState.dependents = dependents
            newState.dependentsMap = dependentsMap
        case .updateMilestone(let state):
            newState.isMilestone = state
        case let .updateSummary(summary):
            newState.richSummary = summary
        case let .updateNotes(notes):
            newState.richNotes = notes
        case let .updateTime(t):
            newState.startTime = t.startTime
            newState.dueTime = t.dueTime
            newState.isAllDay = t.isAllDay
            newState.reminder = t.reminder
            newState.rrule = t.rrule
        case .clearTime:
            newState.startTime = nil
            newState.dueTime = nil
            newState.isAllDay = false
            newState.reminder = nil
            newState.rrule = nil
        case let .updateRefResources(refResources):
            newState.refResourceStates = refResources
        case let .appendAssignees(assignees):
            appendAssignees(assignees, to: &newState)
            assignees.forEach { removeReserveAssignee(by: $0.identifier, from: &newState) }
            memberMaybeChanged = true
        case let .removeAssignees(assignees):
            removeAssignees(by: assignees.map(\.identifier), from: &newState)
            assignees.forEach { removeReserveAssignee(by: $0.identifier, from: &newState) }
            memberMaybeChanged = true
        case let .updateReserveAssignee(assignee):
            if let lastReserveAssignee = newState.reserveAssignee {
                appendAssignees([lastReserveAssignee], to: &newState)
            }
            newState.reserveAssignee = assignee
            memberMaybeChanged = true
        case let .removeReserveAssignee(assignee):
            removeReserveAssignee(by: assignee.identifier, from: &newState)
            memberMaybeChanged = true
        case .clearAssignees:
            newState.assignees = []
            memberMaybeChanged = true
        case let .resetAssignees(assignees):
            newState.assignees = assignees
            memberMaybeChanged = true
        case let .appendFollowers(followers):
            appendFollowers(followers, to: &newState)
            memberMaybeChanged = true
        case let .removeFollowers(followers):
            removeFollowers(by: followers.map(\.identifier), from: &newState)
            memberMaybeChanged = true
        case let .updateFollowing(isFollowed):
            if isFollowed {
                if let user = User.current(passportService) {
                    appendFollowers([.init(member: .user(user))], to: &newState)
                }
            } else {
                removeFollowers(by: [currentUserId], from: &newState)
            }
            memberMaybeChanged = true
        case let .updateCurrentUserCompleted(fromState, role):
            updateCompleteState(with: fromState, role: role, to: &newState)
        case let .updateOtherAssigneeCompleted(identifier, isCompleted):
            updateOtherAssigneeCompleted(isCompleted, for: identifier, to: &newState)
        case .updateTaskList(let taskLists, let sectionRefResult):
            newState.relatedTaskLists = taskLists
            newState.sectionRefResult = sectionRefResult
        case .updateOwnSection(let containerSection):
            newState.ownedSection = containerSection
        case let .updateSubtasksState(state):
            newState.subtasksState = state
        case let .updatePermissions(permissions):
            newState.permissions = permissions
        case let .removeAttachments(attachments):
            removeAttachments(by: attachments.map(\.guid), from: &newState)
        case let .localUpdateAttachments(attachments):
            newState.attachments = attachments
            newState.todo?.attachments = attachments
        case let .updateUploadingAttachments(infos):
            newState.uploadingAttachments = infos
        case let .updateCustomFields(val):
            newState.customFieldValues[val.fieldKey] = val
        }
        if memberMaybeChanged {
            updateSelfRoleAndActiveChatters(from: &newState)
        }
        return newState
    }

    private func appendAssignees(_ assignees: [Assignee], to state: inout DetailModuleState) {
        var exists = Set<String>()
        state.assignees.forEach { exists.insert($0.identifier) }
        let appending = assignees.filter { !exists.contains($0.identifier) }
        state.assignees.append(contentsOf: appending)
    }

    private func removeReserveAssignee(by identifier: String, from state: inout DetailModuleState) {
        if state.reserveAssignee?.identifier == identifier {
            state.reserveAssignee = nil
        }
    }

    private func removeAssignees(by identifiers: [String], from state: inout DetailModuleState) {
        let needsRemove = Set(identifiers)
        state.assignees = state.assignees.filter { !needsRemove.contains($0.identifier) }
    }

    private func appendFollowers(_ followers: [Follower], to state: inout DetailModuleState) {
        var exists = Set<String>()
        state.followers.forEach { exists.insert($0.identifier) }
        let appending = followers.filter { !exists.contains($0.identifier) }
        state.followers.append(contentsOf: appending)
    }

    private func removeFollowers(by identifiers: [String], from state: inout DetailModuleState) {
        let needsRemove = Set(identifiers)
        state.followers = state.followers.filter { !needsRemove.contains($0.identifier) }
    }

    private func removeAttachments(by guids: [String], from state: inout DetailModuleState) {
        let needsRemove = Set(guids)
        state.attachments = state.attachments.filter { !needsRemove.contains($0.guid) }
    }

    private func updateSelfRoleAndActiveChatters(from state: inout DetailModuleState) {
        // acitveChatters = currentUser + owner + assigner + creator + assignees + followers
        var acitveChatters = Set<String>()
        var selfRole = MemberRole()
        defer {
            state.activeChatters = acitveChatters
            state.selfRole = selfRole
        }
        if store.state.scene.isForCreating {
            acitveChatters.insert(currentUserId)
            selfRole.insert(.creator)
        } else {
            if let assignerId = state.assigner?.chatterId {
                acitveChatters.insert(assignerId)
            }
            if let creatorId = state.todo?.creatorID {
                acitveChatters.insert(creatorId)
                if creatorId == currentUserId {
                    selfRole.insert(.creator)
                }
            }
        }

        if let user = state.reserveAssignee?.asUser() {
            acitveChatters.insert(user.chatterId)
        }
        for user in state.assignees.compactMap({ $0.asUser() }) {
            acitveChatters.insert(user.chatterId)
            if user.chatterId == currentUserId {
                selfRole.insert(.assignee)
            }
        }
        for user in state.followers.compactMap({ $0.asUser() }) {
            acitveChatters.insert(user.chatterId)
            if user.chatterId == currentUserId {
                selfRole.insert(.follower)
            }
        }
    }

    private func updateCompleteState(
        with fromState: CompleteState,
        role: CompleteRole,
        to state: inout DetailModuleState
    ) {
        let toState = fromState.toggled(by: role)
        state.completedState = toState

        var markCompleted = false
        var needsMarkAll = false
        switch toState {
        case .assignee(let isCompleted):
            needsMarkAll = false
            markCompleted = isCompleted
        case let .classicMode(isCompleted, isOutsider):
            if isOutsider {
                return
            }
            needsMarkAll = true
            markCompleted = isCompleted
        case let .creator(isCompleted):
            needsMarkAll = true
            markCompleted = isCompleted
        case let .creatorAndAssignee(isTodoCompleted, isSelfCompleted):
            needsMarkAll = role == .todo
            markCompleted = role == .todo ? isTodoCompleted : isSelfCompleted
        case .outsider:
            return
        }
        let completedTime = markCompleted ? Int64(Date().timeIntervalSince1970 * 1_000) : nil
        for i in 0..<state.assignees.count {
            if needsMarkAll || state.assignees[i].identifier == currentUserId {
                state.assignees[i].completedTime = completedTime
            }
        }
    }

    private func updateOtherAssigneeCompleted(
        _ isCompleted: Bool,
        for identifier: String,
        to state: inout DetailModuleState
    ) {
        if identifier == currentUserId {
            switch state.completedState {
            case .assignee:
                state.completedState = .assignee(isCompleted: isCompleted)
            case let .creatorAndAssignee(isTodoCompleted, _):
                state.completedState = .creatorAndAssignee(todo: isTodoCompleted, self: isCompleted)
            default:
                break
            }
        }
        for i in 0..<state.assignees.count where state.assignees[i].identifier == identifier {
            state.assignees[i].completedTime = isCompleted ? Int64(Date().timeIntervalSince1970 * 1_000) : nil
        }
    }

}

// MARK: - push

extension DetailViewModel {

    private func listenUpdateNoti(with todo: Rust.Todo) {
        updateNoti?.rxDiffUpdate
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] changeset in
                guard let self = self else { return }
                Detail.logger.info("detail push count: \(changeset.todos.count)")
                if let newTodo = changeset.todos.first(where: { $0.guid == todo.guid }) {
                    Detail.logger.info("detail push todo info: \(newTodo.logInfo)")
                    // 删除后全部退出
                    guard !newTodo.isDeleted else {
                        self.onNeedsExit?(.delete)
                        return
                    }
                    guard self.setDefaultPage(newTodo) else {
                        return
                    }
                    self.updateDetailState(by: newTodo)
                }
            })
            .disposed(by: disposeBag)
    }

    /// 在无权限或者删除的时候会展示落地页
    private func setDefaultPage(_ todo: Rust.Todo) -> Bool {
        guard todo.selfPermission.isReadable && !todo.isDeleted else {
            setupNaviItemForDisable()
            rxViewState.accept(.failed(todo.isDeleted ? .deleted : .noAuth))
            return false
        }
        return true
    }

    private func updateDetailState(by newTodo: Rust.Todo) {
        var depsMap = [String: Rust.Todo]()
        if let deps = store.state.dependents, !deps.isEmpty {
            deps.forEach { ref in
                if let value = store.state.dependentsMap?[ref.dependentTaskGuid] {
                    depsMap[ref.dependentTaskGuid] = value
                }
            }
        }
        // 重新更新 state
        let detailRes = Rust.DetailRes(
            todo: newTodo,
            parentTodo: store.state.parentTodo?.todo,
            ancestors: store.state.ancestors,
            relatedTaskLists: store.state.relatedTaskLists,
            sectionRefResult: store.state.sectionRefResult,
            ownedSection: newTodo.isAssignee(currentUserId) ? store.state.ownedSection : .init(),
            containerTaskFieldAssocList: store.state.containerTaskFieldAssocList,
            dependentTaskMap: depsMap
        )
        updateStoreState(with: detailRes, type: .update)
    }
}

// MARK: - Update StoreState

extension DetailViewModel {

    enum UpdateStateType: String {
        case initialize         // 初始化
        case update             // 更新
        case toggleComplete     // 切换完成状态
    }

    private func updateStoreState(with res: Rust.DetailRes, type: UpdateStateType) {
        guard let todo = res.todo else {
            Detail.assertionFailure()
            return
        }
        var state = updateStoreState(with: todo)

        state.relatedTaskLists = res.relatedTaskLists
        if let sectionRefResult = res.sectionRefResult {
            state.sectionRefResult = sectionRefResult
        }
        if let ownedSection = res.ownedSection {
            state.ownedSection = ownedSection
        }
        state.ancestors = res.ancestors
        state.parentTodo = .init(todo: res.parentTodo, isLoadSdk: type == .initialize)
        state.dependentsMap = res.dependentTaskMap
        if let subtasks = res.subtasks {
            state.subtasksState = .initData(subtasks: subtasks)
        }
        state.containerTaskFieldAssocList = res.containerTaskFieldAssocList
        updateSelfRoleAndActiveChatters(from: &state)
        switch type {
        case .initialize:
            store.initialize(state)
        default:
            store.setState(state)
        }
    }

    private func updateStoreState(with task: Rust.Todo?) -> DetailModuleState {
        guard let newTask = task else { return store.state }
        var state = store.state
        state.todo = newTask
        state.mode = newTask.mode
        switch newTask.source {
        case .doc, .oapi:
            state.permissions = setupPermissions(pbPermissions: newTask.selfPermission)
        @unknown default:
            state.permissions = setupPermissions(permission: newTask.selfPermission.isEditable ? .writable : .readable)
        }
        state.dependents = newTask.dependents
        state.isMilestone = newTask.isMilestone
        state.richSummary = newTask.richSummary
        state.completedState = completeService?.state(for: newTask) ?? .outsider(isCompleted: false)
        state.richNotes = newTask.richDescription
        state.assigner = newTask.hasAssigner ? User(pb: newTask.assigner) : nil
        state.assignees = newTask.assignees.map(Assignee.init(model:))
        state.followers = newTask.followers.map(Follower.init(model:))
        state.startTime = newTask.isStartTimeValid ? newTask.startTimeForFormat : nil
        state.dueTime = newTask.isDueTimeValid ? newTask.dueTime : nil
        if let pbReminder = newTask.reminders.first {
            state.reminder = Reminder(pb: pbReminder)
        }
        state.isAllDay = newTask.isAllDay
        state.rrule = newTask.isRRuleValid ? newTask.rrule : nil
        state.refResourceStates = newTask.referResourceIds.map(DetailModuleState.RefResourceState.normal(id:))
        state.attachments = newTask.attachments
        state.customFieldValues = newTask.customFieldValues
        return state
    }

}

// MARK: - Navi ViewData

extension DetailViewModel {

    enum NaviItemType: Hashable {
        case minimize         // present时返回
        case subscribe        // 订阅
        case subscribed       // 已订阅
        case copyNum          // 复制ID
        case create           // 新建 ipad 全屏创建
        case share            // 分享
        case more             // 更多
    }

    enum NaviMoreItemType: Int {
        case preDependent   // 前置任务
        case nextDepedent   // 后置任务
        case milestone      // 里程碑
        case editRecord     // 历史记录
        case report         // 举报
        case delete         // 删除
        case quit           // 退出
        case copyTaskGuid   // debug 按钮
        case copyTaskInfo   // debug 按钮
    }

    struct NaviItem {
        var type: NaviItemType
        var isEnabled: Bool
    }

    func naviMoreItems() -> [NaviMoreItemType] {
        let state = store.state
        guard state.scene.isForEditing, let todo = state.todo else { return [] }

        var ret = [NaviMoreItemType]()
        if todo.editable(for: .todoDependent), FeatureGating.boolValue(for: .gantt) {
            ret.append(.preDependent)
            ret.append(.nextDepedent)
        }
        if todo.editable(for: .todoIsMilestone), FeatureGating.boolValue(for: .gantt) {
            ret.append(.milestone)
        }
        if FeatureGating(resolver: userResolver).boolValue(for: .history) {
            ret.append(.editRecord)
        }

        if FeatureGating(resolver: userResolver).boolValue(for: .report) { ret.append(.report) }

        if todo.source == .doc {
            if state.selfRole.contains(.assignee) { ret.append(.quit) }
        } else {
            if todo.editable(for: .todoDeletedTime) {
                ret.append(.delete)
            } else if state.selfRole.contains(.assignee) || state.selfRole.contains(.owner) || state.selfRole.contains(.follower) {
                ret.append(.quit)
            } else {
                // do noting
            }
        }
        if FeatureGatingKey.isDebugMode {
            ret.append(.copyTaskGuid)
            ret.append(.copyTaskInfo)
        }
        return ret
    }

    private func setupNaviItem() {
        store.rxInitialized()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onSuccess: { [weak self] _ in
                guard let self = self else { return }
                if self.store.state.scene.isForCreating {
                    self.setupNaviItemForCreating()
                } else {
                    self.setupNaviItemForEditing()
                }
            })
            .disposed(by: disposeBag)

        store.rxValue(forKeyPath: \.selfRole)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.store.state.scene.isForEditing else {
                    // 只有编辑态下才用
                    return
                }
                self.setupNaviItemForEditing()
            })
            .disposed(by: disposeBag)

    }

    // 新建场景，设置 navi item
    private func setupNaviItemForCreating() {
        if Display.pad {
            Observable.combineLatest(
                store.rxValue(forKeyPath: \.richSummary),
                store.rxValue(forKeyPath: \.uploadingAttachments)
            )
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
                .subscribe(onNext: { [weak self] (richSummary, uploadingAttachments) in
                    let isEnabled = richSummary.richText.hasVisibleContent() && uploadingAttachments.isEmpty
                    self?.rxRightNaviItems.accept([.init(type: .create, isEnabled: isEnabled)])
                })
                .disposed(by: disposeBag)
        } else {
            guard input.isQiuckCreate else { return }
            rxRightNaviItems.accept([
                NaviItem(type: .minimize, isEnabled: true)
            ])
        }
    }

    // 编辑场景，设置 navi item
    private func setupNaviItemForEditing() {
        if case .failed = rxViewState.value {
            setupNaviItemForDisable()
        } else {
            var items = [
                NaviItem(type: .more, isEnabled: true),
                NaviItem(type: .share, isEnabled: true)
                ]
            if FeatureGating(resolver: userResolver).boolValue(for: .entityNum), taskNumber != nil {
                items.insert(NaviItem(type: .copyNum, isEnabled: true), at: 1)
            }
            let subscribed = store.state.selfRole.contains(.follower)
            let type: NaviItemType = subscribed ? .subscribed : .subscribe
            items.append(NaviItem(type: type, isEnabled: true))
            rxRightNaviItems.accept(items)
        }
    }

    // 不可用场景（无权限，已删除），设置 navi item
    private func setupNaviItemForDisable() {
        rxRightNaviItems.accept([])
    }

    var taskNumber: String? {
        guard store.state.scene.isForEditing, let todo = store.state.todo else {
            return nil
        }
        return todo.entityNum.num
    }

    var taskNumberURL: String? {
        guard store.state.scene.isForEditing, let todo = store.state.todo else {
            return nil
        }
        return todo.entityNum.url
    }

}

// MARK: - Bottom Create ViewData

extension DetailViewModel {

    struct BottomViewData: DetailBottomCreateViewDataType {
        var checkboxTitle: String
        var title: String
        var isEnabled: Bool
    }

    private func setupBottomCreate() {
        guard hasBottomCrateView() else { return }
        Observable.combineLatest(
            store.rxValue(forKeyPath: \.richSummary),
            store.rxValue(forKeyPath: \.uploadingAttachments)
        )
        .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
        .subscribe(onNext: { [weak self] (richSummary, uploadingAttachments) in
            guard let self = self else { return }
            let isEnabled = richSummary.richText.hasVisibleContent() && uploadingAttachments.isEmpty
            let checkboxTitle = self.store.state.scene.sendToChatCheckboxTitle
            let title = self.store.state.scene.createBtnTitle
            let viewData = BottomViewData(checkboxTitle: checkboxTitle, title: title, isEnabled: isEnabled)
            self.rxBottomCreate.accept(viewData)
        })
        .disposed(by: disposeBag)
    }

    // 只有手机且新建场景下才有底部新建
    func hasBottomCrateView() -> Bool {
        if store.state.scene.isForCreating, !Display.pad {
            return true
        }
        return false
    }

    var createViewHeight: CGFloat { 44.0 }

}

// MARK: - Navi Action - Exit

extension DetailViewModel {

    /// 退出（用户点击 close/back 按钮）
    func handleExitAction() {
        switch input {
        case .create(_, let callbacks):
            Detail.tracker(.todo_create_cancel)
            let todo = makeTodoForCreating()
            callbacks.cancelHandler?(todo, nil, nil, nil, nil)
            saveDraft(todo)
        case .quickExpand(_, _, _, _, _, _, let callbacks):
            Detail.tracker(.todo_create_cancel)
            var subtasks: [Rust.Todo]?
            if case .dataCallback(let callback) = store.state.subtasksState {
                subtasks = callback()
            }
            callbacks.cancelHandler?(
                makeTodoForCreating(),
                subtasks,
                store.state.relatedTaskLists,
                store.state.sectionRefResult,
                store.state.ownedSection
            )
        case .edit:
            Detail.tracker(.todo_task_close, params: ["task_id": store.state.scene.todoId ?? ""])
        }
    }

}

// MARK: - Navi Action - Create

extension DetailViewModel {

    /// 新建 Todo
    func createTodo(with callback: @escaping (UserResponse<Rust.Todo>) -> Void) {
        var chatContext: TodoCreateBody.ChatSourceContext?
        switch input {
        case .create(let source, _), .quickExpand(_, _, _, _, _, let source, _):
            if case .chat(let context) = source {
                chatContext = context
            }
        case .edit:
            Detail.assertionFailure("out of case in detail")
        }

        doCreate { [weak self] res in
            switch res {
            case .failure(let userErr):
                callback(.failure(userErr))
                self?.saveDraft()
            case .success(let todo):
                callback(.success(todo))
                self?.deleteDraft()

                guard let self = self, let chatContext = chatContext else { return }
                self.shareIfNeeded(with: todo, chatContext: chatContext, callback: callback)
            }
        }
    }

    private func doCreate(with callback: @escaping (UserResponse<Rust.Todo>) -> Void) {
        let trackerTask = Tracker.Appreciable.Task(scene: .create, event: .createTodo).resume()
        if store.state.scene.isForSubTaskCreating {
            guard let req = getSubTaskReq() else { return callback(.success(makeTodoForCreating())) }
            operateApi?.createSubTask(in: req.ancestorGuid, with: req.subTasks)
                .observeOn(MainScheduler.instance)
                .subscribe(
                    onNext: { [weak self] todos in
                        guard let self = self, let subTask = todos.first else { return }
                        callback(.success(subTask))
                        trackerTask.complete()
                        Detail.logger.info("create sub task succeed. todo: \(subTask.logInfo)")
                        self.trackEndCreating(with: subTask)
                    },
                    onError: { [weak self] err in
                        guard let self = self  else { return }
                        trackerTask.error(err)
                        Detail.assertionFailure("create sub task failed. error: \(err)", type: .saveFailed)
                        callback(.failure(self.makeRequestError(err)))
                    }
                )
                .disposed(by: disposeBag)
        } else {
            var subtasks = [Rust.Todo]()
            if case .dataCallback(let callback) = store.state.subtasksState {
                subtasks = callback()
            }
            let containerSection = store.state.ownedSection
            operateApi?.createTodo(makeTodoForCreating(), with: subtasks, and: containerSection, or: store.state.taskListForCreateReq)
                .observeOn(MainScheduler.instance)
                .subscribe(
                    onNext: { [weak self] res in
                        callback(.success(res.todo))
                        trackerTask.complete()
                        Detail.logger.info("createTodo succeed. todo: \(res.todo.logInfo)")
                        switch self?.input {
                        case .create(_, let callbacks), .quickExpand(_, _, _, _, _, _, let callbacks):
                            callbacks.createHandler?(res)
                        default:
                            break
                        }
                        self?.trackEndCreating(with: res.todo)
                    },
                    onError: { [weak self] err in
                        guard let self = self else { return }
                        trackerTask.error(err)
                        Detail.assertionFailure("createTodo failed. error: \(err)", type: .saveFailed)
                        callback(.failure(self.makeRequestError(err)))
                    }
                )
                .disposed(by: disposeBag)
        }
    }

    private func makeRequestError(_ err: Error) -> UserError {
        var userErr = Rust.makeUserError(from: err)
        switch userErr.bizCode() {
        case .assigneeLimit:
            userErr.message = I18N.Todo_UnableToAddMoreThanNumCollabs_Toast(SettingConfig(resolver: userResolver).getAssingeeLimit)
        case .followerLimit:
            userErr.message = I18N.Todo_Task_FollowerLimitToast(SettingConfig(resolver: userResolver).getFollowerLimit)
        default:
            userErr.message = I18N.Todo_common_ActionFailedTryAgainLater
        }
        return userErr
    }

    // for 一键指派和子任务
    private func getSubTaskReq() -> (ancestorGuid: String, subTasks: [Rust.Todo])? {
        guard store.state.scene.isForSubTaskCreating else { return nil }
        let subTasks: [Rust.Todo]
        let ancestorGuid: String
        switch input {
        case.create(let source, _):
            let todoForCreate = makeTodoForCreating()
            switch source {
            case .subTask(let ancestorId, _, _):
                subTasks = [todoForCreate]
                ancestorGuid = ancestorId
            default: return nil
            }
        default: return nil
        }
        return (ancestorGuid, subTasks)
    }

    private func shareIfNeeded(
        with todo: Rust.Todo,
        chatContext: TodoCreateBody.ChatSourceContext,
        callback: @escaping (UserResponse<Rust.Todo>) -> Void
    ) {
        guard let service = todoService, service.getSendToChatIsSeleted() else { return }
        // chatSetting 场景会自己处理发送到会话的逻辑
        if case .chatSetting = chatContext.fromContent { return }

        let item: SelectSharingItemBody.SharingItem
        if let threadId = chatContext.threadId, !threadId.isEmpty {
            if chatContext.isThread {
                item = .thread(threadId: threadId, chatId: chatContext.chatId)
            } else {
                item = .replyThread(threadId: threadId, chatId: chatContext.chatId)
            }
        } else {
            item = .chat(chatId: chatContext.chatId)
        }

        shareService?.shareToLark(
            withTodoId: todo.guid,
            items: [item],
            type: .create,
            message: nil,
            completion: { shareResult in
                switch shareResult {
                case .success(_, let blockAlert):
                    if let blockAlert = blockAlert {
                        callback(.failure(UserError(message: blockAlert.message)))
                    }
                case .failure(let message):
                    callback(.failure(UserError(message: message)))
                }
            }
        )
        // show share guide in chat
        if service.shouldDisplayGuideToastInChat() {
            chatContext.chatGuideHandler?(nil)
        }
    }

    private func makeTodoForCreating() -> Rust.Todo {
        var todo = Rust.Todo().fixedForCreating()
        let state = store.state
        if case .create(let source) = state.scene, let origin = Rust.TodoOrigin(source: source) {
            todo.source = .chat
            todo.origin = origin
        }
        todo.mode = state.mode
        todo.isMilestone = false
        todo.richSummary = state.richSummary
        todo.richDescription = state.richNotes
        todo.assignees = state.assignees.map { $0.asModel() }
        if let assignee = state.reserveAssignee {
            todo.assignees.append(assignee.asModel())
        }
        todo.followers = state.followers.map { $0.asModel() }
        if let reminder = state.reminder {
            todo.reminders = [reminder.toPb()]
        } else {
            todo.reminders = []
        }
        todo.isAllDay = state.isAllDay
        if let rrule = state.rrule {
            todo.rrule = rrule
        } else {
            todo.rrule = ""
        }
        todo.startMilliTime = (state.startTime ?? 0) * Utils.TimeFormat.Thousandth
        todo.dueTimezone = state.isAllDay ? "UTC" : TimeZone.current.identifier
        if let dueTime = state.dueTime {
            todo.dueTime = dueTime
        } else {
            todo.dueTime = 0
        }
        todo.referResourceIds = state.refResourceStates.compactMap { rState -> String? in
            guard case .normal(let resourceId) = rState else { return nil }
            return resourceId
        }
        todo.attachments = state.attachments
        todo.customFieldValues = state.customFieldValues
        return todo
    }

    // 保存草稿
    private func saveDraft(_ draftTodo: Rust.Todo? = nil) {
        let todo = draftTodo ?? makeTodoForCreating()
        if let scene = draftScene {
            operateApi?.saveTodoDraft(todo, scene: scene).subscribe().disposed(by: disposeBag)
        }
    }

    // 删除草稿
    private func deleteDraft() {
        if let scene = draftScene {
            operateApi?.deleteTodoDraft(byScene: scene).subscribe().disposed(by: disposeBag)
        }
    }
}

// MARK: - Navi Action - Delete

extension DetailViewModel {

    /// 删除 Todo
    func deleteTodo(with callback: @escaping ViewActionCallback) {
        guard let todo = store.state.todo else {
            callback(.success(void))
            assertionFailure()
            return
        }
        operateApi?.deleteTodo(forId: todo.guid, source: todo.source)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    callback(.success(void))
                    guard let self = self else { return }
                    if case .edit(_, _, let callbacks) = self.input {
                        var cTodo = todo
                        cTodo.deletedMilliTime = Int64(Date().timeIntervalSince1970) * Utils.TimeFormat.Thousandth
                        callbacks.deleteHandler?(cTodo)
                    }
                },
                onError: { err in
                    callback(.failure(Rust.makeUserError(from: err)))
                }
            )
            .disposed(by: disposeBag)
    }

    func hideDeleteActionTitle() -> Bool {
        let assignees = store.state.assignees
        // 自己是创建者且没有执行者
        if store.state.selfRole.contains(.creator), assignees.isEmpty {
            return true
        }
        // 自己是唯一的执行者
        if assignees.count == 1, assignees.contains(where: { $0.identifier == currentUserId }) {
            return true
        }
        return false
    }

}

// MARK: - Navi Action - Quit

extension DetailViewModel {

    /// 不再参与 Todo
    func quitTodo(with callback: @escaping ViewActionCallback) {
        guard let todo = store.state.todo else {
            callback(.success(void))
            assertionFailure()
            return
        }
        operateApi?.quitTodo(forId: todo.guid, source: todo.source)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    callback(.success(void))
                    guard let self = self else { return }
                    if case .edit(_, _, let callbacks) = self.input {
                        var cTodo = todo
                        cTodo.assignees = cTodo.assignees.filter { $0.identifier != self.currentUserId }
                        callbacks.deleteHandler?(cTodo)
                    }
                },
                onError: { err in
                    var userErr = Rust.makeUserError(from: err)
                    if todo.source == .oapi {
                        userErr.message = I18N.Todo_Tasks_APICantExit
                    }
                    callback(.failure(userErr))
                }
            )
            .disposed(by: disposeBag)
    }

}

// MARK: - Navi Action - Share

extension DetailViewModel {

    func summaryForSharing() -> String {
        return Utils.RichText.makePlainText(from: store.state.richSummary)
    }

    func shareToLark(
        with items: [SelectSharingItemBody.SharingItem],
        message: String?,
        completion: ((ShareToLarkResult) -> Void)?
    ) {
        shareService?.shareToLark(
            withTodoId: store.state.scene.todoId ?? "",
            items: items,
            type: .share,
            message: message,
            completion: completion
        )
    }

}

// MARK: - Navi Action - Subscribe

extension DetailViewModel {

    typealias ToggleCallback = (UserResponse<(toast: String, needsExit: Bool)>) -> Void

    struct AlertContext {
        var title: String
        var item: String
        var before: ((String) -> Void)?
        var confirm: (((String) -> Void)?, @escaping ToggleCallback) -> Void
    }

    func alertBeforeToggling() -> AlertContext? {
        guard store.state.selfRole == .follower else { return nil }
        let title = I18N.Todo_Task_UnfollowCantSeeInTaskCenter
        let item = I18N.Todo_NoLongerFollowTask_Button
        return .init(title: title, item: item) { [weak self] (before, after) in
            self?.setFollowed(false, before: before, after: after)
        }
    }

    func toggleFollowing(before beforeCallBack: ((String) -> Void)? = nil, after callback: @escaping ToggleCallback) {
        let followed = store.state.selfRole.contains(.follower)
        setFollowed(!followed, before: beforeCallBack, after: callback)
    }

    private func setFollowed(_ followed: Bool, before beforeCallBack: ((String) -> Void)? = nil, after callback: @escaping ToggleCallback) {
        let needsExit = store.state.selfRole == .follower
        let toast = followed ? I18N.Todo_Task_SuccesfullyFollow : I18N.Todo_Task_UnfollowedToast
        if !followed, let todo = store.state.todo {
            Detail.Track.clickLeave(with: todo.guid)
        }
        let beforeToast = followed ? I18N.Todo_Task_FollowingToast : I18N.Todo_Task_UnfollowingToast
        beforeCallBack?(beforeToast)
        store.dispatch(.updateFollowing(followed), onState: nil) { res in
            switch res {
            case .success:
                callback(.success((toast, needsExit)))
            case .failure(let userErr):
                callback(.failure(userErr))
            }
        }
    }
}

// MARK: - Commit Editing

extension DetailViewModel {

    /// 同步编辑内容的 Operation
    private final class CommitOperation: Operation {

        private let starter: () -> Single<Void>
        private var disposable: Disposable?

        init(starter: @escaping () -> Single<Void>) {
            self.starter = starter
            super.init()
        }

        deinit {
            disposable?.dispose()
        }

        override func start() {
            if !self.isCancelled {
                self.isExecuting = true
                self.isFinished = false
                disposable = starter().subscribe(
                    onSuccess: { [weak self] in
                        self?.isExecuting = false
                        self?.isFinished = true
                    },
                    onError: { [weak self] _ in
                        self?.isExecuting = false
                        self?.isFinished = true
                    }
                )
            } else {
                self.isExecuting = false
                self.isFinished = true
            }
        }

        private var _executing = false
        override var isExecuting: Bool {
            get { return _executing }
            set {
                if newValue != _executing {
                    willChangeValue(forKey: "isExecuting")
                    _executing = newValue
                    didChangeValue(forKey: "isExecuting")
                }
            }
        }

        private var _finished = false
        override var isFinished: Bool {
            get { return _finished }
            set {
                if newValue != _finished {
                    willChangeValue(forKey: "isFinished")
                    _finished = newValue
                    didChangeValue(forKey: "isFinished")
                }
            }
        }

        override func cancel() {
            super.cancel()
            disposable?.dispose()
        }

        override var isAsynchronous: Bool {
            return true
        }

    }

    private func commitStoreAction(
        _ action: DetailModuleAction,
        fromState: DetailModuleState,
        toState: DetailModuleState,
        callback: ((UserResponse<Void>) -> Void)?
    ) {
        let operation = CommitOperation { [weak self] in
            guard
                let self = self,
                let fromTodo = self.store.state.todo,
                let commit = self.makeCommit(from: action, with: fromState),
                let operateApi = self.operateApi,
                let completeService = self.completeService,
                let fetchApi = self.fetchApi
            else {
                return .just(void)
            }
            let single: Single<Rust.Todo>
            switch commit {
            case .field(let fieldCommit):
                let toTodo = self.mergeState(toState, to: fromTodo, with: fieldCommit)
                single = operateApi.updateTodo(from: fromTodo, to: toTodo, with: nil).take(1).asSingle()
            case .following(let isFollow):
                var authScene: Rust.DetailAuthScene?
                if case .edit(_, let source, _) = self.input {
                    authScene = source.authScene
                }
                single = operateApi.followTodo(forId: fromTodo.guid, isFollow: isFollow, authScene: authScene)
                    .take(1).asSingle()
            case .complete(let ctx):
                let (todoId, todoSource) = (fromTodo.guid, fromTodo.source)
                single = completeService.toggleState(with: ctx, todoId: todoId, todoSource: todoSource, containerID: nil)
                    .map { res in
                        if fromTodo.source == .doc {
                            // 此处针对 Doc Todo 进行特化，complete Doc Todo 不会返回有效的 Todo；
                            // 所以使用当前的 todo 进行 fix 处理然后再返回
                            var fixedTodo = fromTodo
                            if res.newState.isCompleted {
                                fixedTodo.completedMilliTime = Int64(Date().timeIntervalSince1970) * Utils.TimeFormat.Thousandth
                            } else {
                                fixedTodo.completedMilliTime = 0
                            }
                            return fixedTodo
                        } else {
                            return res.todo
                        }
                    }
            case .updatePermissions:
                single = fetchApi.getServerTodo(byId: fromTodo.guid).map {
                    guard let todo = $0.todo else {
                        assertionFailure()
                        return fromTodo
                    }
                    return todo
                }.take(1).asSingle()
            }
            return single.observeOn(MainScheduler.asyncInstance)
                .do(
                    onSuccess: { [weak self] newTodo in
                        guard let self = self else { return }
                        if case .edit(_, _, let callbacks) = self.input {
                            callbacks.updateHandler?(newTodo)
                        }
                        // 重新更新 state
                        let detailRes = Rust.DetailRes(
                            todo: newTodo,
                            parentTodo: toState.parentTodo?.todo,
                            ancestors: toState.ancestors,
                            relatedTaskLists: toState.relatedTaskLists,
                            sectionRefResult: toState.sectionRefResult,
                            ownedSection: newTodo.isAssignee(self.currentUserId) ? toState.ownedSection : .init(),
                            containerTaskFieldAssocList: toState.containerTaskFieldAssocList,
                            dependentTaskMap: toState.dependentsMap
                        )
                        self.updateStoreState(with: detailRes, type: .update)
                        callback?(.success(void))
                    },
                    onError: { [weak self] err in
                        guard let self = self else { return }
                        // 恢复原样
                        let detailRes = Rust.DetailRes(
                            todo: fromTodo,
                            parentTodo: fromState.parentTodo?.todo,
                            ancestors: fromState.ancestors,
                            relatedTaskLists: fromState.relatedTaskLists,
                            sectionRefResult: fromState.sectionRefResult,
                            ownedSection: fromState.ownedSection,
                            containerTaskFieldAssocList: fromState.containerTaskFieldAssocList,
                            dependentTaskMap: fromState.dependentsMap
                        )
                        self.updateStoreState(with: detailRes, type: .update)
                        let userError = self.makeRequestError(err)
                        callback?(.failure(userError))
                    }
                )
                .map { _ in void }
        }
        commitOperationQueue.addOperation(operation)
    }

    private enum Commit {
        enum Field {
            case updateSummary
            case updateNotes
            case updateTime
            case updateRefResource
            case appendAssignee([Assignee])
            case removeAssignee([Assignee])
            case clearAssignee
            case resetAssignee([Assignee])
            case appendFollower([Follower])
            case removeFollower([Follower])
            case removeAttachments([Rust.Attachment])
            case updateCustomFields(Rust.TaskFieldValue)
            case updateMilestone(Bool)
            case updateMode(Rust.TaskMode)
            case updateDependents([Rust.TaskDepRef])
        }
        case field(Field)
        case complete(CompleteContext)
        case following(Bool)
        case updatePermissions
    }

    private func makeCommit(from action: DetailModuleAction, with state: DetailModuleState) -> Commit? {
        switch action {
        case .updateMode(let mode):
            return .field(.updateMode(mode))
        case .updateDependents(let dependents, _):
            return .field(.updateDependents(dependents))
        case .updateMilestone(let state):
            return .field(.updateMilestone(state))
        case .updateSummary:
            return .field(.updateSummary)
        case .updateNotes:
            return .field(.updateNotes)
        case .updateTime, .clearTime:
            return .field(.updateTime)
        case .updateRefResources:
            return .field(.updateRefResource)
        case .appendAssignees(let arr):
            return .field(.appendAssignee(arr))
        case .removeAssignees(let arr):
            return .field(.removeAssignee(arr))
        case .updateReserveAssignee(let a):
            if let exists = state.reserveAssignee, exists.identifier != a.identifier {
                return .field(.appendAssignee([exists]))
            } else {
                return nil
            }
        case .clearAssignees:
            return .field(.clearAssignee)
        case .resetAssignees(let arr):
            return .field(.resetAssignee(arr))
        case .appendFollowers(let arr):
            return .field(.appendFollower(arr))
        case .removeFollowers(let arr):
            return .field(.removeFollower(arr))
        case .updateFollowing(let b):
            return .following(b)
        case let .updateCurrentUserCompleted(fromState, role):
            let ctx = CompleteContext(fromState: fromState, role: role)
            return .complete(ctx)
        case let .updateOtherAssigneeCompleted(identifier, isCompleted):
            let ctx = CompleteContext(
                fromState: .assignee(isCompleted: !isCompleted),
                role: .`self`,
                userId: identifier
            )
            return .complete(ctx)
        case .updatePermissions:
            return .updatePermissions
        case let .removeAttachments(arr):
            return .field(.removeAttachments(arr))
        case let .updateCustomFields(val):
            return .field(.updateCustomFields(val))
        case .removeReserveAssignee, .updateTaskList, .updateSubtasksState, .updateOwnSection,
                .localUpdateAttachments, .updateUploadingAttachments:
            // 不需要触发 commit 的 type
            return nil
        }
    }

    private func mergeState(_ state: DetailModuleState, to todo: Rust.Todo, with commit: Commit.Field) -> Rust.Todo {
        var ret = todo
        switch commit {
        case .updateMode(let mode):
            ret.mode = mode
        case .updateDependents(let dependents):
            ret.dependents = dependents
        case .updateMilestone(let state):
            ret.isMilestone = state
        case .updateSummary:
            ret.richSummary = state.richSummary
        case .updateNotes:
            ret.richDescription = state.richNotes
        case .updateTime:
            ret.startMilliTime = (state.startTime ?? 0) * Utils.TimeFormat.Thousandth
            ret.isAllDay = state.isAllDay
            ret.dueTimezone = state.isAllDay ? "UTC" : TimeZone.current.identifier
            ret.dueTime = state.dueTime ?? 0
            if let reminder = state.reminder {
                ret.reminders = [reminder.toPb()]
            } else {
                ret.reminders = []
            }
            if let rrule = state.rrule {
                ret.rrule = rrule
            } else {
                ret.rrule = ""
            }
        case .updateRefResource:
            ret.referResourceIds = state.refResourceStates.compactMap { rState -> String? in
                guard case .normal(let resourceId) = rState else { return nil }
                return resourceId
            }
        case .appendAssignee(let assignees):
            var exists = Set<String>()
            ret.assignees.forEach { exists.insert($0.identifier) }
            let appending = assignees.filter { !exists.contains($0.identifier) }
            ret.assignees.append(contentsOf: appending.map { $0.asModel() })
        case .removeAssignee(let assignees):
            var needsRemove = Set<String>()
            assignees.forEach { needsRemove.insert($0.identifier) }
            ret.assignees.removeAll(where: { needsRemove.contains($0.identifier) })
        case .clearAssignee:
            ret.assignees = []
        case .resetAssignee(let assignees):
            ret.assignees = assignees.map { $0.asModel() }
        case .appendFollower(let followers):
            var exists = Set<String>()
            ret.followers.forEach { exists.insert($0.identifier) }
            let appending = followers.filter { !exists.contains($0.identifier) }
            ret.followers.append(contentsOf: appending.map { $0.asModel() })
        case .removeFollower(let followers):
            var needsRemove = Set<String>()
            followers.forEach { needsRemove.insert($0.identifier) }
            ret.followers.removeAll(where: { needsRemove.contains($0.identifier) })
        case .removeAttachments(let attachments):
            var needsRemove = Set<String>()
            attachments.forEach { needsRemove.insert($0.guid) }
            ret.attachments.removeAll(where: { needsRemove.contains($0.guid) })
        case .updateCustomFields(let val):
            ret.customFieldValues[val.fieldKey] = val
        }
        return ret
    }

}

// MARK: - Dependent

extension DetailViewModel {

    func handlePickerDependents(_ todos: [Rust.Todo], _ type: Rust.TaskDependent.TypeEnum) {
        var dependents = store.state.dependents ?? [Rust.TaskDepRef]()
        var dependentsMap = store.state.dependentsMap ?? [String: Rust.Todo]()
        let guid = store.state.todo?.guid ?? ""
        todos.forEach { todo in
            var dep = Rust.TaskDepRef()
            dep.taskGuid = guid
            dep.dependentTaskGuid = todo.guid
            dep.dependentType = type
            dependents.append(dep)
            dependentsMap[todo.guid] = todo
        }
        store.dispatch(.updateDependents(dependents, dependentsMap))
    }

}


// MARK: - Track

extension DetailViewModel {

    // 埋点 - 开始新建任务
    private func trackBeginCreating(with source: TodoCreateSource) {
        var params: [AnyHashable: Any] = [:]
        params["ab_version"] = "pop_up"
        TrackerUtil.fillCreatingTodoParams(&params, with: source)
        Detail.tracker(.todo_create, params: params)

        // 多选消息，额外埋点
        if case .chat(let chatContext) = source,
           case .multiSelectMessages(let messageIds, _) = chatContext.fromContent {
            Detail.tracker(.todo_im_conversions_task, params: ["message_num": messageIds.count])
        }
    }

    // 埋点 - 结束新建任务
    private func trackEndCreating(with todo: Rust.Todo) {
        var params = [AnyHashable: Any]()
        let source: TodoCreateSource
        switch input {
        case .create(let createSource, _):
            source = createSource
            params["ab_version"] = "pop_up"
        case .quickExpand(_, _, _, _, _, let createSource, _):
            source = createSource
            params["ab_version"] = "inline"
        case .edit:
            return
        }
        let isSendToChat = store.state.scene.isShowSendToChat && (todoService?.getSendToChatIsSeleted() ?? true)
        Detail.Track.clickSave(
            with: todo,
            isNotInDetailSection: store.state.ownedSection != store.state.scene.createSource?.containerSection,
            isSendToChat: isSendToChat,
            source: source
        )
        TrackerUtil.fillCreatingTodoParams(&params, with: source)
        TrackerUtil.fillCreatingTodoParams(&params, with: todo)
        Detail.tracker(.todo_create_confirm, params: params)
    }

    // 埋点 - 开始编辑任务
    private func trackBeginEditing(with guid: String, source: TodoEditSource) {
        var params: [AnyHashable: Any] = [:]
        params["task_id"] = guid
        switch source {
        case .share:
            params["source"] = "chat"
            params["chat_id"] = store.state.scene.chatId ?? ""
        case .dailyReminder:
            params["source"] = "remind"
        case .chatTodo:
            params["source"] = "chat_todo_list"
        case .list:
            params["source"] = "my_task_all"
        default:
            break
        }
        Detail.tracker(.todo_task_click, params: params)
    }

    func trackScreenshot() {
        Detail.logger.info("user screenshot accompanying infos: \(screenshotInfo() ?? "failed")")
    }

    private func screenshotInfo() -> String? {
        var todo: Rust.Todo?
        switch input {
        case .create, .quickExpand:
            todo = makeTodoForCreating()
        case .edit:
            todo = store.state.todo
        }
        guard let pb = todo else {
            return nil
        }
        let data = SCInfo(
            scenario: "todo_detail/todo_detail_sidebar",
            message_id: "", // 现在取不到messageID?
            guid: pb.guid,
            reminders: pb.reminders.map {
                SCReminder(type: "\($0.type.rawValue)", time: $0.time)
            },
            source: "\(pb.source.rawValue)",
            due_time: pb.dueTime,
            due_timezone: pb.dueTimezone,
            is_all_day: pb.isAllDay,
            self_permission: SCpermission(is_editable: pb.selfPermission.isEditable),
            completed_milli_time: pb.completedMilliTime,
            creator_id: pb.creatorID,
            create_milli_time: pb.createMilliTime,
            assigner: SCassigner(user_id: pb.assigner.userID)
        )
        return Utils.getJson(source: data)
    }

    private struct SCInfo: Encodable {
        let scenario: String
        let message_id: String
        let guid: String
        let reminders: [SCReminder]
        let source: String
        let due_time: Int64
        let due_timezone: String
        let is_all_day: Bool
        let self_permission: SCpermission
        let completed_milli_time: Int64
        let creator_id: String
        let create_milli_time: Int64
        let assigner: SCassigner
    }

    private struct SCReminder: Encodable {
        let type: String
        let time: Int64
    }

    private struct SCpermission: Encodable {
        let is_editable: Bool
    }

    private struct SCassignee: Encodable {
        let assignee_id: String
        let type: String
        let assigner_id: String
    }

    private struct SCassigner: Encodable {
        let user_id: String
    }

}

// MARK: - batchAddSubTasks
extension DetailViewModel {
    func doBatchAddOwner(with chatterIds: [String]) {
        DetailSubTask.logger.info("doBatchAddOwner chatterIds: \(chatterIds)")
        fetchApi?.getUsers(byIds: chatterIds).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] users in
                    DetailSubTask.logger.info("batch getUsers secceed. ids: \(users.map { $0.userID })")
                    guard let self = self, !users.isEmpty, let req = self.getSubTaskReq() else { return }
                    let subTasks = users.map { user -> Rust.Todo in
                        var subTask = self.makeTodoForCreating()
                        let user = User(pb: user)
                        subTask.assignees = [Assignee(member: .user(user)).asModel()]
                        return subTask
                    }
                    self.saveSubTasks(ancestorGuid: req.ancestorGuid, subTasks: subTasks)
                },
                onError: { [weak self] err in
                    guard let self = self else { return }
                    DetailSubTask.logger.error("batch getUsers failed. err: \(err)")
                    // 批量指派点击确认后，接口失败时,需要将详情页关闭
                    self.onNeedsExit?(.bacthAdd)
                }
            )
            .disposed(by: disposeBag)
    }

    // 批量创建子任务
    private func saveSubTasks(ancestorGuid: String, subTasks: [Rust.Todo]) {
        let trackerTask = Tracker.Appreciable.Task(scene: .create, event: .createTodo).resume()
        operateApi?.createSubTask(in: ancestorGuid, with: subTasks).take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] subTasks in
                    guard let self = self else { return }
                    trackerTask.complete()
                    for subTask in subTasks {
                        Detail.logger.info("create sub task succeed. todo: \(subTask.logInfo)")
                        self.trackEndCreating(with: subTask)
                    }
                    // 批量指派点击确认后，接口成功时,需要将详情页关闭
                    self.onNeedsExit?(.bacthAdd)
                },
                onError: { [weak self] err in
                    guard let self = self else { return }
                    trackerTask.error(err)
                    Detail.assertionFailure("create sub task failed. error: \(err)", type: .saveFailed)
                    self.onNeedsExit?(.bacthAdd)
                }
            )
            .disposed(by: disposeBag)
    }
}
