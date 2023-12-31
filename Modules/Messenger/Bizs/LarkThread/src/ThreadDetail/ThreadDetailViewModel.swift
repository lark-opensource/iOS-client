//
//  ThreadDetailViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/30.
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
import AppReciableSDK
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkSDKInterface
import LarkSendMessage
import LarkFeatureGating
import LarkMessengerInterface
import LarkSceneManager
import LarkWaterMark
import RustPB
import LarkGuide
import LarkChatOpenKeyboard
import LarkQuickLaunchInterface

final class ThreadDetailViewModel: AsyncDataProcessViewModel<ThreadDetailViewModel.TableRefreshType, [[ThreadDetailCellViewModel]]>, ThreadDetailTableViewDataSource, UserResolverWrapper {
    let userResolver: UserResolver
    enum TableRefreshType: OuputTaskTypeInfo {
        /// 显示根消息。进入话题详情页先展示根消息，再异步拉取首屏回复消息。
        case showRootMessage
        /// 首屏回复消息
        case initMessages(InitMessagesInfo)
        case refreshMessages(hasHeader: Bool, hasFooter: Bool, scrollType: ScrollType)
        case loadMoreOldMessages(hasHeader: Bool)
        case loadMoreNewMessages(hasFooter: Bool)
        case scrollTo(type: ScrollType)
        case startMultiSelect(startIndex: IndexPath)
        case finishMultiSelect
        case refreshTable
        case refreshMissedMessage
        case hasNewMessage(hasFooter: Bool)
        case updateHeaderView(hasHeader: Bool)
        case updateFooterView(hasFooter: Bool)
        case showRoot(rootHeight: CGFloat)
        case messagesUpdate(indexs: [IndexPath], guarantLastCellVisible: Bool)
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
            case .initMessages(let info):
                duration = getDurationBy(scrollType: info.scrollType)
            case .refreshMessages(_, _, let scrollType):
                duration = getDurationBy(scrollType: scrollType)
            case .hasNewMessage:
                duration = CommonTable.scrollToBottomAnimationDuration
            case .scrollTo(let type):
                duration = getDurationBy(scrollType: type, defaultDuration: 0.1)
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

    private static let logger = Logger.log(ThreadDetailViewModel.self, category: "Business.ThreadChat")
    private var thread: RustPB.Basic_V1_Thread {
        return self.threadObserver.value
    }
    private let context: ThreadDetailContext
    var topLoadMoreReciableKeyInfo: LoadMoreReciableKeyInfo?
    var bottomLoadMoreReciableKeyInfo: LoadMoreReciableKeyInfo?

    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?
    /// 移动端话题圈订阅功能的引导 权值  280
    let guideUIKey = "mobile_group_group_topic_subscribe"
    var _chat: Chat {
        return chatObserver.value
    }

    var topicGroup: TopicGroup {
        return topicGroupObserver.value
    }

    private(set) var firstScreenLoaded: Bool = false

    let pickedMessages = BehaviorRelay<[ChatSelectedMessageContext]>(value: [])
    let inSelectMode: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    let chatObserver: BehaviorRelay<Chat>
    let topicGroupObserver: BehaviorRelay<TopicGroup>
    let threadObserver: BehaviorRelay<RustPB.Basic_V1_Thread>

    internal let chatWrapper: ChatPushWrapper
    private let topicGroupPushWrapper: TopicGroupPushWrapper
    private let threadWrapper: ThreadPushWrapper
    /// solve pushData and fetchChat timing problem
    private var chatPushed: Bool = false
    private var topicGroupPushed: Bool = false
    private var threadPushed: Bool = false

    let userGeneralSettings: UserGeneralSettings
    let translateService: NormalTranslateService

    let draftCache: DraftCache
    private let messageAPI: MessageAPI
    private let sendMessageAPI: SendMessageAPI
    private let postSendService: PostSendService
    private let videoMessageSendService: VideoMessageSendService
    private let factory: ThreadDetailMessageCellViewModelFactory
    private let firstThreadPositionBound: Int32 = -1
    private var disposeBag = DisposeBag()
    private var loadingMoreOldMessages: Bool = false
    private var loadingMoreNewMessages: Bool = false
    private let draftId: String
    private var justShowReply: Bool = false
    private var hasDeleteOfThread: Bool = false
    private let useIncompleteLocalData: Bool
    private let pushHandlers: ThreadDetailPushHandlersRegister
    private let dynamicRequestCountEnable: Bool
    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy var modelService: ModelService?
    @ScopedInjectedLazy var urlPreviewService: MessageURLPreviewService?
    @ScopedInjectedLazy var waterMarkService: WaterMarkService?

