//
//  ChatTodoViewModel.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/25.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import TodoInterface
import LarkAccountInterface
import LarkTimeFormatUtils
import LarkModel
import UniverseDesignIcon
import LarkNavigation

final class ChatTodoViewModel: UserResolverWrapper {

    // MARK: - public
    var userResolver: LarkContainer.UserResolver
    let chatId: String
    let isFromThread: Bool
    var listUpdateResponder: (() -> Void)?
    let rxLoadMoreState: BehaviorRelay<ListLoadMoreState> = .init(value: .none)
    let rxViewState = BehaviorRelay<ListViewState>(value: .idle)

    // MARK: - sections

    private lazy var newCreatedSection = ChatTodoListSection(
        header: V3ListSectionHeaderData(titleInfo: (nil, ChatTodoSectionType.newCreated.titleStr)),
        items: []
    )
    private lazy var assignToMeSection = ChatTodoListSection(
        header: V3ListSectionHeaderData(titleInfo: (nil, ChatTodoSectionType.assignToMe.titleStr)),
        items: []
    )
    private lazy var assignToOtherSection = ChatTodoListSection(
        header: V3ListSectionHeaderData(titleInfo: (nil, ChatTodoSectionType.assignToOther.titleStr)),
        items: []
    )
    private lazy var completedSection: ChatTodoListSection = {
        var headerData = V3ListSectionHeaderData(titleInfo: (nil, ChatTodoSectionType.completed.titleStr))
        headerData.isFold = true
        return ChatTodoListSection(header: headerData, items: [])
    }()
    // 顺序决定显示的顺序
    private lazy var _sections = [newCreatedSection, assignToMeSection, assignToOtherSection, completedSection]
    private var sections: [ChatTodoListSection] {
        return  _sections.filter { !$0.items.isEmpty }
    }

    // MARK: - dependency
    @ScopedInjectedLazy var messengerDependency: MessengerDependency?
    @ScopedInjectedLazy private var chatTodoApi: ChatTodoApi?
    @ScopedInjectedLazy private var operateApi: TodoOperateApi?
    @ScopedInjectedLazy private var formatApi: FormatRuleApi?
    @ScopedInjectedLazy private var shareService: ShareService?
    @ScopedInjectedLazy private var navigationService: NavigationService?
    @ScopedInjectedLazy private var completeService: CompleteService?
    @ScopedInjectedLazy private var richContentService: RichContentService?
    @ScopedInjectedLazy private var timeService: TimeService?

    private var currentUserID: String { userResolver.userID }
    // 时间格式化上下文
    var curTimeContext: TimeContext {
        return TimeContext(
            currentTime: Int64(Date().timeIntervalSince1970),
            timeZone: timeService?.rxTimeZone.value ?? .current,
            is12HourStyle: timeService?.rx12HourStyle.value ?? false
        )
    }

    // MARK: - others

    private let disposeBag = DisposeBag()
    private var lastOffset: Int64?
    private let pageCount = 20
    private var formatRule: Rust.FormatRule = .unknown

    init(resolver: UserResolver, chatId: String, isFromThread: Bool) {
        self.userResolver = resolver
        self.chatId = chatId
        self.isFromThread = isFromThread
    }

    func setup() {
        guard let chatTodoApi = chatTodoApi, let formatApi = formatApi else { return }
        let trackerTask = Tracker.Appreciable.Task(scene: .listInChat, event: .inChatLoadFirstPage).resume()
        rxViewState.accept(.loading)
        Observable.zip(
            chatTodoApi.getChatTodos(byChatId: chatId),
            chatTodoApi.getCompletedChatTodos(byChatId: chatId, pageCount: pageCount, lastOffset: nil),
            formatApi.getAnotherNameFormat()
        ).take(1).asSingle()
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(
            onSuccess: { [weak self] tuple in
                guard let self = self else { return }
                trackerTask.complete()
                let (inCompletedItems, completedItems, formatRule) = tuple
                self.formatRule = formatRule

                if inCompletedItems.assignToMe.isEmpty &&
                    inCompletedItems.assignToOther.isEmpty &&
                    completedItems.chatTodos.isEmpty {
                    self.rxViewState.accept(.empty)
                    return
                }
                // swiftlint:disable line_length
                ChatTodo.logger.info("get binded datas success. countList: \(inCompletedItems.assignToMe.count) \(inCompletedItems.assignToOther.count) \(completedItems.chatTodos.count) hasMore: \(completedItems.hasMore) lastOffset: \(completedItems.lastOffset)")
                // swiftlint:enable line_length
                self.rxViewState.accept(.data)

                self.fixOriginCellDatas(
                    assignToMeItems: inCompletedItems.assignToMe,
                    assignToOtherItems: inCompletedItems.assignToOther,
                    completedItems: completedItems.chatTodos
                )
                self.lastOffset = completedItems.hasMore ? completedItems.lastOffset : nil
                self.listUpdateResponder?()
            },
            onError: { [weak self] error in
                ChatTodo.logger.error("get binded datas failed. error: \(error)")
                self?.rxViewState.accept(.failed())
                trackerTask.error(error)
            }
        )
        .disposed(by: self.disposeBag)
    }

