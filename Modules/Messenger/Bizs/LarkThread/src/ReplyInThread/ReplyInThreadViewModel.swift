//
//  ReplyInThreadViewModel.swift
//  LarkThread
//
//  Created by liluobin on 2022/4/8.
//
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
import RustPB
import UIKit
import LarkChatOpenKeyboard

struct ReplyInThreadHeaderViewConfig {
    static let headerHeight: CGFloat = 26
    static let footerHeight: CGFloat = 0.01
    static let replyMessagesFooterHeight: CGFloat = 12
}

final class ReplyInThreadViewModel: AsyncDataProcessViewModel<ReplyInThreadViewModel.TableRefreshType, [[ThreadDetailCellViewModel]]>, ThreadDetailTableViewDataSource, UserResolverWrapper {
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
        case refreshNavBar
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

    private static let logger = Logger.log(ReplyInThreadViewModel.self, category: "Business.ReplyInThreadViewModel")
    private var thread: RustPB.Basic_V1_Thread {
        return self.threadObserver.value
    }
    private let context: ThreadDetailContext

    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?

    var _chat: Chat {
        return chatObserver.value
    }

    private(set) var firstScreenLoaded: Bool = false

    let pickedMessages = BehaviorRelay<[ChatSelectedMessageContext]>(value: [])
    let inSelectMode: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    let chatObserver: BehaviorRelay<Chat>
    let threadObserver: BehaviorRelay<RustPB.Basic_V1_Thread>

    internal let chatWrapper: ChatPushWrapper
    private let threadWrapper: ThreadPushWrapper

    let userGeneralSettings: UserGeneralSettings
    let translateService: NormalTranslateService

    let draftCache: DraftCache
    let messageAPI: MessageAPI
    private let sendMessageAPI: SendMessageAPI
    private let postSendService: PostSendService
    private let videoMessageSendService: VideoMessageSendService
    private let factory: ThreadReplyMessageCellViewModelFactory
    private let firstThreadPositionBound: Int32 = -1
    private var disposeBag = DisposeBag()
    private var loadingMoreOldMessages: Bool = false
    private var loadingMoreNewMessages: Bool = false
    private let draftId: String
    private var justShowReply: Bool = false
    private var hasDeleteOfThread: Bool = false
    private let useIncompleteLocalData: Bool
    private let pushHandlers: ReplyInThreadPushHandlersRegister
    private let dynamicRequestCountEnable: Bool
    @ScopedInjectedLazy var chatSecurityControlService: ChatSecurityControlService?
    @ScopedInjectedLazy var modelService: ModelService?
    @ScopedInjectedLazy var urlPreviewService: MessageURLPreviewService?
    @ScopedInjectedLazy var scheduleSendService: ScheduleSendService?

    private(set) lazy var redundancyCount: Int32 = {
           return getRedundancyCount()
       }()
    private(set) lazy var requestCount: Int32 = {
        return getRequestCount()
    }()

    var readService: ChatMessageReadService? {
        return readServiceMgr.readService
    }
    private let readServiceMgr: ReplyInThreadReadServiceManager
    let messageDatasource: ReplyInThreadDataSource
    let threadAPI: ThreadAPI
    let pushCenter: PushNotificationCenter
    var threadHadCreate: Bool {
        didSet {
            if oldValue != threadHadCreate {
                self.queueManager.addDataProcess { [weak self] in
                    self?.publish(.refreshNavBar)
                }
            }
        }
    }
    var sendMessageStatusDriver: Driver<(LarkModel.Message, Error?)> {
        return sendMessageAPI.statusDriver
    }
    lazy var pushScheduleMessage: Observable<PushScheduleMessage> = self.pushCenter.observable(for: PushScheduleMessage.self)
    lazy var scheduleMsgEnable = scheduleSendService?.scheduleSendEnable ?? false

