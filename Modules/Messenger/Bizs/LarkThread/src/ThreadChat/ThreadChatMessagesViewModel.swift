//
//  ThreadChatMessagesViewModel.swift
//  LarkThread
//
//  Created by zc09v on 2019/2/14.
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
import AppReciableSDK
import RustPB
import LarkContainer

final class LoadMoreReciableKeyInfo {
    let key: DisposedKey
    let timeStamp: TimeInterval

    init(key: DisposedKey) {
        self.key = key
        self.timeStamp = CACurrentMediaTime()
    }

    class func generate(page: String) -> LoadMoreReciableKeyInfo {
        let key = AppReciableSDK.shared.start(biz: .Messenger, scene: .Thread, event: .loadMoreMessageTime, page: page)
        return LoadMoreReciableKeyInfo(key: key)
    }
}

struct ScrollInfo {
    public let index: Int
    public let tableScrollPosition: UITableView.ScrollPosition
    public let highlightPosition: Int32?
    public var needDuration: Bool
    public init(index: Int, tableScrollPosition: UITableView.ScrollPosition = .top, highlightPosition: Int32? = nil, needDuration: Bool = true) {
        self.index = index
        self.tableScrollPosition = tableScrollPosition
        self.highlightPosition = highlightPosition
        self.needDuration = needDuration
    }
}

enum ErrorType {
    case jumpFail(Error)
    case loadMoreOldMsgFail(Error)
    case loadMoreNewMsgFail(Error)
}

enum MessageInitType {
    //最近消息
    case localRecentMessages
    //最近未读消息
    case lastedUnreadMessage
    //最远未读消息
    case oldestUnreadMessage
    //指定消息
    case specifiedMessages(position: Int32)
    // 上次离开时消息
    case recentLeftMessage
}

struct InitMessagesInfo {
    let hasHeader: Bool
    let hasFooter: Bool
    let newReplyCount: Int32
    let newAtReplyMessages: [Message]
    let newAtReplyCount: Int32
    let scrollInfo: ScrollInfo?
    let initType: MessageInitType
}

final class ThreadChatMessagesViewModel: AsyncDataProcessViewModel<ThreadChatMessagesViewModel.TableRefreshType, [ThreadCellViewModel]>, UserResolverWrapper {
    var userResolver: UserResolver { dependency.userResolver }
    /// 置顶信号
    let topNoticeSubject: BehaviorSubject<ChatTopNotice?> = BehaviorSubject(value: nil)

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
    //第一条未读消息相关信息
    struct FirstUnreadMessageInfo {
        let firstUnreadMessagePosition: Int32
        let readPositionBadgeCount: Int32
    }

    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?
    let messageDatasource: ThreadChatDataSource
    let dependency: ThreadChatMessagesViewModelDependency
    private(set) var firstScreenLoaded: Bool = false
    /// not display onboarding when first screen data all missed
    private(set) var needFetchMissedData: Bool = false
    @ScopedInjectedLazy private var thumbsupReactionService: ThumbsupReactionService?

    //防止反复调用
    private var loadingMoreOldMessages: Bool = false
    private var loadingMoreNewMessages: Bool = false
    var topLoadMoreReciableKeyInfo: LoadMoreReciableKeyInfo?
    var bottomLoadMoreReciableKeyInfo: LoadMoreReciableKeyInfo?

