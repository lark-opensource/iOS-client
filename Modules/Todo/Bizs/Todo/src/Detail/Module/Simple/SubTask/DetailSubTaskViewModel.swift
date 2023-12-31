//
//  DetailSubTaskViewModel.swift
//  Todo
//
//  Created by baiyantao on 2022/7/25.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LarkAccountInterface

final class DetailSubTaskViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    enum ViewState {
        case idle
        case content
        case empty(_ isAtMaxLeafLayer: Bool)
        case failed
        case loading
        case hidden
    }

    // view data
    let reloadNoti = PublishRelay<Void>()
    let rxHeaderData = BehaviorRelay<DetailSubTaskHeaderViewData>(value: .init())
    let rxFooterData = BehaviorRelay<DetailSubTaskFooterViewData>(value: .init())
    let rxViewState = BehaviorRelay<ViewState>(value: .idle)
    let rxContentHeight = PublishRelay<CGFloat>()
    private var cellDatas: [DetailSubTaskContentCellData] = []

    // view action
    var insertRowHandler: ((_ index: Int) -> Void)?

    // 依赖
    let store: DetailModuleStore
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?
    @ScopedInjectedLazy private var updateNoti: TodoUpdateNoti?
    @ScopedInjectedLazy private var timeService: TimeService?
    @ScopedInjectedLazy private var completeService: CompleteService?

    private var currentUserId: String { userResolver.userID }

    // 内部状态
    private var isFullLoaded = false // 是否拉取完所有 sub tasks
    private var guid: String?
    private var token: String?
    private var delayLoadingDisposable: Disposable?

    // 常量
    private let sectionCount = 1
    private let pageCount: Int32 = 10

    init(resolver: UserResolver, store: DetailModuleStore) {
        self.userResolver = resolver
        self.store = store
    }

    func setup() {
        store.rxInitialized().subscribe(onSuccess: { [weak self] _ in
            guard let self = self else { return }
            if self.store.state.scene.isForEditing {
                if let todo = self.store.state.todo {
                    DetailSubTask.logger.info("edit scene, guid: \(todo.guid)")
                    self.guid = todo.guid
                    self.registerExtraNoti(guid: todo.guid)
                    self.registerTodoChangeNoti(guid: todo.guid)
                    self.registerPermissionNoti()
                    self.listenAncestors()
                    if todo.progress.total != 0 {
                        self.delayLoadingDisposable = MainScheduler.instance.scheduleRelative(
                            (),
                            dueTime: .seconds(1),
                            action: { [weak self] _ in
                                guard let self = self else {
                                    return Disposables.create()
                                }
                                self.rxViewState.accept(.loading)
                                self.rxContentHeight.accept(self.getContentHeight())
                                return Disposables.create()
                            }
                        )

                        self.initFetchSubTasks()

                        let headerData = DetailSubTaskHeaderViewData(
                            numerator: todo.progress.completed,
                            denominator: todo.progress.total
                        )
                        self.rxHeaderData.accept(headerData)
                    } else {
                        self.isFullLoaded = true
                        self.rxViewState.accept(.empty(self.isAtMaxLeafLayer))
                    }
                }
            } else {
                DetailSubTask.logger.info("create scene")
                if case .initData(let subtasks) = self.store.state.subtasksState, !subtasks.isEmpty {
                    self.rxViewState.accept(.content)
                    self.appendToCellDatas(subtasks, isForCreating: true)
                    self.reloadNoti.accept(void)
                    self.rxContentHeight.accept(self.getContentHeight())
                    self.localFullCalculateProgress()
                }
                let state = DetailModuleState.SubtasksState.dataCallback({ [weak self] in
                    guard let self = self else { return [] }
                    return self.cellDatas2SubTasks(self.cellDatas)
                })
                self.store.dispatch(.updateSubtasksState(state: state))
            }
        }).disposed(by: disposeBag)
    }

    func getContentHeight() -> CGFloat {
        switch rxViewState.value {
        case .idle, .empty:
            return DetailSubTask.emptyViewHeight
        case .content, .failed:
            let headerHeight = rxHeaderData.value.headerHeight
            let footerHeight = rxFooterData.value.footerHeight
            let cellsHeight = cellDatas.reduce(0, { $0 + $1.cellHeight })
            return headerHeight + footerHeight + cellsHeight
        case .loading:
            return DetailSubTask.withTimeCellHeight * 4
        case .hidden:
            return CGFloat.zero
        }
    }

    func fetchNextPageSubTasks() {
        guard let guid = guid, let token = token else {
            assertionFailure()
            return
        }
        self.rxFooterData.accept(.init(
            loadingState: .loading,
            isAddSubTaskHidden: !self.hasEditRight
        ))
        fetchApi?.getPagingSubTasks(guid: guid, count: pageCount, token: token)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] res in
                    DetailSubTask.logger.info("fetchNextPageSubTasks succeed. hasMore: \(res.hasMore_p), ids: \(res.subTasks.map { $0.guid })")
                    guard let self = self else { return }

                    if res.subTasks.isEmpty {
                        assertionFailure()
                    }

                    self.token = res.lastToken
                    // 当用户没有权限编辑时，隐藏添加子任务按钮
                    self.rxFooterData.accept(.init(
                        loadingState: res.hasMore_p ? .showMore : .hide,
                        isAddSubTaskHidden: !self.hasEditRight
                    ))
                    self.appendToCellDatas(res.subTasks, rankDic: res.subTaskRanks)
                    self.reloadNoti.accept(void)
                    self.rxContentHeight.accept(self.getContentHeight())

                    if !res.hasMore_p {
                        self.isFullLoaded = true
                        self.localFullCalculateProgress()
                    }
                },
                onError: { [weak self] err in
                    DetailSubTask.logger.error("fetchNextPageSubTasks failed. err: \(err)")
                    guard let self = self else { return }
                    self.rxFooterData.accept(.init(
                        loadingState: .failed,
                        isAddSubTaskHidden: !self.hasEditRight
                    ))
                }
            )
            .disposed(by: disposeBag)
    }

    private func initFetchSubTasks() {
        guard let guid = guid else {
            assertionFailure()
            return
        }

        fetchApi?.getPagingSubTasks(guid: guid, count: pageCount, token: nil)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] res in
                    DetailSubTask.logger.info("initFetchSubTasks succeed. hasMore: \(res.hasMore_p), ids: \(res.subTasks.map { $0.guid })")
                    guard let self = self else { return }
                    self.delayLoadingDisposable?.dispose()

                    if res.subTasks.isEmpty {
                        self.rxViewState.accept(.empty(self.isAtMaxLeafLayer))
                        return
                    }
                    self.rxViewState.accept(.content)

                    self.token = res.lastToken
                    self.rxFooterData.accept(.init(
                        loadingState: res.hasMore_p ? .showMore : .hide,
                        isAddSubTaskHidden: !self.hasEditRight
                    ))
                    self.appendToCellDatas(res.subTasks, rankDic: res.subTaskRanks)
                    self.reloadNoti.accept(void)
                    self.rxContentHeight.accept(self.getContentHeight())

                    if !res.hasMore_p {
                        self.isFullLoaded = true
                        self.localFullCalculateProgress()
                    }
                },
                onError: { [weak self] err in
                    DetailSubTask.logger.error("initFetchSubTasks failed. err: \(err)")
                    guard let self = self else { return }
                    self.delayLoadingDisposable?.dispose()
                    self.rxViewState.accept(.failed)
                    self.rxFooterData.accept(.init(
                        loadingState: .initFailed,
                        isAddSubTaskHidden: !self.hasEditRight
                    ))
                    self.rxContentHeight.accept(self.getContentHeight())
                }
            )
            .disposed(by: disposeBag)
    }

    private func appendToCellDatas(
        _ subTasks: [Rust.Todo],
        isForCreating: Bool = false,
        rankDic: [String: String]? = nil
    ) {
        var allCellDatas = self.cellDatas
        var newCellDatas = subTasks2CellDatas(subTasks, isForCreating: isForCreating)

        if let rankDic = rankDic {
            for (index, data) in newCellDatas.enumerated() {
                if let guid = data.todo?.guid, let rank = rankDic[guid] {
                    newCellDatas[index].rank = rank
                }
            }
        }

        let guidSet = Set(allCellDatas.compactMap { $0.todo?.guid })
        allCellDatas += newCellDatas.filter {
            if let guid = $0.todo?.guid {
                return !guidSet.contains(guid)
            } else {
                return false
            }
        }

        let hasRankDatas = allCellDatas.filter { !$0.rank.isEmpty }.sorted(by: { $0.rank < $1.rank })
        let nonRankDatas = allCellDatas.filter { $0.rank.isEmpty }

        self.cellDatas = hasRankDatas + nonRankDatas
    }

    private func isAlreadyExist(_ data: DetailSubTaskContentCellData, guidSet: Set<String>? = nil) -> Bool {
        guard let guid = data.todo?.guid else { return false }
        return (guidSet ?? Set(cellDatas.compactMap { $0.todo?.guid })).contains(guid)
    }

    private func subTasks2CellDatas(_ subTasks: [Rust.Todo], isForCreating: Bool = false) -> [DetailSubTaskContentCellData] {
        let timeZone = timeService?.rxTimeZone.value ?? .current
        let is12HourStyle = timeService?.rx12HourStyle.value ?? false
        return subTasks.map { todo in
            let timeComponents = TimeComponents(from: todo)
            let completedState = completeService?.state(for: todo) ?? .outsider(isCompleted: false)
            var checkState: CheckboxState {
                if isForCreating {
                    return .enabled(isChecked: completedState.isCompleted)
                } else if todo.isCompleteEnabled(with: completedState) {
                    return .enabled(isChecked: completedState.isCompleted)
                } else {
                    return .disabled(isChecked: completedState.isCompleted, hasAction: false)
                }
            }

            var data = DetailSubTaskContentCellData()
            data.todo = todo
            data.checkboxState = checkState
            data.isMilestone = todo.isMilestone
            data.richSummary = todo.richSummary
            data.hasStrikethrough = completedState.isCompleted
            data.assignees = todo.assignees.map(Assignee.init(model:))
            data.taskMode = todo.mode
            data.timeComponents = timeComponents
            data.isForCreating = isForCreating
            data.timeZone = timeZone
            data.is12HourStyle = is12HourStyle
            return data
        }
    }

    private func cellDatas2SubTasks(_ cellDatas: [DetailSubTaskContentCellData]) -> [Rust.Todo] {
        return cellDatas.compactMap { data in
            if !(data.richSummary?.richText.hasVisibleContent() ?? false) {
                return nil
            }

            var todo = Rust.Todo().fixedForCreating()
            todo.richSummary = data.richSummary ?? Rust.RichContent()
            todo.assignees = data.assignees.map { $0.asModel() }
            todo.mode = data.taskMode
            data.timeComponents?.appendSelf(to: &todo)
            todo.dueTimezone = todo.isAllDay ? "UTC" : TimeZone.current.identifier
            todo.richDescription = data.richNotes ?? Rust.RichContent()
            todo.attachments = data.attachments
            return todo
        }
    }

    private func localIncrementalCalculateProgress(numeratorDiff: Int32? = nil, denominatorDiff: Int32? = nil) {
        DetailSubTask.logger.info("localIncrementalCalculateProgress numeratorDiff: \(numeratorDiff), denominatorDiff: \(denominatorDiff).")
        if numeratorDiff == nil && denominatorDiff == nil {
            return
        }

        var data = rxHeaderData.value
        if let diff = numeratorDiff {
            data.numerator += diff
        }
        if let diff = denominatorDiff {
            data.denominator += diff
        }
        guard data.numerator >= 0 && data.denominator >= 0 && data.numerator <= data.denominator else {
            assertionFailure()
            return
        }
        DetailSubTask.logger.info("localIncrementalCalculateProgress done. data: \(data.numerator) : \(data.denominator)")
        rxHeaderData.accept(data)
    }

    private func localFullCalculateProgress() {
        var numerator: Int32 = cellDatas.reduce(0) {
            ($1.todo?.isTodoCompleted ?? false) ? $0 + 1 : $0
        }
        let denominator: Int32 = Int32(cellDatas.count)
        DetailSubTask.logger.info("localFullCalculateProgress done. data: \(numerator) : \(denominator)")
        guard numerator >= 0 && denominator >= 0 && numerator <= denominator else {
            assertionFailure()
            return
        }
        rxHeaderData.accept(.init(numerator: numerator, denominator: denominator))
    }

    private func localDeleteCell(indexPath: IndexPath) -> DetailSubTaskContentCellData? {
        DetailSubTask.logger.info("localDeleteCell index: \(indexPath)")
        guard safeCheck(indexPath: indexPath) else { return nil }
        let removedItem = cellDatas.remove(at: indexPath.row)
        localIncrementalCalculateProgress(
            numeratorDiff: removedItem.checkboxState.isChecked ? -1 : nil,
            denominatorDiff: -1
        )
        reloadNoti.accept(void)
        if cellDatas.isEmpty && rxFooterData.value.loadingState == .hide {
            rxViewState.accept(.empty(isAtMaxLeafLayer))
        }
        rxContentHeight.accept(getContentHeight())
        return removedItem
    }
}

