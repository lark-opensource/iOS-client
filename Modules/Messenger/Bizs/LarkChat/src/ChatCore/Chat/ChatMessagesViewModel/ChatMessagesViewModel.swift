//
//  ChatMessagesViewModel.swift
//  LarkChat
//
//  Created by zc09v on 2018/3/28.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import RxSwift
import LarkModel
import RxCocoa
import LarkFoundation
import LKCommonsLogging
import LarkUIKit
import LarkCore
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import LarkPerf
import LarkMessengerInterface
import AppReciableSDK
import RustPB
import LarkStorage
import LarkFeatureGating
import LarkTracing
import UIKit
import LarkContainer
import LarkSetting

/// 第一条未读消息相关信息
struct FirstUnreadMessageInfo {
    let firstUnreadMessagePosition: Int32
    let readPositionBadgeCount: Int32
}

final class LoadMoreReciableKeyInfo {
    let key: DisposedKey
    let timeStamp: TimeInterval

    init(key: DisposedKey) {
        self.key = key
        self.timeStamp = CACurrentMediaTime()
    }

    class func generate() -> LoadMoreReciableKeyInfo {
        let key = AppReciableSDK.shared.start(biz: .Messenger, scene: .Chat, event: .loadMoreMessageTime, page: ChatMessagesViewController.pageName)
        return LoadMoreReciableKeyInfo(key: key)
    }
}

enum ChatBatchSelectMessageStatus {
    case initHud
    case loadingHud
    case removeHud(showLimit: Bool)
}

typealias GetBufferPushMessagesHandler = (_ range: (minPosition: Int32, maxPosition: Int32)?) -> [Message]

/// TODO: @zhaochen，这个类应该尝试做密聊隔离。
/// 处理chat页面消息相关逻辑
class ChatMessagesViewModel: AsyncDataProcessViewModel<ChatTableRefreshType, [ChatCellViewModel]>, AfterFirstScreenMessagesRenderDelegate {
    enum ErrorType {
        case jumpFail(Error)
        case loadMoreOldMsgFail(Error)
        case loadMoreNewMsgFail(Error)
    }

    static let logger = Logger.log(ChatMessagesViewModel.self, category: "Business.Chat")
    static let redundancyCount: Int32 = 5
    static let requestCount: Int32 = 15
    /// impl for CellConfigProxy
    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?

    let topNoticeSubject: BehaviorSubject<ChatTopNotice?> = BehaviorSubject(value: nil)
    let dependency: ChatMessagesVMDependency

    var disposeBag = DisposeBag()
    let userResolver: UserResolver

    var messageDatasource: ChatMessagesDatasource
    var chatDataContext: ChatDataContextProtocol
    var chatDataProvider: ChatDataProviderProtocol

    let pickedMessages = BehaviorRelay<[ChatSelectedMessageContext]>(value: [])
    let inSelectMode: BehaviorRelay<Bool>
    private let supportUserUniversalLastPostionSetting: Bool
    struct SelectedMessageModel: ChatSelectedMessageContext {
        var id: String
        var type: Message.TypeEnum
        var message: Message?
        var extraInfo: [String: Any]

        init(id: String, type: Message.TypeEnum, extraInfo: [String: Any] = [:]) {
            self.id = id
            self.type = type
            self.message = nil
            self.extraInfo = extraInfo
        }

        init(message: Message, extraInfo: [String: Any] = [:]) {
            self.id = message.id
            self.type = message.type
            self.message = message
            self.extraInfo = extraInfo
        }
    }

    let chatWrapper: ChatPushWrapper
    var chat: Chat {
        return self.chatWrapper.chat.value
    }
    lazy var chatId: String = {
        return self.chat.id
    }()

    var firstUnreadMessageInfo: FirstUnreadMessageInfo?

    var cellViewModelsCount: Int {
        self.messageDatasource.cellViewModels.count
    }

    /// 防止反复调用
    private var loadingMoreOldMessages: Bool = false
    private var loadingMoreNewMessages: Bool = false
    var topLoadMoreReciableKeyInfo: LoadMoreReciableKeyInfo?
    var bottomLoadMoreReciableKeyInfo: LoadMoreReciableKeyInfo?

    private let pushHandlerRegister: ChatPushHandlersRegister

    private(set) var firstScreenLoaded: Bool = false

    /// 获取首屏数据时收到的PUSH消息
    private var bufferPushMessages: GetBufferPushMessagesHandler?

    let gcunit: GCUnit?

    private let errorPublish = PublishSubject<ChatMessagesViewModel.ErrorType>()
    var errorDriver: Driver<ChatMessagesViewModel.ErrorType> {
        return errorPublish.asDriver(onErrorRecover: { _ in Driver<ErrorType>.empty() })
    }
    let context: ChatContext
    private let isMe: (_ chatterID: String, _ chat: Chat) -> Bool