    private(set) lazy var redundancyCount: Int32 = {
           return getRedundancyCount()
       }()
    private(set) lazy var requestCount: Int32 = {
        return getRequestCount()
    }()
    var isTextDraft: Bool = true
    let readService: ChatMessageReadService
    let messageDatasource: ThreadDetailDataSource
    let threadAPI: ThreadAPI
    let pushCenter: PushNotificationCenter
    var sendMessageStatusDriver: Driver<(LarkModel.Message, Error?)> {
        return sendMessageAPI.statusDriver
    }
    lazy var deleteMeFromChannelDriver: Driver<String> = {
        let driver = self.pushCenter.driver(for: PushRemoveMeFromChannel.self)
            .filter { [weak self] (push) -> Bool in
                return push.channelId == self?.topicGroup.id
            }
            .map { (_) -> String in
                return BundleI18n.LarkThread.Lark_IM_YouAreNotInThisChat_Text
            }
        return driver
    }()
    /// 自动翻译开关变化
    private let chatAutoTranslateSettingPublish: PublishSubject<Void> = PublishSubject<Void>()
    var chatAutoTranslateSettingDriver: Driver<()> {
        return chatAutoTranslateSettingPublish.asDriver(onErrorJustReturn: ())
    }
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

    var editingMessage: Message? {
        didSet {
            if oldValue?.id == editingMessage?.id {
                return
            }
            self.queueManager.addDataProcess { [weak self] in
                self?.messageDatasource.editingMessage = self?.editingMessage
                self?.publish(.refreshTable)
            }
        }
    }

    var offlineThreadUpdateDriver: Driver<RustPB.Basic_V1_Thread> {
        return pushCenter.driver(for: PushOfflineThreads.self)
            .map({ (push) -> RustPB.Basic_V1_Thread? in
                return push.threads.first(where: { [weak self] (thread) -> Bool in
                    return thread.id == self?.thread.id ?? ""
                })
            })
            .compactMap { $0 }
    }

    func getWaterMarkImage() -> Observable<UIView?> {
        let chatId = self.chatObserver.value.id
        return self.waterMarkService?.getWaterMarkImageByChatId(chatId, fillColor: nil) ?? Observable.just(nil)
    }