// MARK: - Notification

extension DetailSubTaskViewModel {
    private func registerExtraNoti(guid: String) {
        updateNoti?.rxExtraUpdate
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] infos in
                guard let self = self else { return }
                self.onProgressChange(infos: infos)
                self.onRankChange(infos: infos)
            })
        .disposed(by: disposeBag)
    }

    private func onProgressChange(infos: [Rust.TodoExtraInfo]) {
        guard !isFullLoaded else { return }
        let progressChange: Rust.TodoProgressChange? = infos.compactMap {
            guard case .progress = $0.type else { return nil }
            return $0.progressChange
        }.first(where: { $0.guid == guid })
        guard let change = progressChange else { return }
        DetailSubTask.logger.info("receive progress change. guid: \(guid ?? ""), progress: \(change.progress.completed) : \(change.progress.total).")
        let headerData = DetailSubTaskHeaderViewData(
            numerator: change.progress.completed,
            denominator: change.progress.total
        )
        self.rxHeaderData.accept(headerData)
    }

    private func onRankChange(infos: [Rust.TodoExtraInfo]) {
        let change: Rust.SubTaskRanksChange? = infos.compactMap {
            guard case .subTaskRanks = $0.type else { return nil }
            return $0.subTaskRanksChange
        }.first(where: { $0.guid == guid })
        guard let rankDic = change?.subTaskRanks else { return }

        var allCellDatas = self.cellDatas
        for (index, data) in allCellDatas.enumerated() {
            if let guid = data.todo?.guid, let rank = rankDic[guid] {
                allCellDatas[index].rank = rank
            }
        }

        let hasRankDatas = allCellDatas.filter { !$0.rank.isEmpty }.sorted(by: { $0.rank < $1.rank })
        let nonRankDatas = allCellDatas.filter { $0.rank.isEmpty }

        self.cellDatas = hasRankDatas + nonRankDatas
        reloadNoti.accept(void)
    }

    private func registerTodoChangeNoti(guid: String) {
        updateNoti?.rxDiffUpdate
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] val in
                guard let self = self else { return }
                let deletedTodos = val.todos.filter { $0.isDeleted }
                let changedTodos = val.todos.filter { !$0.isDeleted && $0.ancestorGuid == guid }
                DetailSubTask.logger.info("receive todo change. delete guids: \(deletedTodos.map { $0.guid }) changed guids: \(changedTodos.map { $0.guid })")
                let doDeleteItems = self.onDeletedTodos(deletedTodos)
                self.onChangedTodos(changedTodos)

                if self.isFullLoaded && (doDeleteItems || !changedTodos.isEmpty) {
                    self.localFullCalculateProgress()
                }
            })
        .disposed(by: disposeBag)
    }

    private func registerPermissionNoti() {
        // 父任务的子任务模块权限变更时，重置一下子任务模块，来刷新子任务的权限（分页状态也会被重置）
        store.rxValue(forKeyPath: \.permissions)
            .distinctUntilChanged(\.subTask)
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] permissions in
                guard let self = self else { return }
                if let todo = self.store.state.todo, todo.progress.total != 0 {
                    DetailSubTask.logger.info("reload by permission: \(permissions.subTask.isEditable)")
                    self.token = nil
                    self.isFullLoaded = false
                    self.cellDatas = []
                    self.initFetchSubTasks()
                }
            }).disposed(by: disposeBag)
    }

    // 传进来的 Todo 可能和父 Todo 没有关系，因此只筛选存在的来删除
    private func onDeletedTodos(_ todos: [Rust.Todo]) -> Bool {
        var doDeleteItems = false
        let guidSet = Set(cellDatas.compactMap { $0.todo?.guid })
        for data in subTasks2CellDatas(todos) where isAlreadyExist(data, guidSet: guidSet) {
            if let (index, _) = cellDatas.enumerated().first(where: { $1.todo?.guid == data.todo?.guid }) {
                doDeleteItems = true
                _ = localDeleteCell(indexPath: .init(row: index, section: 0))
            }
        }
        return doDeleteItems
    }

    // 传进来的 Todo 都是和父 Todo 相关的，已有的替换，没有的则直接 append
    private func onChangedTodos(_ todos: [Rust.Todo]) {
        let newCellDatas = subTasks2CellDatas(todos)
        for data in newCellDatas {
            if let firstIndex = cellDatas.firstIndex(where: { $0.todo?.guid == data.todo?.guid }) {
                let rank = cellDatas[firstIndex].rank
                cellDatas[firstIndex] = data
                cellDatas[firstIndex].rank = rank
            } else {
                if cellDatas.isEmpty {
                    rxViewState.accept(.content)
                }
                cellDatas.append(data)
            }
        }
        reloadNoti.accept(void)
        rxContentHeight.accept(getContentHeight())
    }
}