    private lazy var _supportAvatarLeftRightLayout: Bool = {
        let conf = KVPublic.Setting.chatSupportAvatarLeftRight(fgService: try? self.userResolver.resolve(assert: FeatureGatingService.self))
        Self.logger.info("messenger.message_settings_bubble_alignment \(conf.key.defaultValue)")
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "messenger.message_settings_bubble_alignment"))
            && conf.value()
    }()

    deinit {
        print("NewChat: ChatMessagesViewModel deinit")
        self.chatWrapper.decreaseSubscriber(chatId: self.chatId)
        self.dependency.chatKeyPointTracker.leaveChat()
    }

    init(
        userResolver: UserResolver,
        messagesDatasource: ChatMessagesDatasource,
        chatDataContext: ChatDataContextProtocol,
        chatDataProvider: ChatDataProviderProtocol,
        dependency: ChatMessagesVMDependency,
        context: ChatContext,
        chatWrapper: ChatPushWrapper,
        pushHandlerRegister: ChatPushHandlersRegister,
        inSelectMode: Bool,
        supportUserUniversalLastPostionSetting: Bool,
        gcunit: GCUnit?
    ) {
        let chat = chatWrapper.chat.value
        self.dependency = dependency
        self.inSelectMode = BehaviorRelay<Bool>(value: inSelectMode)
        self.supportUserUniversalLastPostionSetting = supportUserUniversalLastPostionSetting
        self.context = context
        self.isMe = context.isMe
        self.messageDatasource = messagesDatasource
        self.chatDataContext = chatDataContext
        self.chatDataProvider = chatDataProvider
        self.chatWrapper = chatWrapper
        self.chatWrapper.increaseSubscriber(chatId: chat.id)
        self.pushHandlerRegister = pushHandlerRegister
        self.gcunit = gcunit
        self.userResolver = userResolver
        super.init(uiDataSource: [])
        self.messageDatasource.container = self
    }

    func locationPackagingMethod(chatModel: Chat) -> MessageInitType {
        let result: MessageInitType
        if chatModel.messagePosition == .recentLeft {
            if chatModel.lastReadPosition != -1 {
                // 定位到上次离开位置
                result = .recentLeftMessage
                ChatMessagesViewModel.logger.info("chatTrace initData recentLeftMessage \(chatModel.lastReadPosition) \(chatModel.lastReadOffset)")
            } else {
                // 定位到最远未读消息
                result = .oldestUnreadMessage
                ChatMessagesViewModel.logger.info("chatTrace initData unread: oldestUnreadMessage")
            }
        } else {
            // 定位到最近未读消息
            result = .lastedUnreadMessage
            ChatMessagesViewModel.logger.info("chatTrace initData unread: lastedUnreadMessage")
        }
        return result
    }

    func initMessages(positionStrategy: ChatMessagePositionStrategy?,
                      firstScreenMessagesObservable: Observable<GetChatMessagesResult>,
                      bufferPushMessages: @escaping GetBufferPushMessagesHandler) {

        self.bufferPushMessages = bufferPushMessages
        onInitializeMessages()
        firstScreenMessagesObservable
            .do(onNext: { [weak self] (_) in
                ChatMessagesViewModel.logger.info("chatTrace firstScreenDataOb callback \(self?.chatId ?? "") \(self?.queueManager.queueIsPause() ?? false)")
            })
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.initMessages, parentName: LarkTracingUtil.firstScreenMessagesRender)
                let loadTrackInfo = self.dependency.chatKeyPointTracker.loadTrackInfo
                loadTrackInfo?.renderStart = CACurrentMediaTime()
                let initType: MessageInitType
                let chatModel = self.chat
                if chatModel.badge > 0 {
                    let position = self.chatDataContext.readPosition + 1
                    let readPositionBadgeCount = self.chatDataContext.readPositionBadgeCount
                    let info = FirstUnreadMessageInfo(firstUnreadMessagePosition: position, readPositionBadgeCount: readPositionBadgeCount)
                    self.firstUnreadMessageInfo = info
                    self.messageDatasource.readPositionBadgeCount = readPositionBadgeCount
                }

                if let positionStrategy = positionStrategy {
                    switch positionStrategy {
                    case .position(let position):
                        ChatMessagesViewModel.logger.info("chatTrace initData specifiedMessages \(position)")
                        self.messageDatasource.setHighlightInfo(HighlightMessageInfo(position: position))
                        initType = .specifiedMessages(position: position)
                    case .toLatestPositon:
                        ChatMessagesViewModel.logger.info("chatTrace initData toLatestPositon")
                        initType = .lastedMessage
                    }
                } else {
                    //全局会话定位配置
                    if self.supportUserUniversalLastPostionSetting {
                        let userSettingStatus = self.dependency
                            .userUniversalSettingService?
                            .getIntUniversalUserSetting(key: "GLOBALLY_ENTER_CHAT_POSITION") ?? Int64(UserUniversalSettingKey.ChatLastPostionSetting.recentLeft.rawValue)
                        ChatMessagesViewModel.logger.info("chatTrace initData userSettingStatus: \(userSettingStatus)")
                        if userSettingStatus == UserUniversalSettingKey.ChatLastPostionSetting.recentLeft.rawValue {
                            if chatModel.lastReadPosition != -1 {
                                //1、上次离开的位置
                                initType = .recentLeftMessage
                                ChatMessagesViewModel.logger.info("chatTrace initData recentLeftMessage \(chatModel.lastReadPosition) \(chatModel.lastReadOffset)")
                            } else {
                                initType = .oldestUnreadMessage
                                ChatMessagesViewModel.logger.info("chatTrace initData unread: oldestUnreadMessage")
                            }
                        } else if userSettingStatus == UserUniversalSettingKey.ChatLastPostionSetting.lastUnRead.rawValue {
                            //2、最后一条未读消息
                            initType = .lastedUnreadMessage
                            ChatMessagesViewModel.logger.info("chatTrace initData unread: lastedUnreadMessage")
                        } else {
                            ChatMessagesViewModel.logger.error("chatTrace initData userSettingStatus error \(userSettingStatus)")
                            initType = self.locationPackagingMethod(chatModel: chatModel)
                        }
                    } else {
                        initType = self.locationPackagingMethod(chatModel: chatModel)
                    }
                }
                self.handleFirstScreen(result: result, initType: initType)
                LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.initMessages)
                ChatMessagesViewModel.logger.info("chatTrace loadFirstScreenMessages by \(result.localData)")
            }, onError: { [weak self] (error) in
                self?.cleanBufferPushMessages()
                ChatMessagesViewModel.logger.error("chatTrace loadFirstScreenMessages error", error: error)
                let loadTrackInfo = self?.dependency.chatKeyPointTracker.loadTrackInfo
                AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                                scene: .Chat,
                                                                event: .enterChat,
                                                                errorType: .SDK,
                                                                errorLevel: .Fatal,
                                                                errorCode: 2,
                                                                userAction: nil,
                                                                page: ChatMessagesViewController.pageName,
                                                                errorMessage: nil,
                                                                extra: Extra(isNeedNet: self?.chat.isCrypto ?? false ? true : false,
                                                                             latencyDetail: [:],
                                                                             metric: loadTrackInfo?.reciableExtraMetric ?? [:],
                                                                             category: loadTrackInfo?.reciableExtraCategory ?? [:])))
            }).disposed(by: self.disposeBag)
        self.observeData()
    }

    func onInitializeMessages() {
    }

    func afterMessagesRender() {
        pushHandlerRegister.startObserve(self)
        pushHandlerRegister.performCachePush(api: self)
    }

    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)? = nil) {
        guard !loadingMoreOldMessages else {
            finish?(.noWork)
            return
        }
        loadingMoreOldMessages = true
        let minPosition = self.messageDatasource.minMessagePosition

        guard minPosition > self.chatDataContext.firstMessagePosition + 1 else {
            // 容错逻辑，出现此情况时，强制将header去除掉
            if self.topLoadMoreReciableKeyInfo != nil {
                self.loadMoreReciableTrackError(loadMoreNew: false, bySDK: false)
                self.topLoadMoreReciableKeyInfo = nil
            }
            self.publish(.updateHeaderView(hasHeader: false))
            loadingMoreOldMessages = false
            finish?(.noWork)
            return
        }
        self.loadMoreMessages(position: minPosition, pullType: .before, sceneForLog: "loadMoreOld")
            .subscribe(onNext: { [weak self] (messages, totalRange, sdkCost) in
                guard let `self` = self else {
                    finish?(.noWork)
                    return
                }
                let sdkCost = Int64(sdkCost)
                let result = self.messageDatasource.headAppend(messages: messages,
                                                               totalRange: totalRange,
                                                                  concurrent: self.concurrentHandler)
                if let loadMoreReciableKeyInfo = self.topLoadMoreReciableKeyInfo {
                    self.loadMoreReciableTrack(key: loadMoreReciableKeyInfo.key, sdkCost: sdkCost, loadMoreNew: false)
                    self.topLoadMoreReciableKeyInfo = nil
                } else {
                    self.loadMoreReciableTrackForPreLoad(sdkCost: sdkCost, loadMoreNew: false)
                }
                if result != .none {
                    self.gcunit?.setWeight(Int64(self.cellViewModelsCount))
                    self.publish(.loadMoreOldMessages(hasHeader: self.hasMoreOldMessages()))
                } else {
                    ChatMessagesViewModel.logger.error("chatTrace \(self.chat.id) 未取得任何有效新消息")
                    self.publish(.updateHeaderView(hasHeader: self.hasMoreOldMessages()))
                }
                self.loadingMoreOldMessages = false
                finish?(.success(sdkCost: sdkCost, valid: result != .none))
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
        loadingMoreNewMessages = true

        let maxPosition = self.messageDatasource.maxMessagePosition
        guard maxPosition < self.chatDataContext.lastVisibleMessagePosition else {
            // 容错逻辑，出现此情况时，强制将footer去除掉
            if self.bottomLoadMoreReciableKeyInfo != nil {
                self.loadMoreReciableTrackError(loadMoreNew: true, bySDK: false)
                self.bottomLoadMoreReciableKeyInfo = nil
            }
            self.publish(.updateFooterView(hasFooter: false))
            loadingMoreNewMessages = false
            finish?(.noWork)
            return
        }
        self.loadMoreMessages(position: maxPosition, pullType: .after, sceneForLog: "loadMoreNew")
            .subscribe(onNext: { [weak self] (messages, totalRange, sdkCost) in
                guard let `self` = self else {
                    finish?(.noWork)
                    return
                }
                let sdkCost = Int64(sdkCost)
                let result = self.messageDatasource.tailAppend(
                    messages: messages,
                    totalRange: totalRange,
                    concurrent: self.concurrentHandler
                )
                if let loadMoreReciableKeyInfo = self.bottomLoadMoreReciableKeyInfo {
                    self.loadMoreReciableTrack(key: loadMoreReciableKeyInfo.key, sdkCost: sdkCost, loadMoreNew: true)
                    self.bottomLoadMoreReciableKeyInfo = nil
                } else {
                    self.loadMoreReciableTrackForPreLoad(sdkCost: sdkCost, loadMoreNew: true)
                }
                if result != .none {
                    self.publish(.loadMoreNewMessages(hasFooter: self.hasMoreNewMessages()))
                } else {
                    ChatMessagesViewModel.logger.error("chatTrace \(self.chat.id) 未取得任何有效新消息")
                    self.publish(.updateFooterView(hasFooter: self.hasMoreNewMessages()))
                }
                self.loadingMoreNewMessages = false
                finish?(.success(sdkCost: sdkCost, valid: result != .none))
            }, onError: { [weak self] (error) in
                self?.loadMoreReciableTrackError(loadMoreNew: true, bySDK: true)
                self?.bottomLoadMoreReciableKeyInfo = nil
                self?.loadingMoreNewMessages = false
                self?.errorPublish.onNext(.loadMoreNewMsgFail(error))
                finish?(.error)
            }).disposed(by: self.disposeBag)
    }

    enum JumpStatus {
        case start
        case finishByRequest //做了接口请求
        case finshDirect //直接跳转
        case error
    }

    /// 跳到chat最后一条消息
    func jumpToChatLastMessage(tableScrollPosition: UITableView.ScrollPosition, needDuration: Bool = true, finish: ((ChatKeyPointTracker.CostTrackInfo?) -> Void)? = nil) {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else {
                return
            }
            ChatMessagesViewModel.logger.info(
                "chatTrace chatMsgVM jumpToChatLastMessage \(self.chat.id) \(self.chatDataProvider.identify) \(self.chatDataContext.lastVisibleMessagePosition) \(self.messageDatasource.maxMessagePosition)"
            )
            if self.chatDataContext.lastVisibleMessagePosition <= self.messageDatasource.maxMessagePosition,
                !self.messageDatasource.cellViewModels.isEmpty {
                let index = self.cellViewModelsCount - 1
                self.publish(.scrollTo(ScrollInfo(index: index, tableScrollPosition: tableScrollPosition, needDuration: needDuration)))
                finish?(ChatKeyPointTracker.CostTrackInfo(bySDK: false))
                return
            }
            let specifiedPosition = self.chatDataContext.lastMessagePosition
            guard specifiedPosition > self.chatDataContext.firstMessagePosition else {
                ChatMessagesViewModel.logger.info("chatTrace chatMsgVM jumpToChatLastMessage position error \(self.chat.id) \(specifiedPosition) \(self.chatDataContext.firstMessagePosition)")
                finish?(nil)
                return
            }
            let sdkStart = CACurrentMediaTime()
            self.fetchMessageForJump(position: specifiedPosition, noNext: { [weak self] (messages, totalRange) in
                let sdkCost = ChatKeyPointTracker.cost(startTime: sdkStart)
                let clientStart = CACurrentMediaTime()
                self?.messageDatasource.merge(messages: messages,
                                              totalRange: totalRange,
                                              concurrent: self?.concurrentHandler ?? { _, _ in })
                let clientCost = ChatKeyPointTracker.cost(startTime: clientStart)
                var scrollInfo: ScrollInfo?
                if let index = self?.cellViewModelsCount, !(self?.messageDatasource.cellViewModels.isEmpty ?? true) {
                    scrollInfo = ScrollInfo(index: index - 1, tableScrollPosition: tableScrollPosition)
                    scrollInfo?.needDuration = needDuration
                }
                self?.publish(.refreshMessages(hasHeader: self?.hasMoreOldMessages() ?? false, hasFooter: self?.hasMoreNewMessages() ?? false, scrollInfo: scrollInfo))
                finish?(ChatKeyPointTracker.CostTrackInfo(bySDK: true, clientCost: clientCost, sdkCost: sdkCost))
            }, onError: { _ in
                finish?(nil)
            })
        }
    }

    /// 跳转到最老一条未读消息
    func jumpToOldestUnreadMessage(finish: ((ChatKeyPointTracker.CostTrackInfo?) -> Void)? = nil) {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self, let firstUnreadMessageInfo = self.firstUnreadMessageInfo else {
                finish?(nil)
                return
            }
            if let newMessageSignIndex = self.messageDatasource.indexForNewMessageSignCell() {
                // 如果有新消息线，直接跳到新消息线
                self.publish(.scrollTo(ScrollInfo(index: newMessageSignIndex, tableScrollPosition: .top)))
                finish?(ChatKeyPointTracker.CostTrackInfo(bySDK: false))
                return
            }
            let sdkStart = CACurrentMediaTime()
            self.fetchMessageForJump(position: firstUnreadMessageInfo.firstUnreadMessagePosition, noNext: { [weak self] (messages, totalRange) in
                let sdkCost = ChatKeyPointTracker.cost(startTime: sdkStart)
                let clientStart = CACurrentMediaTime()
                self?.messageDatasource.merge(messages: messages,
                                              totalRange: totalRange,
                                              concurrent: self?.concurrentHandler ?? { _, _ in })
                let clientCost = ChatKeyPointTracker.cost(startTime: clientStart)
                var scrollInfo: ScrollInfo?
                if let indexForNewMessageSignCell = self?.messageDatasource.indexForNewMessageSignCell() {
                    scrollInfo = ScrollInfo(index: indexForNewMessageSignCell, tableScrollPosition: .top)
                }
                self?.publish(.refreshMessages(hasHeader: self?.hasMoreOldMessages() ?? false, hasFooter: self?.hasMoreNewMessages() ?? false, scrollInfo: scrollInfo))
                finish?(ChatKeyPointTracker.CostTrackInfo(bySDK: true, clientCost: clientCost, sdkCost: sdkCost))
            }, onError: { _ in
                finish?(nil)
            })
        }
    }

    /// 不提供messageId,position按成功消息匹配
    func jumpTo(position: Int32,
                messageId: String? = nil,
                tableScrollPosition: UITableView.ScrollPosition?,
                needHighlight: Bool = false,
                jumpStatus: ((JumpStatus) -> Void)? = nil,
                finish: ((ChatKeyPointTracker.CostTrackInfo?) -> Void)? = nil) {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else {
                return
            }
            guard position > self.chatDataContext.firstMessagePosition else {
                ChatMessagesViewModel.logger.info("chatTrace chatMsgVM jumpTo position error \(self.chat.id) \(position) \(self.chatDataContext.firstMessagePosition)")
                finish?(nil)
                return
            }
            if needHighlight {
                self.messageDatasource.setHighlightInfo(HighlightMessageInfo(position: position, messageId: messageId))
            }
            if let index = self.messageDatasource.index(messagePosition: position, messageId: messageId) {
                jumpStatus?(.finshDirect)
                self.publish(.scrollTo(ScrollInfo(index: index,
                                                  tableScrollPosition: tableScrollPosition,
                                                  highlightPosition: needHighlight ? self.updateTargetPostionIfNeedFor(cellIndex: index,
                                                                                                                  position: position) : nil)))
                finish?(ChatKeyPointTracker.CostTrackInfo(bySDK: false))
            } else {
                jumpStatus?(.start)
                let sdkStart = CACurrentMediaTime()
                self.fetchMessageForJump(position: position, noNext: { [weak self] (messages, totalRange) in
                    let sdkCost = ChatKeyPointTracker.cost(startTime: sdkStart)
                    let clientStart = CACurrentMediaTime()
                    self?.messageDatasource.merge(messages: messages,
                                                  totalRange: totalRange,
                                                  concurrent: self?.concurrentHandler ?? { _, _ in })
                    let clientCost = ChatKeyPointTracker.cost(startTime: clientStart)
                    var scrollInfo: ScrollInfo?
                    let index: Int? = self?.messageDatasource.index(messagePosition: position, messageId: messageId)
                    if let index = index {
                        scrollInfo = ScrollInfo(index: index,
                                                tableScrollPosition: tableScrollPosition,
                                                highlightPosition: needHighlight ? self?.updateTargetPostionIfNeedFor(cellIndex: index,
                                                                                                                     position: position) : nil)
                    }
                    jumpStatus?(.finishByRequest)
                    self?.publish(.refreshMessages(hasHeader: self?.hasMoreOldMessages() ?? false, hasFooter: self?.hasMoreNewMessages() ?? false, scrollInfo: scrollInfo))
                    finish?(ChatKeyPointTracker.CostTrackInfo(bySDK: true, clientCost: clientCost, sdkCost: sdkCost))
                }, onError: { (_) in
                    jumpStatus?(.error)
                    finish?(nil)
                })
            }
        }
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
        let index = self.uiDataSource.firstIndex { (cellVM) -> Bool in
            if let messageVM = cellVM as? HasMessage {
                return messageVM.message.id == id || messageVM.message.cid == id
            }
            return false
        }
        guard let row = index else { return nil }
        return IndexPath(row: row, section: 0)
    }

    /// - Parameters:
    ///   - id: id is messageId or messageCid
    func cellViewModel(by id: String) -> ChatCellViewModel? {
        return self.uiDataSource.first { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasMessage {
                return messageCellVM.message.id == id || messageCellVM.message.cid == id
            }
            return false
        }
    }

    func updateCellViewModel(ids: [String], doUpdate: @escaping (String, ChatCellViewModel) -> Bool) {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else { return }
            var hasUpdate: Bool = false
            for id in ids {
                if let cellVM = self.cellViewModel(by: id) {
                    if doUpdate(id, cellVM) {
                        hasUpdate = true
                    }
                }
            }
            if hasUpdate {
                self.publish(.refreshTable)
            }
        }
    }

    func startMultiSelect(by messageId: String) {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else { return }
            guard let idx = self.messageDatasource.index(messageId: messageId) else { return }

            self.inSelectMode.accept(true)
            if let cellVM = self.messageDatasource.cellViewModels[idx] as? ChatMessageCellViewModel {
                cellVM.checked = true
                self.pickedMessages.accept([SelectedMessageModel(message: cellVM.message)])
            }
            self.publish(.startMultiSelect(startIndex: idx))
        }
    }

    func finishMultiSelect() {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else { return }
            for cellVM in self.messageDatasource.cellViewModels {
                (cellVM as? ChatMessageCellViewModel)?.checked = false
            }
            self.pickedMessages.accept([])
            self.inSelectMode.accept(false)
            self.publish(.finishMultiSelect)
        }
    }

    func toggleSelectedMessage(by messageId: String) {
        self.queueManager.addDataProcess {[weak self] in
            guard let `self` = self else { return }

            var selectedMessages = self.pickedMessages.value
            if let idx = selectedMessages.firstIndex(where: { $0.id == messageId }) {
                /// 取消选中
                selectedMessages.remove(at: idx)
            } else if let idx = self.messageDatasource.index(messageId: messageId),
                      let cellVM = self.messageDatasource.cellViewModels[idx] as? ChatMessageCellViewModel {
                /// 选中
                selectedMessages.append(SelectedMessageModel(message: cellVM.message))
            } else {
                return
            }
            self.pickedMessages.accept(selectedMessages)
            self.publish(.refreshTable)
        }
    }

    func batchSelectMesssages(startPosition: Int32) {
        guard self.inSelectMode.value else { return }

        let maxSelectedCount = MultiSelectInfo.maxSelectedMessageLimitCount
        /// 先选择已在内存中的消息
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            var currentSelectedCount = 0
            var selectedMessages: [ChatSelectedMessageContext] = []
            self.messageDatasource.cellViewModels.forEach { (cellVM) in
                guard let chatCellVM = cellVM as? ChatMessageCellViewModel else { return }
                guard self.inSelectMode.value,
                      chatCellVM.dynamicAuthorityAllowed,
                      chatCellVM.content.contentConfig?.supportMutiSelect ?? false,
                      chatCellVM.content.contentConfig?.selectedEnable ?? false else {
                    return
                }
                /// 选择数量 limit
                guard currentSelectedCount < maxSelectedCount else {
                    chatCellVM.checked = false
                    return
                }
                /// 选择 startPosition 及以后的 message
                guard chatCellVM.message.position >= startPosition else {
                    chatCellVM.checked = false
                    return
                }

                currentSelectedCount += 1
                chatCellVM.checked = true
                selectedMessages.append(SelectedMessageModel(message: chatCellVM.message, extraInfo: [MultiSelectInfo.followingMessageClickKey: true]))
            }
            self.pickedMessages.accept(selectedMessages)
            self.publish(.refreshTable)
        }

        self.publish(.batchFetchSelectMessage(status: .initHud))
        /// 延迟 1000 ms 展示 loading
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + .milliseconds(1000)) {
            self.publish(.batchFetchSelectMessage(status: .loadingHud))
        }
        /// 根据接口返回数据判断是否被选中
        self.chatDataProvider.getMessageIdsByPosition(startPosition: startPosition, count: Int32(maxSelectedCount))
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] res in
                guard let self = self else { return }
                var messageIDTypes = res.messageIDTypes
                var selectedMessages: [ChatSelectedMessageContext] = []

                self.queueManager.addDataProcess { [weak self] in
                    guard let self = self else { return }
                    self.messageDatasource.cellViewModels.forEach { (cellVM) in
                        guard let chatCellVM = cellVM as? ChatMessageCellViewModel else { return }
                        guard chatCellVM.dynamicAuthorityAllowed else {
                            if messageIDTypes.keys.contains(chatCellVM.message.id) {
                                messageIDTypes.removeValue(forKey: chatCellVM.message.id)
                            }
                            return
                        }
                        guard self.inSelectMode.value,
                              chatCellVM.content.contentConfig?.supportMutiSelect ?? false,
                              chatCellVM.content.contentConfig?.selectedEnable ?? false else {
                            return
                        }

                        if messageIDTypes.keys.contains(chatCellVM.message.id) {
                            messageIDTypes.removeValue(forKey: chatCellVM.message.id)
                            chatCellVM.checked = true
                            /// 选中已在内存的消息
                            selectedMessages.append(SelectedMessageModel(message: chatCellVM.message, extraInfo: [MultiSelectInfo.followingMessageClickKey: true]))
                            return
                        }
                        chatCellVM.checked = false
                    }

                    /// 选中未在内存的消息
                    selectedMessages.append(contentsOf: messageIDTypes.map { SelectedMessageModel(id: $0.key, type: $0.value, extraInfo: [MultiSelectInfo.followingMessageClickKey: true]) })
                    self.pickedMessages.accept(selectedMessages)
                    self.publish(.refreshTable)
                    self.publish(.batchFetchSelectMessage(status: .removeHud(showLimit: selectedMessages.count >= maxSelectedCount)))
                }
            }, onError: { _ in
                self.publish(.batchFetchSelectMessage(status: .removeHud(showLimit: false)))
            }).disposed(by: self.disposeBag)
    }

    func updateFooter() {
        self.queueManager.addDataProcess { [weak self] in
            self?.publish(.updateFooterView(hasFooter: self?.hasMoreNewMessages() ?? false))
        }
    }

    private func updateTargetPostionIfNeedFor(cellIndex: Int, position: Int32) -> Int32 {
        if let cellVM = self.messageDatasource.cellViewModels[cellIndex] as? HasMessage,
           cellVM.message.isFoldRootMessage,
           cellVM.message.position != position {
            return cellVM.message.position
        }
        return position
    }

    func adjustMinMessagePosition() {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            let bannerSettingPostion = self.chat.bannerSetting?.chatMessagePosition
            let result = self.messageDatasource.adjustMinMessagePosition(concurrent: self.concurrentHandler)
            ChatMessagesViewModel.logger.info("chatTrace chat firstMessagePosition change \(self.chat.id) \(self.chatDataProvider.identify) \(self.chatDataContext.firstMessagePosition) \(result) \(String(describing: bannerSettingPostion))")
            if result {
                self.publish(.refreshTable)
            }
            self.publish(.updateHeaderView(hasHeader: self.hasMoreOldMessages()))
        }
    }

    func refreshRenders() {
        self.queueManager.addDataProcess { [weak self] in
            self?.messageDatasource.refreshRenders()
            self?.publish(.refreshTable)
        }
    }

    func onResize() {
        self.queueManager.addDataProcess { [weak self] in
            self?.messageDatasource.onResize()
            self?.publish(.refreshTable)
        }
    }

    func highlight(position: Int32) {
        self.queueManager.addDataProcess { [weak self] in
            self?.messageDatasource.setHighlightInfo(HighlightMessageInfo(position: position, messageId: nil))
            self?.publish(.highlight(position: position))
        }
    }

    public func getLastMessage() -> Message? {
        let cellModel = self.uiDataSource.last { (cellVM) -> Bool in
            return cellVM is HasMessage
        }
        let hasMessage = cellModel as? HasMessage
        return hasMessage?.message
    }

    func removeMessages(afterPosition: Int32, redundantCount: Int, finish: @escaping (Int) -> Void) {
        let operation = BlockOperation { [weak self] in
            guard let self = self else { return }
            self.messageDatasource.remove(afterPosition: afterPosition, redundantCount: redundantCount)
            let remainCount = self.cellViewModelsCount
            finish(remainCount)
            ChatMessagesViewModel.logger.info("chatTrace removeMessages after \(self.chat.id) \(remainCount)")
            self.publish(.remain(hasFooter: self.hasMoreNewMessages()))
        }
        operation.queuePriority = .veryHigh
        queueManager.addDataProcessOperation(operation)
    }

    //移除高亮效果
    public func removeHightlight(needRefresh: Bool) {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            if let index = self.messageDatasource.removeHighlightInfo(), needRefresh {
                self.publish(.messagesUpdate(indexs: [index], guarantLastCellVisible: false, animation: .fade))
            }
        }
    }

    func getISSingleMode() -> Bool {
        let userStore = KVStores.MyAITool.build(forUser: self.userResolver.userID)
        let isSingleExtensionMode = userStore[KVKeys.MyAITool.myAIModelType]
        Self.logger.info("isSingleMode: \(isSingleExtensionMode)")
        return isSingleExtensionMode
    }

    /// 首屏的数据
    func handleFirstScreen(result: GetChatMessagesResult, initType: MessageInitType) {
        if !self.messageDatasource.cellViewModels.isEmpty {
            ChatMessagesViewModel
                .logger
                .error("chatTrace 此时数据源不应有数据 \(self.chat.id) \(self.messageDatasource.cellViewModels.count)")
        }
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.transCellVM, parentName: LarkTracingUtil.initMessages)
        let loadTrackInfo = self.dependency.chatKeyPointTracker.loadTrackInfo
        let start = CACurrentMediaTime()
        self.messageDatasource.reset(messages: result.messages,
                                     totalRange: result.totalRange,
                                     concurrent: self.concurrentHandler)

        if result.missedPositions.isEmpty {
            if result.totalRange == nil {
                //https://bytedance.feishu.cn/docs/doccnRPwJJuku5gpTjbcbcSutLb# 尝试用buffermsg上屏(有缺失的会等缺失消息拉回来后再处理bufferpush)
                self.handleBufferPushMessages(range: (minPosition: self.messageDatasource.minMessagePosition,
                                                      maxPosition: self.messageDatasource.maxMessagePosition),
                                              needRefresh: false)
            } else if !result.messages.isEmpty {
                self.handleBufferPushMessages(needRefresh: false)
            }
            self.firstScreenLoaded = true
            loadTrackInfo?.transCellVMCost = ChatKeyPointTracker.cost(startTime: start)
            self.publishInitMessages(initType: initType, getChatMessagesTrakInfo: result.trackInfo)
        } else {
            self.firstScreenLoaded = true
            loadTrackInfo?.transCellVMCost = ChatKeyPointTracker.cost(startTime: start)
            self.publishInitMessages(initType: initType, getChatMessagesTrakInfo: result.trackInfo)
            self.fetchMissedMessages(positions: result.missedPositions, initType: initType)
            AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                            scene: .Chat,
                                                            event: .enterChat,
                                                            errorType: .SDK,
                                                            errorLevel: .Exception,
                                                            errorCode: 3,
                                                            userAction: nil,
                                                            page: ChatMessagesViewController.pageName,
                                                            errorMessage: nil,
                                                            extra: Extra(isNeedNet: true,
                                                                         latencyDetail: [:],
                                                                         metric: loadTrackInfo?.reciableExtraMetric ?? [:],
                                                                         category: loadTrackInfo?.reciableExtraCategory ?? [:])))
        }
        LarkTracingUtil.endSpanByName(spanName: LarkTracingUtil.transCellVM)
    }

    func fetchMissedMessages(positions: [Int32], initType: MessageInitType) {
        guard !positions.isEmpty else {
            return
        }

        var anchorMessageId: String?
        if case .specifiedMessages(position: let position) = initType,
            let index = self.messageDatasource.index(messagePosition: position) {
            anchorMessageId = (self.messageDatasource.cellViewModels[index] as? HasMessage)?.message.id
        }
        self.chatDataProvider.fetchMissedMessages(positions: positions)
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages) in
                self?.handleMiss(result: .success(messages), anchorMessageId: anchorMessageId)
            }, onError: { [weak self] (error) in
                self?.handleMiss(result: .failure(error), anchorMessageId: nil)
            }).disposed(by: self.disposeBag)
    }

    func publishInitMessages(initType: MessageInitType, getChatMessagesTrakInfo: GetChatMessagesTrackInfo) {
        var scrollInfo: ScrollInfo?
        var hitTargetMessage: Bool = true
        switch initType {
        case .specifiedMessages(position: let position):
            if let scrollIndex = self.messageDatasource.index(messagePosition: position) {
                scrollInfo = ScrollInfo(index: scrollIndex,
                                        tableScrollPosition: .middle,
                                        highlightPosition: updateTargetPostionIfNeedFor(cellIndex: scrollIndex,
                                                                                        position: position))

            } else {
                hitTargetMessage = false
                ChatMessagesViewModel.logger.error("chatTrace initBySpecifiedMessages 没找到指定消息index")
            }
        case .recentLeftMessage:
            if let scrollIndex = self.messageDatasource.index(messagePosition: self.chatDataContext.lastReadPosition) {
                scrollInfo = ScrollInfo(index: scrollIndex, tableScrollPosition: .top)
            } else {
                ChatMessagesViewModel.logger.error("chatTrace initByRecentLeftMessage 没找到recentLeftMessage index")
            }
        case .lastedUnreadMessage:
            break
        case .oldestUnreadMessage:
            if let scrollIndex = self.messageDatasource.indexForNewMessageSignCell() {
                scrollInfo = ScrollInfo(index: scrollIndex, tableScrollPosition: .top)
            } else if chat.badge > 0 {
                ChatMessagesViewModel.logger.info("chatTrace oldestUnreadMessage 没找到新消息线")
            }
        case .lastedMessage:
            //My AI分会话预期总是走这个case
            break
        }
        if scrollInfo == nil, !self.messageDatasource.cellViewModels.isEmpty {
            scrollInfo = ScrollInfo(index: self.cellViewModelsCount - 1, tableScrollPosition: .bottom)
        }
        let loadTrackInfo = self.dependency.chatKeyPointTracker.loadTrackInfo
        loadTrackInfo?.getChatMessagesTrakInfo = getChatMessagesTrakInfo
        loadTrackInfo?.pulishToMainThreadStart = CACurrentMediaTime()
        //publishDataToRender
        loadTrackInfo?.hitTargetMessage = hitTargetMessage
        let initInfo = InitMessagesInfo(hasHeader: self.hasMoreOldMessages(),
                                        hasFooter: self.hasMoreNewMessages(),
                                        scrollInfo: scrollInfo,
                                        initType: initType)
        self.publish(.initMessages(initInfo, needHighlight: scrollInfo?.highlightPosition != nil))
        LarkTracingUtil.startChildSpanByPName(spanName: LarkTracingUtil.publishInitMessagesSignal, parentName: LarkTracingUtil.firstScreenMessagesRender)
    }

    func handleMiss(result: Result<[Message], Error>, anchorMessageId: String?) {
        switch result {
        case .success(let messages):
            let missMessagesValid = self.messageDatasource.insert(messages: messages,
                                                                  concurrent: self.concurrentHandler)
            self.handleBufferPushMessages(needRefresh: !missMessagesValid)
            if missMessagesValid {
                self.publish(.refreshMissedMessage(anchorMessageId: anchorMessageId))
            } else {
                 ChatMessagesViewModel.logger.info("chatTrace fetchMissedMessages invalid \(self.chatId)")
            }
        case .failure(let error):
            self.handleBufferPushMessages(needRefresh: true)
            ChatMessagesViewModel.logger.error("chatTrace fetchMissedMessages fail\(self.chatId)", error: error)
        }
    }

    func handleBufferPushMessages(range: (minPosition: Int32, maxPosition: Int32)? = nil, needRefresh: Bool) {
        //https://bytedance.feishu.cn/docs/doccnRPwJJuku5gpTjbcbcSutLb#yx9PQ1
        let bufferPushMessages = self.bufferPushMessages?(range) ?? []
        var hasChange = false
        if range != nil {
            self.messageDatasource.reset(messages: bufferPushMessages,
                                         totalRange: bufferPushMessages.isEmpty ? nil : (bufferPushMessages.first?.position ?? 0,
                                                                                         bufferPushMessages.last?.position ?? 0),
                                         concurrent: self.concurrentHandler)
            hasChange = true
        } else {
            for msg in bufferPushMessages {
                let result = self.messageDatasource.handle(message: msg, concurrent: self.concurrentHandler)
                hasChange = hasChange ? hasChange : result != .none
            }
        }
        if hasChange, needRefresh {
            self.publish(.refreshTable)
        }
    }

    func cleanBufferPushMessages() {
        _ = self.bufferPushMessages?(nil) ?? []
    }

    func loadMoreMessages(position: Int32, pullType: PullMessagesType, sceneForLog: String) -> Observable<([Message], totalRange: (minPostion: Int32, maxPostion: Int32)?, sdkCost: Int64)> {
        Self.logger.info("loadMoreMessages \(position) \(pullType) \(sceneForLog)")
        return self.chatDataProvider.fetchMessages(position: position,
                                                   pullType: pullType,
                                                   redundancyCount: 0,
                                                   count: 30,
                                                   expectDisplayWeights: exceptWeight(height: 2 * hostUIConfig.size.height),
                                                   redundancyDisplayWeights: 0)
        .do(onNext: { [weak self] result in
            guard let self = self else { return }
            self.handleLoadMoreMessagesResult(result)
        }).map({ (result) -> ([Message], totalRange: (minPostion: Int32, maxPostion: Int32)?, sdkCost: Int64) in
            return (result.messages, result.totalRange, sdkCost: result.trackInfo.sdkCost)
        }).observeOn(self.queueManager.dataScheduler)
    }

    func handleLoadMoreMessagesResult(_ result: GetChatMessagesResult) {
    }

    func fetchMessageForJump(position: Int32, noNext: @escaping ([Message],
                                                                 (minPostion: Int32, maxPostion: Int32)?) -> Void, onError: ((Error) -> Void)? = nil) {
        ChatMessagesViewModel.logger.info("chatTrace queueInfo jump pauseQueue")
        self.pauseQueue()

        self.chatDataProvider.fetchSpecifiedMessage(position: position,
                                                    redundancyCount: ChatMessagesViewModel.redundancyCount,
                                                    count: ChatMessagesViewModel.requestCount,
                                                    expectDisplayWeights: exceptWeight(height: hostUIConfig.size.height),
                                                    redundancyDisplayWeights: exceptWeight(height: hostUIConfig.size.height / 3))
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (result) in
            let refreshMessagesOperation = BlockOperation(block: { noNext(result.messages, result.totalRange) })
            refreshMessagesOperation.queuePriority = .high
            self?.queueManager.addDataProcessOperation(refreshMessagesOperation)
            ChatMessagesViewModel.logger.info("chatTrace queueInfo jump resumeQueue (my ai)")
            self?.resumeQueue()
        }, onError: { [weak self] (error) in
            self?.errorPublish.onNext(.jumpFail(error))
            ChatMessagesViewModel.logger.info("chatTrace queueInfo jump resumeQueue (my ai)")
            self?.resumeQueue()
            onError?(error)
        }).disposed(by: self.disposeBag)
    }

    func logForGetMessages(scene: FetchChatMessagesScene, redundancyCount: Int32, count: Int32, expectDisplayWeights: Int32?) {
        ChatMessagesViewModel.logger.info("chatTrace fetchMessages",
                                          additionalData: [
                                            "chatId": self.chat.id,
                                            "firstMessagePosition": "\(self.chat.firstMessagePostion)",
                                            "bannerSetting.chatMessagePosition": "\(self.chat.bannerSetting?.chatMessagePosition)",
                                            "lastMessagePosition": "\(self.chat.lastMessagePosition)",
                                            "lastVisibleMessagePosition": "\(self.chat.lastVisibleMessagePosition)",
                                            "scene": "\(scene.description())",
                                            "count": "\(count)",
                                            "redundancyCount": "\(redundancyCount)",
                                            "expectDisplayWeights": "\(expectDisplayWeights ?? 0)"])
    }

    func observeData() {
        self.chatDataProvider.messagesObservable
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages) in
                guard let `self` = self, self.firstScreenLoaded else { return }
                self.handlePushMessages(messages: messages)
            }).disposed(by: self.disposeBag)
    }

    func handlePushMessages(messages: [Message]) {
        let doUpdate = {
            var needUpdate = false
            for message in messages {
                let result = self.messageDatasource.handle(message: message, concurrent: self.concurrentHandler)
                guard result != .none else {
                    continue
                }
                switch result {
                case .newMessage:
                    self.publishReceiveNewMessage(message: message)
                case .updateMessage:
                    needUpdate = true
                case .messageSendFail:
                    needUpdate = true
                    self.dependency.chatKeyPointTracker.sendMessageFinish(cid: message.cid, messageId: message.id,
                                                                          success: false, page: ChatMessagesViewController.pageName,
                                                                          isCheckExitChat: false)
                case .messageSendSuccess:
                    self.dependency.chatKeyPointTracker.beforePublishFinishSignal(cid: message.cid, messageId: message.id)
                    self.publish(.messageSendSuccess(message: message, hasFooter: self.hasMoreNewMessages()))
                case .messageSending:
                    self.publishReceiveMessageSending(message: message)
                case .none:
                    continue
                }
            }
            if needUpdate {
                self.publish(.refreshTable)
            }
            self.dependency.urlPreviewService?.fetchMissingURLPreviews(messages: messages)
        }
        if messages.contains(where: { (message) -> Bool in
            return message.localStatus != .success && self.messageDatasource.index(cid: message.cid) == nil
        }) {
            self.jumpToChatLastMessage(tableScrollPosition: .bottom, needDuration: false) { _ in
                doUpdate()
            }
        } else {
            doUpdate()
        }
    }

    func publishReceiveNewMessage(message: Message) {
        self.publish(.hasNewMessage(message: message, hasFooter: self.hasMoreNewMessages()))
        self.dependency.chatKeyPointTracker.receiveNewMessage(message: message, pageName: ChatMessagesViewController.pageName)
    }

    func publishReceiveMessageSending(message: Message) {
        self.dependency.chatKeyPointTracker.beforePublishOnScreenSignal(cid: message.cid, messageId: message.id)
        if message.localStatus == .fail {
            // 消息可能直接进入失败态
            self.dependency.chatKeyPointTracker.sendMessageFinish(cid: message.cid, messageId: message.id,
                                                                  success: false, page: ChatMessagesViewController.pageName,
                                                                  isCheckExitChat: false)
        }
        self.publish(.messageSending(message: message))
    }

    func hasMoreOldMessages() -> Bool {
        ChatMessagesViewModel.logger.info("chatTrace hasMoreOldMessages \(self.chatDataContext.identify) \(self.messageDatasource.minMessagePosition) \(self.chatDataContext.firstMessagePosition) \(self.firstScreenLoaded)")
        return self.firstScreenLoaded && self.messageDatasource.minMessagePosition > self.chatDataContext.firstMessagePosition + 1
    }

    func hasMoreNewMessages() -> Bool {
        ChatMessagesViewModel.logger.info("chatTrace hasMoreNewMessages \(self.chatDataContext.identify) \(self.messageDatasource.maxMessagePosition) \(self.chatDataContext.lastVisibleMessagePosition) \(self.firstScreenLoaded)")
        return self.firstScreenLoaded
            && self.messageDatasource.maxMessagePosition < self.chatDataContext.lastVisibleMessagePosition
    }

    func publish(_ type: ChatTableRefreshType, outOfQueue: Bool = false) {
        var dataUpdate: Bool = true
        switch type {
        case .updateFooterView,
             .updateHeaderView,
             .scrollTo:
            dataUpdate = false
        default:
            break
        }
        Self.logger.info("ChatTrace tableRefreshPublish onNext \(self.chatId) \(type.describ) \(outOfQueue)")
        self.tableRefreshPublish.onNext((type, newDatas: dataUpdate ? self.messageDatasource.cellViewModels : nil, outOfQueue: outOfQueue))
    }
}

