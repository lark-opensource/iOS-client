//
//  ReplyInThreadForwardDetailViewModel.swift
//  LarkThread
//
//  Created by liluobin on 2022/6/24.
//
import Foundation
import UIKit
import LarkCore
import RustPB
import LarkMessengerInterface
import LarkMessageCore
import LarkMessageBase
import LarkSDKInterface
import LarkModel
import LarkContainer
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkOpenChat

final class ReplyInThreadForwardDetailViewModel: ThreadDetailTableViewDataSource, UserResolverWrapper {
    let userResolver: UserResolver
    private static let logger = Logger.log(ReplyInThreadForwardDetailViewModel.self, category: "LarkThread.ReplyInThreadForwardDetailViewModel")
    enum TableRefreshType {
        case startMultiSelect(startIndex: IndexPath)
        case finishMultiSelect
        case refreshTable
        case messagesUpdate(indexs: [IndexPath], guarantLastCellVisible: Bool)
    }
    let threadMessageSection = 0
    let replysSection = 1
    let originMergeForwardId: String
    let replyMessages: [Message]
    let rootMessage: Message
    let forwardMessage: Message? //转发的message;为nil时表示不可转发
    private let _replyCount: Int
    var messages: [Message] {
        return [rootMessage] + replyMessages
    }
    let fromChatChatters: [String: Chatter]
    let reactionSnapshots: [String: RustPB.Basic_V1_MergeForwardContent.MessageReaction]
    let context: ThreadDetailContext
    var threadMessage: ThreadMessage?
    let thread: RustPB.Basic_V1_Thread
    let chat: Chat
    var uiDataSource: [[ThreadDetailCellViewModel]] = []
    var hostUIConfig: HostUIConfig = .init(size: .zero, safeAreaInsets: .zero)
    @ScopedInjectedLazy var menuService: ThreadMenuService?
    @ScopedInjectedLazy var generalSettings: UserGeneralSettings?
    let inSelectMode: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    let pickedMessages = BehaviorRelay<[ChatSelectedMessageContext]>(value: [])
    lazy var dataQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "msg.thread.detail.data.queue", qos: .userInitiated)
        return queue
    }()
    private let disposeBag = DisposeBag()
    /// 刷新信号
    var tableRefreshPublish: PublishSubject<TableRefreshType> = PublishSubject<TableRefreshType>()
    private var factory: ThreadReplyMessageCellViewModelFactory?

    init(userResolver: UserResolver,
         originMergeForwardId: String,
         context: ThreadDetailContext,
         chat: Chat,
         thread: RustPB.Basic_V1_Thread,
         forwardMessage: Message?,
         rootMessage: Message,
         replyMessages: [Message],
         replyCount: Int,
         fromChatChatters: [String: Chatter],
         reactionSnapshots: [String: RustPB.Basic_V1_MergeForwardContent.MessageReaction]) {
        self.userResolver = userResolver
        self.originMergeForwardId = originMergeForwardId
        self.context = context
        self.chat = chat
        self.forwardMessage = forwardMessage
        self.replyMessages = replyMessages
        self.rootMessage = rootMessage
        self._replyCount = replyCount
        self.fromChatChatters = fromChatChatters
        self.reactionSnapshots = reactionSnapshots
        self.thread = thread
        self.addObserver()
        Self.logger.info("originMergeForwardId: ---- \(originMergeForwardId)")
    }

    func addObserver() {
        generalSettings?.is24HourTime.asObservable()
            .skip(1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.refreshUIOnTimeStyleChange()
            }).disposed(by: disposeBag)
    }

    func loadData() {
        let chat = self.chat
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            self.fixMessageContent()
            guard let threadMessage = self.threadMessage, let vmFactory = self.factory else { return }
            self.uiDataSource = [[vmFactory.create(with: ThreadDetailMetaModel(message: threadMessage.rootMessage,
                                                                                    isPrivateThread: true,
                                                                                    originMergeForwardId: self.originMergeForwardId,
                                                                                    getChat: { chat }),
                                                   metaModelDependency: self.getCellDependency())],
                                 threadMessage.replyMessages.map({ (message) -> ThreadDetailCellViewModel in
                                 vmFactory.create(with: ThreadDetailMetaModel(message: message,
                                                                                      isPrivateThread: true,
                                                                                      originMergeForwardId: self.originMergeForwardId,
                                                                                      getChat: { chat }),
                                                  metaModelDependency: self.getCellDependency())
                                 })]
            self.tableRefreshPublish.onNext(.refreshTable)
        }
    }

    func constructThreadMessageAndFactoryData() {
        Self.logger.info("messagesCount --- \(messages.count) \(rootMessage.threadId)")
        let threadMessage = ThreadMessage(thread: thread, rootMessage: rootMessage, replyMessages: replyMessages)
        let threadWrapper = threadWrappperItem(thread: thread)
        let factory = ThreadReplyMessageCellViewModelFactory(
            threadWrapper: threadWrapper,
            context: context,
            registery: ReplyInThreadForwardDetailSubFactoryRegistery(context: context),
            threadMessage: threadMessage,
            cellLifeCycleObseverRegister: ThreadDetailCellLifeCycleObseverRegister(),
            messageTypeOfDisableAction: [.calendar, .generalCalendar, .shareCalendarEvent, .todo]
        )
        self.factory = factory
        self.threadMessage = threadMessage
    }

    /// subMessages有时数据携带不全，需要自己填充chatter和parentMsg
    private func fixMessageContent() {
        let messageIds = messages.map({ $0.id })
        var channel = RustPB.Basic_V1_Channel()
        channel.id = chat.id
        channel.type = .chat
        messages.forEach { message in
            if let chatter = fromChatChatters[message.fromId] {
                message.fromChatter = chatter
            }
            if let reactionInfo = reactionSnapshots[message.id] {
                let reactions = reactionInfo.reactions.map { (reactionData) -> Reaction in
                    let reaction = Reaction(type: reactionData.type, chatterIds: reactionData.chatterIds, chatterCount: reactionData.count)
                    reaction.chatters = reactionData.chatterIds.compactMap({ userID in
                        if let value = fromChatChatters[userID] {
                            return value
                        }
                         return nil
                    })
                    return reaction
                }
                message.reactions = reactions
            }
            /// 这里做个兜底 如果层级关系没有对应 对应一下
            if let parentIndex = messageIds.firstIndex(where: { return $0 == message.parentId }) {
                message.parentMessage = messages[parentIndex]
            }
            message.channel = channel
        }
    }
    func showHeader(section: Int) -> Bool {
        return section == replysSection
    }

    func showFooter(section: Int) -> Bool {
        return false
    }

    func showReplyMessageLastSepratorLine(section: Int) -> Bool {
        return false
    }

    func replyCount() -> Int {
        return _replyCount
    }

    func replysIndex() -> Int {
        return replysSection
    }

    func threadHeaderHeightFor(section: Int) -> CGFloat {
        return ReplyInThreadHeaderViewConfig.headerHeight
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

    func cellViewModel(by id: String) -> ThreadDetailCellViewModel? {
        return nil
    }

    func findMessageIndexBy(id: String) -> IndexPath? {
        return nil
    }

    func loadMoreNewMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {

    }

    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?) {

    }

    // MARK: - 多选相关
    /// 获取被选中的消息
    func getPickedMessage() -> [Message] {
        let cellViewModels = uiDataSource
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
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            guard let indexPath = self.indexPath(by: messageId) else {
                return
            }
            self.inSelectMode.accept(true)
            let cellViewModel = self.uiDataSource[indexPath.section][indexPath.row]
            (cellViewModel as? ThreadReplyMessageCellViewModel)?.checked = true
            self.pickedMessages.accept(self.getPickedMessage())
            self.tableRefreshPublish.onNext(.startMultiSelect(startIndex: indexPath))
        }
    }

    func finishMultiSelect() {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            self.uiDataSource.forEach({ (cellViewModels) in
                cellViewModels.forEach({ (viewModel) in
                    (viewModel as? ThreadReplyMessageCellViewModel)?.checked = false
                })
            })
            self.inSelectMode.accept(false)
            self.tableRefreshPublish.onNext(.finishMultiSelect)
        }
    }

    func toggleSelectedMessage(by messageId: String) {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            self.pickedMessages.accept(self.getPickedMessage())
            self.tableRefreshPublish.onNext(.refreshTable)
        }
    }

    func indexPath(by messageId: String) -> IndexPath? {
        for (section, viewModels) in self.uiDataSource.enumerated() {
            if let index = viewModels.firstIndex(where: { (cellViewModel) -> Bool in
                if let viewModel = cellViewModel as? HasMessage {
                    return viewModel.message.id == messageId
                }
                return false
            }) {
                return IndexPath(item: index, section: section)
            }
        }
        return nil
    }

    func refreshUIOnTimeStyleChange() {
        self.refreshRenders()
        self.tableRefreshPublish.onNext(.refreshTable)
    }

    // MARK: - iPad适配
    func onResize() {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            for data in self.uiDataSource {
                data.forEach { (cellVM) in
                    cellVM.onResize()
                }
            }
            self.tableRefreshPublish.onNext(.refreshTable)
        }
    }
    func refreshRenders() {
        for cellvm in self.uiDataSource[threadMessageSection] {
            cellvm.calculateRenderer()
        }
        for cellvm in self.uiDataSource[replysSection] {
            cellvm.calculateRenderer()
        }
    }

    private func getCellDependency() -> ThreadDetailCellMetaModelDependency {
        return ThreadDetailCellMetaModelDependency(
            contentPadding: 0,
            contentPreferMaxWidth: { [weak self] message in
                return self?.getContentPreferMaxWidth(message) ?? 0
            }
        )
    }
}