// MARK: - View Action

extension DetailSubTaskViewModel {
    func getChatId() -> String? {
        store.state.scene.chatId
    }

    func doUpdateTime(indexPath: IndexPath, components: TimeComponents) {
        DetailSubTask.logger.info("doUpdateTime index: \(indexPath), components: \(components)")
        guard safeCheck(indexPath: indexPath) else { return }
        var new = components
        new.startTime = (components.startTime ?? 0) > 0 ? components.startTime : nil
        new.dueTime = (components.dueTime ?? 0) > 0 ? components.dueTime : nil
        cellDatas[indexPath.row].timeComponents = new
        reloadNoti.accept(void)
        rxContentHeight.accept(self.getContentHeight())
    }

    func doClearTime(indexPath: IndexPath) {
        DetailSubTask.logger.info("doClearTime index: \(indexPath)")
        guard safeCheck(indexPath: indexPath) else { return }
        cellDatas[indexPath.row].timeComponents = nil
        reloadNoti.accept(void)
        rxContentHeight.accept(self.getContentHeight())
    }

    func doAddOwners(indexPath: IndexPath, with chatterIds: [String]) {
        DetailSubTask.logger.info("doAddOwner index: \(indexPath), chatterId: \(chatterIds)")
        guard safeCheck(indexPath: indexPath) else { return }
        fetchApi?.getUsers(byIds: chatterIds).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] users in
                    DetailSubTask.logger.info("getUsers secceed. ids: \(users.map { $0.userID })")
                    guard let self = self else { return }

