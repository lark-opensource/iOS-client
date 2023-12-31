//
//  MessageDetailMessagesViewModel.swift
//  Action
//
//  Created by 赵冬 on 2019/7/23.
//

import UIKit
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
import ThreadSafeDataStructure
import RustPB

enum MessageDetailTableRefreshType: OuputTaskTypeInfo {
    case initMessages(isDisplayLoad: Bool, isSucceed: Bool?, index: IndexPath?)
    case refreshMessages
    case refreshTable
    case hasNewMessage(isForceScrollToBottom: Bool, message: Message)
    case updateKeyBoardEnable(_ enable: Bool, message: Message?)
    case scrollToIndexPath(indexPath: IndexPath)

    func canMerge(type: MessageDetailTableRefreshType) -> Bool {
        return false
    }

    func duration() -> Double {
        var duration: Double = 0.1
        switch self {
        case .hasNewMessage:
            duration = CommonTable.scrollToBottomAnimationDuration
        case .updateKeyBoardEnable:
            duration = 0
        case .refreshTable, .initMessages, .scrollToIndexPath, .refreshMessages:
            break
        }
        return duration
    }

    func isBarrier() -> Bool {
        return false
    }
}

final class MessageDetailMessagesViewModel: AsyncDataProcessViewModel<MessageDetailTableRefreshType, [[MessageDetailCellViewModel]]> {
    let replyIndex = 1

    private let dependency: MessageDetailMessagesVMDependency

    // if it happends rootMessage is nil, then return the rootMessageId, which is tapMessage's rootId
    var rootMessageId: String {
        return self.rootMessage?.id ?? self.tapMessage.rootId
    }
    // 回复的根消息
    var rootMessage: LarkModel.Message?
    // 用户点击的消息
    var tapMessage: LarkModel.Message

    static let logger = Logger.log(MessageDetailViewModel.self, category: "Business.MessageDetail")

    let messageDatasource: MessageDetailMessagesDataSource

    private let disposeBag = DisposeBag()

    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    var traitCollection: UITraitCollection?

    // 加载数据的状态
    enum SyncDataStatus {
        case finish
        case loading
        case none
    }

    // 当前网络状态
    private var currentNetState: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus?
    // 当前加载数据的状态
    private var syncDataStatus: SafeAtomic<SyncDataStatus> = SafeAtomic(.none, with: .readWriteLock)

    /// 判断键盘是否禁用，call in self.queueManager
    private var keyBoardEnable: Bool = true
    private func checkNeedUpdateKeyBoardEnable(_ isEnable: Bool, message: Message?) {
        let realityEnable = self.dependency.chatWrapper.chat.value.isAllowPost && isEnable
        if realityEnable != keyBoardEnable {
            self.publish(.updateKeyBoardEnable(realityEnable, message: message))
        }
        keyBoardEnable = realityEnable
    }

    var editingMessage: Message? {
        didSet {
            if oldValue?.id == editingMessage?.id {
                return
            }
            self.queueManager.addDataProcess { [weak self] in
                guard let `self` = self else { return }
                if let oldValue = oldValue {
                    (self.cellViewModel(by: oldValue.id) as? MessageDetailMessageCellViewModel)?.isEditing = false
                }
                if let newValue = self.editingMessage {
                    (self.cellViewModel(by: newValue.id) as? MessageDetailMessageCellViewModel)?.isEditing = true
                }
                self.publish(.refreshTable)
            }
        }
    }

    // 首屏是否已有可使用的初始数据
    private var initMessageFetchFinish: Bool = false

    init(
        tapMessage: LarkModel.Message,
        rootMessage: LarkModel.Message?,
        messagesDatasource: MessageDetailMessagesDataSource,
        dependency: MessageDetailMessagesVMDependency,
        context: MessageDetailContext) {
            self.tapMessage = tapMessage
            self.rootMessage = rootMessage
            self.dependency = dependency
            self.messageDatasource = messagesDatasource
            super.init(uiDataSource: [])
            self.messageDatasource.contentPreferMaxWidth = { [weak self] _ in
                guard let self = self else { return 0 }
                return self.hostUIConfig.size.width - 2 * 16
            }
            self.queueManager.pauseQueue()
            self.observeData()
    }

    deinit {
        print("MessageDetailMessagesViewModel deinit")
    }

    // tableView滚到点击的cell的事件
    // this func should be placed in queueManager block
    private func getPublishScrollToIndexPath() -> IndexPath? {
        var indexPath: IndexPath?
        if self.messageDatasource.isRootMessageOf(self.tapMessage) {
            indexPath = IndexPath(row: 0, section: 0)
        } else if let cellIndexPath = self.messageDatasource.indexOf(self.tapMessage.id) {
            indexPath = cellIndexPath
        }
        return indexPath
    }

