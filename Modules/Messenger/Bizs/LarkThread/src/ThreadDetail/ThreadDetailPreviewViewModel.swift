//
//  ThreadDetailPreviewViewModel.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/3.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkCore
import LarkModel
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkContainer
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkSDKInterface
import LarkFeatureGating
import LarkMessengerInterface
import LarkSceneManager
import LarkWaterMark
import RustPB

final class ThreadDetailPreviewViewModel: AsyncDataProcessViewModel<ThreadDetailPreviewViewModel.TableRefreshType, [[ThreadDetailCellViewModel]]>,
ThreadDetailTableViewDataSource, UserResolverWrapper {
    let userResolver: UserResolver
    enum TableRefreshType: OuputTaskTypeInfo {
        /// 显示根消息。进入话题详情页先展示根消息，再异步拉取首屏回复消息。
        case showRootMessage
        /// 首屏回复消息
        case initMessages(InitMessagesInfo)
        case refreshTable
        case refreshMissedMessage
        case showRoot(rootHeight: CGFloat)
        public func canMerge(type: TableRefreshType) -> Bool {
            switch (self, type) {
            case (.refreshTable, .refreshTable):
                return true
            default:
                return false
            }
        }
        func duration() -> Double {
            var duration: Double = 0
            switch self {
            case .initMessages(let info):
                duration = getDurationBy(scrollType: info.scrollType)
            default:
                break
            }
            return duration
        }
        func isBarrier() -> Bool {
            return false
        }

        private func getDurationBy(scrollType: ScrollType, defaultDuration: Double = 0) -> Double {
            switch scrollType {
            case .toRoot(let needHightlight) where needHightlight == true:
                return MessageCommonCell.highlightDuration
            case .toReply(_, _, _, let needHightlight) where needHightlight == true:
                return MessageCommonCell.highlightDuration
            default:
                break
            }
            return defaultDuration
        }
    }
    enum ScrollType {
        case toRoot(needHightlight: Bool)
        case toReplySection
        case toReply(index: Int, section: Int, tableScrollPosition: UITableView.ScrollPosition, needHightlight: Bool)
        case toLastCell(UITableView.ScrollPosition)
        case toTableBottom
    }
    struct InitMessagesInfo {
        public let hasHeader: Bool
        public let hasFooter: Bool
        public let scrollType: ScrollType
        public let isInitRootMessage: Bool
        public init(
            hasHeader: Bool = false,
            hasFooter: Bool = false,
            isInitRootMessage: Bool = false,
            scrollType: ScrollType
        ) {
            self.isInitRootMessage = isInitRootMessage
            self.hasFooter = hasFooter
            self.hasHeader = hasHeader
            self.scrollType = scrollType
        }
    }

    private static let logger = Logger.log(ThreadDetailPreviewViewModel.self, category: "LarkThread.ThreadDetailPreview")
    private var thread: RustPB.Basic_V1_Thread {
        return self.threadObserver.value
    }
    private let context: ThreadDetailContext
    var isUserInteractionEnabled: Bool {
        return false
    }

    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?
    var _chat: Chat {
        return chatObserver.value
    }

    var topicGroup: TopicGroup {
        return topicGroupObserver.value
    }

    let chatObserver: BehaviorRelay<Chat>
    let topicGroupObserver: BehaviorRelay<TopicGroup>
    let threadObserver: BehaviorRelay<RustPB.Basic_V1_Thread>

    private let chatWrapper: ChatPushWrapper
    private let topicGroupPushWrapper: TopicGroupPushWrapper
    private let threadWrapper: ThreadPushWrapper
    private let factory: ThreadDetailMessageCellViewModelFactory
    private var disposeBag = DisposeBag()
    private var justShowReply: Bool = false
    private let useIncompleteLocalData: Bool
    private let dynamicRequestCountEnable: Bool
    @ScopedInjectedLazy var waterMarkService: WaterMarkService?

    private(set) lazy var redundancyCount: Int32 = {
           return getRedundancyCount()
       }()
    private(set) lazy var requestCount: Int32 = {
        return getRequestCount()
    }()
    let messageDatasource: ThreadDetailDataSource
    let threadAPI: ThreadAPI
    let is24HourTime: Observable<Bool>
    var highlightPosition: Int32?

    var rootMessage: Message {
        return self.messageDatasource.rootMessage
    }

    var replies: [Message] {
        return self.uiDataSource[self.messageDatasource.replysIndex].compactMap({ (cellVM) -> Message? in
            return (cellVM as? HasMessage)?.message
        })
    }

    func getWaterMarkImage() -> Observable<UIView?> {
        let chatId = self.chatObserver.value.id
        return self.waterMarkService?.getWaterMarkImageByChatId(chatId, fillColor: nil) ?? .just(nil)
    }

    init(
        userResolver: UserResolver,
        chatWrapper: ChatPushWrapper,
        topicGroupPushWrapper: TopicGroupPushWrapper,
        threadWrapper: ThreadPushWrapper,
        context: ThreadDetailContext,
        threadAPI: ThreadAPI,
        is24HourTime: Observable<Bool>,
        factory: ThreadDetailMessageCellViewModelFactory,
        threadMessage: ThreadMessage,
        useIncompleteLocalData: Bool,
        needUpdateBlockData: Bool
    ) {
        self.userResolver = userResolver
        self.dynamicRequestCountEnable = (try? userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.dynamicRequestCountEnable))) ?? false
        self.topicGroupObserver = BehaviorRelay<TopicGroup>(value: topicGroupPushWrapper.topicGroupObservable.value)
        self.chatObserver = BehaviorRelay<Chat>(value: chatWrapper.chat.value)
        self.threadObserver = BehaviorRelay<RustPB.Basic_V1_Thread>(value: threadWrapper.thread.value)
        self.chatWrapper = chatWrapper
        self.topicGroupPushWrapper = topicGroupPushWrapper
        self.threadWrapper = threadWrapper
        self.useIncompleteLocalData = useIncompleteLocalData
        self.context = context
        self.threadAPI = threadAPI
        self.factory = factory
        self.messageDatasource = ThreadDetailDataSource(
            chat: {
                return chatWrapper.chat.value
            },
            threadMessage: threadMessage,
            vmFactory: factory,
            minPosition: -1,
            maxPosition: -1
        )
        self.messageDatasource.forwardPreviewBottomTipBlock = { (messageCount, replyCount) in
            var stickToBottom: [ThreadDetailCellViewModel] = []
            if factory.context.isPreview && (messageCount < replyCount) {
                stickToBottom.append(factory.createDetailPreviewTip(copyWriting: BundleI18n.LarkThread.Lark_IM_MoreMessagesViewInChat_Text))
            }
            return stickToBottom
        }
        self.is24HourTime = is24HourTime
        super.init(uiDataSource: [])
        self.messageDatasource.contentPreferMaxWidth = { [weak self] message in
            return self?.getContentPreferMaxWidth(message) ?? 0
        }
        if needUpdateBlockData {
            self.fetchBlockData()
        }
    }

    private func fetchBlockData() {
        self.threadAPI.fetchThreads([thread.id], strategy: .tryLocal, forNormalChatMessage: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self,
                    let thread = result.threadMessages.first?.thread else {
                    return
                }
                self.threadObserver.accept(thread)
            }).disposed(by: self.disposeBag)

        self.threadAPI.fetchChatAndTopicGroup(chatID: thread.channel.id, forceRemote: false, syncUnsubscribeGroups: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let `self` = self, let result = res else { return }
                self.chatObserver.accept(result.chat)

                if let topicGroup = result.topicGroup {
                    self.topicGroupObserver.accept(topicGroup)
                }
            }).disposed(by: self.disposeBag)
    }

    public func initMessages(loadType: ThreadDetailPreviewController.LoadType) {
        self.observeData()
        // 当前场景下一定是有threadMessage的，所以一进入应该立即显示显示根消息
        self.publish(.showRootMessage)

        self.loadFirstScreenMessages(loadType)
    }

    public func initMessagesFinish() {
        self.resumeQueue()
    }

    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)? = nil) {
    }

    func loadMoreNewMessages(finish: ((ScrollViewLoadMoreResult) -> Void)? = nil) {
    }

    /// - Parameters:
    ///   - id: id is messageId or messageCid
    public func cellViewModel(by id: String) -> ThreadDetailCellViewModel? {
        for sectionDatas in self.uiDataSource {
            return sectionDatas.first(where: { (cellVM) -> Bool in
                if let messageCellVM = cellVM as? HasMessage {
                    return messageCellVM.message.id == id || messageCellVM.message.cid == id
                }
                return false
            })
        }
        return nil
    }

    /// 根据消息 id和 cid 查找对应位置
    ///
    /// - Parameters:
    ///   - id: id is messageId or messageCid
    /// - Returns: index in datasource
    func findMessageIndexBy(id: String) -> IndexPath? {
        guard !id.isEmpty else {
            return nil
        }
        if self.rootMessage.id == id || self.rootMessage.cid == id {
            return IndexPath(row: 0, section: 0)
        }
        let index = self.uiDataSource[self.messageDatasource.replysIndex].firstIndex { (cellVM) -> Bool in
            if let messageVM = cellVM as? HasMessage {
                return messageVM.message.id == id || messageVM.message.cid == id
            }
            return false
        }
        guard let row = index else { return nil }
        return IndexPath(row: row, section: self.messageDatasource.replysIndex)
    }

    public func showRootMessage() {
        guard justShowReply else {
            return
        }
        self.justShowReply = false
        if self.queueManager.queueIsPause() {
            let rootHeight = self.messageDatasource.threadMessageCellViewModel.renderer.size().height
            self.publish(.showRoot(rootHeight: rootHeight), outOfQueue: true)
        } else {
            self.queueManager.addDataProcess { [weak self] in
                let rootHeight = self?.messageDatasource.threadMessageCellViewModel.renderer.size().height ?? 0
                self?.publish(.showRoot(rootHeight: rootHeight))
            }
        }
    }

    fileprivate func send(update: Bool) {
        if update {
            self.publish(.refreshTable)
        }
    }

    public func reloadRow(by messageId: String, animation: UITableView.RowAnimation = .fade) {
    }

    func showReplyOnboarding() -> Bool {
        // 没有回复
        if self.messageDatasource.cellViewModels[self.messageDatasource.replysIndex].isEmpty {
            return true
        } else {
            return false
        }
    }

    private func getRequestCount() -> Int32 {
        let defatultCount: Int32 = 15
        guard Display.phone, dynamicRequestCountEnable else {
            return defatultCount
        }

        let navigationBarHeight: CGFloat = 44 + (Display.iPhoneXSeries ? 44 : 20)
        // 82 is input text height
        let bottomHeight: CGFloat = 82.0 + (Display.iPhoneXSeries ? 34 : 0)
        let contentHeight = hostUIConfig.size.height - navigationBarHeight - DetailViewConfig.footerHeight - bottomHeight
        // 101 is cell height of the smallest cell
        var count = Int32((contentHeight / 101.0).rounded(.up))
        count = (count < 1) ? defatultCount : count
        ThreadDetailPreviewViewModel.logger.info("requestCount is \(count)")
        return count
    }

    private func getRedundancyCount() -> Int32 {
        guard Display.phone, dynamicRequestCountEnable else {
            return 0
        }
        return 1
    }

    // MARK: - iPad适配
    func onResize() {
        self.queueManager.addDataProcess { [weak self] in
            self?.messageDatasource.onResize()
            self?.send(update: true)
        }
    }
}