                    self.cellDatas[indexPath.row].assignees = users.map({ Assignee(member: .user(User(pb: $0))) })
                    self.reloadNoti.accept(void)
                },
                onError: { err in
                    DetailSubTask.logger.error("getUsers failed. err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    func doBatchAddOwner(indexPath: IndexPath, with chatterIds: [String]) {
        DetailSubTask.logger.info("doBatchAddOwner index: \(indexPath), chatterIds: \(chatterIds)")
        guard safeCheck(indexPath: indexPath) else { return }
        fetchApi?.getUsers(byIds: chatterIds).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] users in
                    DetailSubTask.logger.info("batch getUsers secceed. ids: \(users.map { $0.userID })")
                    guard let self = self, !users.isEmpty else { return }

                    var users = users
                    let firstUser = users.removeFirst()
                    self.cellDatas[indexPath.row].assignees = [Assignee(member: .user(User(pb: firstUser)))]

                    var copyedDatas = [DetailSubTaskContentCellData]()
                    for user in users {
                        var data = self.cellDatas[indexPath.row]
                        data.assignees = [Assignee(member: .user(User(pb: user)))]
                        copyedDatas.append(data)
                    }

                    if !copyedDatas.isEmpty {
                        self.cellDatas.insert(contentsOf: copyedDatas, at: indexPath.row + 1)
                        self.rxContentHeight.accept(self.getContentHeight())
                        self.localIncrementalCalculateProgress(denominatorDiff: Int32(copyedDatas.count))
                    }

                    self.reloadNoti.accept(void)
                },
                onError: { err in
                    DetailSubTask.logger.error("batch getUsers failed. err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    // 后面可以优化一下逻辑，主要是合并分散在各处的 append 逻辑 for: baiyantao
    func doBatchAddOwner(with chatterIds: [String]) {
        DetailSubTask.logger.info("doBatchAddOwner chatterIds: \(chatterIds)")
        fetchApi?.getUsers(byIds: chatterIds).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] users in
                    DetailSubTask.logger.info("batch getUsers secceed. ids: \(users.map { $0.userID })")
                    guard let self = self, !users.isEmpty else { return }

                    var initData = DetailSubTaskContentCellData()
                    let state = self.store.state
                    initData.richSummary = state.richSummary
                    initData.richNotes = state.richNotes
                    initData.attachments = state.attachments
                    initData.timeComponents = TimeComponents(
                        startTime: state.startTime,
                        dueTime: state.dueTime,
                        reminder: state.reminder,
                        isAllDay: state.isAllDay,
                        rrule: state.rrule
                    )
                    initData.taskMode = state.mode

                    var copyedDatas = [DetailSubTaskContentCellData]()
                    for user in users {
                        var data = initData
                        data.assignees = [Assignee(member: .user(User(pb: user)))]
                        copyedDatas.append(data)
                    }

                    self.handleCopyedDatas(copyedDatas)
                },
                onError: { err in
                    DetailSubTask.logger.error("batch getUsers failed. err: \(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func handleCopyedDatas(_ datas: [DetailSubTaskContentCellData]) {
        guard !datas.isEmpty else { return }
        if store.state.scene.isForCreating {
            if self.cellDatas.isEmpty {
                self.rxViewState.accept(.content)
            }
            self.cellDatas.append(contentsOf: datas)
            self.rxContentHeight.accept(self.getContentHeight())
            self.localIncrementalCalculateProgress(denominatorDiff: Int32(datas.count))
            self.reloadNoti.accept(void)
        } else {
            guard let guid = store.state.scene.todoId else { return }
            let tasks = cellDatas2SubTasks(datas)
            operateApi?.createSubTask(in: guid, with: tasks).take(1).asSingle()
                .subscribe(
                    onSuccess: { _ in
                        // 不用处理 response，依赖 push 刷新
                        Detail.logger.info("handleCopyedDatas create subTasks success")
                    },
                    onError: { err in
                        Detail.logger.error("handleCopyedDatas create subTasks failed, error:\(err)")
                    }
                )
                .disposed(by: disposeBag)
        }
    }

    func doClearOwner(indexPath: IndexPath) {
        DetailSubTask.logger.info("doClearOwner index: \(indexPath)")
        guard safeCheck(indexPath: indexPath) else { return }
        cellDatas[indexPath.row].assignees = []
        reloadNoti.accept(void)
    }

    func doToggleComplete(indexPath: IndexPath, completion: @escaping (UserResponse<String?>) -> Void) {
        guard safeCheck(indexPath: indexPath),
              let todo = cellDatas[indexPath.row].todo,
              let completeService = completeService else {
            return
        }
        cellDatas[indexPath.row].hasStrikethrough = !cellDatas[indexPath.row].hasStrikethrough
        if case .enabled(let isChecked) = cellDatas[indexPath.row].checkboxState {
            cellDatas[indexPath.row].checkboxState = .enabled(isChecked: !isChecked)
        }
        reloadNoti.accept(void)
        if isFullLoaded {
            localFullCalculateProgress()
        }

        var fromState = completeService.state(for: todo)
        if todo.editable(for: .todoCompletedMilliTime) {
            fromState = completeService.mergeCompleteState(fromState, with: todo.isTodoCompleted)
        }
        DetailSubTask.logger.info("doToggleComplete index: \(indexPath), fromState: \(fromState)")
        let ctx = CompleteContext(fromState: fromState, role: .todo)
        completeService.toggleState(with: ctx, todoId: todo.guid, todoSource: todo.source, containerID: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] res in
                    guard let self = self else { return }
                    DetailSubTask.logger.info("toggle succeed. newState: \(res.newState)")
                    if var data = self.subTasks2CellDatas([res.todo]).first {
                        data.rank = self.cellDatas[indexPath.row].rank
                        self.cellDatas[indexPath.row] = data
                        self.reloadNoti.accept(void)
                        if self.isFullLoaded {
                            self.localFullCalculateProgress()
                        }
                    }
                    let toast = fromState.toggleSuccessToast(by: .todo)
                    completion(.success(toast))
                },
                onError: { [weak self] err in
                    guard let self = self else { return }
                    DetailSubTask.logger.error("toggle failed error: \(err)")
                    if var data = self.subTasks2CellDatas([todo]).first {
                        // 失败后需要拿之前的 todo 进行状态回退，并发送 reload 通知
                        data.rank = self.cellDatas[indexPath.row].rank
                        self.cellDatas[indexPath.row] = data
                        self.reloadNoti.accept(void)
                        if self.isFullLoaded {
                            self.localFullCalculateProgress()
                        }
                    }
                    completion(.failure(Rust.makeUserError(from: err)))
                }
            )
            .disposed(by: disposeBag)
    }

    func doAppendNewCell() {
        DetailSubTask.logger.info("doAppendNewCell")
        var data = DetailSubTaskContentCellData()
        data.currentUserId = currentUserId
        guard !isAlreadyExist(data) else { return }
        if cellDatas.isEmpty {
            rxViewState.accept(.content)
        }
        cellDatas.append(data)
        insertRowHandler?(cellDatas.endIndex - 1)
        localIncrementalCalculateProgress(denominatorDiff: 1)
    }

    func doInsertNewCell(indexPath: IndexPath) {
        DetailSubTask.logger.info("doInsertNewCell, index: \(indexPath)")
        guard safeCheck(indexPath: indexPath) else { return }
        let insertIndex = indexPath.row + 1
        var data = DetailSubTaskContentCellData()
        data.currentUserId = currentUserId
        cellDatas.insert(data, at: insertIndex)
        insertRowHandler?(insertIndex)
        localIncrementalCalculateProgress(denominatorDiff: 1)
    }

    func doDeleteEmptyCell(indexPath: IndexPath) {
        DetailSubTask.logger.info("doDeleteEmptyCell, index: \(indexPath)")
        guard safeCheck(indexPath: indexPath) else { return }
        cellDatas.remove(at: indexPath.row)
        localIncrementalCalculateProgress(denominatorDiff: -1)
        if cellDatas.isEmpty {
            rxViewState.accept(.empty(isAtMaxLeafLayer))
            rxContentHeight.accept(getContentHeight())
        }
    }

    func doSwipeDeleteCell(indexPath: IndexPath, completion: @escaping (UserResponse<Void>) -> Void) {
        DetailSubTask.logger.info("doSwipeDeleteCell, index: \(indexPath)")
        guard safeCheck(indexPath: indexPath) else { return }
        let removedItem = localDeleteCell(indexPath: indexPath)
        guard store.state.scene.isForEditing, let item = removedItem, let todo = item.todo else { return }
        operateApi?.deleteTodo(forId: todo.guid, source: todo.source)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { _ in
                    DetailSubTask.logger.info("SwipeDeleteCell succeed.")
                    completion(.success(()))
                },
                onError: { [weak self] err in
                    DetailSubTask.logger.error("SwipeDeleteCell failed error: \(err)")
                    guard let self = self else { return }
                    completion(.failure(Rust.makeUserError(from: err)))
                    // 失败回退
                    guard indexPath.row <= self.cellDatas.endIndex else { return }
                    self.cellDatas.insert(item, at: indexPath.row)
                    self.reloadNoti.accept(void)
                    self.rxContentHeight.accept(self.getContentHeight())
                    self.localIncrementalCalculateProgress(
                        numeratorDiff: item.checkboxState.isChecked ? 1 : nil,
                        denominatorDiff: 1
                    )
                }
            )
            .disposed(by: disposeBag)
    }

    func doUpdateSummary(indexPath: IndexPath, content: Rust.RichContent) {
        if store.state.scene.isForCreating { // 编辑场景下用户无法在 cell 中编辑标题，因此该日志无意义，屏蔽掉
            DetailSubTask.logger.info("doUpdateSummary, index: \(indexPath)")
        }
        guard safeCheck(indexPath: indexPath) else { return }
        cellDatas[indexPath.row].richSummary = content
    }

    func doRetry() {
        DetailSubTask.logger.info("doRetry. current state: \(rxFooterData.value.loadingState)")
        switch rxFooterData.value.loadingState {
        case .initFailed:
            rxFooterData.accept(.init(
                loadingState: .loading,
                isAddSubTaskHidden: !self.hasEditRight
            ))
            initFetchSubTasks()
        case .failed:
            fetchNextPageSubTasks()
        default:
            assertionFailure()
        }
    }
}