    init(
        userResolver: UserResolver,
        chatWrapper: ChatPushWrapper,
        topicGroupPushWrapper: TopicGroupPushWrapper,
        threadWrapper: ThreadPushWrapper,
        context: ThreadDetailContext,
        sendMessageAPI: SendMessageAPI,
        postSendService: PostSendService,
        videoMessageSendService: VideoMessageSendService,
        threadAPI: ThreadAPI,
        messageAPI: MessageAPI,
        draftCache: DraftCache,
        pushCenter: PushNotificationCenter,
        pushHandlers: ThreadDetailPushHandlersRegister,
        is24HourTime: Observable<Bool>,
        factory: ThreadDetailMessageCellViewModelFactory,
        threadMessage: ThreadMessage,
        useIncompleteLocalData: Bool,
        userGeneralSettings: UserGeneralSettings,
        translateService: NormalTranslateService,
        readService: ChatMessageReadService,
        needUpdateBlockData: Bool
    ) throws {
        self.userResolver = userResolver
        self.dynamicRequestCountEnable = try userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.dynamicRequestCountEnable))
        self.topicGroupObserver = BehaviorRelay<TopicGroup>(value: topicGroupPushWrapper.topicGroupObservable.value)
        self.chatObserver = BehaviorRelay<Chat>(value: chatWrapper.chat.value)
        self.threadObserver = BehaviorRelay<RustPB.Basic_V1_Thread>(value: threadWrapper.thread.value)
        self.chatWrapper = chatWrapper
        self.topicGroupPushWrapper = topicGroupPushWrapper
        self.threadWrapper = threadWrapper
        self.userGeneralSettings = userGeneralSettings
        self.translateService = translateService
        self.useIncompleteLocalData = useIncompleteLocalData
        self.context = context
        self.sendMessageAPI = sendMessageAPI
        self.postSendService = postSendService
        self.videoMessageSendService = videoMessageSendService
        self.threadAPI = threadAPI
        self.messageAPI = messageAPI
        self.draftCache = draftCache
        self.factory = factory
        let rootMessage = threadMessage.rootMessage
        var draftId = rootMessage.textDraftId
        if draftId.isEmpty {
            draftId = rootMessage.postDraftId
        }
        self.draftId = draftId
        isTextDraft = !rootMessage.textDraftId.isEmpty
        self.messageDatasource = ThreadDetailDataSource(
            chat: {
                return chatWrapper.chat.value
            },
            threadMessage: threadMessage,
            vmFactory: factory,
            minPosition: -1,
            maxPosition: -1
        )
        self.pushCenter = pushCenter
        self.pushHandlers = pushHandlers
        self.is24HourTime = is24HourTime
        self.readService = readService
        super.init(uiDataSource: [])
        self.messageDatasource.contentPreferMaxWidth = { [weak self] message in
            return self?.getContentPreferMaxWidth(message) ?? 0
        }
        if needUpdateBlockData {
            self.fetchBlockData()
        }
    }

    deinit {
        /// 退会话时，清空一次标记
        self.translateService.resetMessageCheckStatus(key: self.chatObserver.value.id)
    }

    private func fetchBlockData() {
        self.threadAPI.fetchThreads([thread.id], strategy: .tryLocal, forNormalChatMessage: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let `self` = self,
                    self.threadPushed == false,
                    let thread = result.threadMessages.first?.thread else {
                    return
                }
                self.threadObserver.accept(thread)
            }).disposed(by: self.disposeBag)

        self.threadAPI.fetchChatAndTopicGroup(chatID: thread.channel.id, forceRemote: false, syncUnsubscribeGroups: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let `self` = self, let result = res else {
                    return
                }
                if self.chatPushed == false {
                    self.chatObserver.accept(result.chat)
                }

                if self.topicGroupPushed == false,
                    let topicGroup = result.topicGroup {
                    self.topicGroupObserver.accept(topicGroup)
                }
            }).disposed(by: self.disposeBag)
    }

    public func initMessages(loadType: ThreadDetailController.LoadType) {
        self.observeData()
        ThreadPerformanceTracker.endUIRender()
        ThreadPerformanceTracker.startDataRender()
        // 当前场景下一定是有threadMessage的，所以一进入应该立即显示显示根消息
        self.publish(.showRootMessage)

        self.loadFirstScreenMessages(loadType)
    }

    public func initMessagesFinish() {
        self.resumeQueue()
    }

    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)? = nil) {
        guard !loadingMoreOldMessages else {
            finish?(.noWork)
            return
        }
        loadingMoreOldMessages = true
        let minPosition = self.messageDatasource.minPosition
        guard minPosition > firstThreadPositionBound + 1 else {
            if self.topLoadMoreReciableKeyInfo != nil {
                self.loadMoreReciableTrackError(loadMoreNew: false, bySDK: false)
                self.topLoadMoreReciableKeyInfo = nil
            }
            //容错逻辑，出现此情况时，强制将header去除掉
            self.publish(.updateHeaderView(hasHeader: false))
            loadingMoreOldMessages = false
            finish?(.noWork)
            return
        }
        let theadID = self.thread.id
        self.loadMoreMessages(position: minPosition, direction: .previous)
            .subscribe(onNext: { [weak self] (messages, invisiblePositions, sdkCost) in
                guard let `self` = self else {
                    finish?(.noWork)
                    return
                }
                // 添加耗时埋点
                let sdkCost = Int64(sdkCost * 1000)
                if let loadMoreReciableKeyInfo = self.topLoadMoreReciableKeyInfo {
                    self.loadMoreReciableTrack(key: loadMoreReciableKeyInfo.key, sdkCost: sdkCost, loadMoreNew: false)
                    self.topLoadMoreReciableKeyInfo = nil
                } else {
                    self.loadMoreReciableTrackForPreLoad(sdkCost: sdkCost, loadMoreNew: false)
                }

                let hasChange = self.messageDatasource.headInsert(messages: messages,
                                                                  invisiblePositions: invisiblePositions,
                                                                  concurrent: self.concurrentHandler)
                if hasChange {
                    self.publish(.loadMoreOldMessages(hasHeader: self.hasMoreOldMessages()))
                } else {
                    ThreadDetailViewModel.logger.error("LarkThread error: chatTrace threadDetail loadMoreOldMessages dont have new message \(theadID)")
                    self.publish(.updateHeaderView(hasHeader: self.hasMoreOldMessages()))
                }
                self.loadingMoreOldMessages = false
                finish?(.success(sdkCost: sdkCost, valid: hasChange))
            }, onError: { [weak self] (error) in
                self?.loadMoreReciableTrackError(loadMoreNew: false, bySDK: true)
                self?.topLoadMoreReciableKeyInfo = nil
                self?.loadingMoreOldMessages = false
                Self.logger.error("chatTrace threadDetail loadMoreOldMessages \(theadID)", error: error)
                finish?(.error)
            }).disposed(by: self.disposeBag)
    }

    func loadMoreNewMessages(finish: ((ScrollViewLoadMoreResult) -> Void)? = nil) {
        guard !loadingMoreNewMessages else {
            finish?(.noWork)
            return
        }
        let maxPosition = self.messageDatasource.maxPosition
        loadingMoreNewMessages = true
        guard maxPosition < self.thread.lastMessagePosition else {
            if self.bottomLoadMoreReciableKeyInfo != nil {
                self.loadMoreReciableTrackError(loadMoreNew: true, bySDK: false)
                self.bottomLoadMoreReciableKeyInfo = nil
            }
            //容错逻辑，出现此情况时，强制将footer去除掉
            self.publish(.updateFooterView(hasFooter: false))
            loadingMoreNewMessages = false
            finish?(.noWork)
            return
        }
        let theadID = self.thread.id
        self.loadMoreMessages(position: maxPosition, direction: .after)
            .subscribe(onNext: { [weak self] (messages, invisiblePositions, sdkCost) in
                guard let `self` = self else {
                    finish?(.noWork)
                    return
                }

                let sdkCost = Int64(sdkCost * 1000)
                if let loadMoreReciableKeyInfo = self.bottomLoadMoreReciableKeyInfo {
                    self.loadMoreReciableTrack(key: loadMoreReciableKeyInfo.key, sdkCost: sdkCost, loadMoreNew: true)
                    self.bottomLoadMoreReciableKeyInfo = nil
                } else {
                    self.loadMoreReciableTrackForPreLoad(sdkCost: sdkCost, loadMoreNew: true)
                }

                let hasChange = self.messageDatasource.tailAppend(
                    messages: messages,
                    invisiblePositions: invisiblePositions,
                    concurrent: self.concurrentHandler)
                if hasChange {
                    self.publish(.loadMoreNewMessages(hasFooter: self.hasMoreNewMessages()))
                } else {
                    ThreadDetailViewModel.logger.error("LarkThread error: chatTrace threadDetailloadMoreNewMessages dont have new message -\(theadID)")
                    self.publish(.updateFooterView(hasFooter: self.hasMoreNewMessages()))
                }
                self.loadingMoreNewMessages = false
                finish?(.success(sdkCost: sdkCost, valid: hasChange))
            }, onError: { [weak self] (error) in
                self?.loadMoreReciableTrackError(loadMoreNew: true, bySDK: true)
                self?.bottomLoadMoreReciableKeyInfo = nil
                self?.loadingMoreNewMessages = false
                Self.logger.error("chatTrace threadDetail loadMoreNewMessages \(theadID)", error: error)
                finish?(.error)
            }).disposed(by: self.disposeBag)
    }

    //跳到chat最近一条消息
    public func jumpToLastReply(tableScrollPosition: UITableView.ScrollPosition, finish: (() -> Void)? = nil) {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self, self.thread.lastMessagePosition > self.firstThreadPositionBound else {
                finish?()
                return
            }
            let threadID = self.thread.id
            ThreadDetailViewModel.logger.info("chatTrace threadDetail jumpToLastReply \(threadID) \(self.thread.lastMessagePosition) \(self.messageDatasource.maxPosition)")
            if self.thread.lastMessagePosition <= self.messageDatasource.maxPosition {
                self.publish(.scrollTo(type: .toLastCell(tableScrollPosition)))
                finish?()
                return
            }
            self.fetchMessageForJump(position: self.thread.lastMessagePosition, noNext: { [weak self] (messages, invisiblePositions) in
                self?.messageDatasource.replaceReplys(messages: messages,
                                                invisiblePositions: invisiblePositions,
                                                concurrent: self?.concurrentHandler ?? { _, _ in })
                self?.publish(.refreshMessages(hasHeader: self?.hasMoreOldMessages() ?? false,
                                               hasFooter: self?.hasMoreNewMessages() ?? false,
                                               scrollType: .toLastCell(tableScrollPosition)))
                finish?()
            }, onError: { error in
                Self.logger.error("chatTrace threadDetail fetchMessageForJump threadID \(threadID)", error: error)
                finish?()
            })
        }
    }

    public func jumpTo(index: Int, section: Int, tableScrollPosition: UITableView.ScrollPosition, needHightlight: Bool) {
        self.queueManager.addDataProcess { [weak self] in
            self?.tableRefreshPublish.onNext((.scrollTo(type: .toReply(index: index,
                                                                       section: section,
                                                                       tableScrollPosition: tableScrollPosition,
                                                                       needHightlight: needHightlight)),
                                              nil,
                                              false))
        }
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

    public func toggleFollow() {
        let threadId = self.thread.id
        let isFollow = self.thread.isFollow
        self.threadAPI.update(threadId: threadId, isFollow: !isFollow, threadState: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                if let apiError = error.underlyingError as? APIError {
                    UDToast.showFailure(with: apiError.displayMessage,
                                        on: self?.context.targetVC?.view ?? UIView(),
                                        error: error)
                }
            })
            .disposed(by: disposeBag)

        ThreadTracker.trackFollowTopicClick(
            isFollow: !isFollow,
            locationType: .threadDetail,
            chatId: self._chat.id,
            messageId: threadId
        )
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

    func sendPost(title: String,
                  content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  transmitToChat: Bool = false,
                  parentMessage: Message?,
                  chatId: String,
                  stateHandler: ((SendMessageState) -> Void)?) {
        let threadId = self.thread.id
        postSendService.sendMessage(
            context: APIContext(contextID: ""),
            title: title,
            content: content,
            lingoInfo: lingoInfo,
            parentMessage: parentMessage,
            chatId: chatId,
            threadId: threadId,
            isGroupAnnouncement: false,
            isAnonymous: false,
            isReplyInThread: false,
            transmitToChat: transmitToChat,
            scheduleTime: nil,
            sendMessageTracker: nil,
            stateHandler: stateHandler)
    }

    func sendText(content: RustPB.Basic_V1_RichText, lingoInfo: RustPB.Basic_V1_LingoOption?, parentMessage: Message?, chatId: String, callback: ((SendMessageState) -> Void)?) {
        let context = APIContext(contextID: "")
        let params = SendTextParams(content: content,
                                    lingoInfo: lingoInfo,
                                    parentMessage: parentMessage,
                                    chatId: chatId,
                                    threadId: self.thread.id)
        self.sendMessageAPI.sendText(
            context: context,
            sendTextParams: params,
            sendMessageTracker: nil,
            stateHandler: callback)
    }

    fileprivate func send(update: Bool) {
        if update {
            self.publish(.refreshTable)
        }
    }

    func rootMessageTextDraft() -> Observable<String> {
        return draftCache.getDraft(key: self.draftId).map { $0.content }
    }

    func save(draft: String,
              id: DraftId) {
        switch id {
        case .chat(let chatId):
            draftCache.saveDraft(chatId: chatId, type: .post, content: draft, callback: nil)
        case .replyMessage(let messageId, _):
            draftCache.saveDraft(messageId: messageId, type: .post, content: draft, callback: nil)
        case .multiEditMessage(let messageId, let chatId):
            draftCache.saveDraft(editMessageId: messageId, chatId: chatId, content: draft, callback: nil)
        case .schuduleSend(let chatId, let time, _, let parentMsg, let item):
            draftCache.saveScheduleMsgDraft(chatId: chatId,
                                            parentMessageId: parentMsg?.id,
                                            content: draft,
                                            time: time,
                                            item: item,
                                            callback: nil)
        case .replyInThread(messageId: let messageId):
            break
        }
    }

    func cleanPostDraftWith(key: String, id: DraftId) {
        switch id {
        case .chat(let chatId):
            self.draftCache.deleteDraft(key: key, chatId: chatId, type: .post)
        case .replyMessage(let messageId, _):
            self.draftCache.deleteDraft(key: key, messageID: messageId, type: .post)
        case .multiEditMessage(let messageId, let chatId):
            self.draftCache.deleteDraft(key: key, editMessageId: messageId, chatId: chatId)
        case .schuduleSend:
            break
        case .replyInThread(messageId: let messageId):
            break
        }
    }

    public func reloadRow(by messageId: String, animation: UITableView.RowAnimation = .fade) {
        guard !messageId.isEmpty else {
            return
        }
        func calculateRenderer(datas: [[ThreadDetailCellViewModel]]) -> IndexPath? {
            for (section, sectionDatas) in datas.enumerated() {
                for (row, cellVM) in sectionDatas.enumerated() {
                    if let messageCellVM = cellVM as? HasMessage, messageCellVM.message.id == messageId {
                        cellVM.calculateRenderer()
                        return IndexPath(row: row, section: section)
                    }
                }
            }
            return nil
        }
        if self.queueIsPause() {
            if let indexPath = calculateRenderer(datas: self.uiDataSource) {
                self.tableRefreshPublish.onNext((.messagesUpdate(indexs: [indexPath], guarantLastCellVisible: false), newDatas: nil, outOfQueue: true))
            }
        } else {
            self.queueManager.addDataProcess { [weak self] in
                if let indexPath = calculateRenderer(datas: self?.messageDatasource.cellViewModels ?? []) {
                    self?.publish(.messagesUpdate(indexs: [indexPath], guarantLastCellVisible: false))
                }
            }
        }
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
        let defatultCount: Int32 = 10
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
        ThreadDetailViewModel.logger.info("requestCount is \(count)")
        return count
    }

    private func getRedundancyCount() -> Int32 {
        guard Display.phone, dynamicRequestCountEnable else {
            return 5
        }
        return 1
    }

    // MARK: - 多选相关
    /// 获取被选中的消息
    func getPickedMessage() -> [Message] {
        let cellViewModels = self.messageDatasource.cellViewModels
        var pickedMessages = [Message]()
        cellViewModels.forEach { (cellVMs) in
            cellVMs.forEach({ (cellViewModel) in
                if let vm = cellViewModel as? ThreadDetailRootCellViewModel,
                    vm.checked {
                    pickedMessages.append(vm.message)
                } else if let vm = cellViewModel as? ThreadDetailMessageCellViewModel,
                    vm.checked {
                    pickedMessages.append(vm.message)
                }
            })
        }

        return pickedMessages
    }

    func startMultiSelect(by messageId: String) {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else { return }
            guard let indexPath = self.messageDatasource.indexPath(by: messageId) else { return }

            self.inSelectMode.accept(true)
            let cellViewModel = self.messageDatasource.cellViewModels[indexPath.section][indexPath.row]
            (cellViewModel as? ThreadDetailMessageCellViewModel)?.checked = true
            self.pickedMessages.accept(self.getPickedMessage())
            self.publish(.startMultiSelect(startIndex: indexPath))
        }
    }

    func finishMultiSelect() {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else { return }
            self.messageDatasource.cellViewModels.forEach({ (cellViewModels) in
                cellViewModels.forEach({ (viewModel) in
                    (viewModel as? ThreadDetailMessageCellViewModel)?.checked = false
                })
            })

            self.inSelectMode.accept(false)
            self.publish(.finishMultiSelect)
        }
    }

    func toggleSelectedMessage(by messageId: String) {
        self.queueManager.addDataProcess {[weak self] in
            guard let `self` = self else { return }
            self.pickedMessages.accept(self.getPickedMessage())
            self.publish(.refreshTable)
        }
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
extension ThreadDetailViewModel {
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

private extension ThreadDetailViewModel {
    func loadFirstScreenMessages(_ loadType: ThreadDetailController.LoadType) {
        ThreadDetailViewModel.logger.info(
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
                    ThreadDetailViewModel.logger.info("chatTrace threadDetail loadFirstScreenMessages by local messages count: \(localResult.messages.count) - threadID: \(self.thread.id)")
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
                ThreadPerformanceTracker.updateRequestCost(trackInfo: result.trackInfo)
                self?.handleFirstScreen(
                    localResult: result,
                    loadType: loadType
                )
                ThreadDetailViewModel.logger.info("chatTrace threadDetail loadFirstScreenMessages by \(result.localData) resultCount \(result.messages.count) - replyCount: \(self?.thread.replyCount) - threadID: \(self?.thread.id)")
            }, onError: { [weak self]  (error) in
                AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                scene: .Thread,
                                                                event: .enterChat,
                                                                errorType: .SDK,
                                                                errorLevel: .Fatal,
                                                                errorCode: 2,
                                                                userAction: nil,
                                                                page: ThreadDetailController.pageName,
                                                                errorMessage: nil,
                                                                extra: Extra(isNeedNet: false,
                                                                             latencyDetail: [:],
                                                                             metric: ThreadPerformanceTracker.reciableExtraMetric(self?._chat),
                                                                             category: ThreadPerformanceTracker.reciableExtraCategory(self?._chat, type: .Topic))))
                ThreadDetailViewModel.logger.error("chatTrace threadDetail loadFirstScreenMessages by remote error threadID: \(self?.thread.id)", error: error)
            }).disposed(by: disposeBag)
    }

    func handleFirstScreen(
        localResult: GetThreadMessagesResult,
        loadType: ThreadDetailController.LoadType) {
        firstScreenLoaded = true
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
                ThreadDetailViewModel.logger.error("chatTrace threadDetail initBySpecifiedMessages not find specifie message for index threadID: \(self.thread.id)")
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

        threadAPI.fetchThreadMessagesBy(positions: positions, threadID: thread.id)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages, _) in
                guard let self = self else { return }
                if self.messageDatasource.insertMiss(
                    messages: messages,
                    readPositionBadgeCount: self.thread.readPositionBadgeCount,
                    concurrent: self.concurrentHandler) {
                    ThreadDetailViewModel.logger.info("chatTrace threadDetail insertMiss  thread.id \(self.thread.id) --\(messages.count)")
                    self.publish(.refreshMissedMessage)
                } else {
                    ThreadDetailViewModel.logger.info("chatTrace  threadDetail fetchMissedMessages not in effective range \(self.thread.id)")
                }
            }, onError: { (error) in
                ThreadDetailViewModel.logger.error("chatTrace threadDetail fetchMissedMessages fail \(self.thread.id)", error: error)
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
                ThreadDetailViewModel.logger
                    .error("chatTrace threadDetail fetchMessages error",
                           additionalData: ["threadId": self?.thread.id ?? "",
                                            "scene": "\(scene.description())"],
                           error: error)
            })
    }

    func logForGetMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32) {
        ThreadDetailViewModel.logger.info("chatTrace threadDetail fetchMessages",
                                                additionalData: [
                                                    "threadId": self.thread.id,
                                                    "lastMessagePosition": "\(self.thread.lastMessagePosition)",
                                                    "lastVisibleMessagePosition": "\(self.thread.lastVisibleMessagePosition)",
                                                    "scene": "\(scene.description())",
                                                    "count": "\(count)",
                                                    "redundancyCount": "\(redundancyCount)"])
    }

    func fetchMessageForJump(position: Int32, noNext: @escaping ([Message], [Int32]) -> Void, onError: ((Error) -> Void)? = nil) {
        self.pauseQueue()
        self.fetchMessages(
            scene: .specifiedPosition(position),
            redundancyCount: self.redundancyCount,
            count: self.requestCount)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                let refreshMessagesOperation = BlockOperation(block: { noNext(result.messages, result.invisiblePositions) })
                refreshMessagesOperation.queuePriority = .high
                self?.queueManager.addDataProcessOperation(refreshMessagesOperation)
                self?.resumeQueue()
            }, onError: { [weak self] (error) in
                self?.resumeQueue()
                onError?(error)
            }).disposed(by: self.disposeBag)
    }

    enum LoadMoreDirection {
        case previous
        case after
    }
    func loadMoreMessages(position: Int32, direction: LoadMoreDirection) -> Observable<([Message], invisiblePositions: [Int32], sdkCost: Int64)> {
        var scene: GetDataScene
        switch direction {
        case .previous:
            scene = .previous(before: position + 1)
        case .after:
            scene = .after(after: position - 1)
        }
        let threadId = self.thread.id
        return self.fetchMessages(scene: scene, redundancyCount: 0, count: 15).map({ (result) -> ([Message], invisiblePositions: [Int32], sdkCost: Int64) in
            ThreadDetailViewModel.logger.info("chatTrace threadDetail loadMoreMessages by serverData \(threadId)")
            return (result.messages, invisiblePositions: result.invisiblePositions, sdkCost: Int64(result.sdkCost * 1000))
        }).observeOn(self.queueManager.dataScheduler)
    }

    func hasMoreOldMessages() -> Bool {
        ThreadDetailViewModel.logger.info("chatTrace threadDetail hasMoreOldMessages \(self.messageDatasource.minPosition) \(self.thread.id)")
        return firstScreenLoaded && (self.messageDatasource.minPosition > firstThreadPositionBound + 1)
    }

    func hasMoreNewMessages() -> Bool {
        ThreadDetailViewModel.logger.info("chatTrace threadDetail hasMoreNewMessages \(self.messageDatasource.maxPosition) \(self.thread.lastMessagePosition) - \(self.thread.id)")
        return firstScreenLoaded && (self.messageDatasource.maxPosition < self.thread.lastMessagePosition)
    }

    func publish(_ type: TableRefreshType, outOfQueue: Bool = false) {
        var dataUpdate: Bool = true
        switch type {
        case .updateFooterView,
             .updateHeaderView,
             .scrollTo:
            dataUpdate = false
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
        pushHandlers.startObserve(self)
        self.pushCenter.observable(for: PushThreads.self)
            .map({ [weak self] (push) -> [RustPB.Basic_V1_Thread] in
                return push.threads.filter({ (thread) -> Bool in
                    return thread.id == self?.thread.id ?? ""
                })
            })
            .filter({ !$0.isEmpty })
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (threads) in
                guard let pushThread = threads.first else { return }
                if pushThread.isNoTraceDeleted {
                    DispatchQueue.main.async {
                        guard let self else { return }
                        // 已经提示过 就不再提示。避免反复触发的情况
                        if self.hasDeleteOfThread == false {
                            self.hasDeleteOfThread = true

                            guard let targetVC = self.context.targetVC,
                                let navigation = targetVC.navigationController else { return }

                            if let window = targetVC.view.window {
                                UDToast.showFailure(with: BundleI18n.LarkThread.Lark_Chat_TopicWasRecalledToast,
                                                       on: window)
                            }

                            /// if target vc is navigation root vc
                            /// show default empty detail VC in iPad
                            if Display.pad, navigation.viewControllers.count == 1 {
                               if let from = targetVC.larkSplitViewController {
                                    self.navigator.showDetail(
                                        UIViewController.DefaultDetailController(),
                                        wrap: LkNavigationController.self,
                                        from: from,
                                        completion: nil
                                    )
                               } else {
                                    if #available(iOS 13.0, *) {
                                        /// 删除独立 scene
                                        if let sceneInfo = targetVC.currentScene()?.sceneInfo,
                                           !sceneInfo.isMainScene() {
                                            SceneManager.shared.deactive(from: targetVC)
                                        }
                                    }
                               }
                            } else {
                                self.navigator.pop(from: targetVC)
                            }
                        }
                    }
                }
                self?.messageDatasource.update(thread: pushThread)
                self?.publish(.refreshTable)
                self?.publish(.updateFooterView(hasFooter: self?.hasMoreNewMessages() ?? false))
            }).disposed(by: self.disposeBag)

        self.pushCenter.observable(for: PushChannelMessages.self)
            .map({ [weak self] (push) -> [Message] in
                return push.messages.filter({ [weak self] (msg) -> Bool in
                    return msg.rootMessage?.id == self?.thread.id ?? "" || msg.id == self?.thread.id
                })
            })
            .filter({ !$0.isEmpty })
            .observeOn(self.queueManager.dataScheduler)
            .do(onNext: { [weak self] (messages) in
                guard let self = self, self.firstScreenLoaded else { return }
                if messages.contains(where: { (message) -> Bool in
                    return message.localStatus != .success && self.messageDatasource.indexForReply(cid: message.cid) == nil
                }) {
                    if self.thread.lastMessagePosition == self.firstThreadPositionBound {
                        self.publish(.scrollTo(type: .toTableBottom))
                    } else {
                        self.jumpToLastReply(tableScrollPosition: .bottom)
                    }
                }
            })
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages) in
                guard let `self` = self, self.firstScreenLoaded else { return }
                var needUpdate = false
                for msg in messages {
                    let result = self.messageDatasource.handle(message: msg)
                    switch result {
                    case .newMessage:
                        self.publish(.hasNewMessage(hasFooter: self.hasMoreNewMessages()))
                    case .messageSendSuccess:
                        self.publish(.hasNewMessage(hasFooter: self.hasMoreNewMessages()))
                    case .updateMessage:
                        needUpdate = true
                    case .none:
                        break
                    }
                }
                if needUpdate {
                    self.publish(.refreshTable)
                }
                self.urlPreviewService?.fetchMissingURLPreviews(messages: messages)
            }).disposed(by: self.disposeBag)

        self.pushCenter.observable(for: PushThreadMessages.self)
            .map({ [weak self] (push) -> [ThreadMessage] in
                return push.messages.filter({ thread -> Bool in
                    return thread.id == self?.thread.id ?? ""
                })
            })
            .filter({ !$0.isEmpty })
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (threadMessages) in
                guard let threadMessage = threadMessages.first, let self else { return }
                self.messageDatasource.update(threadMessage: threadMessage)
                self.publish(.refreshTable)
                let messages = [threadMessage.rootMessage] + threadMessage.replyMessages + threadMessage.latestAtMessages
                self.urlPreviewService?.fetchMissingURLPreviews(messages: messages)
            }).disposed(by: self.disposeBag)

        self.is24HourTime
            .skip(1)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.messageDatasource.refreshRenders()
                self?.publish(.refreshTable)
            }).disposed(by: disposeBag)

        wrapPushObservers()
    }

    private func wrapPushObservers() {
        chatWrapper.chat
            .observeOn(MainScheduler.instance)
            .do(onNext: { [weak self] (chat) in
                self?.chatPushed = true
                self?.chatObserver.accept(chat)
            }).map({ $0.isAutoTranslate })
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (_) in
                self?.chatAutoTranslateSettingPublish.onNext(())
            }).disposed(by: self.disposeBag)

        topicGroupPushWrapper.topicGroupObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (topicGroup) in
                self?.topicGroupPushed = true
                self?.topicGroupObserver.accept(topicGroup)
            }).disposed(by: self.disposeBag)

        threadWrapper.thread
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (thread) in
                self?.threadPushed = true
                self?.threadObserver.accept(thread)
            }).disposed(by: self.disposeBag)
    }
}