    func initMessages() {
        // rootMessage是本地传参过来的，需要单独处理预览懒加载
        if let message = self.rootMessage {
            self.dependency.urlPreviewService?.fetchMissingURLPreviews(messages: [message])
        }
        self.queueManager.resumeQueue()
        self.judgeRootMessageAndPullDatas()
    }

    // judge rootMessage is nil or not
    // if it is nil , need to fetch rootMessage by rootId
    // and then pull replies
    private func judgeRootMessageAndPullDatas() {
        let messageDetailPageTrackKey = MessageDetailApprecibleTrack.getMessageDetailPageKey()

        if self.rootMessage == nil {
            MessageDetailMessagesViewModel.logger.error("rootMessage为空", additionalData: [
                "rootId": self.rootMessageId
            ])
            self.checkNeedUpdateKeyBoardEnable(false, message: nil)
            let startTime = CACurrentMediaTime()
            self.dependency.messageAPI.fetchMessage(id: self.rootMessageId)
                .subscribeOn(self.queueManager.dataScheduler)
                .subscribe(onNext: { [weak self] (message) in
                    guard let self = self else { return }
                    self.initMessageFetchFinish = true
                    MessageDetailApprecibleTrack.updateSDKCostTrack(key: messageDetailPageTrackKey,
                                                                    cost: CACurrentMediaTime() - startTime)
                    MessageDetailApprecibleTrack.clientDataCostStartTrack(key: messageDetailPageTrackKey)
                    self.rootMessage = message
                    // 消息不可见，删除根消息
                    if !self.checkVisible(message) {
                        self.messageDatasource.delete(self.rootMessageId)
                        self.messageDatasource.existInVisibleMessage = true
                    } else if self.dependency.messageBurnService.isBurned(message: message) {
                        // 消息销毁，删除根消息
                        self.messageDatasource.delete(self.rootMessageId)
                    } else {
                        self.messageDatasource.update(message: message)
                    }

                    self.queueManager.addDataProcess { [weak self] in
                        guard let `self` = self else { return }
                        self.publish(.initMessages(isDisplayLoad: true, isSucceed: nil, index: nil),
                                     outOfQueue: false)
                        self.checkNeedUpdateKeyBoardEnable(!self.messageDatasource.dataSourceIsEmpty, message: message)
                    }
                    self.pullMessageReplies()
                }, onError: { [weak self] (error) in
                    Self.logger.error("fetchMessage error: \(error)")
                    MessageDetailApprecibleTrack.onError(key: messageDetailPageTrackKey, error: error)
                    self?.pullMessageReplies()
                }).disposed(by: self.disposeBag)
        } else {
            MessageDetailApprecibleTrack.clientDataCostStartTrack(key: messageDetailPageTrackKey)
            self.initMessageFetchFinish = true
            self.pullMessageReplies()
        }
    }

