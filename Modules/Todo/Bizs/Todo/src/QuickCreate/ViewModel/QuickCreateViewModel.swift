//
//  QuickCreateViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2021/3/22.
//

import RxSwift
import RxCocoa
import LarkContainer
import CTFoundation
import LarkAccountInterface
import UniverseDesignIcon

/// QuickCreate - ViewModel

final class QuickCreateViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    // 负责人
    let rxOwnerViewData = BehaviorRelay<QuickCreateOwnerViewDataType?>(value: nil)
    /// 时间（截止时间 & 提醒时间）
    let rxTimeViewData = BehaviorRelay<DetailDueTimeViewData?>(value: nil)
    /// 选择截止时间
    let rxDueTimePickViewData = BehaviorRelay<QuickCreateDueTimePickViewDataType?>(value: nil)
    /// 底部
    let rxBottomViewData = BehaviorRelay<QuickCreateBottomViewDataType?>(value: nil)

    lazy var inputController = InputController(resolver: userResolver, sourceId: nil)

    let source: TodoCreateSource
    let callbacks: TodoCreateCallbacks

    var sourceChatId: String? {
        switch source {
        case .chat(let context):
            return context.chatId
        case .subTask(_, _, let chatId):
            return chatId
        case .list, .inline:
            return nil
        }
    }

    fileprivate struct UpdateSet: OptionSet {
        let rawValue: Int

        static let summary = UpdateSet(rawValue: 1 << 0)
        static let time = UpdateSet(rawValue: 1 << 1)
        static let owner = UpdateSet(rawValue: 1 << 2)

        static let all: UpdateSet = [.summary, .time, .owner]
    }

    private let rxUpdate = PublishSubject<UpdateSet>()

    @ScopedInjectedLazy private var anchorService: AnchorService?
    @ScopedInjectedLazy private var settingService: SettingService?
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?
    @ScopedInjectedLazy private var fetchApi: TodoFetchApi?
    @ScopedInjectedLazy private var shareService: ShareService?
    @ScopedInjectedLazy private var passportService: PassportUserService?
    @ScopedInjectedLazy private var timeService: TimeService?
    @ScopedInjectedLazy private var listApi: TaskListApi?

    private var timeZone: TimeZone { timeService?.rxTimeZone.value ?? .current }
    private var is12HourStyle: Bool { timeService?.rx12HourStyle.value ?? false }
    private var defaultDueTimeDayOffset: Int64 { settingService?.defaultDueTimeDayOffset ?? 0 }
    private var dueReminderOffset: Int64 { settingService?.value(forKeyPath: \.dueReminderOffset) ?? 0 }

    private let disposeBag = DisposeBag()
    // 草稿的 scene 参数
    private let draftScene: Rust.DraftScene
    private(set) var todoData = Rust.Todo().fixedForCreating()
    // 子任务，从全屏创建而来
    private(set) var subTasksData: [Rust.Todo]?
    // 任务清单
    private(set) var relatedTaskLists: [Rust.TaskContainer]?
    // 关联的分组，用于新建
    private(set) var sectionRefResult: [String: Rust.SectionRefResult]?
    // 我负责的分组
    private(set) var ownedContainerSection: Rust.ContainerSection?
    // 是否该显示快速选择 dueTime 的入口
    private let rxEnableQuickDueTimeEntry = BehaviorRelay(value: false)
    private let rxSummaryValid = BehaviorRelay(value: false)

    init(resolver: UserResolver, source: TodoCreateSource, callbacks: TodoCreateCallbacks) {
        self.userResolver = resolver
        self.source = source
        self.callbacks = callbacks
        self.draftScene = source.getDraftScene()
    }

    /// 初始化
    func setup() -> Driver<Void> {
        let defaultTodo = Rust.Todo().fixedForCreating(fillOwner: fillOwner, passportService: passportService)
        guard let operateApi = operateApi else { return .empty() }
        bindViewData()
        return operateApi.getTodoDraft(byScene: draftScene)
            .do(onError: { QuickCreate.logger.error("get todo draft failed, err: \($0)") })
                .map { [weak self] todo in
                    guard let self = self, let todo = todo else { return defaultTodo }
                    guard self.source.isEnableDraft() else { return defaultTodo }
                    return todo
                }
                .map { $0 ?? defaultTodo }
                .catchErrorJustReturn(defaultTodo)
                .do(onNext: { [weak self] _ in
                    guard let self = self else { return  }
                    guard let taskListGuid = self.source.taskListGuid else { return }
                    self.listApi?.getContainerMetaData(by: taskListGuid, needSection: true)
                        .take(1).asSingle()
                        .subscribe(onSuccess: { [weak self] metaData in
                            self?.cacheTaskList(metaData)
                        })
                        .disposed(by: self.disposeBag)
                })
                .flatMapFirst { [weak self] todo -> Observable<Rust.Todo> in
                    guard let self = self else { return .just(todo) }
                    var ret = todo.fixedForCreating()
                    if !ret.isValidDraft,
                       case .chat(let chatContext) = self.source,
                       let richSummary = chatContext.extractRichSummary() {
                        ret.richSummary = richSummary
                        var userIds = [String]()
                        let richText = richSummary.richText
                        for atEleId in richText.atIds {
                            if let userId = richText.elements[atEleId]?.property.at.userID,
                               !userId.isEmpty {
                                userIds.append(userId)
                            }
                        }
                        if userIds.isEmpty {
                            return .just(ret)
                        } else {
                            guard let fetchApi = self.fetchApi else { return .just(ret) }
                            // 从 chat 中流入的 at 信息，可能包含了昵称，需要 fix 一下
                            return fetchApi.getUsers(byIds: userIds)
                                .catchErrorJustReturn([])
                                .take(1)
                                .map { users in
                                    var userIdNameMap = [String: String]()
                                    users.forEach { userIdNameMap[$0.userID] = $0.name }
                                    for (key, ele) in todo.richSummary.richText.elements where ele.tag == .at {
                                        if let fixedName = userIdNameMap[ele.property.at.userID], !fixedName.isEmpty {
                                            ret.richSummary.richText.elements[key]?.property.at.content = fixedName
                                        }
                                    }
                                    return ret
                                }
                        }
                    } else {
                        return .just(ret)
                    }
                }
                .asDriver(onErrorJustReturn: defaultTodo)
                .do(onNext: { [weak self] todo in
                    // 读取 RichContent，将其中的 Anchor Hang 资源给缓存起来，方便后续使用
                    self?.anchorService?.cacheHangEntities(in: todo.richSummary)
                    self?.anchorService?.cacheHangEntities(in: todo.richDescription)
                    self?.reset(with: todo)
                    self?.trackBeginCreating()
                })
                    .map { _ in void }
    }

    /// 重置
    func reset() {
        reset(with: Rust.Todo().fixedForCreating())
    }

    /// 使用 todo 重置
    func reset(
        with todo: Rust.Todo,
        subTasks: [Rust.Todo]? = nil,
        tasklists: [Rust.TaskContainer]? = nil,
        sections: [String: Rust.SectionRefResult]? = nil,
        ownedSection: Rust.ContainerSection? = nil
    ) {
        let todo = todo.fixedForCreating()
        inputController.updateAnchorContext(with: todo.richSummary)
        todoData = todo
        subTasksData = subTasks
        relatedTaskLists = tasklists
        sectionRefResult = sections
        ownedContainerSection = ownedSection
        rxUpdate.onNext(.all)
        rxEnableQuickDueTimeEntry.accept(false)
    }

    /// 保存，返回 todo 的 guid
    func save() -> Single<Rust.Todo> {
        if isFromSubTask {
            let defaultTodo = Rust.Todo().fixedForCreating()
            guard let operateApi = operateApi, let req = getSingleSubTaskReq() else { return .just(defaultTodo) }
            return operateApi.createSubTask(in: req.ancestorGuid, with: req.subTasks).take(1).asSingle()
                .observeOn(MainScheduler.instance)
                .do(
                    onSuccess: { subTasks in
                        QuickCreate.logger.error("create subTasks success, subTasks:\(subTasks.map(\.logInfo))")
                    },
                    onError: { err in
                        QuickCreate.logger.error("create subTasks failed, error:\(err)")
                    }
                ).map { $0.first ?? defaultTodo }
        } else {
            var todo = todoData
            if let origin = Rust.TodoOrigin(source: source) {
                todo.source = .chat
                todo.origin = origin
            }
            todo.dueTimezone = todo.isAllDay ? "UTC" : TimeZone.current.identifier
            guard let operateApi = operateApi else { return .just(todo) }
            let trackerTask = Tracker.Appreciable.Task(scene: .create, event: .createTodo).resume()
            return operateApi.createTodo(todo, with: subTasksData ?? [], and: ownedContainerReq, or: taskListForCreateReq)
                .take(1).asSingle()
                .observeOn(MainScheduler.instance)
                .do(
                    onSuccess: { [weak self] res in
                        trackerTask.complete()
                        guard let self = self else { return }
                        self.deleteDraft()
                        self.callbacks.createHandler?(res)
                        QuickCreate.logger.info("create todo success, todo:\(res.todo.logInfo)")
                        self.trackEndCreating()
                        QuickCreate.Track.clickSave(with: res.todo, isNotInDetailSection: self.ownedContainerReq != self.source.containerSection)
                    },
                    onError: { err in
                        QuickCreate.logger.error("create todo failed, error:\(err)")
                        trackerTask.error(err)
                    }
                ).map { $0.todo }
        }
    }

    private func cacheTaskList(_ metaData: Rust.ContainerMetaData) {
        let taskList = metaData.container
        let sectionRank = source.sectionRankForCreate
        var sectionID = sectionRank?.sectionID ?? ""
        if sectionID.isEmpty {
            sectionID = metaData.sections.first(where: { $0.isDefault })?.guid ?? ""
        }

        var ref = Rust.ContainerTaskRef()
        ref.taskGuid = ""
        ref.sectionGuid = sectionID
        ref.containerGuid = taskList.guid
        ref.rank = sectionRank?.rank ?? ""

        var sectionRef = Rust.SectionRefResult()
        sectionRef.ref = ref
        sectionRef.sections = metaData.sections

        relatedTaskLists = [taskList]
        sectionRefResult = [taskList.guid: sectionRef]
    }

    var ownedContainerReq: Rust.ContainerSection? {
        if let containerSection = ownedContainerSection {
            return containerSection
        }
        return source.containerSection
    }

    var taskListForCreateReq: [Rust.ContainerSection]? {
        guard let relatedTaskLists = relatedTaskLists, let sectionRefResult = sectionRefResult else {
            return nil
        }
        return relatedTaskLists.compactMap { taskList in
            guard let sectionRef = sectionRefResult[taskList.guid] else { return nil }
            var param = Rust.ContainerSection()
            param.containerGuid = taskList.guid
            param.sectionGuid = sectionRef.ref.sectionGuid
            param.rank = sectionRef.ref.rank
            return param
        }
    }

    // 批量创建子任务
    private func saveSubTasks(ancestorGuid: String, subTasks: [Rust.Todo]) {
        guard isFromSubTask else { return }
        operateApi?.createSubTask(in: ancestorGuid, with: subTasks).take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onError: { err in
                    QuickCreate.logger.error("create subTasks failed, error:\(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    func getSingleSubTaskReq() -> (ancestorGuid: String, subTasks: [Rust.Todo], ancestorIsSubTask: Bool)? {
        guard isFromSubTask else { return nil }
        let subTasks: [Rust.Todo], ancestorGuid: String, ancestorIsSubTask: Bool
        switch source {
        case .subTask(let ancestorId, let isSubTask, _):
            subTasks = [todoData]
            ancestorGuid = ancestorId
            ancestorIsSubTask = isSubTask
        default: return nil
        }
        return (ancestorGuid, subTasks, ancestorIsSubTask)
    }

    func shareAfterSave(todoId: String, callback: ((ShareToLarkResult) -> Void)?) {
        // chatSetting 场景会自己处理分享卡片逻辑
        guard case .chat(let chatContext) = source,
              case .chatKeyboard = chatContext.fromContent else {
            return
        }
        shareService?.shareToLark(
            withTodoId: todoId,
            items: [.chat(chatId: chatContext.chatId)],
            type: .create,
            message: nil,
            completion: callback
        )
    }

    /// 保存草稿
    func saveDraft() {
        guard source.isEnableDraft() else { return }
        operateApi?.saveTodoDraft(todoData, scene: draftScene).subscribe().disposed(by: disposeBag)
    }

    /// 删除草稿
    func deleteDraft() {
        guard source.isEnableDraft() else { return }
        operateApi?.deleteTodoDraft(byScene: draftScene).subscribe().disposed(by: disposeBag)
    }

}

// MARK: View Data

extension QuickCreateViewModel {

    private func bindViewData() {
        rxUpdate.subscribe(onNext: { [weak self] updateSet in
            if updateSet.contains(.owner) {
                self?.updateOwnerViewData()
            }
            if updateSet.contains(.time) {
                self?.updateTimeViewData()
                self?.updateTimePickerViewData()
            }
            if updateSet.contains(.summary) || updateSet.contains(.time) {
                self?.updateBottomViewData()
            }
        }).disposed(by: disposeBag)

        rxEnableQuickDueTimeEntry.distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.updateTimePickerViewData()
                self?.updateBottomViewData()
            })
            .disposed(by: disposeBag)

        rxSummaryValid.distinctUntilChanged()
            .subscribe(onNext: { [weak self] _ in
                self?.updateTimePickerViewData()
                self?.updateBottomViewData()
            })
            .disposed(by: disposeBag)
    }

    private func updateOwnerViewData() {
        let assignees = todoData.assignees.map({ Assignee(model: $0 )})
        let viewData = OwnersViewData(
            owners: assignees,
            canSelectMulti: FeatureGating(resolver: userResolver).boolValue(for: .multiAssignee),
            mode: todoData.mode
        )
        rxOwnerViewData.accept(viewData)
    }

    private func updateActiveChatters() {
        var targetSet = Set<String>()
        let currentUserId = userResolver.userID
        targetSet.insert(currentUserId)
        for assignee in todoData.assignees where assignee.type == .user {
            targetSet.insert(assignee.assigneeID)
        }
        for follower in todoData.followers where follower.type == .user {
            targetSet.insert(follower.followerID)
        }
        if inputController.rxActiveChatters.value != targetSet {
            inputController.rxActiveChatters.accept(targetSet)
        }
    }

    private func updateTimeViewData() {
        var hasReminder: Bool {
            guard let remind = todoData.reminders.first else {
                return false
            }
            return remind.time != -1
        }
        var hasRepeat: Bool { !todoData.rrule.isEmpty }

        var startTimeText: String?, dueTimeText: String?
        if todoData.isStartTimeValid, todoData.isDueTimeValid {
            startTimeText = formatTime(todoData.startTimeForFormat, todoData.isAllDay)
            dueTimeText = formatTime(todoData.dueTime, todoData.isAllDay)
        } else if todoData.isStartTimeValid {
            startTimeText = I18N.Todo_TaskStartsFrom_Text(formatTime(todoData.startTimeForFormat, todoData.isAllDay))
        } else if todoData.isDueTimeValid {
            dueTimeText = I18N.Todo_Task_TimeDue(formatTime(todoData.dueTime, todoData.isAllDay))
        }

        var viewData = DetailDueTimeViewData(
            preferQuick: false,
            hasReminder: hasReminder,
            hasRepeat: hasRepeat,
            hasClearBtn: true,
            isClearBtnDisable: false
        )
        viewData.startTimeText = startTimeText
        viewData.dueTimeText = dueTimeText
        rxTimeViewData.accept(viewData)
    }

    private func updateTimePickerViewData() {
        if !hasDueTime() && rxEnableQuickDueTimeEntry.value {
            rxDueTimePickViewData.accept(DueTimePickViewData(isVisible: true))
        } else {
            rxDueTimePickViewData.accept(DueTimePickViewData(isVisible: false))
        }
    }

    private func updateBottomViewData() {
        var bottomViewData = BottomViewData()
        if sourceChatId != nil {
            bottomViewData.sendAction.title = I18N.Todo_Task_CreateAndSendButton
        } else {
            bottomViewData.sendAction.title = I18N.Todo_Task_CreateButton
        }
        bottomViewData.sendAction.isEnabled = rxSummaryValid.value
        let icon = UDIcon.memberAddOutlined
        let atIconAction = QuickCreateBottomIconAction(type: .assignee,
                                                       icon: icon,
                                                       highlightedIcon: icon.ud.withTintColor(UIColor.ud.primaryContentDefault))
        var timeIcon = UDIcon.calendarDateOutlined
        if !hasDueTime() {
            if rxEnableQuickDueTimeEntry.value {
                timeIcon = timeIcon.ud.withTintColor(UIColor.ud.primaryContentDefault)
            }
        }
        let timeIconAction = QuickCreateBottomIconAction(type: .time,
                                                         icon: timeIcon,
                                                         highlightedIcon: timeIcon.ud.withTintColor(UIColor.ud.primaryContentDefault))
        bottomViewData.iconActions = [atIconAction, timeIconAction]
        rxBottomViewData.accept(bottomViewData)
    }

    private func hasDueTime() -> Bool {
        todoData.dueTime > 0
    }

}

