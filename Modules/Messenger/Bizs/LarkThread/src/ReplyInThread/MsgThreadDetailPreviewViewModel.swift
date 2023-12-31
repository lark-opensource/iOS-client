//
//  MsgThreadDetailPreviewViewModel.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/6.
//

import Foundation
import RxSwift
import RxCocoa
import LarkCore
import LarkModel
import LarkUIKit
import EENavigator
import LarkContainer
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkSDKInterface
import LarkFeatureGating
import LarkMessengerInterface
import LarkSceneManager
import RustPB
import UIKit

final class MsgThreadDetailPreviewViewModel: AsyncDataProcessViewModel<MsgThreadDetailPreviewViewModel.TableRefreshType, [[ThreadDetailCellViewModel]]>,
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
        /// 滚动到最后一个cell的某个位置
        case toLastCell(UITableView.ScrollPosition)
        /// 滚动到tableView的最底部
        case toTableBottom
    }
    struct InitMessagesInfo {
        public let hasHeader: Bool
        public let hasFooter: Bool
        public let scrollType: ScrollType
        public let isInitRootMessage: Bool
        public init(
            scrollType: ScrollType,
            hasHeader: Bool = false,
            hasFooter: Bool = false,
            isInitRootMessage: Bool = false
        ) {
            self.isInitRootMessage = isInitRootMessage
            self.hasFooter = hasFooter
            self.hasHeader = hasHeader
            self.scrollType = scrollType
        }
    }

    private static let logger = Logger.log(MsgThreadDetailPreviewViewModel.self, category: "LarkThread.MsgThreadDetailPreview")
    private var thread: RustPB.Basic_V1_Thread {
        return self.threadObserver.value
    }
    private let context: ThreadDetailContext

    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?

    var _chat: Chat {
        return chatObserver.value
    }

    var isUserInteractionEnabled: Bool {
        return false
    }

    let chatObserver: BehaviorRelay<Chat>
    let threadObserver: BehaviorRelay<RustPB.Basic_V1_Thread>

    private let chatWrapper: ChatPushWrapper
    private let threadWrapper: ThreadPushWrapper

    private let factory: ThreadReplyMessageCellViewModelFactory
    private var disposeBag = DisposeBag()
    private var justShowReply: Bool = false
    private let useIncompleteLocalData: Bool
    private let dynamicRequestCountEnable: Bool
    @ScopedInjectedLazy var urlPreviewService: MessageURLPreviewService?
    private(set) lazy var redundancyCount: Int32 = {
           return getRedundancyCount()
       }()
    private(set) lazy var requestCount: Int32 = {
        return getRequestCount()
    }()
    let messageDatasource: ReplyInThreadDataSource
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

    /// 当前thread的threadId
    let threadId: String

    init(
        userResolver: UserResolver,
        chatWrapper: ChatPushWrapper,
        threadWrapper: ThreadPushWrapper,
        context: ThreadDetailContext,
        threadAPI: ThreadAPI,
        is24HourTime: Observable<Bool>,
        factory: ThreadReplyMessageCellViewModelFactory,
        threadMessage: ThreadMessage,
        useIncompleteLocalData: Bool
    ) {
        self.userResolver = userResolver
        self.dynamicRequestCountEnable = (try? userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.dynamicRequestCountEnable))) ?? false
        self.chatObserver = BehaviorRelay<Chat>(value: chatWrapper.chat.value)
        self.threadObserver = BehaviorRelay<RustPB.Basic_V1_Thread>(value: threadWrapper.thread.value)
        self.chatWrapper = chatWrapper
        self.threadWrapper = threadWrapper
        self.useIncompleteLocalData = useIncompleteLocalData
        self.context = context
        self.threadAPI = threadAPI
        self.factory = factory
        self.threadId = threadMessage.thread.id
        let rootMessage = threadMessage.rootMessage
        self.messageDatasource = ReplyInThreadDataSource(
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
    }

    public func initMessages(loadType: MsgThreadDetailPreviewViewController.LoadType) {
        // threadMessage是本地传参过来的，需要单独处理预览懒加载
        let messages = [self.messageDatasource.threadMessage.rootMessage] +
                        self.messageDatasource.threadMessage.replyMessages +
                        self.messageDatasource.threadMessage.latestAtMessages
        self.urlPreviewService?.fetchMissingURLPreviews(messages: messages)
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

    private func getRequestCount() -> Int32 {
        let defatultCount: Int32 = 15
        guard Display.phone, dynamicRequestCountEnable else {
            return defatultCount
        }

        let navigationBarHeight: CGFloat = 44 + (Display.iPhoneXSeries ? 44 : 20)
        // 82 is input text height
        let bottomHeight: CGFloat = 82.0 + (Display.iPhoneXSeries ? 34 : 0)
        let contentHeight = hostUIConfig.size.height - navigationBarHeight - ReplyInThreadHeaderViewConfig.footerHeight - bottomHeight
        // 101 is cell height of the smallest cell
        var count = Int32((contentHeight / 101.0).rounded(.up))
        count = (count < 1) ? defatultCount : count
        Self.logger.info("requestCount is \(count)")
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
extension MsgThreadDetailPreviewViewModel {
    func showHeader(section: Int) -> Bool {
        // section ！= replyIndex 不显示
        if section != self.messageDatasource.replysIndex {
            return false
        }
        // reply 没有加载完时 不显示。其他情况包括无reply回复时都要显示
        return (self.messageDatasource.minPosition > 0 ? false : true)
    }

    func showFooter(section: Int) -> Bool {
        if section == self.messageDatasource.replysIndex {
            return true
        }
        // 回复消息 最后不加 footer
        return false
    }
    func footerBackgroundColor(section: Int) -> UIColor? {
        return UIColor.clear
    }
    /// UI效果上不需要分割线
    func showReplyMessageLastSepratorLine(section: Int) -> Bool {
        return false
    }

    func replyCount() -> Int {
        return Int(messageDatasource.threadMessage.thread.replyCount)
    }
    func replysIndex() -> Int {
        return messageDatasource.replysIndex
    }

    func threadHeaderForSection(_ section: Int, replyCount: Int) -> UIView? {
        let bgView = UIView()
        bgView.backgroundColor = UIColor.clear
        let header = ReplyInThreadHeader(repliesCount: replyCount)
        bgView.addSubview(header)
        header.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(ReplyInThreadHeaderViewConfig.headerHeight - 6)
        }
        return bgView
    }

    func threadHeaderHeightFor(section: Int) -> CGFloat {
        return ReplyInThreadHeaderViewConfig.headerHeight
    }

    func threadFooterHeightFor(section: Int) -> CGFloat {
        if section == self.messageDatasource.replysIndex {
            return 32
        }
        return ReplyInThreadHeaderViewConfig.footerHeight
    }

    func threadReplyMessagesFooterHeightFor(section: Int) -> CGFloat {
        return ReplyInThreadHeaderViewConfig.replyMessagesFooterHeight
    }
}

private extension MsgThreadDetailPreviewViewModel {
    func loadFirstScreenMessages(_ loadType: MsgThreadDetailPreviewViewController.LoadType) {
        Self.logger.info(
            "chatTrace replyInthread new initData: " +
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
                Self.logger.info("chatTrace reply in thread loadFirstScreenMessages by \(result.localData)")
            }, onError: { (error) in
                Self.logger.error("LarkThread error: chatTrace reply in thread loadFirstScreenMessages by remote error", error: error)
            }).disposed(by: disposeBag)
    }

    func handleFirstScreen(
        localResult: GetThreadMessagesResult,
        loadType: MsgThreadDetailPreviewViewController.LoadType) {
        let messages = localResult.messages
        /// 不可见的消息
        let invisiblePositions = localResult.invisiblePositions
        /// 丢失的消息
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
                Self.logger.error("LarkThread error: chatTrace threadDetail initBySpecifiedMessages no find index")
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
        let initInfo = InitMessagesInfo(scrollType: scrollType, hasHeader: self.hasMoreOldMessages(), hasFooter: self.hasMoreNewMessages())
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
                    Self.logger.info("chatTrace fetchMissedMessages is not valid thread.id \(self.thread.id)")
                }
            }, onError: { [weak self] (error) in
                Self.logger.error("LarkThread error: chatTrace fetchMissedMessages error \(self?.thread.id ?? "")", error: error)
            }).disposed(by: self.disposeBag)
    }

    func getMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32) -> Observable<GetThreadMessagesResult?> {
        self.logForGetMessages(scene: scene, redundancyCount: redundancyCount, count: count)
        return threadAPI.getThreadMessages(
            threadId: self.thread.id,
            isReplyInThread: true,
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
                Self.logger
                    .error("chatTrace reply in thread fetchMessages error",
                           additionalData: ["threadId": self?.thread.id ?? "",
                                            "scene": "\(scene.description())"],
                           error: error)
            })
    }

    func logForGetMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32) {
        Self.logger.info("chatTrace reply in thread fetchMessages",
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

extension MsgThreadDetailPreviewViewModel: DataSourceAPI {
    func processMessageSelectedEnable(message: Message) -> Bool {
        return false
    }

    var scene: ContextScene {
        return .replyInThread
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
        var width: CGFloat = 0
        /// 这里发现有些时候 SDK推送的push中 threadID为空， 导致距离算错
        if message.threadId == message.id || message.id == self.threadId {
            width = hostUIConfig.size.width - 16 - 16
        } // reply message
        else {
            width = hostUIConfig.size.width - 60 - 16
        }
        return width
    }
    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return nil
    }
}