    func loadMore() {
        guard let lastOffset = lastOffset, let chatTodoApi = chatTodoApi else {
            ChatTodo.assertionFailure()
            return
        }
        let trackerTask = Tracker.Appreciable.Task(scene: .listInChat, event: .inChatLoadMore).resume()
        self.rxLoadMoreState.accept(.loading)
        chatTodoApi.getCompletedChatTodos(byChatId: chatId, pageCount: pageCount, lastOffset: lastOffset)
            .take(1).asSingle()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onSuccess: { [weak self] tuple in
                    trackerTask.complete()
                    guard let self = self else { return }
                    self.completedSection.items += tuple.chatTodos.map { self.mapToCellData(from: $0, type: .completed) }
                    self.listUpdateResponder?()
                    self.lastOffset = tuple.hasMore ? tuple.lastOffset : nil

                    ChatTodo.logger.info("loadMore success. count: \(tuple.chatTodos.count) hasMore: \(tuple.hasMore) lastOffset: \(tuple.lastOffset)")

                    guard self.rxLoadMoreState.value != .none else { return }
                    self.rxLoadMoreState.accept(tuple.hasMore ? .hasMore : .noMore)
                },
                onError: { [weak self] error in
                    self?.rxLoadMoreState.accept(.hasMore)
                    ChatTodo.logger.error("loadMore failed. error: \(error)")
                    trackerTask.error(error)
                }
            )
            .disposed(by: self.disposeBag)
    }

    private func fixOriginCellDatas(
        assignToMeItems: [Rust.ChatTodo],
        assignToOtherItems: [Rust.ChatTodo],
        completedItems: [Rust.ChatTodo]
    ) {
        var assignToMeList = [ChatTodoCellData]()
        var assignToOtherList = [ChatTodoCellData]()
        var completedList = [ChatTodoCellData]()

        var allTodos = assignToMeItems + assignToOtherItems + completedItems
        var idSet = Set<String>()

        for chatTodo in allTodos {
            if idSet.contains(chatTodo.todo.guid) {
                ChatTodo.logger.error("get repetitionary datas \(chatTodo.todo.guid)")
                continue
            } else {
                idSet.insert(chatTodo.todo.guid)
            }

            let sectionType = getSectionType(chatTodo)
            ChatTodo.logger.info("section type. guid: \(chatTodo.todo.guid) newType: \(sectionType)")
            let cellData = mapToCellData(from: chatTodo, type: sectionType)

            switch sectionType {
            case .assignToMe:
                assignToMeList.append(cellData)
            case .assignToOther:
                assignToOtherList.append(cellData)
            case .completed:
                completedList.append(cellData)
            case .newCreated:
                ChatTodo.assertionFailure()
            }
        }
        assignToMeSection.items = sortCellDataList(assignToMeList, type: .assignToMe)
        assignToOtherSection.items = sortCellDataList(assignToOtherList, type: .assignToOther)
        completedSection.items = sortCellDataList(completedList, type: .completed)

        ChatTodo.logger.info("fixOriginCellDatas. countList: \(assignToMeList.count) \(assignToOtherList.count) \(completedList.count)")
    }

    /// 是否有Todo入口
    func hasTodoTab() -> Bool {
        return navigationService?.checkInTabs(for: .todo) ?? false
    }

}

// MARK: - CellData

extension ChatTodoViewModel {
    private func mapToCellData(from chatTodo: Rust.ChatTodo, type: ChatTodoSectionType) -> ChatTodoCellData {
        let timeContext = curTimeContext
        let completeState = completeService?.state(for: chatTodo.todo) ?? .outsider(isCompleted: false)
        var cellData = ChatTodoCellData(with: chatTodo, completeState: completeState)
        let contentData = V3ListContentData(
            todo: chatTodo.todo,
            isTaskEditableInContainer: false,
            completeState: (completeState, false),
            richContentService: richContentService,
            timeContext: timeContext
        )
        cellData.contentData = contentData
        cellData.type = type
        if chatTodo.hasSender {
            let otherName = UserName(
                alias: chatTodo.sender.alias,
                anotherName: chatTodo.sender.anotherName,
                localizedName: chatTodo.sender.localizedName
            )
            cellData.senderTitle = I18N.Todo_Chat_SenderSentAtTimeDesc(
                otherName.displayNameForPick(formatRule),
                getFormatedTimeString(by: chatTodo.sendTime)
            )
        }
        return cellData
    }