// MARK: - View Action

extension QuickCreateViewModel {

    // MARK: Summary

    /// 更新标题
    func updateSummaryInput(_ attrText: AttrText) {
        todoData.richSummary = inputController.makeRichContent(from: attrText)
        rxUpdate.onNext(.summary)
        let summaryValid = !attrText.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        rxSummaryValid.accept(summaryValid)
    }

    func headerPlaceholder() -> String {
        if source.isFromSubTask {
            return I18N.Todo_AddSubTasks_Placeholder_Mobile
        }
        return I18N.Todo_Task_AddTask
    }

    // Batch SubTasks
    func createSubTasks(_ chatterIds: [String]) {
        guard !chatterIds.isEmpty else { return }
        fetchApi?.getUsers(byIds: chatterIds).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] users in
                    QuickCreate.logger.info("get subTasks owner succeed")
                    guard let self = self, let req = self.getSingleSubTaskReq() else { return }
                    let subTasks = users.map { user -> Rust.Todo in
                        var subTask = self.todoData
                        let user = User(pb: user)
                        subTask.assignees = [Assignee(member: .user(user)).asModel()]
                        return subTask
                    }
                    self.saveSubTasks(ancestorGuid: req.ancestorGuid, subTasks: subTasks)
                },
                onError: { err in
                    QuickCreate.logger.error("get todo subTasks failed, error:\(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: Owner
    func addOwners(with chatterIds: [String]) {
        guard !chatterIds.isEmpty else { return }
        fetchApi?.getUsers(byIds: chatterIds).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] users in
                    guard let self = self else { return }
                    QuickCreate.logger.info("get user succeed when get owner")
                    self.selectOwner(with: users.map({ User(pb: $0) }))
                    self.rxUpdate.onNext(.owner)
                },
                onError: { err in
                    QuickCreate.logger.error("get todo owner failed, error:\(err)")
                }
            )
            .disposed(by: disposeBag)

    }

    func removeOwner() {
        todoData.assignees = []
        rxUpdate.onNext(.owner)
    }

    var selectedAssigneeIds: [String] {
        todoData.assignees.map { $0.assigneeID }
    }

    // MARK: Assignee
    func selectOwner(with users: [User]) {
        let newUsers = users.map({ Assignee(member: .user($0)).asModel() })
        var assignees = todoData.assignees
        assignees.append(contentsOf: newUsers)
        todoData.assignees = assignees.lf_unique(by: \.assigneeID)
        rxUpdate.onNext(.owner)
    }

    func fetchTodoUsers(with ids: [String], onSuccess: @escaping ([User]) -> Void) {
        guard !ids.isEmpty else { return }
        fetchApi?.getUsers(byIds: ids).take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { users in
                    onSuccess(users.map(User.init(pb:)))
                },
                onError: { err in
                    QuickCreate.logger.error("fetch users failed, error:\(err)")
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: Time

    func setTimeComponents(_ tuple: DueRemindTuple) {
        todoData.startMilliTime = (tuple.startTime ?? 0) * 1_000
        todoData.dueTime = tuple.dueTime ?? 0
        if let reminder = tuple.reminder {
            todoData.reminders = [reminder.toPb()]
        } else {
            todoData.reminders = []
        }
        todoData.isAllDay = tuple.isAllDay
        if let rrule = tuple.rrule {
            todoData.rrule = rrule
        } else {
            todoData.rrule = ""
        }

        rxUpdate.onNext(.time)
    }

    func clearTimeComponents() {
        todoData.dueTime = 0
        todoData.isAllDay = false
        todoData.reminders = []
        todoData.rrule = ""

        rxUpdate.onNext(.time)
        rxEnableQuickDueTimeEntry.accept(false)
    }

    func setTodayDueTime() {
        setupDueTime(.today)
    }

    func setTomorrowDueTime() {
        setupDueTime(.tomorrow)
    }

    private func setupDueTime(_ type: V3ListTimeGroup.DueTime) {
        let timestamp = type.defaultDueTime(
            by: defaultDueTimeDayOffset,
            timeZone: timeZone,
            isAllDay: FeatureGating(resolver: userResolver).boolValue(for: .startTime)
        )
        var offset = dueReminderOffset
        if FeatureGating(resolver: userResolver).boolValue(for: .startTime) {
            offset = AllDayReminder.onDayofEventAt6pm.rawValue
        }
        offset = Utils.Reminder.fixReminder(by: timestamp, offset: offset)


        todoData.dueTime = timestamp
        todoData.reminders = [Reminder.relativeToDueTime(offset).toPb()]
        todoData.isAllDay = FeatureGating(resolver: userResolver).boolValue(for: .startTime)
        if isReminderInValid() {
            todoData.reminders = []
        }
        rxUpdate.onNext(.time)
    }

    // MARK: Bottom

    func respondsToBottomTimeAction() -> Bool {
        guard !hasDueTime() else { return false }
        let flag = rxEnableQuickDueTimeEntry.value
        rxEnableQuickDueTimeEntry.accept(!flag)
        return true
    }

}

// MARK: - Other

extension QuickCreateViewModel {

    func getDueRemindTuple() -> DueRemindTuple? {
        return DueRemindTuple(from: todoData)
    }

    func getSelectedChatterIds() -> [String] {
        var selectedChatterIds = [String]()
        for assignee in todoData.assignees {
            switch assignee.type {
            case .user:
                selectedChatterIds.append(assignee.assigneeID)
            @unknown default:
                break
            }
        }
        return selectedChatterIds
    }

    func hasAssigee() -> Bool {
        return !todoData.assignees.isEmpty
    }

    func getSelectedAssignees() -> [Rust.Assignee] {
        return todoData.assignees
    }

    func isReminderInValid() -> Bool {
        guard todoData.isDueTimeValid else { return false }
        var reminder: Reminder?
        if let pbReminder = todoData.reminders.first {
            reminder = Reminder(pb: pbReminder)
        }
        return Utils.Reminder.isReminderInValid(
            .init(dueTime: todoData.dueTime, reminder: reminder, isAllDay: todoData.isAllDay),
            timeZone: timeZone
        )
    }

    func cancelInValidReminder() {
        todoData.reminders = []
    }

}

// MARK: - View Data Impl

extension QuickCreateViewModel {

    private struct OwnersViewData: QuickCreateOwnerViewDataType {
        var owners: [Assignee]?
        var canSelectMulti: Bool
        var mode: Rust.TaskMode
        var avatars: [AvatarSeed]? {
            guard let owners = owners, !owners.isEmpty else {
                return nil
            }
            return owners.compactMap({ assignee in
                return assignee.asUser()?.avatar
            })
        }
        var text: String? {
            guard let owners = owners, !owners.isEmpty else { return nil }
            var value = I18N.Todo_MultiOwners_CompleteRatio_Text("0/\(owners.count)")
            if mode == .taskComplete {
                value = I18N.Todo_NumTaskOwners_ICU(owners.count)
            }
            if owners.count == 1 {
                value = owners.first?.name ?? ""
            }
            return value
        }
        var hasClearBtn: Bool {
            guard let owners = owners, owners.count == 1 else {
                return false
            }
            return true
        }
        var hasIcon: Bool { !canSelectMulti }
    }

    private struct DueTimePickViewData: QuickCreateDueTimePickViewDataType {
        var isVisible: Bool
    }

    private struct BottomViewData: QuickCreateBottomViewDataType {
        var iconActions = [QuickCreateBottomIconAction]()
        var sendAction = (title: "", isEnabled: false)
        var descriptionText: String?
    }

    private func formatTime(_ time: Int64, _ isAllDay: Bool) -> String {
       return Utils.DueTime.formatedString(
            from: time,
            in: timeZone,
            isAllDay: isAllDay,
            is12HourStyle: is12HourStyle
        )
    }

    private func getJulianDayDueTime(_ date: Date) -> Int64 {
        let dueTime = Int64(date.timeIntervalSince1970)
        let julianDay = JulianDayUtil.julianDay(from: dueTime, in: timeZone)
        return JulianDayUtil.startOfDay(for: julianDay, in: timeService?.utcTimeZone ?? .current)
    }
}

// MARK: - Method

extension QuickCreateViewModel {

    // 是否需要展示扩展按钮
    var displayHeaderExpand: Bool { source.isFromSubTask }

    // 点击键盘return后是否关闭
    var closeAfterReturnType: Bool { displayHeaderExpand }

    // 描述是否是会话场景
    var isFromChat: Bool { source.isFromChat }

    // 是否来自子任务创建
    var isFromSubTask: Bool { source.isFromSubTask }

    // 是否列表场景
    var isInLineScene: Bool { source.isFromList || source.isFromInline }

    var fillOwner: Bool { source.autoFillOwner }

    // 校验在子任务场景是否可选
    var checkOwnerPickerInSubTask: Bool {
        guard isFromSubTask else { return true }
        return rxSummaryValid.value
    }
}

// MARK: - Track

extension QuickCreateViewModel: MemberListViewModelDependency {

    var memberListInput: MemberListViewModelInput {
        return MemberListViewModelInput(
            todoId: "",
            todoSource: .todo,
            chatId: sourceChatId,
            scene: .creating_assignee,
            selfRole: [.creator],
            canEditOther: true,
            members: todoData.assignees.map { $0.asMember() },
            mode: todoData.mode,
            modeEditable: true
        )
    }
    
    func appendMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?) {
        let result = getSingleSubTaskReq()
        OwnerPicker.Track.finalAddClick(
            with: result?.ancestorGuid ?? "",
            isEdit: (result?.ancestorIsSubTask ?? false),
            isSubTask: true
        )
        let assignees = members.map { member in
            return Assignee(member: member)
        }
        var existsAssignees = todoData.assignees.map({ Assignee(model: $0) })
        var exists = Set<String>()
        existsAssignees.forEach { exists.insert($0.identifier) }
        let appending = assignees.filter { !exists.contains($0.identifier) }
        existsAssignees.append(contentsOf: appending)
        todoData.assignees = existsAssignees.map({ $0.asModel() })
        rxUpdate.onNext(.owner)
    }

    func removeMembers(input: MemberListViewModelInput, _ members: [Member], completion: Completion?) {
        let assignees = members.map { member in
            return Assignee(member: member)
        }
        let needsRemove = Set(assignees.map(\.identifier))
        todoData.assignees = todoData.assignees.filter { !needsRemove.contains($0.identifier) }
        rxUpdate.onNext(.owner)
    }

    func changeTaskMode(input: MemberListViewModelInput, _ newMode: Rust.TaskMode, completion: Completion?) {
        let result = getSingleSubTaskReq()
        OwnerPicker.Track.changeDoneClick(
            with: result?.ancestorGuid ?? "",
            isEdit: (result?.ancestorIsSubTask ?? false),
            isSubTask: true
        )
        todoData.mode = newMode
        rxUpdate.onNext(.owner)
    }

}