//table相关
extension ThreadDetailPreviewViewModel {
    func showHeader(section: Int) -> Bool {
        // section ！= replyIndex 不显示
        if section != self.messageDatasource.replysIndex {
            return false
        }

        // reply 没有加载完时 不显示。其他情况包括无reply回复时都要显示
        return (self.messageDatasource.minPosition > 0 ? false : true)
    }

    func showFooter(section: Int) -> Bool {
        // 回复消息 最后不加 footer
        if section == self.messageDatasource.replysIndex {
            return false
        }

        return self.uiDataSource[section].isEmpty ? false : true
    }

    func showReplyMessageLastSepratorLine(section: Int) -> Bool {
        // 存在回复消息
        if section == self.messageDatasource.replysIndex && !self.uiDataSource[section].isEmpty {
            return true
        }

        return false
    }

    func replyCount() -> Int {
        return Int(messageDatasource.threadMessage.thread.replyCount)
    }
    func replysIndex() -> Int {
        return messageDatasource.replysIndex
    }

}

private extension ThreadDetailPreviewViewModel {
    func loadFirstScreenMessages(_ loadType: ThreadDetailPreviewController.LoadType) {
        ThreadDetailPreviewViewModel.logger.info(
            "chatTrace threadDetail new initData: " +
            "\(self.thread.id) \(loadType.rawValue)" +
            "\(self.thread.lastMessagePositionBadgeCount) \(self.thread.readPositionBadgeCount)"
        )
        let scene: GetDataScene
        switch loadType {
        case .position(let position):
            //-1代表根消息，搜索、推送等入口
            scene = .specifiedPosition(position == -1 ? 0 : position)
        case .root:
            scene = .specifiedPosition(0)
        case .unread:
            scene = .firstScreen
        case .justReply:
            scene = .specifiedPosition(0)
            justShowReply = true
        }
        let firstScreenDataOb: Observable<GetThreadMessagesResult>
        firstScreenDataOb = self.getMessages(
            scene: scene,
            redundancyCount: self.redundancyCount,
            count: self.requestCount
            ).flatMap({ [weak self] (localResult) -> Observable<GetThreadMessagesResult> in
                guard let self = self else { return .empty() }
                if let localResult = localResult {
                    return .just(localResult)
                } else {
                    return self.fetchMessages(
                        scene: scene,
                        redundancyCount: self.redundancyCount,
                        count: self.requestCount
                    )
                }
            })

        firstScreenDataOb
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                self?.handleFirstScreen(
                    localResult: result,
                    loadType: loadType
                )
                ThreadDetailPreviewViewModel.logger.info("chatTrace threadDetail loadFirstScreenMessages by \(result.localData)")
            }, onError: { (_) in
                ThreadDetailPreviewViewModel.logger.error("LarkThread error: chatTrace threadDetail loadFirstScreenMessages by remote error")
            }).disposed(by: disposeBag)
    }

    func handleFirstScreen(
        localResult: GetThreadMessagesResult,
        loadType: ThreadDetailPreviewController.LoadType) {
        let messages = localResult.messages
        let invisiblePositions = localResult.invisiblePositions
        let missedPositions = localResult.missedPositions

        var scrollType: ScrollType = .toLastCell(.bottom)
        switch loadType {
        case .position(let position):
            highlightPosition = position
            self.messageDatasource.replaceReplys(
                messages: messages,
                invisiblePositions: invisiblePositions,
                missedPositions: missedPositions,
                concurrent: concurrentHandler
            )
            if position == -1 {
                scrollType = .toRoot(needHightlight: true)
            } else if let index = self.messageDatasource.indexForReply(position: position) {
                scrollType = .toReply(index: index, section: self.messageDatasource.replysIndex, tableScrollPosition: .top, needHightlight: true)
            } else {
                ThreadDetailPreviewViewModel.logger.error("LarkThread error: chatTrace threadDetail initBySpecifiedMessages didn't geet specified message index")
            }
        case .unread:
            self.messageDatasource.replaceReplys(
                messages: messages,
                invisiblePositions: invisiblePositions,
                missedPositions: missedPositions,
                readPositionBadgeCount: self.thread.readPositionBadgeCount,
                concurrent: concurrentHandler
            )
            if let index = self.messageDatasource.indexForReadPositionReply() {
                scrollType = .toReply(index: index, section: self.messageDatasource.replysIndex, tableScrollPosition: .top, needHightlight: false)
            }
        case .root:
            self.messageDatasource.replaceReplys(
                messages: messages,
                invisiblePositions: invisiblePositions,
                missedPositions: missedPositions,
                concurrent: concurrentHandler
            )
            scrollType = .toRoot(needHightlight: false)
        case .justReply:
            self.messageDatasource.replaceReplys(
                messages: messages,
                invisiblePositions: invisiblePositions,
                missedPositions: missedPositions,
                concurrent: concurrentHandler
            )
            scrollType = .toReplySection
        }
        let initInfo = InitMessagesInfo(hasHeader: self.hasMoreOldMessages(), hasFooter: self.hasMoreNewMessages(), scrollType: scrollType)
        self.publish(.initMessages(initInfo))

        if localResult.localData {
            self.fetchMissedMessageBy(positions: localResult.missedPositions)
        }
    }

    func fetchMissedMessageBy(positions: [Int32]) {
        guard !positions.isEmpty else {
            return
        }

        var channel = RustPB.Basic_V1_Channel()
        channel.id = _chat.id
        channel.type = .chat
        threadAPI.fetchThreadMessagesBy(positions: positions, threadID: thread.id)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages, _) in
                guard let self = self else { return }
                if self.messageDatasource.insertMiss(
                    messages: messages,
                    readPositionBadgeCount: self.thread.readPositionBadgeCount,
                    concurrent: self.concurrentHandler) {
                    self.publish(.refreshMissedMessage)
                } else {
                    ThreadDetailPreviewViewModel.logger.info("chatTrace fetchMissedMessages not in range \(self.thread.id)")
                }
            }, onError: { (error) in
                ThreadDetailPreviewViewModel.logger.error("LarkThread error: chatTrace fetchMissedMessages failed \(self.thread.id)", error: error)
            }).disposed(by: self.disposeBag)
    }

    func getMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32) -> Observable<GetThreadMessagesResult?> {
        self.logForGetMessages(scene: scene, redundancyCount: redundancyCount, count: count)
        return threadAPI.getThreadMessages(
            threadId: self.thread.id,
            isReplyInThread: false,
            scene: scene,
            redundancyCount: redundancyCount,
            count: count,
            useIncompleteLocalData: useIncompleteLocalData
        )
    }

    func fetchMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32) -> Observable<GetThreadMessagesResult> {
        self.logForGetMessages(scene: scene, redundancyCount: redundancyCount, count: count)
        return self.threadAPI.fetchThreadMessages(
            threadId: self.thread.id,
            scene: scene,
            redundancyCount: redundancyCount,
            count: count
            ).do(onError: { [weak self] (error) in
                ThreadDetailPreviewViewModel.logger
                    .error("chatTrace threadDetail fetchMessages error",
                           additionalData: ["threadId": self?.thread.id ?? "",
                                            "scene": "\(scene.description())"],
                           error: error)
            })
    }

    func logForGetMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32) {
        ThreadDetailPreviewViewModel.logger.info("chatTrace threadDetailPreview fetchMessages",
                                                additionalData: [
                                                    "threadId": self.thread.id,
                                                    "lastMessagePosition": "\(self.thread.lastMessagePosition)",
                                                    "lastVisibleMessagePosition": "\(self.thread.lastVisibleMessagePosition)",
                                                    "scene": "\(scene.description())",
                                                    "count": "\(count)",
                                                    "redundancyCount": "\(redundancyCount)"])
    }

    func hasMoreOldMessages() -> Bool {
        return false
    }

    func hasMoreNewMessages() -> Bool {
        return false
    }

    func publish(_ type: TableRefreshType, outOfQueue: Bool = false) {
        var dataUpdate: Bool = true
        switch type {
        default:
            break
        }
        if dataUpdate {
            if justShowReply || self.messageDatasource.minPosition > 0 {
                self.tableRefreshPublish.onNext((type, newDatas: [[], self.messageDatasource.cellViewModels[self.messageDatasource.replysIndex]], outOfQueue: outOfQueue))
            } else {
                self.tableRefreshPublish.onNext((type, newDatas: self.messageDatasource.cellViewModels, outOfQueue: outOfQueue))
            }
        } else {
            self.tableRefreshPublish.onNext((type, newDatas: nil, outOfQueue: outOfQueue))
        }
    }

    func observeData() {
        self.is24HourTime
            .skip(1)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.messageDatasource.refreshRenders()
                self?.publish(.refreshTable)
            }).disposed(by: disposeBag)
    }
}

extension ThreadDetailPreviewViewModel: DataSourceAPI {
    func processMessageSelectedEnable(message: Message) -> Bool {
        return false
    }

    var scene: ContextScene {
        return .threadDetail
    }

    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return self.messageDatasource.cellViewModels
            .flatMap { $0 }
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
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        // rootMessage
        if message.threadId == message.id {
            return hostUIConfig.size.width - 16 - 16
        } // reply message
        else {
            return hostUIConfig.size.width - 52 - 16
        }
    }
    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return nil
    }
}