extension ThreadDetailViewModel: DataSourceAPI {
    func processMessageSelectedEnable(message: Message) -> Bool {
        return true
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

extension ThreadDetailViewModel: HandlePushDataSourceAPI {
    func update(messageIds: [String], doUpdate: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(messageIds: messageIds, doUpdate: { (msg) -> Message? in
                return doUpdate(msg) as? Message
            }) ?? false
            completion?(needUpdate)
            self?.send(update: needUpdate)
        }
    }

    func update(original: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(original: { (msg) -> Message? in
                return original(msg) as? Message
            }) ?? false
            completion?(needUpdate)
            self?.send(update: needUpdate)
        }
    }
}

extension Message: PushData {
    public var message: Message {
        return self
    }
}

//AppReciableTrack
private extension ThreadDetailViewModel {

    func loadMoreReciableTrack(key: DisposedKey?, sdkCost: Int64, loadMoreNew: Bool) {
        if let key = key {
            let chat = self._chat
            var category = ThreadPerformanceTracker.reciableExtraCategory(chat, type: .Topic)
            category["load_type"] = loadMoreNew
            AppReciableSDK.shared.end(key: key, extra: Extra(isNeedNet: true,
                                                             latencyDetail: ["sdk_cost": sdkCost],
                                                             metric: ThreadPerformanceTracker.reciableExtraMetric(chat),
                                                             category: category))
        }
    }