extension ReplyInThreadForwardDetailViewModel: DataSourceAPI {
    func reloadRow(by messageId: String, animation: UITableView.RowAnimation) {
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
        self.dataQueue.async { [weak self] in
            if let indexPath = calculateRenderer(datas: self?.uiDataSource ?? []) {
                self?.tableRefreshPublish.onNext(.messagesUpdate(indexs: [indexPath], guarantLastCellVisible: false))
            }
        }
    }
    var traitCollection: UITraitCollection? {
        return nil
    }

    func processMessageSelectedEnable(message: Message) -> Bool {
        return true
    }

    var scene: ContextScene {
        return .threadPostForwardDetail
    }

    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>] {
        return uiDataSource
            .flatMap { $0 }
            .compactMap { $0 as? MessageCellViewModel<M, D, T> }
            .filter(predicate)
    }

    func pauseDataQueue(_ pause: Bool) {}

    func reloadTable() {
        self.tableRefreshPublish.onNext(.refreshTable)
    }

    func reloadRows(by messageIds: [String], doUpdate: @escaping (Message) -> Message?) {}

    func deleteRow(by messageId: String) {
    }

    func getContentPreferMaxWidth(_ message: Message) -> CGFloat {
        // rootMessage
        var width: CGFloat = 0
        if message.threadId == message.id {
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