    lazy var deleteMeFromChannelDriver: Driver<String> = {
        let chatId = self._chat.id
        let driver = self.pushCenter.driver(for: PushRemoveMeFromChannel.self)
            .filter { (push) -> Bool in
                return push.channelId == chatId
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

    /// 当前thread的threadId
    let threadId: String

    var offlineThreadUpdateDriver: Driver<RustPB.Basic_V1_Thread> {
        return pushCenter.driver(for: PushOfflineThreads.self)
            .map({ (push) -> RustPB.Basic_V1_Thread? in
                return push.threads.first(where: { [weak self] (thread) -> Bool in
                    return thread.id == self?.thread.id ?? ""
                })
            })
            .compactMap { $0 }
    }

    init(
        userResolver: UserResolver,
        chatWrapper: ChatPushWrapper,
        threadWrapper: ThreadPushWrapper,
        context: ThreadDetailContext,
        sendMessageAPI: SendMessageAPI,
        postSendService: PostSendService,
        videoMessageSendService: VideoMessageSendService,
        threadAPI: ThreadAPI,
        messageAPI: MessageAPI,
        draftCache: DraftCache,
        pushCenter: PushNotificationCenter,
        pushHandlers: ReplyInThreadPushHandlersRegister,
        is24HourTime: Observable<Bool>,
        factory: ThreadReplyMessageCellViewModelFactory,
        threadMessage: ThreadMessage,
        useIncompleteLocalData: Bool,
        userGeneralSettings: UserGeneralSettings,
        translateService: NormalTranslateService,
        readServiceManager: ReplyInThreadReadServiceManager
    ) {
        self.userResolver = userResolver
        self.dynamicRequestCountEnable = (try? userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: FeatureGatingKey.dynamicRequestCountEnable))) ?? false
        self.chatObserver = BehaviorRelay<Chat>(value: chatWrapper.chat.value)
        self.threadObserver = BehaviorRelay<RustPB.Basic_V1_Thread>(value: threadWrapper.thread.value)
        self.chatWrapper = chatWrapper
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
        self.threadId = threadMessage.thread.id
        let rootMessage = threadMessage.rootMessage
        self.draftId = rootMessage.msgThreadDraftId
        self.messageDatasource = ReplyInThreadDataSource(
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
        self.threadHadCreate = !threadObserver.value.isMock
        self.readServiceMgr = readServiceManager
        super.init(uiDataSource: [])
        self.messageDatasource.contentPreferMaxWidth = { [weak self] message in
            return self?.getContentPreferMaxWidth(message) ?? 0
        }
    }

    deinit {
        /// 退会话时，清空一次标记
        self.translateService.resetMessageCheckStatus(key: self.chatObserver.value.id)
    }

    public func initMessages(loadType: ReplyInThreadViewController.LoadType) {
        // threadMessage是本地传参过来的，需要单独处理预览懒加载
        let messages = [self.messageDatasource.threadMessage.rootMessage] +
                        self.messageDatasource.threadMessage.replyMessages +
                        self.messageDatasource.threadMessage.latestAtMessages
        self.urlPreviewService?.fetchMissingURLPreviews(messages: messages)
        self.observeData()
        // 当前场景下一定是有threadMessage的，所以一进入应该立即显示显示根消息
        self.queueManager.addDataProcess { [weak self] in
            self?.publish(.showRootMessage)
        }
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
            //容错逻辑，出现此情况时，强制将header去除掉
            self.publish(.updateHeaderView(hasHeader: false))
            loadingMoreOldMessages = false
            finish?(.noWork)
            return
        }
        self.loadMoreMessages(position: minPosition, direction: .previous)
            .subscribe(onNext: { [weak self] (messages, invisiblePositions, sdkCost) in
                guard let `self` = self else {
                    finish?(.noWork)
                    return
                }

                let hasChange = self.messageDatasource.headInsert(messages: messages,
                                                                  invisiblePositions: invisiblePositions,
                                                                  concurrent: self.concurrentHandler)
                if hasChange {
                    self.publish(.loadMoreOldMessages(hasHeader: self.hasMoreOldMessages()))
                } else {
                    Self.logger.error("chatTrace reply in thread has no valid history messages threadId: \(self.threadId)")
                    self.publish(.updateHeaderView(hasHeader: self.hasMoreOldMessages()))
                }
                self.loadingMoreOldMessages = false
                finish?(.success(sdkCost: sdkCost, valid: hasChange))
            }, onError: { [weak self] (error) in
                Self.logger.error("chatTrace reply in thread loadMoreMessages \(self?.threadId)", error: error)
                self?.loadingMoreOldMessages = false
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
            //容错逻辑，出现此情况时，强制将footer去除掉
            self.publish(.updateFooterView(hasFooter: false))
            loadingMoreNewMessages = false
            finish?(.noWork)
            return
        }
        Self.logger.info("reply In thread Load more message postion \(maxPosition)")
        self.loadMoreMessages(position: maxPosition, direction: .after)
            .subscribe(onNext: { [weak self] (messages, invisiblePositions, sdkCost) in
                guard let `self` = self else {
                    finish?(.noWork)
                    return
                }
                let hasChange = self.messageDatasource.tailAppend(
                    messages: messages,
                    invisiblePositions: invisiblePositions,
                    concurrent: self.concurrentHandler)
                if hasChange {
                    self.publish(.loadMoreNewMessages(hasFooter: self.hasMoreNewMessages()))
                } else {
                    Self.logger.error("LarkThread error: chatTrace threadDetail no get new messages")
                    self.publish(.updateFooterView(hasFooter: self.hasMoreNewMessages()))
                }
                self.loadingMoreNewMessages = false
                finish?(.success(sdkCost: sdkCost, valid: hasChange))
            }, onError: { [weak self] (error) in
                self?.loadingMoreNewMessages = false
                Self.logger.error("chatTrace reply in thread loadMoreNewMessages \(self?.threadId)", error: error)
                finish?(.error)
            }).disposed(by: self.disposeBag)
    }

    //跳到chat最近一条消息
    public func jumpToLastReply(tableScrollPosition: UITableView.ScrollPosition, finish: (() -> Void)? = nil) {
        let theadID = self.thread.id
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self, self.thread.lastMessagePosition > self.firstThreadPositionBound else {
                finish?()
                return
            }
            Self.logger.info("chatTrace threadDetail jumpToLastReply \(self.thread.id) \(self.thread.lastMessagePosition) \(self.messageDatasource.maxPosition)")
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
                Self.logger.error("chatTrace threadDetail jumpToLastReply error theadID: \(theadID)", error: error)
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
        if self._chat.isInMeetingTemporary {
            if let targetVC = self.context.targetVC {
                UDToast.showTips(with: BundleI18n.LarkThread.Lark_IM_TemporaryJoinMeetingFunctionUnavailableNotice_Desc, on: targetVC.view)
            }
            return
        }
        let threadId = self.thread.id
        let isFollow = self.thread.isFollow
        self.threadAPI.update(threadId: threadId, isFollow: !isFollow, threadState: nil)
            .observeOn(MainScheduler.instance)
            .subscribe( onNext: { [weak self] _ in
                let tips: String
                if !isFollow {
                    tips = BundleI18n.LarkThread.Lark_IM_Thread_SubscribedToThread_SuccessToast
                } else {
                    tips = BundleI18n.LarkThread.Lark_IM_Thread_UnsubscribedToThread_SuccessToast
                }
                self?.showTips(tips)
            }, onError: { [weak self] error in
                if let apiError = error.underlyingError as? APIError {
                    UDToast.showFailure(with: apiError.displayMessage,
                                        on: self?.context.targetVC?.view ?? UIView(),
                                        error: error)
                }
                Self.logger.error("update update:\(threadId), isFollow:\(!isFollow)", error: error)
            })
            .disposed(by: disposeBag)
    }

    func toggleThreadRemindStatus() {
        let threadId = thread.id
        let isRemind = !thread.isRemind
        self.threadAPI.update(threadId: threadId, isRemind: isRemind)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                let tips: String
                if isRemind {
                    tips = BundleI18n.LarkThread.Lark_Core_TouchAndHold_UnmuteChats_UnmutedToast
                } else {
                    tips = BundleI18n.LarkThread.Lark_Core_TouchAndHold_MuteChats_MutedToast
                }
                self?.showTips(tips)
            }, onError: { [weak self] error in
                if let apiError = error.underlyingError as? APIError {
                    UDToast.showFailure(with: apiError.displayMessage,
                                        on: self?.context.targetVC?.view ?? UIView(),
                                        error: error)
                }
                Self.logger.error("update threadId:\(threadId), isRemind:\(isRemind)", error: error)
            }).disposed(by: disposeBag)
    }

    func showTips(_ tips: String) {
        UDToast.showTips(with: tips,
                         on: self.context.targetVC?.view ?? UIView())
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
                  parentMessage: Message?,
                  chatId: String,
                  isAnonymous: Bool,
                  scheduleTime: Int64? = nil,
                  transmitToChat: Bool,
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
            isAnonymous: isAnonymous,
            isReplyInThread: true,
            transmitToChat: transmitToChat,
            scheduleTime: scheduleTime,
            sendMessageTracker: nil,
            stateHandler: stateHandler)
    }

    func sendText(content: RustPB.Basic_V1_RichText,
                  lingoInfo: RustPB.Basic_V1_LingoOption?,
                  parentMessage: Message?,
                  chatId: String,
                  isAnonymous: Bool,
                  scheduleTime: Int64? = nil,
                  transmitToChat: Bool,
                  callback: ((SendMessageState) -> Void)?) {
        let params = SendTextParams(content: content,
                                    lingoInfo: lingoInfo,
                                    parentMessage: parentMessage,
                                    chatId: chatId,
                                    threadId: self.thread.id,
                                    createScene: nil,
                                    scheduleTime: scheduleTime,
                                    transmitToChat: transmitToChat)
        self.sendMessageAPI.sendText(
            context: defaultSendContext(isAnonymous: isAnonymous),
            sendTextParams: params,
            sendMessageTracker: nil,
            stateHandler: callback)
    }

    func sendSticker(sticker: RustPB.Im_V1_Sticker,
                     parentMessage: Message?,
                     chat: Chat,
                     isAnonymous: Bool,
                     stateHandler: ((SendMessageState) -> Void)?) {
        self.sendMessageAPI.sendSticker(context: defaultSendContext(isAnonymous: isAnonymous),
                                        sticker: sticker,
                                        parentMessage: parentMessage,
                                        chatId: chat.id,
                                        threadId: thread.id,
                                        sendMessageTracker: nil,
                                        stateHandler: stateHandler)
    }

    func defaultSendContext(isAnonymous: Bool = false) -> APIContext {
        let context = APIContext(contextID: "")
        context.set(key: APIContext.anonymousKey, value: isAnonymous)
        context.set(key: APIContext.replyInThreadKey, value: true)
        return context
    }

    fileprivate func send(update: Bool) {
        if update {
            self.publish(.refreshTable)
        }
    }

    func rootMessageMsgThreadDraft() -> Observable<String> {
        return draftCache.getDraft(key: self.draftId).map { $0.content }
    }

    func save(draft: String,
              id: DraftId) {
        switch id {
        case .replyInThread(let messageId):
            draftCache.saveDraft(msgThreadId: messageId, content: draft, callback: nil)
        case .multiEditMessage(let messageId, let chatId):
            draftCache.saveDraft(editMessageId: messageId, chatId: chatId, content: draft, callback: nil)
        default:
            break
        }
    }

    func cleanPostDraftWith(key: String, id: DraftId) {
        switch id {
        case .replyInThread(let messageId):
            draftCache.deleteDraft(key: key, threadId: messageId)
        case .multiEditMessage(let messageId, let chatId):
            self.draftCache.deleteDraft(key: key, editMessageId: messageId, chatId: chatId)
        default:
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

    private func getRequestCount() -> Int32 {
        let defatultCount: Int32 = 10
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
                if let vm = cellViewModel as? ThreadReplyRootCellViewModel,
                    vm.checked {
                    pickedMessages.append(vm.message)
                } else if let vm = cellViewModel as? ThreadReplyMessageCellViewModel,
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
            (cellViewModel as? ThreadReplyMessageCellViewModel)?.checked = true
            self.pickedMessages.accept(self.getPickedMessage())
            self.publish(.startMultiSelect(startIndex: indexPath))
        }
    }

    func finishMultiSelect() {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else { return }
            self.messageDatasource.cellViewModels.forEach({ (cellViewModels) in
                cellViewModels.forEach({ (viewModel) in
                    (viewModel as? ThreadReplyMessageCellViewModel)?.checked = false
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
extension ReplyInThreadViewModel {
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

private extension ReplyInThreadViewModel {
    func loadFirstScreenMessages(_ loadType: ReplyInThreadViewController.LoadType) {
        Self.logger.info(
            "chatTrace replyInthread new initData: " +
            "message id \(self.rootMessage.id)" +
            "threadId:\(self.thread.id) \(loadType.rawValue)" +
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
                    Self.logger.info("chatTrace reply in thread loadFirstScreenMessages by local messages count: \(localResult.messages.count) threadId: \(self.threadId)")
                    return .just(localResult)
                } else {
                    return self.fetchMessages(
                        scene: scene,
                        redundancyCount: self.redundancyCount,
                        count: self.requestCount
                    )
                }
            })
        let threadID = self.threadId
        firstScreenDataOb
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                self?.handleFirstScreen(
                    localResult: result,
                    loadType: loadType
                )
                Self.logger.info("chatTrace reply in thread loadFirstScreenMessages by \(result.localData) --- resultCount \(result.messages.count) -- replyCount: \(self?.thread.replyCount) threadId: \(threadID)")
            }, onError: { (error) in
                Self.logger.error("chatTrace reply in thread loadFirstScreenMessages by remote error \(threadID)", error: error)
            }).disposed(by: disposeBag)
    }

    func handleFirstScreen(
        localResult: GetThreadMessagesResult,
        loadType: ReplyInThreadViewController.LoadType) {
        firstScreenLoaded = true
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
                Self.logger.error("chatTrace reply in thread initBySpecifiedMessages no find index threadId \(self.threadId)")
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

        threadAPI.fetchThreadMessagesBy(positions: positions, threadID: thread.id)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages, _) in
                guard let self = self else { return }
                if self.messageDatasource.insertMiss(
                    messages: messages,
                    readPositionBadgeCount: self.thread.readPositionBadgeCount,
                    concurrent: self.concurrentHandler) {
                    Self.logger.info("chatTrace reply in thread insertMiss  thread.id \(self.thread.id) --\(messages.count)")
                    self.publish(.refreshMissedMessage)
                } else {
                    Self.logger.info("chatTrace reply in thread fetchMissedMessages is not valid thread.id \(self.thread.id)")
                }
            }, onError: { [weak self] (error) in
                Self.logger.error("chatTrace reply in thread fetchMissedMessages error \(self?.thread.id ?? "")", error: error)
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

        return self.fetchMessages(scene: scene, redundancyCount: 0, count: 15).map({ (result) -> ([Message], invisiblePositions: [Int32], sdkCost: Int64) in
            Self.logger.info("chatTrace reply in thread loadMoreMessages by serverData")
            return (result.messages, invisiblePositions: result.invisiblePositions, sdkCost: Int64(result.sdkCost * 1000))
        }).observeOn(self.queueManager.dataScheduler)
    }

    func hasMoreOldMessages() -> Bool {
        Self.logger.info("chatTrace reply in thread hasMoreOldMessages \(self.messageDatasource.minPosition)")
        return firstScreenLoaded && (self.messageDatasource.minPosition > firstThreadPositionBound + 1)
    }

    func hasMoreNewMessages() -> Bool {
        Self.logger.info("chatTrace reply in thread hasMoreNewMessages \(self.messageDatasource.maxPosition) \(self.thread.lastMessagePosition)")
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
                        if ( self.hasDeleteOfThread ?? true ) == false {
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
        /// 子消息变化的时候
        self.pushCenter.observable(for: PushChannelMessages.self)
            .map({ [weak self] (push) -> [Message] in
                return push.messages.filter({ [weak self] (msg) -> Bool in
                    /// msg.id == self?.thread.id 表示根消息
                    /// msg.threadId == self?.thread.id 表示子消息 其他的都应该过滤
                    return msg.id == self?.thread.id || msg.threadId == self?.thread.id
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
        /// rootMessage变化
        self.pushCenter.observable(for: PushThreadMessages.self)
            .map({ [weak self] (push) -> [ThreadMessage] in
                return push.messages.filter({ thread -> Bool in
                    return thread.id == self?.thread.id ?? ""
                })
            })
            .filter({ !$0.isEmpty })
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (threadMessages) in
                guard let self = self, let threadMessage = threadMessages.first else { return }
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
                self?.chatObserver.accept(chat)
            }).map({ $0.isAutoTranslate })
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] (_) in
                self?.chatAutoTranslateSettingPublish.onNext(())
            }).disposed(by: self.disposeBag)

        threadWrapper.thread
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (thread) in
                guard let self = self else {
                    return
                }
                self.threadObserver.accept(thread)
                if !self.threadHadCreate {
                    self.threadHadCreate = !thread.isMock
                }
            }).disposed(by: self.disposeBag)
    }
}

extension ReplyInThreadViewModel: DataSourceAPI {
    func processMessageSelectedEnable(message: Message) -> Bool {
        return true
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

extension ReplyInThreadViewModel: HandlePushDataSourceAPI {
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

    func canHandleScheduleTip(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                              entity: RustPB.Basic_V1_Entity) -> Bool {
        guard let itemId = messageItems.first?.itemID else {
            return false
        }
        if let message = entity.messages[itemId] {
            if message.threadMessageType == .unknownThreadMessage {
                return false
            }
            return message.threadID == threadId
        } else if let quasi = entity.quasiMessages[itemId] {
            if quasi.threadID.isEmpty == true {
                return false
            }
            return quasi.threadID == threadId
        }
        return true
    }
}
