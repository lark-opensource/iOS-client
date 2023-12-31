//
//  ThreadPreviewMessagesViewModel.swift
//  LarkThread
//
//  Created by ByteDance on 2022/9/9.
//

import UIKit
import Foundation
import LarkCore
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import LKCommonsLogging
import LarkFeatureGating
import LarkAccountInterface
import RustPB
import LarkContainer

final class ThreadPreviewMessagesViewModel: AsyncDataProcessViewModel<ThreadPreviewMessagesViewModel.TableRefreshType, [ThreadCellViewModel]>, UserResolverWrapper {
    var userResolver: UserResolver { dependency.userResolver }
    enum TableRefreshType: OuputTaskTypeInfo {
        case hasNewMessage(hasLoading: Bool)
        case initMessages(InitMessagesInfo, needHightlight: Bool)
        case refreshMessages(hasHeader: Bool, hasFooter: Bool, scrollInfo: ScrollInfo?)
        case messagesUpdate(indexs: [Int], guarantLastCellVisible: Bool)
        case loadMoreOldMessages(hasLoading: Bool)
        case loadMoreNewMessages(hasLoading: Bool)
        case updateHeaderView(hasHeader: Bool)
        case updateFooterView(hasFooter: Bool)
        case scrollTo(ScrollInfo)
        case refreshTable
        case refreshMissedMessage
        case remain(hasLoading: Bool)
        case noMessage
        public func canMerge(type: TableRefreshType) -> Bool {
            switch (self, type) {
            case (.updateHeaderView, .updateHeaderView),
                (.updateFooterView, .updateFooterView),
                (.refreshTable, .refreshTable),
                (.hasNewMessage, .hasNewMessage):
                return true
            default:
                return false
            }
        }
        func duration() -> Double {
            var duration: Double = 0
            switch self {
            case .hasNewMessage:
                duration = CommonTable.scrollToTopAnimationDuration
            case .initMessages(_, needHightlight: let needHightlight) where needHightlight:
                duration = MessageCommonCell.highlightDuration
            case .scrollTo(let scrollInfo):
                duration = scrollInfo.highlightPosition != nil ? MessageCommonCell.highlightDuration : 0.1
            default:
                break
            }
            return duration
        }
        func isBarrier() -> Bool {
            switch self {
            case .messagesUpdate, .scrollTo:
                return true
            default:
                return false
            }
        }
    }

    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?
    let messageDatasource: ThreadChatDataSource
    let dependency: ThreadChatMessagesViewModelDependency
    private(set) var firstScreenLoaded: Bool = false

    //防止反复调用
    private var loadingMoreOldMessages: Bool = false
    private var loadingMoreNewMessages: Bool = false
    var topLoadMoreReciableKeyInfo: LoadMoreReciableKeyInfo?
    var bottomLoadMoreReciableKeyInfo: LoadMoreReciableKeyInfo?
    private static let logger = Logger.log(ThreadPreviewMessagesViewModel.self, category: "Business.ThreadChat")
    private(set) lazy var redundancyCount: Int32 = {
        return 5
    }()
    private(set) lazy var requestCount: Int32 = {
        return 30
    }()
    private var disposeBag = DisposeBag()
    private let pushHandlerRegister: ThreadChatPushHandlersRegister

    let chatWrapper: ChatPushWrapper
    var totalSystemCellHeight: CGFloat? {
        // 已经有话题
        let topics = self.messageDatasource.cellViewModels.first(where: { (cellVM) -> Bool in
            if let cellMessageVM = cellVM as? ThreadMessageCellViewModel,
               !(cellMessageVM.threadMessage.rootMessage.content is SystemContent) {
                return true
            }

            return false
        })

        // 已经存在一条话题
        if topics != nil {
            return nil
        }

        var totalCellsHeight: CGFloat = 0
        self.messageDatasource.cellViewModels.forEach { (cellVM) in
            totalCellsHeight += cellVM.renderer.size().height
        }

        ThreadPreviewMessagesViewModel.logger.info("ThreadOnboradingView system height \(totalCellsHeight)")
        return totalCellsHeight
    }

    var _chat: Chat {
        return self.chatWrapper.chat.value
    }

    var topicGroup: TopicGroup {
        return self.topicGroupPushWrapper.topicGroupObservable.value
    }

    lazy var chatId: String = {
        return self.chatWrapper.chat.value.id
    }()