extension Message: PushData {
    public var message: Message {
        return self
    }
}

extension ChatMessagesViewModel: HandlePushDataSourceAPI {
    func update(messageIds: [String], doUpdate: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            let needUpdate = self.messageDatasource.update(messageIds: messageIds, doUpdate: { (msg) -> Message? in
                return doUpdate(msg) as? Message
            })
            completion?(needUpdate)
            if needUpdate {
                self.publish(.refreshTable)
            }
        }
    }

    func update(original: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            let needUpdate = self.messageDatasource.update(original: { (msg) -> Message? in
                return original(msg) as? Message
            })
            completion?(needUpdate)
            if needUpdate {
                self.publish(.refreshTable)
            }
        }
    }
}

extension ChatMessagesViewModel: DataSourceAPI {
    var scene: ContextScene {
        return .newChat
    }

    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return self.uiDataSource
            .compactMap { $0 as? MessageCellViewModel<M, D, T> }
            .filter(predicate)
    }

    func pauseDataQueue(_ pause: Bool) {
        if pause {
            ChatMessagesViewModel.logger.info("chatTrace queueInfo dataSourceAPI pauseQueue")
            self.pauseQueue()
        } else {
            ChatMessagesViewModel.logger.info("chatTrace queueInfo dataSourceAPI resumeQueue")
            self.resumeQueue()
        }
    }

    func reloadTable() {
        self.queueManager.addDataProcess { [weak self] in
            Self.logger.info("chatTrace reloadTable trigger tableRefreshPublish onNext \(self?.chat.id ?? "")")
            self?.publish(.refreshTable)
        }
    }

    func reloadRow(by messageId: String, animation: UITableView.RowAnimation) {
        Self.logger.info("chatTrace reloadRow by \(self.chatId) \(messageId)")
        if self.queueIsPause() {
            if let index = self.uiDataSource.firstIndex(where: { (cellVM) -> Bool in
                if let messageCellVM = cellVM as? HasMessage {
                    return messageCellVM.message.id == messageId
                }
                return false
            }) {
                Self.logger.info("chatTrace reloadRow trigger tableRefreshPublish onNext \(self.chatId) \(messageId)")
                self.tableRefreshPublish.onNext(
                    (
                        .messagesUpdate(indexs: [index],
                        guarantLastCellVisible: false,
                        animation: animation
                    ),
                     newDatas: nil,
                     outOfQueue: true
                    )
                )
            }
        } else {
            self.queueManager.addDataProcess { [weak self] in
                if let index = self?.messageDatasource.index(messageId: messageId) {
                    self?.publish(.messagesUpdate(indexs: [index], guarantLastCellVisible: false, animation: animation))
                }
            }
        }
    }

    func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(messageIds: messageIds, doUpdate: doUpdate) ?? false
            if needUpdate {
                self?.publish(.refreshTable)
            }
        }
    }

    func reloadRow(byViewModelId viewModelId: String, animation: UITableView.RowAnimation) {
        Self.logger.info("chatTrace reloadRow by \(self.chatId) viewModelId: \(viewModelId)")
        if self.queueIsPause() {
            if let index = self.uiDataSource.firstIndex(where: { (cellVM) -> Bool in
                return cellVM.id == viewModelId
            }) {
                Self.logger.info("chatTrace reloadRow trigger tableRefreshPublish onNext \(self.chatId) viewModelId: \(viewModelId)")
                self.tableRefreshPublish.onNext(
                    (
                        .messagesUpdate(indexs: [index],
                        guarantLastCellVisible: false,
                        animation: animation
                    ),
                     newDatas: nil,
                     outOfQueue: true
                    )
                )
            }
        } else {
            self.queueManager.addDataProcess { [weak self] in
                if let index = self?.messageDatasource.index(viewModelId: viewModelId, positive: true) {
                    self?.publish(.messagesUpdate(indexs: [index], guarantLastCellVisible: false, animation: animation))
                }
            }
        }
    }

    func deleteRow(by messageId: String) {
        self.queueManager.addDataProcess { [weak self] in
            let result = self?.messageDatasource.delete(messageId: messageId) ?? false
            ChatMessagesViewModel.logger.info("chatTrace deleteRow \(self?.chat.id ?? "") \(messageId) \(result)")
            if result {
                self?.publish(.refreshTable)
            }
        }
    }

    func processMessageSelectedEnable(message: Message) -> Bool {
        return self.dependency.processMessageSelectedEnable(message)
    }

    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return topNoticeSubject
    }
}