    private func getFormatedTimeString(by timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        var options = TimeFormatUtils.defaultOptions
        options.timePrecisionType = .minute
        options.timeFormatType = .short
        options.dateStatusType = .relative
        options.timeZone = curTimeContext.timeZone
        options.is12HourStyle = curTimeContext.is12HourStyle
        return TimeFormatUtils.formatDateTime(from: date, with: options)
    }

    private func sortCellDataList(_ list: [ChatTodoCellData], type: ChatTodoSectionType) -> [ChatTodoCellData] {
        switch type {
        case .completed:
            return list.sorted { [weak self] s1, s2 in
                guard let self = self else { return true }
                return SortType.byCompletedTime.sorter(s1, s2, self.curTimeContext.timeZone)
            }
        case .assignToMe, .assignToOther:
            return list.sorted { [weak self] s1, s2 in
                guard let self = self else { return true }
                return SortType.byDueTime.sorter(s1, s2, self.curTimeContext.timeZone)
            }
        case .newCreated:
            return list.sorted { [weak self] s1, s2 in
                guard let self = self else { return true }
                return SortType.byCreatTime.sorter(s1, s2, self.curTimeContext.timeZone)
            }
        }
    }

    private enum SortType {
        case byCompletedTime
        case byDueTime
        case byCreatTime

        func sorter(_ m: ChatTodoCellData, _ n: ChatTodoCellData, _ timeZone: TimeZone) -> Bool {
            let mTodo = m.chatTodo.todo
            let nTodo = n.chatTodo.todo

            switch self {
            case .byCreatTime:
                return mTodo.createMilliTime >= nTodo.createMilliTime
            case .byCompletedTime:
                let t1 = mTodo.userCompletedTime(with: m.completeState)
                let t2 = nTodo.userCompletedTime(with: n.completeState)
                return t1 >= t2
            case .byDueTime:
                switch (mTodo.isDueTimeValid, nTodo.isDueTimeValid) {
                case (false, false):
                    return mTodo.createMilliTime >= nTodo.createMilliTime
                case (false, true):
                    return false
                case (true, false):
                    return true
                case (true, true):
                    let (dueTime0, dueTime1) = (mTodo.dueTimeForDisplay(timeZone), nTodo.dueTimeForDisplay(timeZone))
                    if dueTime0 == dueTime1 {
                        return mTodo.createMilliTime >= nTodo.createMilliTime
                    } else {
                        return dueTime0 < dueTime1
                    }
                default:
                    ChatTodo.assertionFailure("out of case in chat todo")
                }
            }
        }
    }
}

// MARK: - UICollectionView Data Source

extension ChatTodoViewModel {
    func sectionCount() -> Int {
        return sections.count
    }

    func headerData(in section: Int) -> V3ListSectionHeaderData? {
        guard safeCheckSection(section) else {
            return nil
        }
        var data = sections[section].header
        guard let text = data.titleInfo?.text, !text.isEmpty else {
            return nil
        }
        if data.titleInfo?.text != ChatTodoSectionType.completed.titleStr {
            data.totalCount = sections[section].items.count
        }
        if data.layoutInfo == nil {
            data.layoutInfo = data.makeLayoutInfo()
        }
        return data
    }

    func itemCount(in section: Int) -> Int {
        guard safeCheckSection(section) else { return 0 }
        let data = sections[section]
        return data.header.isFold ? 0 : data.items.count
    }

    func itemData(at indexPath: IndexPath) -> ChatTodoCellData? {
        guard let (section, row) = safeUnwrapIndexPath(indexPath) else {
            return nil
        }
        return sections[section].items[row]
    }

    func chatTodo(at indexPath: IndexPath) -> Rust.ChatTodo? {
        guard let (section, row) = safeUnwrapIndexPath(indexPath) else { return nil }
        return sections[section].items[row].chatTodo
    }

    private func safeCheckSection(_ section: Int, file: StaticString = #fileID, line: UInt = #line) -> Bool {
        guard section >= 0 && section < sections.count else {
            ChatTodo.assertionFailure("checkSection failed.")
            return false
        }
        return true
    }