    private static let logger = Logger.log(ThreadChatMessagesViewModel.self, category: "Business.ThreadChat")
    private(set) var firstUnreadMessageInfo: FirstUnreadMessageInfo?
    private(set) lazy var redundancyCount: Int32 = {
           return getRedundancyCount()
       }()
    private(set) lazy var requestCount: Int32 = {
        return getRequestCount()
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

        ThreadChatMessagesViewModel.logger.info("ThreadOnboradingView system height \(totalCellsHeight)")
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
    private let navBarHeight: CGFloat

    let gcunit: GCUnit?

    let errorPublish = PublishSubject<ErrorType>()
    var errorDriver: Driver<ErrorType> {
        return errorPublish.asDriver(onErrorRecover: { _ in Driver<ErrorType>.empty() })
    }

    private let context: ThreadContext

    init(
        dependency: ThreadChatMessagesViewModelDependency,
        context: ThreadContext,
        chatWrapper: ChatPushWrapper,
        topicGroupPushWrapper: TopicGroupPushWrapper,
        pushHandlerRegister: ThreadChatPushHandlersRegister,
        gcunit: GCUnit?,
        navBarHeight: CGFloat
    ) {
        self.context = context
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
        self.navBarHeight = navBarHeight
        super.init(uiDataSource: [])
        self.messageDatasource.contentPreferMaxWidth = { [weak self] _ in
            guard let self = self else { return 0 }
            return self.hostUIConfig.size.width - 16 - 16
        }
        self.addObserver()
    }

    private func addObserver() {
        thumbsupReactionService?.thumbsupUpdate
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (_) in
                self?.messageDatasource.cellViewModels.forEach { $0.calculateRenderer() }
                self?.publish(.refreshTable)
            }).disposed(by: disposeBag)
    }

    func threadLocationPackagingMethod(chatModel: Chat) -> MessageInitType {
        let result: MessageInitType
        if chatModel.threadBadge > 0 {
            //消息加载的起始位置
            if chatModel.messagePosition == .newestUnread {
                result = .lastedUnreadMessage
                ThreadChatMessagesViewModel.logger.info("chatTrace initData unread: newestUnread")
            } else {
                ThreadChatMessagesViewModel.logger.info("chatTrace initData unread: oldestUnreadMessage")
                result = .oldestUnreadMessage
            }
        } else {
            ThreadChatMessagesViewModel.logger.info("chatTrace initData unread: localRecentMessages")
            result = .localRecentMessages
        }
        return result
    }

    func initMessages(specifiedPosition: Int32?) {
        self.observeData()
        let initType: MessageInitType
        let chatModel = self._chat
        ThreadChatMessagesViewModel.logger.info(
            "chatTrace new initData: " +
            "\(self._chat.id) \(chatModel.threadBadge) \(chatModel.lastThreadPositionBadgeCount) \(chatModel.readThreadPosition) \(chatModel.readThreadPositionBadgeCount)" +
            "\(chatModel.firstMessagePostion) \(chatModel.bannerSetting?.chatThreadPosition)"
        )
        if chatModel.threadBadge > 0 {
            let position = chatModel.readThreadPosition + 1
            let readPositionBadgeCount = chatModel.readThreadPositionBadgeCount
            let info = FirstUnreadMessageInfo(firstUnreadMessagePosition: position, readPositionBadgeCount: readPositionBadgeCount)
            self.firstUnreadMessageInfo = info
        }
        if let position = specifiedPosition {
            ThreadChatMessagesViewModel.logger.info("chatTrace initData specifiedMessages \(position)")
            initType = .specifiedMessages(position: position)
        } else {
            //全局会话定位配置
            let userSettingStatus = self.dependency
                .userUniversalSettingService
                .getIntUniversalUserSetting(key: "GLOBALLY_ENTER_CHAT_POSITION") ?? Int64(UserUniversalSettingKey.ChatLastPostionSetting.recentLeft.rawValue)
            ThreadChatMessagesViewModel.logger.info("threadChatTrace initData userSettingStatus: \(userSettingStatus)")
            if userSettingStatus == UserUniversalSettingKey.ChatLastPostionSetting.recentLeft.rawValue {
                //1、上次离开的位置
                if chatModel.lastReadPosition != -1 {
                    //1、上次离开的位置
                    initType = .recentLeftMessage
                    ThreadChatMessagesViewModel.logger.info("chatTrace initData unread: recentLeftMessage -\(chatModel.lastReadPosition) - \(chatModel.id)")
                } else {
                    if chatModel.threadBadge > 0 {
                        initType = .oldestUnreadMessage
                        ThreadChatMessagesViewModel.logger.info("chatTrace initData unread: oldestUnreadMessage")
                    } else {
                        initType = .localRecentMessages
                        ThreadChatMessagesViewModel.logger.info("chatTrace initData unread: localRecentMessages")
                    }
                }
            } else if userSettingStatus == UserUniversalSettingKey.ChatLastPostionSetting.lastUnRead.rawValue {
                //2、最后一条未读消息
                if chatModel.threadBadge > 0 {
                    initType = .lastedUnreadMessage
                    ThreadChatMessagesViewModel.logger.info("threadChatTrace initData unread: lastedUnreadMessage")
                } else {
                    initType = .localRecentMessages
                    ThreadChatMessagesViewModel.logger.info("chatTrace initData unread: localRecentMessages")
                }
            } else {
                ThreadChatMessagesViewModel.logger.error("threadChatTrace initData userSettingStatus error \(userSettingStatus)")
                initType = self.threadLocationPackagingMethod(chatModel: chatModel)
            }
        }
        self.loadFirstScreenMessages(initType: initType)
    }

    // MARK: fetch data
    func fetchMissedThreadMessages(positions: [Int32]) {
        guard !positions.isEmpty else {
            self.needFetchMissedData = false
            return
        }

        var channel = RustPB.Basic_V1_Channel()
        channel.id = _chat.id
        channel.type = .chat
        self.dependency.threadAPI.fetchThreadsBy(positions: positions, channel: channel)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (threadMessages, _) in
                guard let self = self else { return }
                self.needFetchMissedData = false
                let handleData = self.handleFetchData(threadMessages: threadMessages)
                let sortedThreadMessages = handleData.threadMessages

                if self.messageDatasource.insertMiss(
                    threads: sortedThreadMessages,
                    readPositionBadgeCount: self.firstUnreadMessageInfo?.readPositionBadgeCount,
                    concurrent: self.concurrentHandler) {
                    self.publish(.refreshMissedMessage)
                } else {
                    ThreadChatMessagesViewModel.logger.info("chatTrace fetchMissedMessages 不在有效范围内 \(self.chatId)")
                }
            }, onError: { (error) in
                self.needFetchMissedData = false
                ThreadChatMessagesViewModel.logger.error("LarkThread error: chatTrace fetchMissedMessages 失败 \(self.chatId)", error: error)
            }).disposed(by: self.disposeBag)
        self.uploadEnterChatDataMissWith(errorCode: 3)
    }

    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)? = nil) {
        guard !loadingMoreOldMessages else {
            finish?(.noWork)
            return
        }
        loadingMoreOldMessages = true
        let minPosition = self.messageDatasource.minPosition
        guard minPosition > self._chat.firstMessagePostion + 1 else {
            //容错逻辑，出现此情况时，强制将footer去除掉
            if self.topLoadMoreReciableKeyInfo != nil {
                self.loadMoreReciableTrackError(loadMoreNew: false, bySDK: false)
                self.topLoadMoreReciableKeyInfo = nil
            }
            updateOldMessageLoadingView(isExist: false)
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
                let sdkCost = Int64(sdkCost * 1000)
                if let loadMoreReciableKeyInfo = self.topLoadMoreReciableKeyInfo {
                    self.loadMoreReciableTrack(key: loadMoreReciableKeyInfo.key, sdkCost: sdkCost, loadMoreNew: false)
                    self.topLoadMoreReciableKeyInfo = nil
                } else {
                    self.loadMoreReciableTrackForPreLoad(sdkCost: sdkCost, loadMoreNew: false)
                }
                self.append(isOldMessages: true, messages: messages, invisiblePositions: invisiblePositions)
                self.loadingMoreOldMessages = false
                finish?(.success(sdkCost: sdkCost, valid: true))
            }, onError: { [weak self] (error) in
                self?.loadMoreReciableTrackError(loadMoreNew: false, bySDK: true)
                self?.topLoadMoreReciableKeyInfo = nil
                self?.loadingMoreOldMessages = false
                self?.errorPublish.onNext(.loadMoreOldMsgFail(error))
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
        guard maxPosition < self._chat.lastVisibleThreadPosition else {
            //容错逻辑，出现此情况时，强制将loadView去除掉
            if self.bottomLoadMoreReciableKeyInfo != nil {
                self.loadMoreReciableTrackError(loadMoreNew: true, bySDK: false)
                self.bottomLoadMoreReciableKeyInfo = nil
            }
            self.publish(.updateFooterView(hasFooter: false))
            loadingMoreNewMessages = false
            finish?(.noWork)
            return
        }
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
                self.append(isOldMessages: false, messages: messages, invisiblePositions: invisiblePositions)
                self.loadingMoreNewMessages = false
                finish?(.success(sdkCost: sdkCost, valid: true))
            }, onError: { [weak self] (error) in
                self?.loadMoreReciableTrackError(loadMoreNew: true, bySDK: true)
                self?.bottomLoadMoreReciableKeyInfo = nil
                self?.loadingMoreNewMessages = false
                self?.errorPublish.onNext(.loadMoreNewMsgFail(error))
                finish?(.error)
            }).disposed(by: self.disposeBag)
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

    //设置最后一条已读消息
    public func setLastRead(messagePosition: Int32, offsetInScreen: CGFloat) {
        ThreadChatMessagesViewModel.logger.info("threadTrace setLastRead \(self._chat.id) \(messagePosition) \(offsetInScreen)")
        dependency.chatAPI.setChatLastRead(chatId: self._chat.id, messagePosition: messagePosition, offsetInScreen: offsetInScreen)
            .subscribe()
            .disposed(by: self.disposeBag)
    }

    //跳到chat最近一条消息
    func jumpToChatLastMessage(finish: (() -> Void)? = nil) {
        let tableScrollPosition = getScrollPostionForJumpToLastesMessage()
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self, self._chat.lastThreadPosition > self._chat.firstMessagePostion else {
                finish?()
                return
            }
            ThreadChatMessagesViewModel.logger.info(
                "chatTrace chatMsgVM jumpToChatLastMessage \(self._chat.id) \(self._chat.lastVisibleThreadPosition) \(self.messageDatasource.maxPosition)"
            )
            if self._chat.lastVisibleThreadPosition <= self.messageDatasource.maxPosition,
                !self.messageDatasource.cellViewModels.isEmpty {
                let index = self.getLastestMessgaeIndex()
                self.publish(.scrollTo(ScrollInfo(index: index, tableScrollPosition: tableScrollPosition)))
                finish?()
                return
            }
            let lastThreadPosition = self._chat.lastThreadPosition
            self.fetchMessageForJump(position: lastThreadPosition, noNext: { [weak self] (messages, invisiblePositions) in
                guard let `self` = self else { return }
                self.messageDatasource.reset(messages: messages,
                                                invisiblePositions: invisiblePositions,
                                                readPositionBadgeCount: self.firstUnreadMessageInfo?.readPositionBadgeCount,
                                                concurrent: self.concurrentHandler)
                let scrollInfo = self.getScrollInfoForJumpTolastesMessage(tableScrollPosition: tableScrollPosition)
                self.publish(self.getRefreshMessages(scrollInfo: scrollInfo))
                finish?()
            }, onError: { error in
                finish?()
                Self.logger.error("chatTrace fetchMessageForJump _chat.lastThreadPosition \(lastThreadPosition) error, error = \(error)")
            })
        }
    }

    /// 不提供messageId,position按成功消息匹配
    func jumpTo(threadPosition: Int32,
                scrollPosition: UITableView.ScrollPosition,
                finish: (() -> Void)? = nil) {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else {
                return
            }
            if let index = self.messageDatasource.index(threadPosition: threadPosition) {
                self.publish(.scrollTo(ScrollInfo(index: index, tableScrollPosition: scrollPosition, highlightPosition: nil)))
                finish?()
                Self.logger.info("chatTrace messageDatasource.index \(index)")
            } else {
                self.fetchMessageForJump(position: threadPosition, noNext: { [weak self] (messages, invisiblePositions) in
                    guard let `self` = self else { return }
                    self.messageDatasource.reset(messages: messages,
                                                 invisiblePositions: invisiblePositions,
                                                 readPositionBadgeCount: self.firstUnreadMessageInfo?.readPositionBadgeCount,
                                                 concurrent: self.concurrentHandler)
                    var scrollInfo: ScrollInfo?
                    if let index = self.messageDatasource.index(threadPosition: threadPosition) {
                        scrollInfo = ScrollInfo(index: index, tableScrollPosition: scrollPosition)
                    }
                    Self.logger.info("chatTrace fetchMessageForJump.scrollInfo \(scrollInfo?.index)")
                    self.publish(self.getRefreshMessages(scrollInfo: scrollInfo))
                    finish?()
                }, onError: { (error) in
                    Self.logger.error("chatTrace fetchMessageForJump \(threadPosition) error, error = \(error)")
                    finish?()
                })
            }
        }
    }

    func jumpToOldestUnreadMessage(finish: (() -> Void)? = nil) {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self, let firstUnreadMessageInfo = self.firstUnreadMessageInfo else {
                finish?()
                return
            }
            let scrollPosition: UITableView.ScrollPosition = .top
            if let newMessageSignIndex = self.messageDatasource.indexForNewMessageSignCell() {
                //如果有新消息线，直接跳到新消息线
                self.publish(.scrollTo(ScrollInfo(index: newMessageSignIndex, tableScrollPosition: scrollPosition)))
                finish?()
                return
            }
            let readPositionBadgeCount = firstUnreadMessageInfo.readPositionBadgeCount
            self.fetchMessageForJump(position: firstUnreadMessageInfo.firstUnreadMessagePosition, noNext: { [weak self] (messages, invisiblePositions) in
                guard let `self` = self else { return }
                self.messageDatasource.reset(messages: messages,
                                                invisiblePositions: invisiblePositions,
                                                readPositionBadgeCount: readPositionBadgeCount,
                                                concurrent: self.concurrentHandler)
                var scrollInfo: ScrollInfo?
                if let indexForNewMessageSignCell = self.messageDatasource.indexForNewMessageSignCell() {
                    scrollInfo = ScrollInfo(index: indexForNewMessageSignCell, tableScrollPosition: scrollPosition)
                }
                self.publish(self.getRefreshMessages(scrollInfo: scrollInfo))
                finish?()
            }, onError: { error in
                Self.logger.error("chatTrace fetchMessageForJump firstUnreadMessageInfo \(firstUnreadMessageInfo.firstUnreadMessagePosition) error, error = \(error)")
                finish?()
            })
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

    func updateNewMessageLoadingView() {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else { return }
            self.publish(self.getUpdateNewMessageLoadingView())
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

    func hasMoreOldMessages() -> Bool {
        ThreadChatMessagesViewModel.logger.info("chatTrace hasMoreOldMessages \(self.messageDatasource.minPosition) -- \(self._chat.firstMessagePostion + 1)")
        // 首屏加载完成后 才能进行加载更多判断
        return firstScreenLoaded && (self.messageDatasource.minPosition > self._chat.firstMessagePostion + 1)
    }

    func hasMoreNewMessages() -> Bool {
        ThreadChatMessagesViewModel.logger.info("chatTrace hasMoreNewMessages \(self.messageDatasource.maxPosition) \(self._chat.lastVisibleThreadPosition)")
        // 首屏加载完成后 才能进行加载更多判断
        return firstScreenLoaded && (self.messageDatasource.maxPosition < self._chat.lastVisibleThreadPosition)
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

    func removeMessages(afterPosition: Int32, redundantCount: Int, finish: @escaping (Int) -> Void) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }
            self.messageDatasource.remove(afterPosition: afterPosition, redundantCount: redundantCount)
            let remainCount = self.messageDatasource.cellViewModels.count
            finish(remainCount)
            ThreadChatMessagesViewModel.logger.info("chatTrace removeMessages after \(self.chatId) \(remainCount)")
            self.publish(.remain(hasLoading: self.hasMoreNewMessages()))
        }
        operation.queuePriority = .veryHigh
        queueManager.addDataProcessOperation(operation)
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

    private func updateOldMessageLoadingView(isExist: Bool) {
        self.publish(.updateHeaderView(hasHeader: isExist))
    }

    private func append(isOldMessages: Bool, messages: [ThreadMessage], invisiblePositions: [Int32]) {
        let sortedData = self.handleFetchData(threadMessages: messages, invisiblePositions: invisiblePositions)
        let sortedMessages = sortedData.threadMessages
        let sortedInvisiblePositions = sortedData.invisiblePositions
        let hasChange: Bool
        if !isOldMessages {
            hasChange = self.messageDatasource.tailAppend(
                messages: sortedMessages,
                invisiblePositions: sortedInvisiblePositions,
                readPositionBadgeCount: self.firstUnreadMessageInfo?.readPositionBadgeCount,
                concurrent: self.concurrentHandler
                )
        } else {
            hasChange = self.messageDatasource.headInsert(
                messages: sortedMessages,
                invisiblePositions: sortedInvisiblePositions,
                concurrent: self.concurrentHandler
                )
        }

        if hasChange {
            let loadOld = TableRefreshType.loadMoreOldMessages(hasLoading: self.hasMoreOldMessages())
            let loadNew = TableRefreshType.loadMoreNewMessages(hasLoading: self.hasMoreNewMessages())
            if isOldMessages {
                self.gcunit?.setWeight(Int64(self.messageDatasource.cellViewModels.count))
            }
            self.publish(isOldMessages ? loadOld : loadNew)
        } else {
            let hasLoadView = isOldMessages ? self.hasMoreOldMessages() : self.hasMoreNewMessages()
            ThreadChatMessagesViewModel.logger.error("LarkThread error: chatTrace 未取得任何有效历史消息")
            if isOldMessages {
                self.publish(.updateHeaderView(hasHeader: hasLoadView))
            } else {
                self.publish(.updateFooterView(hasFooter: hasLoadView))
            }
        }
    }

    private func getUpdateNewMessageLoadingView() -> TableRefreshType {
        return .updateFooterView(hasFooter: self.getHasFooter())
    }

    private func getLastestMessgaeIndex() -> Int {
        return self.messageDatasource.cellViewModels.count - 1
    }

    private func getScrollPostionForJumpToLastesMessage() -> UITableView.ScrollPosition {
        return .bottom
    }

    private func getScrollInfoForJumpTolastesMessage(tableScrollPosition: UITableView.ScrollPosition) -> ScrollInfo? {
        if !self.messageDatasource.cellViewModels.isEmpty {
            let index = self.messageDatasource.cellViewModels.count
            return ScrollInfo(index: index - 1, tableScrollPosition: tableScrollPosition)
        }
        return nil
    }

    private func getRefreshMessages(scrollInfo: ScrollInfo?) -> TableRefreshType {
       return .refreshMessages(hasHeader: getHasHeader(), hasFooter: getHasFooter(), scrollInfo: scrollInfo)
    }

    private func getHasHeader() -> Bool {
        return self.hasMoreOldMessages()
    }

    private func getHasFooter() -> Bool {
        return self.hasMoreNewMessages()
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

    private func getRequestCount() -> Int32 {
        let defaultCount: Int32 = 10
        guard Display.phone, dynamicRequestCountEnable else {
            return defaultCount
        }
        let segementHeight: CGFloat = 44
        // 160 is cell height of the smallest cell
        var count = Int32(((hostUIConfig.size.height - self.navBarHeight - segementHeight) / 160.0).rounded(.up))
        count = (count < 1) ? defaultCount : count
        ThreadChatMessagesViewModel.logger.info("requestCount is \(count)")
        return count
    }

    private func getRedundancyCount() -> Int32 {
        guard Display.phone, dynamicRequestCountEnable else {
            return 5
        }
        return 1
    }

    func adjustMinMessagePosition() {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            let result = self.messageDatasource.adjustMinMessagePosition(readPositionBadgeCount: self.firstUnreadMessageInfo?.readPositionBadgeCount)
            let chat = self._chat
            ThreadChatMessagesViewModel.logger.info("threadTrace chat firstMessagePosition change \(chat.firstMessagePostion) \(chat.id) -- \(result) -\(chat.bannerSetting?.chatThreadPosition)")
            if result {
                self.publish(.refreshTable)
            }
            self.publish(.updateHeaderView(hasHeader: self.hasMoreOldMessages()))
        }
    }
}