    func loadMoreReciableTrackError(loadMoreNew: Bool, bySDK: Bool) {
        let chat = self._chat
        var category = ThreadPerformanceTracker.reciableExtraCategory(chat, type: .Topic)
        category["load_type"] = loadMoreNew
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Thread,
                                                        event: .loadMoreMessageTime,
                                                        errorType: bySDK ? .SDK : .Other,
                                                        errorLevel: bySDK ? .Fatal : .Exception,
                                                        errorCode: bySDK ? 1 : 0,
                                                        userAction: nil,
                                                        page: ThreadDetailController.pageName,
                                                        errorMessage: nil,
                                                        extra: Extra(isNeedNet: bySDK,
                                                                     latencyDetail: [:],
                                                                     metric: ThreadPerformanceTracker.reciableExtraMetric(chat),
                                                                     category: category)))
    }

    func loadMoreReciableTrackForPreLoad(sdkCost: Int64, loadMoreNew: Bool) {
        let chat = self._chat
        var category = ThreadPerformanceTracker.reciableExtraCategory(chat, type: .Topic)
        category["load_type"] = loadMoreNew
        AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                              scene: .Thread,
                                                              event: .loadMoreMessageTime,
                                                              cost: -1,
                                                              page: ThreadDetailController.pageName,
                                                              extra: Extra(isNeedNet: true,
                                                                           latencyDetail: ["sdk_cost": sdkCost],
                                                                           metric: ThreadPerformanceTracker.reciableExtraMetric(chat),
                                                                           category: category)))
    }
}