// MARK: - UITableView

extension DetailSubTaskViewModel {
    func numberOfSections() -> Int {
        sectionCount
    }

    func numberOfItems() -> Int {
        cellDatas.count
    }

    func cellInfo(indexPath: IndexPath) -> DetailSubTaskContentCellData? {
        guard safeCheck(indexPath: indexPath) else { return nil }
        return cellDatas[indexPath.row]
    }

    func indexPath(from viewData: DetailSubTaskContentCellData?) -> IndexPath? {
        guard let viewData = viewData else { return nil }
        let firstIndex = cellDatas.firstIndex { cellData in
            return cellData.todo?.guid == viewData.todo?.guid
        }
        guard let firstIndex = firstIndex else { return nil }
        return IndexPath(row: firstIndex, section: 0)
    }

    private func safeCheck(indexPath: IndexPath) -> Bool {
        let (section, row) = (indexPath.section, indexPath.row)
        guard section >= 0
                && section < sectionCount
                && row >= 0
                && row < cellDatas.count
        else {
            var text = "check indexPath failed. indexPath: \(indexPath)"
            text += " sectionCount: \(sectionCount)"
            if section >= 0 && section < sectionCount {
                text += " itemCount: \(cellDatas.count)"
            }
            assertionFailure(text)
            return false
        }
        return true
    }