// MARK: - Handle Data
private extension ThreadChatMessagesViewModel {
    func loadFirstScreenMessages(initType: MessageInitType) {
        let scene: GetDataScene
        switch initType {
        case .specifiedMessages(position: let position):
            scene = .specifiedPosition(position)
        case .lastedUnreadMessage, .oldestUnreadMessage, .localRecentMessages, .recentLeftMessage:
            scene = .firstScreen
        }
        let firstScreenDataOb = self.getMessages(
            scene: scene,
            redundancyCount: redundancyCount,
            count: requestCount
        ).flatMap({ [weak self] (localResult) -> Observable<GetThreadsResult> in
            guard let `self` = self else { return .empty() }
            // 拉取到SDK本地数据，上传耗时
            ThreadPerformanceTracker.updateRequestCost(trackInfo: localResult.trackInfo)
            if localResult.needFetchRemote == false {
                return .just(localResult)
            } else {
                // 拉取到本地的数据为空 需要从服务端拉取
                self.uploadEnterChatDataMissWith(errorCode: 4)
                return self.fetchMessages(
                    scene: scene,
                    redundancyCount: self.redundancyCount,
                    count: self.requestCount,
                    needReplyPrompt: true
                )
            }
        })

        firstScreenDataOb
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (result) in
                self?.handleFirstScreen(
                    localResult: result,
                    initType: initType
                )
                self?.putReadAgainWhenLoadFirstScreenData(threadMessages: result.threadMessages)
                ThreadChatMessagesViewModel.logger.info("LarkThread: chatTrace loadFirstScreenMessages by \(result.localData) \(self?.chatId)")
        }, onError: { (_) in
            AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                            scene: .Thread,
                                                            event: .enterChat,
                                                            errorType: .SDK,
                                                            errorLevel: .Fatal,
                                                            errorCode: 2,
                                                            userAction: nil,
                                                            page: ThreadChatController.pageName,
                                                            errorMessage: nil,
                                                            extra: Extra(isNeedNet: false,
                                                                         latencyDetail: [:],
                                                                         metric: ThreadPerformanceTracker.reciableExtraMetric(self._chat),
                                                                         category: ThreadPerformanceTracker.reciableExtraCategory(self._chat, type: .Thread))))
            ThreadChatMessagesViewModel.logger.error("LarkThread error: chatTrace loadFirstScreenMessages by remote error")
        }).disposed(by: disposeBag)
    }

    func getMessages(
        scene: GetDataScene,
        redundancyCount: Int32,
        count: Int32) -> Observable<GetThreadsResult> {
        self.logForGetMessages(scene: scene, redundancyCount: redundancyCount, count: count)
        return self.dependency.threadAPI.getThreads(
            channel: self.channel,
            scene: scene,
            redundancyCount: redundancyCount,
            count: count,
            useIncompleteLocalData: true,
            needReplyPrompt: true
        )
    }

    func fetchMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32, needReplyPrompt: Bool) -> Observable<GetThreadsResult> {
        self.logForGetMessages(scene: scene, redundancyCount: redundancyCount, count: count)
        return self.dependency.threadAPI.fetchThreads(channel: self.channel, scene: scene, redundancyCount: redundancyCount, count: count, needReplyPrompt: needReplyPrompt)
            .do(onError: { [weak self] (error) in
                ThreadChatMessagesViewModel.logger.error(
                    "LarkThread error: chatTrace fetchMessages error",
                    additionalData: [
                        "chatId": self?._chat.id ?? "",
                        "scene": "\(scene.description())"
                    ],
                    error: error
                )
            })
    }

    func logForGetMessages(scene: GetDataScene, redundancyCount: Int32, count: Int32) {
        ThreadChatMessagesViewModel.logger.info("chatTrace fetchMessages",
                                          additionalData: [
                                            "chatId": self._chat.id,
                                            "lastMessagePosition": "\(self._chat.lastThreadPosition)",
                                            "lastVisibleMessagePosition": "\(self._chat.lastVisibleThreadPosition)",
                                            "scene": "\(scene.description())",
                                            "count": "\(count)",
                                            "redundancyCount": "\(redundancyCount)"])
    }

    func handleFirstScreen(
        localResult: GetThreadsResult,
        initType: MessageInitType) {
            if !self.messageDatasource.cellViewModels.isEmpty {
                Self
                    .logger
                    .error("LarkThread error: chatTrace 此时数据源不应有数据 \(self._chat.id) \(self.messageDatasource.cellViewModels.count)")
            }
            ThreadPerformanceTracker.startDataRender()
            self.firstScreenLoaded = true
            let handleData = self.handleFetchData(
                threadMessages: localResult.threadMessages,
                invisiblePositions: localResult.invisiblePositions,
                missedPositions: localResult.missedPositions
            )

            let threadMessages = handleData.threadMessages
            let invisiblePositions = handleData.invisiblePositions
            let missedPositions = handleData.missedPositions

            var scrollInfo: ScrollInfo?
            switch initType {
            case .specifiedMessages(position: let position):
                self.highlightPosition = position
                self.messageDatasource.reset(
                    messages: threadMessages,
                    invisiblePositions: invisiblePositions,
                    missedPositions: missedPositions,
                    readPositionBadgeCount: self.firstUnreadMessageInfo?.readPositionBadgeCount,
                    concurrent: self.concurrentHandler)
                if let scrollIndex = self.messageDatasource.index(messagePosition: position) {
                    scrollInfo = getScrollInfoForMessagePositon(
                        messageInitType: .specifiedMessages(position: position),
                        scrollIndex: scrollIndex
                    )
                } else {
                    ThreadChatMessagesViewModel.logger.error("LarkThread error: chatTrace initBySpecifiedMessages 没找到指定消息index")
                }
            case .recentLeftMessage:
                self.messageDatasource.reset(
                    messages: threadMessages,
                    invisiblePositions: invisiblePositions,
                    missedPositions: missedPositions,
                    readPositionBadgeCount: self.firstUnreadMessageInfo?.readPositionBadgeCount,
                    concurrent: self.concurrentHandler
                )
                if !self.messageDatasource.cellViewModels.isEmpty {
                    if let scrollIndex = self.messageDatasource.index(messagePosition: self._chat.lastReadPosition) {
                        scrollInfo = getScrollInfoForMessagePositon(
                            messageInitType: .recentLeftMessage,
                            scrollIndex: scrollIndex
                        )
                        ThreadChatMessagesViewModel.logger.info("LarkThread recentLeftMessage scrollIndex --\(self._chat.lastReadPosition) -\(scrollIndex)")
                    } else {
                        ThreadChatMessagesViewModel.logger.error("LarkThread initByRecentLeftMessage 没找到recentLeftMessage index")
                    }
                }
            case .localRecentMessages:
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
            case .lastedUnreadMessage:
                self.messageDatasource.reset(
                    messages: threadMessages,
                    invisiblePositions: invisiblePositions,
                    missedPositions: missedPositions,
                    readPositionBadgeCount: self.firstUnreadMessageInfo?.readPositionBadgeCount,
                    concurrent: self.concurrentHandler
                )
                if !self.messageDatasource.cellViewModels.isEmpty {
                    scrollInfo = getScrollInfoForMessagePositon(
                        messageInitType: .lastedUnreadMessage,
                        scrollIndex: 0
                    )
                }
            case .oldestUnreadMessage:
                self.messageDatasource.reset(
                    messages: threadMessages,
                    invisiblePositions: invisiblePositions,
                    missedPositions: missedPositions,
                    readPositionBadgeCount: self.firstUnreadMessageInfo?.readPositionBadgeCount,
                    concurrent: self.concurrentHandler
                )
                if let scrollIndex = self.messageDatasource.indexForNewMessageSignCell() {
                    scrollInfo = getScrollInfoForMessagePositon(
                        messageInitType: .oldestUnreadMessage,
                        scrollIndex: scrollIndex
                    )
                } else {
                     if !self.messageDatasource.cellViewModels.isEmpty {
                        let idx = self.messageDatasource.cellViewModels.count - 1
                        scrollInfo = ScrollInfo(index: idx, tableScrollPosition: .bottom)
                        ThreadChatMessagesViewModel.logger.info("LarkThread info: chatTrace oldestUnreadMessage not find newline jump to bottom -\(idx)")
                    } else {
                        ThreadChatMessagesViewModel.logger.error("LarkThread error: chatTrace oldestUnreadMessage not find newline due to data is empty")
                    }
                }
            }

            self.needFetchMissedData = localResult.localData && !missedPositions.isEmpty
            let initInfo = InitMessagesInfo(
                hasHeader: getHasHeader(),
                hasFooter: getHasFooter(),
                newReplyCount: localResult.newReplyCount,
                newAtReplyMessages: localResult.newAtReplyMessages,
                newAtReplyCount: localResult.newAtReplyCount,
                scrollInfo: scrollInfo,
                initType: initType
            )
            self.publish(.initMessages(initInfo, needHightlight: scrollInfo?.highlightPosition != nil))
            if localResult.localData {
                let missedPositionsStr = missedPositions.reduce("") { partialResult, position in
                    return partialResult + ", \(position)"
                }
                ThreadChatMessagesViewModel.logger.info("LarkThread chatTrace fetchMissedThreadMessages \(missedPositions.count) - \(missedPositionsStr) -\(self.chatId))")
                self.fetchMissedThreadMessages(positions: missedPositions)
            }
    }

    enum LoadMoreDirection {
        case previous
        case after
    }

    func loadMoreMessages(position: Int32, direction: LoadMoreDirection) -> Observable<([ThreadMessage], invisiblePositions: [Int32], requestCost: Double)> {
        var scene: GetDataScene
        switch direction {
        case .previous:
            scene = .previous(before: position + 1)
        case .after:
            scene = .after(after: position - 1)
        }

        return self.fetchMessages(scene: scene, redundancyCount: 0, count: 15, needReplyPrompt: false).map({ (result) -> ([ThreadMessage], invisiblePositions: [Int32], requestCost: Double) in
            ThreadChatMessagesViewModel.logger.info("loadMoreMessages by serverData")
            return (result.threadMessages, invisiblePositions: result.invisiblePositions, requestCost: result.trackInfo.requestCost)
        }).observeOn(self.queueManager.dataScheduler)
    }

    func fetchMessageForJump(position: Int32, noNext: @escaping ([ThreadMessage], [Int32]) -> Void, onError: ((Error) -> Void)? = nil) {
        self.pauseQueue()
        self.fetchMessages(scene: .specifiedPosition(position), redundancyCount: redundancyCount, count: requestCount, needReplyPrompt: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let handleData = self?.handleFetchData(threadMessages: result.threadMessages, invisiblePositions: result.invisiblePositions) else {
                    return
                }
                let refreshMessagesOperation = BlockOperation(block: { noNext(handleData.threadMessages, handleData.invisiblePositions) })
                refreshMessagesOperation.queuePriority = .high
                self?.queueManager.addDataProcessOperation(refreshMessagesOperation)
                self?.resumeQueue()
            }, onError: { [weak self] (error) in
                self?.errorPublish.onNext(.jumpFail(error))
                self?.resumeQueue()
                onError?(error)
            }).disposed(by: self.disposeBag)
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
        self.tableRefreshPublish.onNext((type, newDatas: dataUpdate ? self.messageDatasource.cellViewModels : nil, outOfQueue: outOfQueue))
    }

    func observeData() {
        self.pushHandlerRegister.startObserve(self)
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

        self.dependency.threadMessageObservable
            .observeOn(self.queueManager.dataScheduler)
            .do(onNext: { [weak self] (messages) in
                guard let self = self, self.firstScreenLoaded else { return }
                if messages.contains(where: { (threadMessage) -> Bool in
                    return threadMessage.localStatus != .success && self.messageDatasource.index(cid: threadMessage.cid) == nil
                }) {
                    self.jumpToChatLastMessage()
                }
            })
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (threadMessages) in
                guard let `self` = self, self.firstScreenLoaded else { return }
                var needUpdate = false
                for threadMessage in threadMessages {
                    let result = self.messageDatasource.handle(threadMessage: threadMessage)
                    switch result {
                    case .none:
                        continue
                    case .newMessage:
                        self.publish(.hasNewMessage(hasLoading: self.hasMoreNewMessages()))
                    case .messageSendSuccess:
                        needUpdate = true
                        self.publish(.hasNewMessage(hasLoading: self.hasMoreNewMessages()))
                    case .updateMessage:
                        needUpdate = true
                    }
                }
                if needUpdate {
                    self.publish(.refreshTable)
                }
                let messages = threadMessages.flatMap({ [$0.rootMessage] + $0.replyMessages + $0.latestAtMessages })
                self.dependency.urlPreviewService.fetchMissingURLPreviews(messages: messages)
            }).disposed(by: self.disposeBag)

        self.dependency.messagesObservable
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages) in
                guard let `self` = self else { return }
                var hasUpdate: Bool = false
                for message in messages {
                    if self.messageDatasource.update(rootMessage: message) {
                        hasUpdate = true
                    }
                }
                if hasUpdate {
                    self.publish(.refreshTable)
                }
                self.dependency.urlPreviewService.fetchMissingURLPreviews(messages: messages)
            }).disposed(by: self.disposeBag)

        self.dependency.is24HourTime
            .skip(1)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.messageDatasource.refreshRenders()
                self?.publish(.refreshTable)
            }).disposed(by: disposeBag)
    }

    /// 进入ThreadChat时对已经发过已读的rootMessage再发一次已读请求，SDK对于特殊场景下删除的话题无法修正badge，需要前端再触发一次已读来修改。
    private func putReadAgainWhenLoadFirstScreenData(threadMessages: [ThreadMessage]) {
        if let readMessage = threadMessages.first(where: { (threadMessage) -> Bool in
            return threadMessage.rootMessage.meRead
        }) {
            ThreadChatMessagesViewModel.logger.info("chatTrace put read again \(readMessage.id)")
            self.dependency.threadAPI.updateThreadsMeRead(
                channel: channel,
                threadIds: [readMessage.thread.id],
                readPosition: readMessage.thread.position,
                readPositionBadgeCount: readMessage.thread.originBadgeCount
            )
        }
    }

    func send(update: Bool) {
        if update {
            self.publish(.refreshTable)
        }
    }
}