    private func safeUnwrapIndexPath(
        _ indexPath: IndexPath,
        file: StaticString = #fileID,
        line: UInt = #line
    ) -> (section: Int, row: Int)? {
        let (section, row) = (indexPath.section, indexPath.row)
        guard section >= 0
                && section < sections.count
                && row >= 0
                && row < sections[section].items.count else {
            var text = "unwrapIndexPath failed. indexPath: \(indexPath)"
            text += " sectionCount: \(sections.count)"
            if section >= 0 && section < sections.count {
                text += " itemCount: \(sections[section].items.count)"
            }
            ChatTodo.assertionFailure(text, type: .unwrapIndexPath)
            return nil
        }
        return (section, row)
    }
}

// MARK: - UICollectionView Action

extension ChatTodoViewModel {

    func toggleFold(sectionKey: String) {
        guard let section = sections.first(where: { $0.header.titleInfo?.text == sectionKey }) else { return }

        let isFold = !section.header.isFold
        section.header.isFold = isFold

        // 「完成」section 且 是展开状态
        if sectionKey == ChatTodoSectionType.completed.titleStr, !isFold {
            let hasMore = lastOffset != nil
            rxLoadMoreState.accept(hasMore ? .hasMore : .noMore)
        } else {
            rxLoadMoreState.accept(.none)
        }
    }

    func getCustomComplete(at indexPath: IndexPath) -> CustomComplete? {
        guard let todo = chatTodo(at: indexPath)?.todo else { return nil }
        return completeService?.customComplete(from: todo)
    }

    func doubleCheckBeforeToggleCompleteState(at indexPath: IndexPath) -> CompleteDoubleCheckContext? {
        guard let todo = chatTodo(at: indexPath)?.todo else { return nil }
        return completeService?.doubleCheckBeforeToggleState(with: .todo, todo: todo, hasContainerPermission: false)
    }

    func toggleCompleteState(forId guid: String) {
        guard let indexPath = findIndexPath(by: guid) else {
            return
        }
        toggleCompleteState(at: indexPath)
    }

    private func toggleCompleteState(at indexPath: IndexPath) {
        guard let chatTodo = chatTodo(at: indexPath) else { return }
        guard let data = itemData(at: indexPath) else { return }
        var toState = data.completeState.toggled(by: .todo)

        ChatTodo.logger.info("toggleCompleteState. guid: \(chatTodo.todo.guid) indexPath: \(indexPath) value: \(toState.logInfo)")

        if toState.isCompleted {
            Detail.tracker(.todo_task_status_done, params: ["task_id": chatTodo.todo.guid, "source": "chat_todo_list"])
        }

        var todo = chatTodo.todo
        completeService?.updateTodo(&todo, to: toState)
        handleUpdatedItem(at: indexPath, item: todo)

        let ctx = CompleteContext(fromState: data.completeState, role: .todo)
        completeService?.toggleState(
            with: ctx,
            todoId: data.chatTodo.todo.guid,
            todoSource: chatTodo.todo.source,
            containerID: nil
        )
        .observeOn(MainScheduler.asyncInstance)
        .subscribe(
            onSuccess: { [weak self] _ in
                guard let self = self else { return }
                ChatTodo.Track.clickCheckBox(with: todo, chatId: self.chatId, fromState: data.completeState)
            },
            onError: { error in
                ChatTodo.logger.error("toggleCompleteState failed. error: \(error)")
            }
        )
        .disposed(by: self.disposeBag)
    }
}

// MARK: - Data Updated

extension ChatTodoViewModel {
    func handleDeletedItem(at indexPath: IndexPath) {
        guard let (section, row) = safeUnwrapIndexPath(indexPath) else { return }
        ChatTodo.logger.info("handleDeletedItem at \(indexPath)")
        sections[section].items.remove(at: row)

        listUpdateResponder?()
        checkDataStatus()
    }

