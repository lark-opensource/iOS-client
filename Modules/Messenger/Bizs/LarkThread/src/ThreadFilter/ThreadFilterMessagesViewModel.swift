//
//  ThreadFilterDataSource.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/8/19.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import LarkCore
import LarkModel
import LarkContainer
import LarkMessageBase
import LarkMessageCore
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import RustPB

/// 初始数据(首屏)状态
enum InitDataStatus {
    /// 开始
    case start
    /// 结束
    case finish
    /// 加载出错
    case error
    case none
}

final class ThreadFilterMessagesViewModel: AsyncDataProcessViewModel<ThreadFilterMessagesViewModel.TableRefreshType, [ThreadCellViewModel]>, UserResolverWrapper {
    let userResolver: UserResolver

    enum TableRefreshType: OuputTaskTypeInfo {
        case initMessages(hasLoading: Bool)
        case refreshMessages(hasLoading: Bool)
        case messagesUpdate(indexs: [Int])
        case loadMoreOldMessages(hasLoading: Bool)
        case updateOldMessageLoadingView(hasLoading: Bool)
        case refreshTable
        public func canMerge(type: TableRefreshType) -> Bool {
            switch (self, type) {
            case (.updateOldMessageLoadingView, .updateOldMessageLoadingView),
                 (.refreshTable, .refreshTable):
                return true
            default:
                return false
            }
        }
        func duration() -> Double {
            var duration: Double = 0
            switch self {
            case .updateOldMessageLoadingView:
                duration = 0
            case .initMessages:
                duration = MessageCommonCell.highlightDuration
            default:
                break
            }
            return duration
        }
        func isBarrier() -> Bool {
            switch self {
            case .messagesUpdate:
                return true
            default:
                return false
            }
        }
    }

    // MARK: - internal
    var highlightPosition: Int32?
    var viewWillAppear: Bool = false
    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?
    let chatWrapper: ChatPushWrapper
    private(set) var topicPushWrapper: TopicGroupPushWrapper
    let translateService: NormalTranslateService
    let userGeneralSettings: UserGeneralSettings
    let messageDatasource: ThreadListDataSource<ThreadMessage>
    let navBarHeight: CGFloat
    @ScopedInjectedLazy private var thumbsupReactionService: ThumbsupReactionService?
    @ScopedInjectedLazy private var urlPreviewService: MessageURLPreviewService?

    /// 置顶信号
    let topNoticeSubject: BehaviorSubject<ChatTopNotice?> = BehaviorSubject(value: nil)
    /// 自动翻译开关变化
    private let chatAutoTranslateSettingPublish: PublishSubject<Void> = PublishSubject<Void>()
    public var chatAutoTranslateSettingDriver: Driver<()> {
        return chatAutoTranslateSettingPublish.asDriver(onErrorJustReturn: ())
    }
    private lazy var processThreadMessage: (ThreadMessage) -> [ThreadCellViewModel] = {
        return { [weak self] threadMessage in
            guard let `self` = self else { return [ThreadCellViewModel]() }
            var viewModels: [ThreadCellViewModel] = []
            if let metaModel = self.messageDatasource.createThreadMetaData(threadMessage: threadMessage) {
                let messageCellViewModel = self.vmFactory.create(with: metaModel, metaModelDependency: self.getCellDependency())
                viewModels.append(messageCellViewModel)
            } else {
                ThreadFilterMessagesViewModel.logger.error("LarkThread error: processMessages threadMessage no chat")
                assertionFailure("threadMessage no chat")
            }
            return viewModels
        }
    }()
    private let vmFactory: ThreadCellViewModelFactory

    /// 初始化状态信号
    public var initDataStatus = BehaviorRelay<InitDataStatus>(value: .none)
    public var initDataStatusDriver: Driver<InitDataStatus> {
        return initDataStatus.asDriver()
    }