extension ChatMessagesViewModel: CellConfigProxy {
    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        let hasFlag = message.isFlag
        var hasStatusView = self.isMe(message.fromId, self.chat) || hasFlag
        let padding: CGFloat = message.showInThreadModeStyle ? self.contentPadding * 2 : 0
        // 下面场景卡片宽度一致，取StatusView显示时的宽度
        // 1.视频卡片
        // 2.投票
        // 3.日程分享卡片
        // 4 文件/文件夹卡片
        // 5 todo卡片
        // 6 独立卡片无气泡时
        let isSinglePreview = TCPreviewContainerComponentFactory.canCreateSinglePreview(message: message, chat: self.chat, context: context) &&
        !TCPreviewContainerComponentFactory.isSinglePreviewWithBubble(message: message, scene: context.contextScene)
        if message.content is VChatMeetingCardContent
            || message.type == .shareCalendarEvent
            || message.type == .file
            || message.type == .folder
            || (message.content as? CardContent)?.type == .vote
            || message.type == .todo
            || isSinglePreview {
            hasStatusView = true
        }

        if message.type == .generalCalendar {
            switch message.content {
            case is GeneralCalendarEventRSVPContent,
                is RoundRobinCardContent,
                is SchedulerAppointmentCardContent:
                hasStatusView = true
            default:
                break
            }
        }