    func handleUpdatedItem(at indexPath: IndexPath, item: Rust.Todo) {
        guard let (section, row) = safeUnwrapIndexPath(indexPath) else { return }
        ChatTodo.logger.info("handleUpdatedItem at \(indexPath)")
        let oldCellData = sections[section].items[row]
        var chatTodo = oldCellData.chatTodo

        guard chatTodo.todo.guid == item.guid else {
            if let indexPath = findIndexPath(by: item.guid) {
                ChatTodo.logger.info("handleUpdatedItem at fixed path: \(indexPath)")
                handleUpdatedItem(at: indexPath, item: item)
            }
            return
        }

        sections[section].items.remove(at: row)
        chatTodo.todo = item

        let type = judgeChatTodoType(chatTodo, fromType: oldCellData.type)
        guard var sectionData = _sections.first(where: { $0.header.titleInfo?.text == type.titleStr }) else { return }

        if type == .completed {
            sectionData.header.isFold = false
        }
        let cellData = mapToCellData(from: chatTodo, type: type)

        sectionData.items.append(cellData)
        sectionData.items = sortCellDataList(sectionData.items, type: type)

        listUpdateResponder?()
    }

    func findIndexPath(by guid: String) -> IndexPath? {
        for (section, sectionData) in sections.enumerated() {
            for (row, cellData) in sectionData.items.enumerated() where cellData.chatTodo.todo.guid == guid {
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }

    private func judgeChatTodoType(_ item: Rust.ChatTodo, fromType: ChatTodoSectionType?) -> ChatTodoSectionType {
        let type = getSectionType(item)
        if fromType == .some(.newCreated) {
            return type == .completed ? .completed : .newCreated
        }
        return type
    }

    private func getSectionType(_ chatTodo: Rust.ChatTodo) -> ChatTodoSectionType {
        let type: ChatTodoSectionType
        if let completeService = completeService, completeService.state(for: chatTodo.todo).isCompleted {
            type = .completed
        } else {
            let isSelfInAssignees = chatTodo.todo.assignees.contains(where: { $0.assigneeID == currentUserID })
            let isSelfCreator = chatTodo.todo.creatorID == currentUserID
            let isAssignToMe = isSelfInAssignees || (chatTodo.todo.assignees.isEmpty && isSelfCreator)
            type = isAssignToMe ? .assignToMe : .assignToOther
        }
        return type
    }

    func handleCreatedTodo(_ todo: Rust.Todo, completion: @escaping (UserResponse<Void>) -> Void) {
        ChatTodo.logger.info("handleCreatedTodo guid: \(todo.guid)")

        let insertTodoToList = { [weak self] (todo: Rust.Todo, message: LarkModel.Message?) in
            var chatTodo = Rust.ChatTodo()
            chatTodo.todo = todo
            if let message = message {
                chatTodo.messageID = message.id
                chatTodo.messagePosition = message.position
                chatTodo.sendTime = Int64(message.createTime)
                if let chatter = message.fromChatter?.transform() {
                    chatTodo.sender = chatter
                }
            }
            self?.handleCreatedChatTodo(chatTodo: chatTodo)
        }
        shareService?.shareToLark(
            withTodoId: todo.guid,
            items: [.chat(chatId: chatId)],
            type: .create,
            message: nil
        ) { [weak self] result in
            guard let self = self else { return }

            var messageIds = [String]()
            switch result {
            case .success(let ids, _):
                messageIds = ids
            case .failure(let errorMessage):
                insertTodoToList(todo, nil)
                completion(.failure(.init(message: errorMessage)))
                return
            }
            guard !messageIds.isEmpty else {
                insertTodoToList(todo, nil)
                completion(.failure(.init(message: I18N.Todo_Task_FailToShare)))
                return
            }
            ChatTodo.logger.info("shareToLark success. messageIds: \(messageIds)")
            self.messengerDependency?.fetchMessages(byIds: messageIds).asSingle()
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(
                    onSuccess: { messages in
                        if let message = messages.first {
                            ChatTodo.logger.info("fetchMessages success.")
                            insertTodoToList(todo, message)
                            completion(.success(void))
                        } else {
                            ChatTodo.logger.info("fetchMessages failed")
                            insertTodoToList(todo, nil)
                            completion(.failure(.init(message: I18N.Todo_Task_FailToShare)))
                        }
                    },
                    onError: { error in
                        ChatTodo.logger.info("fetchMessages failed. error: \(error)")
                        insertTodoToList(todo, nil)
                        completion(.failure(.init(error: error, message: I18N.Todo_Task_FailToShare)))
                    }
                )
                .disposed(by: self.disposeBag)
        }
    }

    private func handleCreatedChatTodo(chatTodo: Rust.ChatTodo) {
        newCreatedSection.items.append(mapToCellData(from: chatTodo, type: .newCreated))
        newCreatedSection.items = sortCellDataList(newCreatedSection.items, type: .newCreated)

        listUpdateResponder?()
        checkDataStatus()
    }

    private func checkDataStatus() {
        rxViewState.accept(sections.isEmpty ? .empty : .data)
    }
}