    init(userResolver: UserResolver,
         userGeneralSettings: UserGeneralSettings,
         translateService: NormalTranslateService,
         vmFactory: ThreadCellViewModelFactory,
         chatWrapper: ChatPushWrapper,
         topicPushWrapper: TopicGroupPushWrapper,
         chatID: String,
         threadAPI: ThreadAPI,
         pushCenter: PushNotificationCenter,
         pushHandlerRegister: ThreadChatPushHandlersRegister,
         navBarHeight: CGFloat
    ) {
        self.userResolver = userResolver
        self.userGeneralSettings = userGeneralSettings
        self.translateService = translateService
        self.chatWrapper = chatWrapper
        self.topicPushWrapper = topicPushWrapper
        self.vmFactory = vmFactory
        self.messageDatasource = ThreadListDataSource(
            currentChatterID: userResolver.userID,
            getChat: {
                return chatWrapper.chat.value
            },
            getTopicGroup: {
                return topicPushWrapper.topicGroupObservable.value
            }
        )
        self.pushHandlerRegister = pushHandlerRegister
        self.pushCenter = pushCenter
        self.chatID = chatID
        self.threadAPI = threadAPI
        self.navBarHeight = navBarHeight
        super.init(uiDataSource: [])
    }

    deinit {
        /// 退会话时，清空一次标记
        self.translateService.resetMessageCheckStatus(key: chatWrapper.chat.value.id)
    }