    private func pullMessageReplies() {
        // 过滤掉被删除/已销毁/不可见的消息
        func filterMessages(_ messages: [Message]) -> [Message] {
            return messages.filter({
                // code_next_line tag CryptChat
                !$0.isDeleted && !self.dependency.messageBurnService.isBurned(message: $0) && self.checkVisible($0)
            })
        }
        self.syncDataStatus.value = .loading
        Observable<[LarkModel.Message]>
            .create { [unowned self] (observer) -> Disposable in
                var replies: [LarkModel.Message] = []
                do {
                    // 这里不能提前过滤删除/销毁的消息，某些场景会造成流量浪费
                    // 例如：A有4条回复消息A.replyCount=4，但有2条被删除/焚毁了，那么此处过滤后replies.count=2，会导致下一步判断
                    //    replies.count!=A.replyCount时成立，然后去从服务端拉取回复消息
                    // 优化：在下一步replies.count!=A.replyCount判断后过滤删除/销毁的消息
                    replies = try self.dependency.messageAPI.getReplies(messageId: self.rootMessageId)
                } catch {
                    MessageDetailMessagesViewModel.logger.error("获取本地replies失败", additionalData: [
                        "rootId": self.rootMessageId
                    ], error: error)
                    self.queueManager.addDataProcess { [weak self] in
                        self?.publish(.initMessages(isDisplayLoad: false, isSucceed: false, index: nil), outOfQueue: false)
                    }
                }
                observer.onNext(replies)
                observer.onCompleted()
                return Disposables.create()
            }
            .subscribeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages) in
                guard let self = self else { return }
                let localSuccessRepliesCount = messages.count
                // 只要不相同就拉取
                if self.rootMessage?.replyCount != 0, self.rootMessage?.replyCount != Int32(localSuccessRepliesCount) {
                    self.dependency.messageAPI.fetchReplies(messageId: self.rootMessageId)
                        .subscribeOn(self.queueManager.dataScheduler)
                        .subscribe(onNext: { [weak self] (messages) in
                            guard let self = self else { return }
                            self.syncDataStatus.value = .finish
                            // 过滤删除/销毁的消息
                            self.messageDatasource.replaceReplies(messages: filterMessages(messages))
                            self.checkNeedUpdateKeyBoardEnable(!self.messageDatasource.dataSourceIsEmpty, message: nil)
                            self.publish(.initMessages(isDisplayLoad: false, isSucceed: true, index: self.getPublishScrollToIndexPath()), outOfQueue: false)
                        }, onError: { [weak self] (error) in
                            guard let self = self else { return }
                            MessageDetailMessagesViewModel.logger.error(
                                "加载回复失败",
                                additionalData: ["rootId": self.rootMessageId],
                                error: error)
                            // 过滤删除/销毁的消息
                            self.updateRepliesFromLocal(messages: filterMessages(messages))
                        })
                        .disposed(by: self.disposeBag)
                } else {
                    // 过滤删除/销毁的消息
                    self.updateRepliesFromLocal(messages: filterMessages(messages))
                }
            })
            .disposed(by: disposeBag)
    }

    /// messages：已经过滤了删除/销毁的消息
    private func updateRepliesFromLocal(messages: [Message]) {
        self.syncDataStatus.value = .finish
        self.messageDatasource.replaceReplies(messages: messages)
        self.checkNeedUpdateKeyBoardEnable(!self.messageDatasource.dataSourceIsEmpty, message: nil)
        self.publish(.initMessages(isDisplayLoad: false, isSucceed: true, index: getPublishScrollToIndexPath()), outOfQueue: false)
    }

    private func observeData() {
        self.dependency.pushHandlerRegister.startObserve(self)

        self.dependency.pushChannelMessages
            .map({ [weak self] (push) -> [Message] in
                return push.messages.filter({ (msg) -> Bool in
                    return msg.channel.id == self?.dependency.channelId &&
                        (msg.message.rootId == self?.rootMessageId || msg.message.id == self?.rootMessageId)
                })
            })
            .filter({ (msgs) -> Bool in
                return !msgs.isEmpty
            })
            .observeOn(self.queueManager.dataScheduler)
            .subscribe(onNext: { [weak self] (messages) in
                guard let self = self else { return }
                var needUpdate = false
                for message in messages {
                    switch self.messageDatasource.handle(message: message) {
                    case .deleteMessage, .updateReply:
                        needUpdate = true
                    case .updateRoot:
                        self.rootMessage = message
                        needUpdate = true
                    case .newReply:
                        self.publish(.hasNewMessage(isForceScrollToBottom: false, message: message), outOfQueue: false)
                    case .none:
                        continue
                    }
                }
                if needUpdate {
                    self.checkNeedUpdateKeyBoardEnable(!self.messageDatasource.dataSourceIsEmpty, message: nil)
                    self.publish(.refreshMessages, outOfQueue: false)
                }
                self.dependency.urlPreviewService?.fetchMissingURLPreviews(messages: messages)
            }).disposed(by: self.disposeBag)

        //网络从无到有时，需要重新拉取回复
        dependency.pushDynamicNetStatusObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                // 进详情页时无网再到网络恢复场景currentNetState为空
                // 也要拉取重新拉取回复
                if self?.currentNetState == nil || self?.currentNetState == .offline {
                    switch push.dynamicNetStatus {
                    case .evaluating, .weak, . excellent:
                        if self?.syncDataStatus.value != .loading {
                            self?.pullMessageReplies()
                        }
                    @unknown default:
                        break
                    }
                }
                self?.currentNetState = push.dynamicNetStatus
            })
            .disposed(by: disposeBag)
    }

    private func isNeedRemove(message: LarkModel.Message) -> Bool {
        if self.messageDatasource.isRootMessageOf(message) {
            if dependency.messageBurnService.isBurned(message: message) { return true }
            return false
        }
        if message.isDeleted || dependency.messageBurnService.isBurned(message: message) {
            return true
        }
        return false
    }

    private func publish(_ type: MessageDetailTableRefreshType, outOfQueue: Bool = false) {
        var dataUpdate: Bool = true
        switch type {
        case .updateKeyBoardEnable:
            dataUpdate = false
        case .initMessages(isDisplayLoad: let displayLoad, _, _):
            if displayLoad == false {
                // loading用于展示回复是否在加载，displayLoad == false, 说明拉到了评论
                // 此处设置为了处理根消息没拉到情况下，拉到了回复
                self.initMessageFetchFinish = true
            }
        default:
            break
        }
        let cellVMs = initMessageFetchFinish ? self.messageDatasource.renderCellViewModels : [[], []]
        self.tableRefreshPublish.onNext((type, newDatas: dataUpdate ? cellVMs : nil, outOfQueue: outOfQueue))
    }

    /// 检查消息是否可见
    func checkVisible(_ message: Message) -> Bool {
        return messageDatasource.checkVisible(message)
    }

    /// 根据消息 id和 cid 查找对应位置
    ///
    /// - Parameters:
    ///   - id: id is messageId or messageCid
    /// - Returns: indexPath in datasource
    func findMessageIndexBy(id: String) -> IndexPath? {
        guard !id.isEmpty else {
            return nil
        }
        if self.messageDatasource.isRootMessageOf(id) {
            return IndexPath(row: 0, section: 0)
        }
        let index = self.uiDataSource[replyIndex].firstIndex { (cellVM) -> Bool in
            if let messageVM = cellVM as? HasMessage {
                return messageVM.message.id == id || messageVM.message.cid == id
            }
            return false
        }
        guard let row = index else { return nil }
        return IndexPath(row: row, section: replyIndex)
    }

    /// - Parameters:
    ///   - id: id is messageId or messageCid
    public func cellViewModel(by id: String) -> MessageDetailCellViewModel? {
        return self.uiDataSource.flatMap { $0 }.first(where: { (cellVM) -> Bool in
            if let messageCellVM = cellVM as? HasMessage {
                return messageCellVM.message.id == id || messageCellVM.message.cid == id
            }
            return false
        })
    }

    func onResize() {
        self.queueManager.addDataProcess { [weak self] in
            self?.messageDatasource.onResize()
            self?.send(update: true)
        }
    }

    func putRead(element: LarkModel.Message) {
        self.dependency.chatMessageReadService.putRead(element: element, urgentConfirmed: nil)
    }

    func setReadService(enable: Bool) {
        self.dependency.chatMessageReadService.set(enable: enable)
    }

    func send(update: Bool) {
        if update {
            self.publish(.refreshTable)
        }
    }

}