        let maxContentWidth = ChatCellUIStaticVariable.maxCellContentWidth(
            hasStatusView: hasStatusView,
            maxCellWidth: hostUIConfig.size.width
        )
        return ChatCellUIStaticVariable.getContentPreferMaxWidth(
            message: message,
            maxCellWidth: hostUIConfig.size.width,
            maxContentWidth: maxContentWidth,
            bubblePadding: padding
        )
    }

    var supportAvatarLeftRightLayout: Bool {
        return _supportAvatarLeftRightLayout
    }
}

extension ChatMessagesViewModel: ChatTableViewDataSourceDelegate {
    var readService: ChatMessageReadService {
        return self.dependency.readService
    }
}

extension FetchChatMessagesScene {
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
private extension ChatMessagesViewModel {
    func loadMoreReciableTrack(key: DisposedKey?, sdkCost: Int64, loadMoreNew: Bool) {
        let tracker = self.dependency.chatKeyPointTracker
        if let key = key, let loadTrackInfo = tracker.loadTrackInfo {
            var category = loadTrackInfo.reciableExtraCategory
            category["load_type"] = loadMoreNew
            AppReciableSDK.shared.end(key: key, extra: Extra(isNeedNet: true,
                                                             latencyDetail: ["sdk_cost": sdkCost],
                                                             metric: loadTrackInfo.reciableExtraMetric,
                                                             category: category))
        }
    }