    private func addObservers() {
        pushHandlerRegister.startObserve(self)

        let threadObservable = pushCenter.observable(for: PushThreads.self)
            .map({ [weak self] (push) -> [RustPB.Basic_V1_Thread] in
                return push.threads.filter({ (thread) -> Bool in
                    return thread.channel.id == (self?.chatID ?? "")
                })
            })
            .filter({ (threads) -> Bool in
                return !threads.isEmpty
            })

        let threadMessageObservable = pushCenter.observable(for: PushThreadMessages.self)
            .map({ [weak self] (push) -> [ThreadMessage] in
                return push.messages
                    .filter({ thread -> Bool in
                        return thread.channel.id == (self?.chatID ?? "")
                    })
            })
            .filter({ (threadMessages) -> Bool in
                return !threadMessages.isEmpty
            })

        let messagesObservable = pushCenter.observable(for: PushChannelMessages.self)
            .map({ [weak self] (push) -> [Message] in
                return push.messages.filter({ (msg) -> Bool in
                    return msg.channel.id == (self?.chatID ?? "")
                })
            })
            .filter({ (msgs) -> Bool in
                return !msgs.isEmpty
            })

        threadObservable
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

        threadMessageObservable
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (threadMessages) in
                guard let `self` = self else { return }
                var needUpdate = false
                for threadMessage in threadMessages {
                    // 不需要处理假消息
                    if threadMessage.localStatus != .success {
                        continue
                    }

                    let handleResult = self.messageDatasource.handle(
                        threadMessage: threadMessage,
                        removeFilter: { [weak self] (threadMsg) in
                            guard let `self` = self else { return false }
                            // 话题取消关注 || 删除话题
                            let unfollowedOrDeleted = (threadMsg.thread.isFollow == false
                                || threadMsg.isNoTraceDeleted == true)
                            // 界面没有显示在屏幕内 && 取消订阅或是删除话题
                            return self.viewWillAppear == false && unfollowedOrDeleted
                        },
                        addFilter: { (threadMsg) in
                            // 只有订阅的话题才能被添加
                            return (threadMsg.thread.isFollow, false)
                        },
                        processThreadMessage: { [weak self] threadMsg in
                            guard let `self` = self else { return [ThreadCellViewModel]() }
                            return self.processThreadMessage(threadMsg)
                        }
                    )
                    switch handleResult {
                    case .addMessage, .deleteMessage, .updateMessage:
                        needUpdate = true
                    case .none:
                        continue
                    }
                }

                if needUpdate {
                    self.publish(.refreshMessages(hasLoading: self.hasMoreOldMessages()))
                }
                let messages = threadMessages.flatMap({ [$0.rootMessage] + $0.replyMessages + $0.latestAtMessages })
                self.urlPreviewService?.fetchMissingURLPreviews(messages: messages)
            }).disposed(by: self.disposeBag)

        messagesObservable
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
                self.urlPreviewService?.fetchMissingURLPreviews(messages: messages)
            }).disposed(by: self.disposeBag)

        chatWrapper.chat.map({ $0.isAutoTranslate }).distinctUntilChanged().subscribe(onNext: { [weak self] (_) in
            self?.chatAutoTranslateSettingPublish.onNext(())
        }).disposed(by: self.disposeBag)

        thumbsupReactionService?.thumbsupUpdate
            .observeOn(queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (_) in
                self?.messageDatasource.cellViewModels.forEach { $0.calculateRenderer() }
                self?.publish(.refreshTable)
            }).disposed(by: disposeBag)

    }

    func publish(_ type: TableRefreshType, outOfQueue: Bool = false) {
        var dataUpdate: Bool = true
        switch type {
        case .updateOldMessageLoadingView:
            dataUpdate = false
        default:
            break
        }
        self.tableRefreshPublish.onNext((type, newDatas: dataUpdate ? self.messageDatasource.cellViewModels : nil, outOfQueue: outOfQueue))
    }

    func loadFirstScreen() {
        self.addObservers()
        threadAPI.fetchFilteredThreads(
            channelID: chatID,
            filterID: "1",
            extendFilterID: ["1"],
            scene: .firstScreen,
            cursor: nil,
            count: 15,
            preloadCount: 0
        ).observeOn(self.queueManager.dataScheduler)
        .subscribe(onNext: { [weak self] (result) in
            guard let `self` = self else { return }
            self.cursor = result.1
            self.handleFirstScreen(threadMessages: self.handleThreadMessages(result.0))
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            ThreadFilterMessagesViewModel.logger.error("LarkThread error: ThreadFilterTrace loadFirstScreen 请求失败 \(self.chatID) \(error.localizedDescription)")
            self.initDataStatus.accept(.error)
        }).disposed(by: disposeBag)
    }

    /// 重新布局
    func onResize() {
        self.queueManager.addDataProcess { [weak self] in
            self?.messageDatasource.onResize()
            self?.send(update: true)
        }
    }

    // MARK: handle Data
    private func handleFirstScreen(threadMessages: [ThreadMessage]) {
        if threadMessages.isEmpty {
            ThreadFilterMessagesViewModel.logger.info("ThreadFilterTrace loadFirstScreen 空数据 \(self.chatID)")
            self.initDataStatus.accept(.none)
            return
        }
        guard self.messageDatasource.replace(
            messages: threadMessages,
            filter: { (threadMessage) in
                // 过滤掉已经被无痕删除的消息
                return threadMessage.rootMessage.isNoTraceDeleted != true
            },
            concurrent: self.concurrentHandler,
            processMessage: self.processThreadMessage
        ) else {
            ThreadFilterMessagesViewModel.logger.info("ThreadFilterTrace loadFirstScreen replaced 空数据 \(self.chatID)")
            self.initDataStatus.accept(.none)
            return
        }
        self.initDataStatus.accept(.finish)
        self.publish(.initMessages(hasLoading: self.hasMoreOldMessages()))
    }

    private func hasMoreOldMessages() -> Bool {
        ThreadFilterMessagesViewModel.logger.info("ThreadFilterTrace 加载更多 \(self.cursor ?? "") \(self.chatID)")
        // cursor.isEmpty || cursor 时nil时，无加载更多
        if cursor?.isEmpty ?? true {
            return false
        } else {
            return true
        }
    }

    /// 在已经存在的数据中，过滤 未关注的话题和被无痕撤回的话题
    func filterUnfollowAndRecalled() {
        self.queueManager.addDataProcess { [weak self] in
            guard let `self` = self else { return }
            var isFilted = false
            self.messageDatasource.filterDataProcess(filter: { (cellVM) -> Bool in
                if let cellViewModel = cellVM as? ThreadMessageCellViewModel {
                    // 过滤掉未关注和被删除的。
                    let filterFlag = cellViewModel.getThread().isFollow
                        && (cellViewModel.getThreadMessage().isNoTraceDeleted == false)
                    if filterFlag == false {
                        isFilted = true
                    }
                    return filterFlag
                }
                return true
            })

            // 只有数据存在过滤的情况时才去刷新界面
            if isFilted {
                self.publish(.refreshMessages(hasLoading: self.hasMoreOldMessages()))
            }
        }
    }

    // MARK: - private
    private static let logger = Logger.log(ThreadFilterMessagesViewModel.self, category: "Business.ThreadFilter")
    private var cursor: String?
    private let pushCenter: PushNotificationCenter
    private let disposeBag = DisposeBag()
    private let pushHandlerRegister: ThreadChatPushHandlersRegister
    //防止反复调用
    private var loadingMoreOldMessages: Bool = false
    private let threadAPI: ThreadAPI
    private let chatID: String

    fileprivate func send(update: Bool) {
        if update {
            self.publish(.refreshTable)
        }
    }

    private func loadMoreOldMessages() {
        guard hasMoreOldMessages() else {
            return
        }
        if loadingMoreOldMessages {
            return
        }
        self.initDataStatus.accept(.start)
        // filterID: "1"，获取 已订阅 的话题数据。因为现在只有一种，所以这里是写死的ID。
        threadAPI.fetchFilteredThreads(
            channelID: chatID,
            filterID: "1",
            extendFilterID: ["1"],
            scene: .previousPage,
            cursor: self.cursor,
            count: 15,
            preloadCount: 0
        ).observeOn(self.queueManager.dataScheduler)
        .subscribe(onNext: { [weak self] (result) in
            guard let `self` = self else { return }
            self.cursor = result.1
            self.loadingMoreOldMessages = false
            let threadMessages = self.handleThreadMessages(result.0)
            self.appendOldMessages(threadMessages)
        }, onError: { [weak self] (_) in
            guard let `self` = self else { return }
            ThreadFilterMessagesViewModel.logger.info("ThreadFilterTrace 加载更多请求失败 \(self.cursor ?? "") \(self.chatID)")
            self.loadingMoreOldMessages = false
            self.initDataStatus.accept(.error)
        }).disposed(by: disposeBag)
    }

    private func processThreadMessage(_ threadMessage: ThreadMessage) -> [ThreadCellViewModel] {
        var viewModels: [ThreadCellViewModel] = []
        if let metaModel = self.messageDatasource.createThreadMetaData(threadMessage: threadMessage) {
            let messageCellViewModel = self.vmFactory.create(with: metaModel, metaModelDependency: self.getCellDependency())
            viewModels.append(messageCellViewModel)
        } else {
            ThreadFilterMessagesViewModel.logger.error("LarkThread error: processMessages threadMessage no chat")
            assertionFailure("threadMessage no chat")
        }

        return viewModels
    }

    // MARK: supprot reverse FG
    private func handleThreadMessages(_ threadMessages: [ThreadMessage]) -> [ThreadMessage] {
        let firstMessagePosition = self.chatWrapper.chat.value.firstMessagePostion
        return threadMessages.reversed().filter { (msg) -> Bool in
            return msg.isVisible && msg.position > firstMessagePosition
        }
    }

    private func appendOldMessages(_ threadMessages: [ThreadMessage]) {
        let hasChange: Bool = self.messageDatasource.headInsert(
            messages: threadMessages,
            concurrent: self.concurrentHandler,
            processMessage: self.processThreadMessage
        )
        if hasChange {
            self.publish(.loadMoreOldMessages(hasLoading: self.hasMoreOldMessages()))
        } else {
            ThreadFilterMessagesViewModel.logger.info("ThreadFilterTrace 未取得任何有效历史消息")
            self.publish(.updateOldMessageLoadingView(hasLoading: self.hasMoreOldMessages()))
        }
    }

    private func getCellDependency() -> ThreadCellMetaModelDependency {
        return ThreadCellMetaModelDependency(
            contentPadding: 0,
            contentPreferMaxWidth: { [weak self] _ in
                guard let self = self else { return 0 }
                return self.hostUIConfig.size.width - 16 - 16
            }
        )
    }
}