    lazy var channel: RustPB.Basic_V1_Channel = {
        var channel = RustPB.Basic_V1_Channel()
        channel.id = self._chat.id
        channel.type = .chat
        return channel
    }()

    var highlightPosition: Int32?

    var threads: [RustPB.Basic_V1_Thread] {
        return self.uiDataSource.compactMap { (cellVM) -> RustPB.Basic_V1_Thread? in
            return (cellVM as? HasThreadMessage)?.getThread()
        }
    }

    private let topicGroupPushWrapper: TopicGroupPushWrapper
    private let dynamicRequestCountEnable: Bool

    let gcunit: GCUnit?

    let errorPublish = PublishSubject<ErrorType>()
    var errorDriver: Driver<ErrorType> {
        return errorPublish.asDriver(onErrorRecover: { _ in Driver<ErrorType>.empty() })
    }

    init(
        dependency: ThreadChatMessagesViewModelDependency,
        context: ThreadContext,
        chatWrapper: ChatPushWrapper,
        topicGroupPushWrapper: TopicGroupPushWrapper,
        pushHandlerRegister: ThreadChatPushHandlersRegister,
        gcunit: GCUnit?
    ) {
        self.dynamicRequestCountEnable = dependency.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.dynamicRequestCountEnable))
        self.chatWrapper = chatWrapper
        self.topicGroupPushWrapper = topicGroupPushWrapper
        self.dependency = dependency
        self.pushHandlerRegister = pushHandlerRegister
        self.messageDatasource = ThreadChatDataSource(
            userResolver: dependency.userResolver,
            chat: {
                return chatWrapper.chat.value
            },
            getTopicGroup: {
                return topicGroupPushWrapper.topicGroupObservable.value
            },
            currentChatterID: self.dependency.currentChatterID,
            vmFactory: ThreadCellViewModelFactory(
                context: context,
                registery: ThreadChatSubFactoryRegistery(context: context),
                cellLifeCycleObseverRegister: ThreadChatCellLifeCycleObseverRegister()
            ),
            minPosition: -1,
            maxPosition: -1
        )
        self.gcunit = gcunit
        super.init(uiDataSource: [])
        self.messageDatasource.contentPreferMaxWidth = { [weak self] _ in
            guard let self = self else { return 0 }
            return self.hostUIConfig.size.width - 16 - 16
        }
    }

    func initMessages() {
        self.loadFirstScreenMessages()
    }

    // MARK: Helper
    /// 根据消息 id和 cid 查找对应位置
    ///
    /// - Parameters:
    ///   - id: id is messageId or messageCid
    /// - Returns: index in datasource
    func findThreadIndexBy(id: String) -> Int? {
        guard !id.isEmpty else {
            return nil
        }
        return self.uiDataSource.firstIndex { (cellVM) -> Bool in
            if let messageVM = cellVM as? HasThreadMessage {
                return messageVM.getThread().id == id || messageVM.getRootMessage().cid == id
            }
            return false
        }
    }

    func reloadRow(by messageId: String, animation: UITableView.RowAnimation = .fade) {
        guard !messageId.isEmpty else {
            return
        }
        if self.queueIsPause() {
            if let index = self.uiDataSource.firstIndex(where: { (cellVM) -> Bool in
                if let messageCellVM = cellVM as? HasThreadMessage {
                    return messageCellVM.getRootMessage().id == messageId
                }
                return false
            }) {
                self.tableRefreshPublish.onNext((.messagesUpdate(indexs: [index], guarantLastCellVisible: false), newDatas: nil, outOfQueue: true))
            }
        } else {
            self.queueManager.addDataProcess { [weak self] in
                if let index = self?.messageDatasource.index(messageId: messageId) {
                    self?.publish(.messagesUpdate(indexs: [index], guarantLastCellVisible: false))
                }
            }
        }
    }

    /// - Parameters:
    ///   - id: id is messageId or messageCid
    func cellViewModel(by id: String) -> ThreadCellViewModel? {
        return self.uiDataSource.first { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasThreadMessage {
                let message = messageCellVM.getRootMessage()
                return message.id == id || message.cid == id
            }
            return false
        }
    }

    func onResize() {
        self.queueManager.addDataProcess { [weak self] in
            self?.messageDatasource.onResize()
            self?.send(update: true)
        }
    }

    func getCellsHeightOver(maxHeigh: CGFloat) -> Bool {
        var totalCellsHeight: CGFloat = 0
        for cellVM in self.messageDatasource.cellViewModels {
            totalCellsHeight += cellVM.renderer.size().height
            if totalCellsHeight > maxHeigh {
                return true
            }
        }
        return false
    }

    // MARK: support revser FG
    private func handleFetchData(
        threadMessages: [ThreadMessage],
        invisiblePositions: [Int32]? = nil,
        missedPositions: [Int32]? = nil
    ) -> (threadMessages: [ThreadMessage], invisiblePositions: [Int32], missedPositions: [Int32]) {
        let sortedThreadMessages: [ThreadMessage]
        let sortedInvisiblePositions: [Int32]?
        let sortedMissedPositions: [Int32]?

        let sortThreadMessage: (ThreadMessage, ThreadMessage) -> Bool = { (threadMessage1, threadMessage2) in
            // 假消息的position是相同的
            if threadMessage1.position == threadMessage2.position {
                // tmsg1为假消息 && tmsg2为假消息，按照创建时间
                if threadMessage1.localStatus != .success, threadMessage2.localStatus != .success {
                    return threadMessage1.createTime < threadMessage2.createTime
                } else {
                    return threadMessage2.localStatus != .success
                }
            }
            return threadMessage1.position < threadMessage2.position
        }

        let sortPosition: (Int32, Int32) -> Bool = { (position1, position2) in
            return position1 < position2
        }

        sortedThreadMessages = threadMessages.sorted(by: sortThreadMessage)
        sortedInvisiblePositions = invisiblePositions?.sorted(by: sortPosition)
        sortedMissedPositions = missedPositions?.sorted(by: sortPosition)

        return (sortedThreadMessages, sortedInvisiblePositions ?? [Int32](), sortedMissedPositions ?? [Int32]())
    }

    private func getRefreshMessages(scrollInfo: ScrollInfo?) -> TableRefreshType {
        return .refreshMessages(hasHeader: getHasHeader(), hasFooter: getHasFooter(), scrollInfo: scrollInfo)
    }

    private func getHasHeader() -> Bool {
        return false
    }

    private func getHasFooter() -> Bool {
        return false
    }

    private func getScrollInfoForMessagePositon(messageInitType: MessageInitType, scrollIndex: Int) -> ScrollInfo {
        switch messageInitType {
        case .specifiedMessages(position: let position):
            return ScrollInfo(index: scrollIndex, tableScrollPosition: .top, highlightPosition: position)
        case .recentLeftMessage:
            return ScrollInfo(index: scrollIndex, tableScrollPosition: .top)
        case .localRecentMessages:
            return ScrollInfo(index: self.messageDatasource.cellViewModels.count - 1, tableScrollPosition: .bottom)
        case .lastedUnreadMessage:
            return ScrollInfo(index: self.messageDatasource.cellViewModels.count - 1, tableScrollPosition: .bottom)
        case .oldestUnreadMessage:
            return ScrollInfo(index: scrollIndex, tableScrollPosition: .top)
        }
    }
}