    /// 获取左滑按钮描述
    func getSwipeAction(indexPath: IndexPath) -> [V3SwipeActionDescriptor]? {
        if store.state.scene.isForCreating { return [.delete] }
        guard safeCheck(indexPath: indexPath),
              let subTask = cellDatas[indexPath.row].todo,
              subTask.editable(for: .todoDeletedTime) else {
            return nil
        }
        return [.delete]
    }

}


// MARK: - Member List

extension DetailSubTaskViewModel: MemberListViewModelDependency {

    func memberListInput(indexPath: IndexPath) -> MemberListViewModelInput? {
        guard safeCheck(indexPath: indexPath) else { return nil }
        return MemberListViewModelInput(
            todoId: "",
            todoSource: .todo,
            chatId: chatId,
            scene: .creating_subTask_assignee(indexPath),
            selfRole: .creator,
            canEditOther: true,
            members: cellDatas[indexPath.row].assignees.map { $0.asMember() },
            mode: cellDatas[indexPath.row].taskMode,
            modeEditable: true
        )
    }

    func appendMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?) {
        guard case .creating_subTask_assignee(let indexPath) = input.scene,
        safeCheck(indexPath: indexPath) else {
            return
        }
        OwnerPicker.Track.finalAddClick(with: ancestorGuid ?? "", isEdit: isEdit, isSubTask: true)
        let assignees = members.map { member in
            return Assignee(member: member)
        }
        var existsAssignees = cellDatas[indexPath.row].assignees
        var exists = Set<String>()
        existsAssignees.forEach { exists.insert($0.identifier) }
        let appending = assignees.filter { !exists.contains($0.identifier) }
        existsAssignees.append(contentsOf: appending)
        
        cellDatas[indexPath.row].assignees = existsAssignees
        reloadNoti.accept(void)
    }

    func removeMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?) {
        guard case .creating_subTask_assignee(let indexPath) = input.scene,
              safeCheck(indexPath: indexPath) else {
            return
        }
        let assignees = members.map { member in
            return Assignee(member: member)
        }
        let needsRemove = Set(assignees.map(\.identifier))
        cellDatas[indexPath.row].assignees = cellDatas[indexPath.row].assignees.filter { !needsRemove.contains($0.identifier) }
        reloadNoti.accept(void)
    }

    func changeTaskMode(input: MemberListViewModelInput, _ newMode: Rust.TaskMode, completion: Completion?) {
        guard case .creating_subTask_assignee(let indexPath) = input.scene,
              safeCheck(indexPath: indexPath) else {
            return
        }
        OwnerPicker.Track.changeDoneClick(with: ancestorGuid ?? "", isEdit: isEdit, isSubTask: true)
        cellDatas[indexPath.row].taskMode = newMode
    }

}

// MARK: - SubTask Create

extension DetailSubTaskViewModel {

    /// 为解决首次ancestors没有取完成，空标题显示不正确
    func listenAncestors() {
        guard store.state.scene.isForEditing else { return }
        store.rxValue(forKeyPath: \.ancestors)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                let isAtMaxLeafLayer = self.isAtMaxLeafLayer
                if isAtMaxLeafLayer {
                    switch self.rxViewState.value {
                    case .idle, .empty:
                        self.rxViewState.accept(.empty(isAtMaxLeafLayer))
                    default:
                        break
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    var ancestorGuid: String? {
        return store.state.todo?.guid
    }

    var isSubTask: Bool { store.state.isSubTask }

    var chatId: String? { store.state.scene.chatId }

    var isEdit: Bool { store.state.scene.isForEditing }

    var isAtMaxLeafLayer: Bool { store.state.isAtMaxLeafLayer }

    // 是否有权限
    var hasEditRight: Bool {
        return store.state.permissions.subTask.isEditable
    }
}