// MARK: - extension DataSourceAPI
extension ThreadChatMessagesViewModel: DataSourceAPI {
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
        return topNoticeSubject
    }
}

// MARK: - extension HandlePushDataSourceAPI
extension ThreadChatMessagesViewModel: HandlePushDataSourceAPI {
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
extension ThreadChatMessagesViewModel: ThreadListViewModel {
    func putRead(threadMessage: ThreadMessage) {
        self.dependency.readService.putRead(element: threadMessage, urgentConfirmed: nil)
    }

    func loadMoreBottomMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
            loadMoreNewMessages(finish: finish)
    }

    func loadMoreTopMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
            loadMoreOldMessages(finish: finish)
    }
}

// MARK: - Others
extension ThreadMessage: PushData {
    public var message: Message {
        return self.rootMessage
    }
}

extension GetDataScene {
    func description() -> String {
        switch self {
        case .firstScreen:
            return "firstScreen"
        case .previous(before: let position):
            return "previous from \(position)"
        case .after(after: let position):
            return "after from \(position)"
        case .specifiedPosition(let position):
            return "specifiedPosition \(position)"
        }
    }
}

//AppReciableTrack
private extension ThreadChatMessagesViewModel {
    func loadMoreReciableTrack(key: DisposedKey?, sdkCost: Int64, loadMoreNew: Bool) {
        if let key = key {
            let chat = self._chat
            var category = ThreadPerformanceTracker.reciableExtraCategory(chat, type: .Thread)
            category["load_type"] = loadMoreNew
            AppReciableSDK.shared.end(key: key, extra: Extra(isNeedNet: true,
                                                             latencyDetail: ["sdk_cost": sdkCost],
                                                             metric: ThreadPerformanceTracker.reciableExtraMetric(chat),
                                                             category: category))
        }
    }