// MARK: - Handle Data
private extension ThreadPreviewMessagesViewModel {
    func loadFirstScreenMessages() {
        let firstScreenDataOb = self.fetchMessages(
            scene: .firstScreen,
            redundancyCount: self.redundancyCount,
            count: self.requestCount,
            needReplyPrompt: true
        ).flatMap({ [weak self] (remoteResult) -> Observable<GetThreadsResult> in
            guard let `self` = self else { return .empty() }
            return .just(remoteResult)
        })

        firstScreenDataOb
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                self?.handleFirstScreen(
                    result: result
                )
                ThreadPreviewMessagesViewModel.logger.info("LarkThread: chatTrace loadFirstScreenMessages by \(result.localData)")
        }, onError: { (_) in
            ThreadPreviewMessagesViewModel.logger.error("LarkThread error: chatTrace loadFirstScreenMessages by remote error")
        }).disposed(by: disposeBag)
    }

    func fetchMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32, needReplyPrompt: Bool) -> Observable<GetThreadsResult> {
        return self.dependency.threadAPI.fetchThreads(channel: self.channel, scene: scene, redundancyCount: redundancyCount, count: count, needReplyPrompt: needReplyPrompt)
            .do(onError: { [weak self] (error) in
                ThreadPreviewMessagesViewModel.logger.error(
                    "LarkThread error: chatTrace fetchMessages error",
                    additionalData: [
                        "chatId": self?._chat.id ?? "",
                        "scene": "\(scene.description())"
                    ],
                    error: error
                )
            })
    }

    func handleFirstScreen(result: GetThreadsResult) {
        if !self.messageDatasource.cellViewModels.isEmpty {
            Self
                .logger
                .error("LarkThread error: chatTrace curernt dat source shouldn't have data \(self._chat.id) \(self.messageDatasource.cellViewModels.count)")
        }
        self.firstScreenLoaded = true
        let handleData = self.handleFetchData(
            threadMessages: result.threadMessages,
            invisiblePositions: result.invisiblePositions,
            missedPositions: result.missedPositions
        )

        let threadMessages = handleData.threadMessages
        let invisiblePositions = handleData.invisiblePositions
        let missedPositions = handleData.missedPositions

        var scrollInfo: ScrollInfo?
        self.messageDatasource.reset(
            messages: threadMessages,
            invisiblePositions: invisiblePositions,
            missedPositions: missedPositions,
            concurrent: self.concurrentHandler
        )
        if !self.messageDatasource.cellViewModels.isEmpty {
            scrollInfo = getScrollInfoForMessagePositon(
                messageInitType: .localRecentMessages,
                scrollIndex: 0
            )
        }
        let initInfo = InitMessagesInfo(
            hasHeader: getHasHeader(),
            hasFooter: getHasFooter(),
            newReplyCount: result.newReplyCount,
            newAtReplyMessages: result.newAtReplyMessages,
            newAtReplyCount: result.newAtReplyCount,
            scrollInfo: scrollInfo,
            initType: .localRecentMessages
        )
        if threadMessages.isEmpty {
            self.publish(.noMessage)
        } else {
            self.publish(.initMessages(initInfo, needHightlight: scrollInfo?.highlightPosition != nil))
        }
    }

    func publish(_ type: TableRefreshType, outOfQueue: Bool = false) {
        var dataUpdate: Bool = true
        switch type {
        case .updateFooterView,
                .updateHeaderView,
                .scrollTo,
                .noMessage:
            dataUpdate = false
        default:
            break
        }
        self.tableRefreshPublish.onNext((type, newDatas: dataUpdate ? self.messageDatasource.cellViewModels : nil, outOfQueue: outOfQueue))
    }

    func observeData() {
        self.dependency.threadObservable
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (threads) in
                var needUpdate = false
                for thread in threads {
                    needUpdate = self?.messageDatasource.update(thread: thread) ?? false
                }
                if needUpdate {
                    self?.publish(.refreshTable)
                }
            }).disposed(by: self.disposeBag)
    }

    func send(update: Bool) {
        if update {
            self.publish(.refreshTable)
        }
    }
}