// MARK: - Track

extension QuickCreateViewModel {

    private func trackBeginCreating() {
        var params: [AnyHashable: Any] = [:]
        params["ab_version"] = "inline"
        TrackerUtil.fillCreatingTodoParams(&params, with: source)
        QuickCreate.trackEvent(key: .create, params: params)

        // 多选消息，额外埋点
        if case .chat(let chatContext) = source,
           case .multiSelectMessages(let messageIds, _) = chatContext.fromContent {
            Detail.tracker(.todo_im_conversions_task, params: ["message_num": messageIds.count])
        }
    }

    private func trackEndCreating() {
        var params = [AnyHashable: Any]()
        params["ab_version"] = "inline"
        TrackerUtil.fillCreatingTodoParams(&params, with: source)
        TrackerUtil.fillCreatingTodoParams(&params, with: todoData)
        QuickCreate.trackEvent(key: .create_confirm, params: params)
    }

    func trackPickTime(type: String) {
        QuickCreate.trackEvent(
            key: .select_time,
            params: [
                "source": "create",
                "task_id": "",
                "state": todoData.dueTime == 0 ? "no" : "yes",
                "time_type": type
            ]
        )
    }

    func trackExpand() {
        QuickCreate.trackEvent(key: .expand_to_detail, params: ["type": "yes"])
    }

    func trackUnexpand() {
        QuickCreate.trackEvent(key: .expand_to_detail, params: ["type": "no"])
    }

    func suspendCreateTrack() {
        QuickCreate.trackEvent(key: .create_suspend)
    }

}