    func loadMoreReciableTrackError(loadMoreNew: Bool, bySDK: Bool) {
        let chat = self._chat
        var category = ThreadPerformanceTracker.reciableExtraCategory(chat, type: .Thread)
        category["load_type"] = loadMoreNew
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Thread,
                                                        event: .loadMoreMessageTime,
                                                        errorType: bySDK ? .SDK : .Other,
                                                        errorLevel: bySDK ? .Fatal : .Exception,
                                                        errorCode: bySDK ? 1 : 0,
                                                        userAction: nil,
                                                        page: ThreadChatController.pageName,
                                                        errorMessage: nil,
                                                        extra: Extra(isNeedNet: bySDK,
                                                                     latencyDetail: [:],
                                                                     metric: ThreadPerformanceTracker.reciableExtraMetric(chat),
                                                                     category: category)))
    }

    func loadMoreReciableTrackForPreLoad(sdkCost: Int64, loadMoreNew: Bool) {
        let chat = self._chat
        var category = ThreadPerformanceTracker.reciableExtraCategory(chat, type: .Thread)
        category["load_type"] = loadMoreNew
        AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                              scene: .Thread,
                                                              event: .loadMoreMessageTime,
                                                              cost: -1,
                                                              page: ThreadChatController.pageName,
                                                              extra: Extra(isNeedNet: true,
                                                                           latencyDetail: ["sdk_cost": sdkCost],
                                                                           metric: ThreadPerformanceTracker.reciableExtraMetric(chat),
                                                                           category: category)))
    }

    /// 上报进入首屏数据缺失的情况
    /// - Parameter errorCode: 错误码
    private func uploadEnterChatDataMissWith(errorCode: Int) {
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Thread,
                                                        event: .enterChat,
                                                        errorType: .SDK,
                                                        errorLevel: .Exception,
                                                        errorCode: errorCode,
                                                        userAction: nil,
                                                        page: ThreadChatController.pageName,
                                                        errorMessage: nil,
                                                        extra: Extra(isNeedNet: true,
                                                                     latencyDetail: [:],
                                                                     metric: ThreadPerformanceTracker.reciableExtraMetric(self._chat),
                                                                     category: ThreadPerformanceTracker.reciableExtraCategory(self._chat, type: .Thread))))
    }
}