extension MessageDetailMessagesViewModel: HandlePushDataSourceAPI {
    func update(messageIds: [String], doUpdate: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(messageIds: messageIds, doUpdate: { (msg) -> LarkModel.Message? in
                return doUpdate(msg) as? LarkModel.Message
            }) ?? false
            completion?(needUpdate)
            self?.send(update: needUpdate)
        }
    }

    func update(original: @escaping (PushData) -> PushData?, completion: ((Bool) -> Void)?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(original: { (msg) -> LarkModel.Message? in
                return original(msg) as? LarkModel.Message
            }) ?? false
            completion?(needUpdate)
            self?.send(update: needUpdate)
        }
    }
}

extension MessageDetailMessagesViewModel: DataSourceAPI {
    func reloadTable() {
        self.queueManager.addDataProcess { [weak self] in
            self?.publish(.refreshTable)
        }
    }

    func reloadRow(by messageId: String, animation: UITableView.RowAnimation = .fade) {
        self.queueManager.addDataProcess { [weak self] in
            self?.send(update: true)
        }
    }

    var scene: ContextScene {
        return .messageDetail
    }

    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return self.uiDataSource
            .flatMap({ $0 })
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

    func reloadRows(by messageIds: [String], doUpdate: @escaping (LarkModel.Message) -> LarkModel.Message?) {
        self.queueManager.addDataProcess { [weak self] in
            let needUpdate = self?.messageDatasource.update(messageIds: messageIds, doUpdate: doUpdate) ?? false
            self?.send(update: needUpdate)
        }
    }

    func deleteRow(by messageId: String) {
        self.queueManager.addDataProcess { [weak self] in
            guard let self = self else { return }
            let deleteSuccess = self.messageDatasource.delete(messageId)
            if deleteSuccess {
                self.checkNeedUpdateKeyBoardEnable(!self.messageDatasource.dataSourceIsEmpty, message: nil)
            }
            self.send(update: deleteSuccess)
        }
    }

    func processMessageSelectedEnable(message: LarkModel.Message) -> Bool {
        return true
    }

    func currentTopNotice() -> BehaviorSubject<ChatTopNotice?>? {
        return nil
    }
}