extension ThreadFilterMessagesViewModel: DataSourceAPI {
    func processMessageSelectedEnable(message: Message) -> Bool {
        return true
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
                self.tableRefreshPublish.onNext((.messagesUpdate(indexs: [index]), newDatas: nil, outOfQueue: true))
            }
        } else {
            self.queueManager.addDataProcess { [weak self] in
                if let index = self?.messageDatasource.index(messageId: messageId) {
                    self?.publish(.messagesUpdate(indexs: [index]))
                }
            }
        }
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
            let index = self?.messageDatasource.index(messageId: messageId)
            let needUpdate = self?.messageDatasource.delete(by: { () -> Int? in
                return index
            })
            self?.send(update: needUpdate ?? false)
        }
    }

    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return self.topNoticeSubject
    }
}

extension ThreadFilterMessagesViewModel: HandlePushDataSourceAPI {
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

    func getThreadIndexForMessage(id: String) -> Int? {
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

}

extension ThreadFilterMessagesViewModel: ThreadListViewModel {
    func putRead(threadMessage: ThreadMessage) {
        return
    }

    func loadMoreBottomMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
    }

    func loadMoreTopMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
        loadMoreOldMessages(finish: finish)
    }

    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {
        self.loadMoreOldMessages()
    }

    func findThreadIndexBy(id: String) -> Int? {
        return nil
    }

    func cellViewModel(by id: String) -> ThreadCellViewModel? {
        return self.messageDatasource.cellViewModel(by: id)
    }
}