// MARK: - extension DataSourceAPI
extension ThreadPreviewMessagesViewModel: DataSourceAPI {
    func processMessageSelectedEnable(message: Message) -> Bool {
        return true
    }

    var scene: ContextScene {
        return .threadChat
    }

    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return self.messageDatasource.cellViewModels
            .compactMap { $0 as? MessageCellViewModel<M, D, T> }
            .filter(predicate)
    }

    func pauseDataQueue(_ pause: Bool) {
        if pause {
            self.pauseQueue()
        } else {
            self.resumeQueue()
        }
    }

    func reloadTable() {
        self.queueManager.addDataProcess { [weak self] in
            self?.publish(.refreshTable)
        }
    }

    func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(messageIds: messageIds, doUpdate: doUpdate) ?? false
            self?.send(update: needUpdate)
        }
    }

    func deleteRow(by messageId: String) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.delete(by: messageId) ?? false
            self?.send(update: needUpdate)
        }
    }

    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return nil
    }
}

// MARK: - extension HandlePushDataSourceAPI
extension ThreadPreviewMessagesViewModel: HandlePushDataSourceAPI {
    func update(messageIds: [String], doUpdate: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(
                messageIds: messageIds,
                doUpdate: { (message) -> Message? in
                    return doUpdate(message) as? Message
                }) ?? false
            completion?(needUpdate)
            self?.send(update: needUpdate)
        }
    }

    func update(original: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(original: { (threadMessage) -> ThreadMessage? in
                return original(threadMessage) as? ThreadMessage
            }) ?? false
            completion?(needUpdate)
            self?.send(update: needUpdate)
        }
    }
}

// MARK: - extentsion ThreadListViewModel
extension ThreadPreviewMessagesViewModel: ThreadListViewModel {
    func putRead(threadMessage: ThreadMessage) {
    }

    func loadMoreBottomMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
    }

    func loadMoreTopMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
    }

    func updateTrackActiveTime() {
    }
}