    func loadMoreReciableTrackForPreLoad(sdkCost: Int64, loadMoreNew: Bool) {
        let tracker = self.dependency.chatKeyPointTracker
        if let loadTrackInfo = tracker.loadTrackInfo {
            var category = loadTrackInfo.reciableExtraCategory
            category["load_type"] = loadMoreNew
            AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                                  scene: .Chat,
                                                                  event: .loadMoreMessageTime,
                                                                  cost: -1,
                                                                  page: ChatMessagesViewController.pageName,
                                                                  extra: Extra(isNeedNet: true,
                                                                               latencyDetail: ["sdk_cost": sdkCost],
                                                                               metric: loadTrackInfo.reciableExtraMetric,
                                                                               category: category)))
        }
    }

    func loadMoreReciableTrackError(loadMoreNew: Bool, bySDK: Bool) {
        let tracker = self.dependency.chatKeyPointTracker
        if let loadTrackInfo = tracker.loadTrackInfo {
            var category = loadTrackInfo.reciableExtraCategory
            category["load_type"] = loadMoreNew
            AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                            scene: .Chat,
                                                            event: .loadMoreMessageTime,
                                                            errorType: bySDK ? .SDK : .Other,
                                                            errorLevel: bySDK ? .Fatal : .Exception,
                                                            errorCode: bySDK ? 1 : 0,
                                                            userAction: nil,
                                                            page: ChatMessagesViewController.pageName,
                                                            errorMessage: nil,
                                                            extra: Extra(isNeedNet: bySDK,
                                                                         latencyDetail: [:],
                                                                         metric: loadTrackInfo.reciableExtraMetric,
                                                                         category: category)))
        }
    }
}

extension ChatMessagesViewModel: BaseMessageContainer {
    var firstMessagePosition: Int32 {
        return self.chatDataContext.firstMessagePosition
    }

    var lastMessagePosition: Int32 {
        return self.chatDataContext.lastMessagePosition
    }

    var contentPadding: CGFloat {
        return ChatCellUIStaticVariable.bubblePadding
    }

    func getFeatureIntroductions() -> [String] {
        return dependency.getFeatureIntroductions()
    }
}
